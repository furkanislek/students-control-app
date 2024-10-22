import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:students_follow_app/pages/Profile/profile.dart';
import 'package:students_follow_app/services/auth.dart';
import 'package:students_follow_app/utils/category-utils.dart';

class QuestionDetail extends StatefulWidget {
  final Map<String, dynamic> question;

  const QuestionDetail({Key? key, required this.question}) : super(key: key);

  @override
  State<QuestionDetail> createState() => _QuestionDetailState();
}

class _QuestionDetailState extends State<QuestionDetail> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCommenting = false;
  final TextEditingController _commentController = TextEditingController();
  File? _selectedImage;
  List<Map<String, dynamic>> _comments = [];
  String? commentUserId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    QuerySnapshot snapshot = await _firestore
        .collection('comments')
        .where('questionId', isEqualTo: widget.question['questionId'])
        .get();

    List<Map<String, dynamic>> comments =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    comments.sort((a, b) {
      return (b['commentId'] ?? 0).compareTo(a['commentId'] ?? 0);
    });

    setState(() {
      _comments = comments;
    });
  }

  Future<void> _markCorrectAnswer(String commentId, bool currentValue) async {
    try {
      bool newCorrectAnswerValue = !currentValue;

      QuerySnapshot commentSnapshot = await _firestore
          .collection('comments')
          .where('questionId', isEqualTo: widget.question['questionId'])
          .where('commentId', isEqualTo: int.parse(commentId))
          .get();

      if (commentSnapshot.docs.isNotEmpty) {
        setState(() {
          commentUserId = commentSnapshot.docs.first['commentUserId'];
        });
        print('Comment User ID: $commentUserId'); 
      } else {
        print('No comment found for commentId: $commentId');
        return; 
      }

      await _firestore
          .collection('comments')
          .doc(commentSnapshot.docs.first.id)
          .update({
        'isCorrectAnswer': newCorrectAnswerValue,
      });

      _fetchComments();
      updateUserPoint(newCorrectAnswerValue);
    } catch (e) {
      print(e);
    }
  }

Future<void> updateUserPoint(bool isCorrectAnswer) async {
    var docRef = await _firestore
        .collection("users")
        .where("uid", isEqualTo: commentUserId)
        .limit(1)
        .get();

    if (docRef.docs.isNotEmpty) {
      var userDoc = docRef.docs.first;

      if (isCorrectAnswer) {
        await userDoc.reference.update({
          "userPoint": FieldValue.arrayUnion([
            {
              'dateTime': DateTime.now().millisecondsSinceEpoch,
              "userPoint": 10, // Örnek puan değeri
              "questionId": widget.question["questionId"]
            }
          ])
        });
      } else {
        var userData = userDoc.data();
        List<dynamic> userPoints = userData["userPoint"] ?? [];

        var pointToRemove;
        for (var point in userPoints) {
          if (point is Map<String, dynamic> &&
              point["questionId"] == widget.question["questionId"]) {
            pointToRemove = point;
            break; 
          }
        }

        if (pointToRemove != null) {
          await userDoc.reference.update({
            "userPoint": FieldValue.arrayRemove([pointToRemove])
          });
        }
      }
    } else {
      print("docRef.docs.isEmpty");
    }
  }

  Future<int> _getLatestCommentId() async {
    final snapshot = await _firestore
        .collection('comments')
        .orderBy('commentId', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['commentId'] as int;
    } else {
      return 0;
    }
  }

  Future<void> saveImageToFirestoreComment(
      String? selectedImage, String? comment, bool correctAnswer) async {
    int latestCommentId = await _getLatestCommentId();
    int newCommentId = latestCommentId + 1;
    try {
      await FirebaseFirestore.instance.collection("comments").add({
        "commentId": newCommentId,
        "comment": comment,
        "questionId": widget.question["questionId"],
        "commentUserId": Auth().currentUser?.uid,
        "isCorrectAnswer": correctAnswer,
        "selectedImage": selectedImage,
        "dateTime": DateTime.now().millisecondsSinceEpoch
      });
      _fetchComments();
    } catch (e) {
      print(e);
    }
  }

  void _submitComment() async {
    final commentText = _commentController.text;

    if (commentText.isNotEmpty || _selectedImage != null) {
      String? base64Image;

      if (_selectedImage != null) {
        List<int> imageBytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      await saveImageToFirestoreComment(
          base64Image, _commentController.text, false);

      setState(() {
        _commentController.clear();
        _selectedImage = null;
        _isCommenting = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Görsel başarıyla yüklendi.")),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Yorumu Sil"),
          content: const Text("Bu yorumu silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              child: const Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              child: const Text("Sil"),
              onPressed: () async {
                await _deleteComment(commentId);
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore
          .collection('comments')
          .where('commentId',
              isEqualTo: int.parse(
                  commentId)) 
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          String docId = doc.id; 

          FirebaseFirestore.instance.collection('comments').doc(docId).delete();
        });
      });

      setState(() {
        _comments.removeWhere(
            (comment) => comment['commentId'].toString() == commentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorum başarıyla silindi.")),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorum silinirken bir hata oluştu.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = Auth().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question['title'] ?? 'Question Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getCategoryString(widget.question["category"]) ,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    DateFormat('dd-MM-yyyy HH:mm').format(
                        DateTime.fromMicrosecondsSinceEpoch(
                            widget.question['dateTime'])),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 8),
                widget.question['image'] != null
                    ? Image.memory(
                        Base64Decoder().convert(widget.question['image']),
                        fit: BoxFit.fill,
                        height: 220,
                        width: double.infinity,
                      )
                    : const SizedBox(
                        height: 100, child: Placeholder()), // Placeholder

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.question['title'] ?? 'No Title',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Profile(userID: widget.question["uid"]),
                                ),
                              );
                            },
                            child: Text(
                              widget.question['nickName'] ?? "",
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 76, 52, 117)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        widget.question['description'] ?? 'No Information',
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.comment),
              onPressed: () {
                setState(() {
                  _isCommenting = !_isCommenting;
                });
              },
              label: Text(
                _isCommenting ? 'Cevap yazmayı İptal Et' : 'Cevap Yaz',
              ),
            ),
            if (_isCommenting) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Yorumunuzu yazın',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    borderSide: BorderSide(color: Color.fromARGB(0, 8, 8, 70)),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Resim Ekle'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send),
                    label: const Text('Yorumu Gönder'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 10),
                  if (_selectedImage != null)
                    Image.file(
                      _selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ListView.builder(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 0.0),
              itemCount: _comments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final isQuestionOwner =
                    currentUserUid == widget.question['uid'];
                final isCommentOwner =
                    currentUserUid == comment["commentUserId"];
                final isCorrectAnswer = comment['isCorrectAnswer'] == true;

                return GestureDetector(
                  onLongPress: isCommentOwner
                      ? () => _showDeleteConfirmationDialog(
                          context, comment["commentId"].toString())
                      : null,
                  child: Card(
                    color: isCorrectAnswer
                        ? Colors.green[50]
                        : Colors.white, // Doğru cevapsa arka planı yeşil yap
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isCorrectAnswer
                            ? Colors.green
                            : Colors.grey, // Doğru cevapsa kenarlığı yeşil yap
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (comment['selectedImage'] != null) ...[
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                Base64Decoder()
                                    .convert(comment['selectedImage']),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ],
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  // Wrap Text in Expanded to prevent overflow
                                  child: Text(
                                    comment['comment'] ?? 'No Comment',
                                    textAlign: TextAlign
                                        .justify, // Optional: Justify the text
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow
                                        .ellipsis, // Add overflow handling
                                    maxLines:
                                        10, // Adjust maxLines as per your UI requirements
                                  ),
                                ),
                                if (isQuestionOwner)
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_box,
                                      color: isCorrectAnswer
                                          ? const Color.fromARGB(255, 2, 153,
                                              39) // Gold color if true
                                          : const Color.fromARGB(255, 219, 217,
                                              217), // Grey color if false
                                    ),
                                    onPressed: () {
                                      _markCorrectAnswer(
                                          comment['commentId'].toString(),
                                          isCorrectAnswer);
                                    },
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                          comment['dateTime'])
                                      .toString(),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  widget.question["nickName"],
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
