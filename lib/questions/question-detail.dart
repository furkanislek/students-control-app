import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:students_follow_app/services/auth.dart';

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

  Future<void> _markCorrectAnswer(String commentId) async {
    try {
      await _firestore
          .collection('comments')
          .where('questionId', isEqualTo: widget.question['questionId'])
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          String docId = doc.id;

          // Belgeyi güncelle
          FirebaseFirestore.instance.collection('comments').doc(docId).update({
            'isCorrectAnswer': true,
          });
        });
      });
    } catch (e) {
      print(e);
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
                Navigator.of(context).pop(); // Modalı kapat
              },
            ),
            TextButton(
              child: const Text("Sil"),
              onPressed: () async {
                await _deleteComment(commentId);
                Navigator.of(context).pop(); // Modalı kapat
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
                  commentId)) // commentId'yi int'e çevirerek kontrol ediyoruz.
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          String docId = doc.id; // İlgili belgeyi buluyoruz.

          // Belgeyi siliyoruz.
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${widget.question['category'] ?? 'No Category'}',
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
            Text(
              widget.question['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              widget.question['description'] ?? 'No Information',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCommenting = !_isCommenting;
                });
              },
              child:
                  Text(_isCommenting ? 'Yorum Yapmayı İptal Et' : 'Yorum Yap'),
            ),

            if (_isCommenting) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Yorumunuzu yazın',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Resim Ekle'),
                  ),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitComment,
                child: const Text('Yorumu Gönder'),
              ),
            ],

            const SizedBox(height: 20),
            ListView.builder(
              itemCount: _comments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final isQuestionOwner =
                    currentUserUid == widget.question['uid'];

                return GestureDetector(
                  onLongPress: isQuestionOwner
                      ? () => _showDeleteConfirmationDialog(
                          context, comment["commentId"].toString())
                      : null,
                  child: Card(
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
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              comment['comment'] ?? 'No Comment',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              DateTime.fromMillisecondsSinceEpoch(
                                      comment['dateTime'])
                                  .toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          if (isQuestionOwner)
                            IconButton(
                              icon: Icon(
                                Icons.star,
                                color: comment['isCorrectAnswer'] == true
                                    ? const Color.fromARGB(255, 190, 147, 15)
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                _markCorrectAnswer(
                                    comment['commentId'].toString());
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
