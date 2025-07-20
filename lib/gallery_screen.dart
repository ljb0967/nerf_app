import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> videoFiles = [];
  bool isDownloading = false;
  double downloadProgress = 0.0;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    loadVideoFiles();
  }

  Future<void> loadVideoFiles() async {
    // Assume the server returns a list of video URLs and names
    // Replace with actual server API call
    videoFiles = [
      {'name': 'Video 1', 'url': 'https://yourserver.com/videos/video1.mp4'},
      {'name': 'Video 2', 'url': 'https://yourserver.com/videos/video2.mp4'},
    ];
    setState(() {});
  }

  Future<void> downloadVideo(String url, String fileName) async {
    setState(() {
      isDownloading = true;
    });

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final response = await http.get(Uri.parse(url));
    final total = response.contentLength;
    int received = 0;

    file.writeAsBytesSync([], mode: FileMode.write);

    response.stream.listen(
          (chunk) {
        file.writeAsBytesSync(chunk, mode: FileMode.append);
        received += chunk.length;
        setState(() {
          downloadProgress = received / total!;
        });
      },
      onDone: () {
        setState(() {
          isDownloading = false;
          videoFiles.add({'name': fileName, 'path': filePath});
        });
      },
    );
  }

  void playVideo(String path) {
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gallery')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: videoFiles.length,
              itemBuilder: (context, index) {
                final videoFile = videoFiles[index];
                return ListTile(
                  title: Text(videoFile['name']),
                  trailing: isDownloading && downloadProgress < 1.0
                      ? CircularProgressIndicator(value: downloadProgress)
                      : ElevatedButton(
                    onPressed: () => playVideo(videoFile['path']),
                    child: Text('Watch'),
                  ),
                );
              },
            ),
          ),
          if (isDownloading) LinearProgressIndicator(value: downloadProgress),
        ],
      ),
    );
  }
}
