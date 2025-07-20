import 'dart:async';
import 'dart:convert'; // 추가된 import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class MyApp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;
  late List<CameraDescription> cameras;
  late CameraController controller;
  // CameraController? controller;
  GyroscopeEvent? currentGyroData;
  AccelerometerEvent? currentAccelData;
  MagnetometerEvent? currentMagnetData;
  List<Map<String, dynamic>> sensorDataList = [];
  Timer? _timer;
  String imagePrefix = 'IMU_Frame_'; // 이미지 파일 접두사
  String imuDataFileName = ''; // IMU 데이터 파일 이름

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
