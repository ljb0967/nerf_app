import 'dart:async';
import 'dart:convert'; // 추가된 import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

late List<CameraDescription> cameras;
late CameraController controller;
GyroscopeEvent? currentGyroData;
AccelerometerEvent? currentAccelData;
MagnetometerEvent? currentMagnetData;
List<Map<String, dynamic>> sensorDataList = [];
Timer? _timer;
const String imagePrefix = 'IMU_Frame_'; // 이미지 파일 접두사
String imuDataFileName = ''; // IMU 데이터 파일 이름

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  // 권한 요청
  await Permission.storage.request();
  await Permission.camera.request();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _children = [CameraScreen(), GalleryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        currentGyroData = event;
      });
    });
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        currentAccelData = event;
      });
    });
    magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        currentMagnetData = event;
      });
    });
  }

  Future<void> initializeCamera() async {
    controller = CameraController(cameras[0], ResolutionPreset.high);
    try {
      await controller.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = Directory('/storage/emulated/0/Download');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory.path;
  }

  Future<File> get _imuDataFile async {
    final path = await _localPath;
    return File('$path/$imuDataFileName');
  }

  Future<void> writeSensorData(String data) async {
    final file = await _imuDataFile;
    await file.writeAsString(data, mode: FileMode.append);
    print('Sensor data written to: ${file.path}');
  }

  void startCapture() async {
    sensorDataList.clear(); // Clear previous sensor data
    _isCapturing = true;

    try {
      int frameCount = 0;
      final directory = await _localPath;
      final timestamp = DateTime.now().toIso8601String().replaceAll(":", "-");
      imuDataFileName = 'IMU_data_$timestamp.txt'; // 새로운 IMU 데이터 파일 이름 설정

      _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (timer.tick >= 60 || !_isCapturing) { // 60초 동안 촬영 또는 중지 버튼 눌림
          _timer?.cancel();
          _isCapturing = false;
          stopCapture(); // 데이터 저장을 위해 stopCapture 호출
          return;
        }

        // 프레임 캡처
        final image = await controller.takePicture();
        final frameTimestamp = DateTime.now().toIso8601String().replaceAll(":", "-");
        final newFileName = '$imagePrefix$frameTimestamp.jpg';

        if (currentGyroData != null && currentAccelData != null && currentMagnetData != null) {
          final sensorData = {
            'timestamp': frameTimestamp,
            'imagePath': newFileName,
            'frameNumber': frameCount,
            'gyro': {
              'x': currentGyroData!.x,
              'y': currentGyroData!.y,
              'z': currentGyroData!.z,
            },
            'accel': {
              'x': currentAccelData!.x,
              'y': currentAccelData!.y,
              'z': currentAccelData!.z,
            },
            'magnet': {
              'x': currentMagnetData!.x,
              'y': currentMagnetData!.y,
              'z': currentMagnetData!.z,
            },
          };

          sensorDataList.add(sensorData);

          // 이미지 파일을 다운로드 디렉토리에 저장
          final newImagePath = '$directory/$newFileName';
          await File(image.path).copy(newImagePath); // 이미지 파일을 복사하여 저장
          frameCount++;
          print('Image saved to: $newImagePath');
        }
      });
    } catch (e) {
      print('Error in startCapture: $e');
    }
  }

  void stopCapture() async {
    if (_isCapturing) {
      _timer?.cancel();
      _isCapturing = false;
    }

    // IMU 데이터 파일에 저장
    if (sensorDataList.isNotEmpty) {
      final sensorDataStr = sensorDataList.map((data) => jsonEncode(data)).join('\n');
      await writeSensorData(sensorDataStr);
      print('Capture stopped by user and IMU data saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text('Camera with IMU Sensors')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(controller),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isCapturing ? null : startCapture,
                  child: Text('Start Capture'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isCapturing ? stopCapture : null,
                  child: Text('Stop Capture'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> mediaFiles = [];

  @override
  void initState() {
    super.initState();
    loadMediaFiles();
  }

  Future<void> loadMediaFiles() async {
    final directory = Directory('/storage/emulated/0/Download');
    if (directory.existsSync()) {
      final files = directory.listSync();
      setState(() {
        mediaFiles = files.where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.txt')).map((file) => File(file.path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gallery')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: mediaFiles.length,
        itemBuilder: (context, index) {
          final mediaFile = mediaFiles[index];
          return GridTile(
            child: Column(
              children: [
                if (mediaFile.path.endsWith('.jpg'))
                  Image.file(mediaFile, fit: BoxFit.cover),
                if (mediaFile.path.endsWith('.txt'))
                  Icon(Icons.description, size: 50),
                Text(
                  mediaFile.path.split('/').last,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'camera_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// late List<CameraDescription> cameras;
// late CameraController controller;
// GyroscopeEvent? currentGyroData;
// AccelerometerEvent? currentAccelData;
// MagnetometerEvent? currentMagnetData;
// List<Map<String, dynamic>> sensorDataList = [];
// const String imagePrefix = 'IMU_Frame_'; // 이미지 파일 접두사
// String imuDataFileName = ''; // IMU 데이터 파일 이름
// // import 'gallery_screen.dart';
// // import 'upload_screen.dart';
//
// // void main() {
// //   runApp(MyApp());
// // }
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//
//   // 권한 요청
//   await Permission.storage.request();
//   await Permission.camera.request();
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: MainScreen(),
//     );
//   }
// }
//
// class MainScreen extends StatefulWidget {
//   @override
//   _MainScreenState createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   int _currentIndex = 0;
//   final List<Widget> _children = [CameraScreen()];
//   // final List<Widget> _children = [CameraScreen(), GalleryScreen(), UploadScreen()];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _children[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.camera),
//             label: 'Camera',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.video_library),
//             label: 'Gallery',
//           ),
//           // BottomNavigationBarItem(
//           //   icon: Icon(Icons.upload),
//           //   label: 'Upload',
//           // ),
//         ],
//       ),
//     );
//   }
// }

