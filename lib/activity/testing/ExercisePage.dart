import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});
  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late ImagePicker imagePicker;
  File? _image;
  late PoseDetector poseDetector;
  dynamic image;
  List<Pose> poses = [];
  String poseRes = "";

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    final options = PoseDetectorOptions(model: PoseDetectionModel.accurate, mode: PoseDetectionMode.single);
    poseDetector = PoseDetector(options: options);
  }

  @override
  void dispose() {
    poseDetector.close();
    super.dispose();
  }

  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      doPoseDetection();
    }
  }

  _imgFromGallery() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      doPoseDetection();
    }
  }

  doPoseDetection() async {
    if (_image == null) return;
    drawPose();
    InputImage inputImage = InputImage.fromFile(_image!);
    poses = await poseDetector.processImage(inputImage);
    setState(() {
      poses;
    });

    if (poses.isNotEmpty) {
      poseRes = validateUpwardDog(poses.first);
    } else {
      poseRes = "Không phát hiện được tư thế. Vui lòng chụp rõ toàn thân.";
    }
    setState(() {
      poseRes;
    });
  }

  drawPose() async {
    if (_image == null) return;
    var bytes = await _image!.readAsBytes();
    var decodedImage = await decodeImageFromList(bytes);
    setState(() {
      image = decodedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Kiểm tra tư thế', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: image != null
                ? Center(
                    child: FittedBox(
                      child: SizedBox(
                        width: image.width.toDouble(),
                        height: image.height.toDouble(),
                        child: CustomPaint(
                          painter: PosePainter(image, poses),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          'Chọn ảnh hoặc chụp ảnh \nđể kiểm tra tư thế',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
          poseRes != ""
              ? Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      poseRes,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: _imgFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.photo,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.accessibility_new,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                InkWell(
                  onTap: _imgFromCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.camera,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double radians = atan2(last.y - mid.y, last.x - mid.x) - atan2(first.y - mid.y, first.x - mid.x);
    double angle = (radians * 180.0) / pi;
    return angle.abs();
  }

  String validateUpwardDog(Pose pose) {
    PoseLandmark? leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    PoseLandmark? rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    PoseLandmark? leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    PoseLandmark? rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    PoseLandmark? leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    PoseLandmark? rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    PoseLandmark? rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    PoseLandmark? rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    PoseLandmark? leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    PoseLandmark? rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    PoseLandmark? nose = pose.landmarks[PoseLandmarkType.nose];

    if ([leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle, nose].contains(null)) {
      return "Đảm bảo nhìn thấy toàn bộ cơ thể của bạn.";
    }

    double leftArmAngle = calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
    double rightArmAngle = calculateAngle(rightShoulder!, rightElbow!, rightWrist!);

    bool armsStraight = (leftArmAngle > 150 && leftArmAngle < 200) && (rightArmAngle > 150 && rightArmAngle < 200);

    if (!armsStraight) {
      return "Gần được rồi! Hãy duỗi thẳng cánh tay hơn nữa.";
    }

    bool chestLifted = (leftShoulder.y < leftHip!.y) && (rightShoulder.y < rightHip!.y);
    if (!chestLifted) {
      return "Hãy nâng ngực cao hơn để giãn cơ lưng.";
    }

    bool hipsAboveKnees = (leftHip.y < leftKnee!.y) && (rightHip.y < rightKnee!.y);
    if (!hipsAboveKnees) {
      return "Đưa hông cao hơn một chút để giữ thăng bằng.";
    }

    bool kneesOffGround = (leftKnee.y > leftAnkle!.y) && (rightKnee.y > rightAnkle!.y);
    if (!kneesOffGround) {
      return "Hãy nhấc đầu gối lên khỏi mặt đất.";
    }

    bool headUp = nose!.y < leftShoulder.y;
    if (!headUp) {
      return "Ngẩng đầu nhẹ lên để giữ tư thế tốt nhất.";
    }

    return "Tuyệt vời! Tư thế Upward Dog của bạn trông rất chuẩn!";
  }
}

class PosePainter extends CustomPainter {
  final dynamic image;
  final List<Pose> poses;
  PosePainter(this.image, this.poses);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
    
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    Paint leftPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    Paint rightPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (Pose pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(Offset(landmark.x, landmark.y), 2, paint);
      });

      void drawCustomLine(PoseLandmarkType point1, PoseLandmarkType point2, Paint linePaint) {
        PoseLandmark? poseLandmark1 = pose.landmarks[point1];
        PoseLandmark? poseLandmark2 = pose.landmarks[point2];
        if (poseLandmark1 != null && poseLandmark2 != null) {
          canvas.drawLine(Offset(poseLandmark1.x, poseLandmark1.y), Offset(poseLandmark2.x, poseLandmark2.y), linePaint);
        }
      }

      drawCustomLine(PoseLandmarkType.rightWrist, PoseLandmarkType.rightElbow, rightPaint);
      drawCustomLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightShoulder, rightPaint);

      drawCustomLine(PoseLandmarkType.leftWrist, PoseLandmarkType.leftElbow, leftPaint);
      drawCustomLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder, leftPaint);

      drawCustomLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, rightPaint);
      drawCustomLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      drawCustomLine(PoseLandmarkType.rightHip, PoseLandmarkType.leftHip, rightPaint);
      drawCustomLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, leftPaint);

      drawCustomLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      drawCustomLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      drawCustomLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      drawCustomLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
