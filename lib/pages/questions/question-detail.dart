import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:Tudora/pages/Profile/profile.dart';
import 'package:Tudora/services/auth.dart';
import 'package:Tudora/utils/category-utils.dart';

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
              "userPoint": 10,
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

  Future<void> updateCommenCountPoint() async {
    var docRef = await _firestore
        .collection("questions")
        .where("questionId", isEqualTo: widget.question['questionId'])
        .limit(1)
        .get();

    if (docRef.docs.isNotEmpty) {
      var comments = docRef.docs.first;
      if (comments.exists) {
        await comments.reference
            .update({"commentCount": FieldValue.increment(1)});
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
    updateCommenCountPoint();
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
          .where('commentId', isEqualTo: int.parse(commentId))
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
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;

    final currentUserUid = Auth().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question['title'] ?? 'Question Detail'),
        backgroundColor: const Color(0xfff2f2f2),
      ),
      body: Container(
        color: const Color(0xfff2f2f2),
        child: SingleChildScrollView(
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
                      getCategoryString(widget.question["category"]),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      DateFormat("d MMMM y - HH:mm", "tr_TR").format(
                          DateTime.fromMicrosecondsSinceEpoch(
                              widget.question['dateTime'])),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
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
                          height: height / 4,
                          width: double.infinity,
                        )
                      : SizedBox(height: height / 8.9, child: Placeholder()),
                  SizedBox(height: height / 110),
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
                                fontSize: 15,
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
                                    fontSize: 15,
                                    color: Color.fromARGB(255, 76, 52, 117)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height / 55.625),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255)
                                          .withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.question['description'] ??
                                  'No Information',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: height / 44.5),
              ListView.builder(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 0.0),
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
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 192, 192, 192)
                                .withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Card(
                        color:
                            isCorrectAnswer ? Colors.green[50] : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isCorrectAnswer
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: height / 89, right: width / 41),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: width / 34.25),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment['comment'] ?? 'No Comment',
                                        textAlign: TextAlign.justify,
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 10,
                                      ),
                                    ),
                                    if (isQuestionOwner)
                                      IconButton(
                                        icon: Icon(
                                          Icons.check_box,
                                          color: isCorrectAnswer
                                              ? const Color.fromARGB(
                                                  255, 2, 153, 39)
                                              : const Color.fromARGB(
                                                  255, 219, 217, 217),
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
                                padding: EdgeInsets.symmetric(
                                    vertical: 5.0, horizontal: width / 34.25),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat("d MMMM, y", "tr_TR")
                                          .format(DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  comment['dateTime']))
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      widget.question["nickName"],
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: height / 35.6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.comment,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCommenting = !_isCommenting;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8256DF),
                    padding: EdgeInsets.symmetric(
                        vertical: height / 59.33, horizontal: width / 4.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  label: Text(
                    _isCommenting ? 'Cevap yazmayı İptal Et' : 'Cevap Yaz',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (_isCommenting) ...[
                SizedBox(height: height / 44.5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        "Yorumunuzu Yazınız",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF282625),
                        ),
                      ),
                    ),
                    SizedBox(height: height / 89),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: height / 89),
                          TextField(
                            controller: _commentController,
                            textInputAction: TextInputAction.done,
                            minLines: 2,
                            maxLines: 2,
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height / 89),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: width * 0.4,
                      height: height * 0.054,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8256DF),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text('Resim Ekle',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: height / 89),
                    SizedBox(
                      width: width * 0.4,
                      height: height * 0.054,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8256DF),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Yorumu Gönder',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height / 89),
                Row(
                  children: [
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        height: height / 5,
                        width: width / 1.2,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ],
              SizedBox(height: height / 89),
            ],
          ),
        ),
      ),
    );
  }
}
