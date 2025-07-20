import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool isUploading = false;
  double uploadProgress = 0.0;

  Future<void> uploadFiles() async {
    final directory = Directory('/storage/emulated/0/Download');
    final imageFiles = directory.listSync().where((file) => file.path.endsWith('.jpg')).toList();
    final imuDataFile = File('${directory.path}/$imuDataFileName');

    setState(() {
      isUploading = true;
    });

    for (var i = 0; i < imageFiles.length; i++) {
      var request = http.MultipartRequest('POST', Uri.parse('https://yourserver.com/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFiles[i].path));
      request.files.add(await http.MultipartFile.fromPath('imu', imuDataFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          uploadProgress = (i + 1) / imageFiles.length;
        });
      } else {
        // Handle error
      }
    }

    setState(() {
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isUploading ? null : uploadFiles,
              child: Text('Upload'),
            ),
            if (isUploading)
              LinearProgressIndicator(value: uploadProgress),
          ],
        ),
      ),
    );
  }
}
