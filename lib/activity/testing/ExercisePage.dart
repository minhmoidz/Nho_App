import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';


class ExercisePage extends StatefulWidget {
  ExercisePage({Key? key}) : super(key: key);
  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late ImagePicker imagePicker;
  File? _image;
  late PoseDetector poseDetector;
  var image;
  List<Pose> poses = [];
  String poseRes="";

  //TODO declare detector
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imagePicker = ImagePicker();
    final options = PoseDetectorOptions(model: PoseDetectionModel.accurate,mode: PoseDetectionMode.single);
    poseDetector = PoseDetector(options:options);
    //TODO initialize detector

  }

  @override
  void dispose() {
    super.dispose();
  }

  //TODO capture image using camera
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doPoseDetection();
    }
  }

  //TODO choose image using gallery
  _imgFromGallery() async {
    XFile? pickedFile =
    await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      doPoseDetection();
    }
  }

  //TODO pose detection code here
  doPoseDetection() async {
    drawPose();
    InputImage inputImage = InputImage.fromFile(_image!);
    poses = await poseDetector.processImage(inputImage);
    setState(() {
      poses;
    });
    for (Pose pose in poses){
      pose.landmarks.forEach((_,landmark){
        final type = landmark.type;
        final x=landmark.x;
        final y=landmark.y;

      });
      final landmark = pose.landmarks[PoseLandmarkType.nose];
    }

    poseRes=validateUpwardDog(poses.first);
    setState(() {
      poseRes;
    });
  }

  drawPose() async{
    var bytes = await _image!.readAsBytes();
    image =await decodeImageFromList(bytes);
    setState((){
      image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Kiểm tra tư thế'),
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
                  height: image.width.toDouble(),
                  child: CustomPaint(
                      painter: PosePainter(image, poses)),
                ),
              ),
            )
                : SizedBox(
              height: MediaQuery.of(context).size.height - 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white54),
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
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                poseRes,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.photo,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: 20, horizontal: 20),
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
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
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


  String validateDownwardDog(Pose pose) {
    // Extract key landmarks
    PoseLandmark? leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    PoseLandmark? rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    PoseLandmark? leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    PoseLandmark? rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    PoseLandmark? leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    PoseLandmark? rightShoulder =
    pose.landmarks[PoseLandmarkType.rightShoulder];
    PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    PoseLandmark? rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    PoseLandmark? rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    PoseLandmark? leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    PoseLandmark? rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Ensure all required landmarks are detected
    if ([
      leftWrist,
      rightWrist,
      leftElbow,
      rightElbow,
      leftShoulder,
      rightShoulder,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftAnkle,
      rightAnkle
    ].contains(null)) {
      return "Unable to detect full body. Ensure hands and feet are visible.";
    }

    // Calculate angles for arms and legs
    double leftArmAngle = calculateAngle(leftWrist!, leftElbow!, leftShoulder!);
    double rightArmAngle =
    calculateAngle(rightWrist!, rightElbow!, rightShoulder!);
    double leftLegAngle = calculateAngle(leftHip!, leftKnee!, leftAnkle!);
    double rightLegAngle = calculateAngle(rightHip!, rightKnee!, rightAnkle!);

    // Flexible angle check (allowing slight bends)
    bool armsStraight = (leftArmAngle > 130 && leftArmAngle < 200) &&
        (rightArmAngle > 130 && rightArmAngle < 200);
    bool legsStraight = (leftLegAngle > 130 && leftLegAngle < 190) &&
        (rightLegAngle > 130 && rightLegAngle < 190);
    print(armsStraight.toString() +
        " left arm angle=" +
        leftArmAngle.toString() +
        "   right arm angle=" +
        rightArmAngle.toString());
    print(legsStraight.toString() +
        " left leg angle=" +
        leftLegAngle.toString() +
        "   right leg angle=" +
        rightLegAngle.toString());

    if (!armsStraight) {
      return "Great effort! Try straightening your arms a little more.";
    }
    if (!legsStraight) {
      return "You're almost there! Straighten your legs a bit for a deeper stretch.";
    }

    // Hip should be the highest point
    if (leftHip.y > leftShoulder.y || rightHip.y > rightShoulder.y) {
      return "Nice work! Try lifting your hips higher to form an inverted V shape.";
    }

    // // Heel position check (optional flexibility)
    // bool heelsTouching = (leftAnkle.y - leftKnee.y).abs() < 20 &&
    //     (rightAnkle.y - rightKnee.y).abs() < 20;
    // if (!heelsTouching) {
    //   return "Good job! Over time, work towards lowering your heels for a deeper stretch.";
    // }

    return "Perfect! Your Downward Dog pose looks amazing!";
  }

//Function to calculate angle between three points using arctan2
  double calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double radians = atan2(last.y - mid.y, last.x - mid.x) - atan2(first.y - mid.y, first.x - mid.x);
    double angle = (radians * 180.0) / pi;
    return angle.abs();
  }


  String validateUpwardDog(Pose pose) {
    // Extract key landmarks
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

    // Ensure all required landmarks are detected
    if ([leftWrist, rightWrist, leftElbow, rightElbow, leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle, nose].contains(null)) {
      return "Ensure your full body is visible.";
    }

    // Calculate arm angles
    double leftArmAngle = calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
    double rightArmAngle = calculateAngle(rightShoulder!, rightElbow!, rightWrist!);

    bool armsStraight = (leftArmAngle > 150 && leftArmAngle < 200) &&
        (rightArmAngle > 150 && rightArmAngle < 200);

    if (!armsStraight) {
      return "Almost there! Straighten your arms more.";
    }

    // Shoulders should be above hips
    bool chestLifted = (leftShoulder.y < leftHip!.y) && (rightShoulder.y < rightHip!.y);
    if (!chestLifted) {
      return "Lift your chest more to engage your back.";
    }

    // Hips should be above knees
    bool hipsAboveKnees = (leftHip.y < leftKnee!.y) && (rightHip.y < rightKnee!.y);
    if (!hipsAboveKnees) {
      return "Bring your hips higher to engage your core.";
    }

    // Knees should be off the ground (ankles lower than knees)
    bool kneesOffGround = (leftKnee.y > leftAnkle!.y) && (rightKnee.y > rightAnkle!.y);
    if (!kneesOffGround) {
      return "Lift your knees off the ground.";
    }

    // Head should be slightly up
    bool headUp = nose!.y < leftShoulder.y;
    if (!headUp) {
      return "Lift your head slightly for better posture.";
    }

    return "Perfect! Your Upward Dog pose looks amazing!";
  }

  String validateUpwardDog1(Pose pose) {
    // Extract key landmarks
    PoseLandmark? leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    PoseLandmark? rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    PoseLandmark? leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    PoseLandmark? rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    PoseLandmark? leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    PoseLandmark? rightShoulder =
    pose.landmarks[PoseLandmarkType.rightShoulder];
    PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    PoseLandmark? rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    PoseLandmark? rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    PoseLandmark? leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    PoseLandmark? rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    PoseLandmark? nose = pose.landmarks[PoseLandmarkType.nose];

    // Ensure all required landmarks are detected
    if ([
      leftWrist,
      rightWrist,
      leftElbow,
      rightElbow,
      leftShoulder,
      rightShoulder,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftAnkle,
      rightAnkle,
      nose
    ].contains(null)) {
      return "Ensure your full body is visible.";
    }

    // Calculate angles for arms
    double leftArmAngle = calculateAngle(leftWrist!, leftElbow!, leftShoulder!);
    double rightArmAngle =
    calculateAngle(rightWrist!, rightElbow!, rightShoulder!);

    // Allow some flexibility in arm angles (160Â°-180Â°)
    bool armsStraight = (leftArmAngle > 140 && leftArmAngle < 200) &&
        (rightArmAngle > 140 && rightArmAngle < 200);
    print(armsStraight.toString() +
        " left arm angle=" +
        leftArmAngle.toString() +
        "   right arm angle=" +
        rightArmAngle.toString());

    if (!armsStraight) {
      return "Almost there! Try straightening your arms a bit more.";
    }

    //print(legsStraight.toString()+" left leg angle="+leftLegAngle.toString()+"   right leg angle="+rightLegAngle.toString());

    // Ensure chest is lifted above hips
    bool chestLifted =
        (leftShoulder.y < leftHip!.y) && (rightShoulder.y < rightHip!.y);
    if (!chestLifted) {
      return "Good effort! Lift your chest higher to deepen the stretch.";
    }

    // Ensure knees are off the ground
    bool kneesUp = (leftKnee!.y > leftHip!.y) && (rightKnee!.y > rightHip!.y);
    if (!kneesUp) {
      return "Nice work! Try keeping your knees off the ground.";
    }

    // Ensure slight upward head tilt
    bool headUp = (nose!.y < leftShoulder.y);
    if (!headUp) {
      return "Great job! Lift your head slightly for better posture.";
    }

    return "Perfect! Your Upward Dog pose looks amazing!";
  }


}

class PosePainter extends CustomPainter{
  var image;
  List<Pose> poses;
  PosePainter(this.image,this.poses);
  @override
  void paint(Canvas canvas, Size size){
    canvas.drawImage(image,Offset.zero,Paint());
    Paint paint = Paint();
    paint.color=Colors.red;
    paint.style=PaintingStyle.stroke;
    paint.strokeWidth=3;

    Paint leftPaint = Paint();
    paint.color=Colors.yellow;
    paint.style=PaintingStyle.stroke;
    paint.strokeWidth=3;

    Paint rightPaint = Paint();
    paint.color=Colors.deepPurple;
    paint.style=PaintingStyle.stroke;
    paint.strokeWidth=3;
    for (Pose pose in poses){
      pose.landmarks.forEach((_,landmark){
        canvas.drawCircle(Offset(landmark.x,landmark.y ), 1, paint);
      });

      void drawCustomLine(PoseLandmarkType point1,PoseLandmarkType point2,Paint linePaint){
        PoseLandmark poseLandmark1 = pose.landmarks[point1]!;
        PoseLandmark poseLandmark2 = pose.landmarks[point2]!;
        canvas.drawLine(Offset(poseLandmark1.x, poseLandmark1.y),Offset(poseLandmark2.x, poseLandmark2.y),linePaint);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate){
    return true;
  }
}