# untitled

A new Flutter project.

# nerf-app

1. 촬영 화면
<img width="418" height="863" alt="image" src="https://github.com/user-attachments/assets/46cd205d-7ff5-4e45-af6e-e4a812111235" />


2. 갤러리 화면
<img width="425" height="873" alt="image" src="https://github.com/user-attachments/assets/5e51dd4d-904a-4161-9dfe-45118a6a0e00" />

3. 결과물 저장
- 찍은 영상을 프레임으로 분해하여 사진 파일로 저장
- 각 사진 프레임의 IMU 센서, 가속도 센서 값을 저장
<img width="625" height="800" alt="image" src="https://github.com/user-attachments/assets/cc444101-054c-4c99-aff4-ef71b17f1c0d" />

- 데이터 예시
  {"timestamp":"2025-07-20T14-02-16.660139","imagePath":"IMU_Frame_2025-07-20T14-02-16.660139.jpg","frameNumber":0,"gyro":{"x":0.0,"y":0.0,"z":0.0},"accel":{"x":0.0,"y":9.776321411132812,"z":0.812345027923584},"magnet":{"x":0.0,"y":9.875,"z":-47.75}}
  {"timestamp":"2025-07-20T14-02-17.855052","imagePath":"IMU_Frame_2025-07-20T14-02-17.855052.jpg","frameNumber":1,"gyro":{"x":0.0,"y":0.0,"z":0.0},"accel":{"x":0.0,"y":9.776321411132812,"z":0.812345027923584},"magnet":{"x":0.0,"y":9.875,"z":-47.75}}
  {"timestamp":"2025-07-20T14-02-20.491809","imagePath":"IMU_Frame_2025-07-20T14-02-20.491809.jpg","frameNumber":2,"gyro":{"x":0.0,"y":0.0,"z":0.0},"accel":{"x":0.0,"y":9.776321411132812,"z":0.812345027923584},"magnet":{"x":0.0,"y":9.875,"z":-47.75}}
  {"timestamp":"2025-07-20T14-02-21.812691","imagePath":"IMU_Frame_2025-07-20T14-02-21.812691.jpg","frameNumber":3,"gyro":{"x":0.0,"y":0.0,"z":0.0},"accel":{"x":0.0,"y":9.776321411132812,"z":0.812345027923584},"magnet":{"x":0.0,"y":9.875,"z":-47.75}}
