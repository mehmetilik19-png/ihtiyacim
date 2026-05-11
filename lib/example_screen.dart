import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_comment_service.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  String? comment;
  bool loading = false;

  Future<void> takePhotoAndComment() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    setState(() {
      loading = true;
      comment = null;
    });

    try {
      final result =
      await PhotoCommentService.uploadAndGetComment(File(photo.path));

      setState(() {
        comment = result;
      });
    } catch (e) {
      setState(() {
        comment = 'Hata: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto Yorum')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: loading ? null : takePhotoAndComment,
              child: const Text('Foto çek ve yorum al'),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (comment != null) Text(comment!),
          ],
        ),
      ),
    );
  }
}