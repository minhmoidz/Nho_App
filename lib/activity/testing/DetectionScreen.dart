import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'Model/ExerciseDataModel.dart';


class DetectionScreen extends StatefulWidget {
  DetectionScreen({Key? key, required this.exerciseDataModel}) : super(key: key);
  ExerciseDataModel exerciseDataModel;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<DetectionScreen> with WidgetsBindingObserver {
  CameraController? controller;
  bool isBusy = false;
  late Size size;
  List<CameraDescription> cameras = [];
  bool isInSimulator = false;

  // Thêm biến để lưu trạng thái khởi tạo camera
  bool isInitializing = true;
  String errorMessage = '';

  //TODO declare detector
  late PoseDetector poseDetector;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeResources();
  }

  Future<void> _initializeResources() async {
    // Khởi tạo các camera có sẵn trước khi sử dụng
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        await initializeCamera();
      } else {
        setState(() {
          errorMessage = 'Không tìm thấy camera!';
          isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khi khởi tạo camera: $e';
        isInitializing = false;
      });
      print('Lỗi khi khởi tạo camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kiểm tra nếu controller chưa được khởi tạo
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    // Xử lý các trạng thái của ứng dụng
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initializeCamera();
    }
  }

  //TODO code to initialize the camera feed
  Future<void> initializeCamera() async {
    try {
      setState(() {
        isInitializing = true;
        errorMessage = '';
      });

      //TODO initialize detector
      final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
      poseDetector = PoseDetector(options: options);

      // Kiểm tra nếu đang chạy trong máy ảo
      bool isSimulator = false;
      if (Platform.isIOS) {
        isSimulator = !(await isRealDevice());
      } else if (Platform.isAndroid) {
        // Kiểm tra Android emulator
        isSimulator = await isAndroidEmulator();
      }

      if (isSimulator) {
        // Hiển thị hình ảnh mô phỏng thay vì camera thật trong máy ảo
        setState(() {
          isInSimulator = true;
          isInitializing = false;
        });
        return;
      }

      // Đảm bảo danh sách cameras không rỗng
      if (cameras.isEmpty) {
        setState(() {
          errorMessage = 'Không có camera nào khả dụng';
          isInitializing = false;
        });
        return;
      }

      // Khởi tạo camera controller
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
        enableAudio: false, // Không cần audio
      );

      // Đợi camera khởi tạo xong
      await controller!.initialize();

      // Kiểm tra xem widget còn hiển thị không
      if (!mounted) {
        return;
      }

      // Bắt đầu stream hình ảnh
      await controller!.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          img = image;
          doPoseEstimationOnFrame();
        }
      });

      // Cập nhật UI
      setState(() {
        isInitializing = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi khởi tạo camera: $e';
        isInitializing = false;
      });
      print('Lỗi khởi tạo camera: $e');
    }
  }

  // Kiểm tra thiết bị iOS thật
  Future<bool> isRealDevice() async {
    try {
      final String utsname = await const MethodChannel('flutter/platform')
          .invokeMethod('getUtsname');
      return !utsname.toLowerCase().contains('simulator');
    } catch (e) {
      return true; // Mặc định coi là thiết bị thật nếu không thể kiểm tra
    }
  }

  // Kiểm tra Android emulator
  Future<bool> isAndroidEmulator() async {
    try {
      final List<String> result = await const MethodChannel('flutter/platform')
          .invokeMethod('getSystemProperty', {'key': 'ro.product.cpu.abi'});
      final String abiString = result.isNotEmpty ? result.first : "";
      return abiString.contains('x86');
    } catch (e) {
      // Thử phương pháp khác nếu không thành công
      try {
        final String brand = await const MethodChannel('flutter/platform')
            .invokeMethod('getSystemProperty', {'key': 'ro.product.manufacturer'});
        return brand.toLowerCase().contains('genymotion') ||
            brand.toLowerCase().contains('google');
      } catch (_) {
        return false; // Mặc định coi là thiết bị thật nếu không thể kiểm tra
      }
    }
  }

  //TODO pose detection on a frame
  dynamic _scanResults;
  CameraImage? img;
  doPoseEstimationOnFrame() async {
    var inputImage = _inputImageFromCameraImage();
    if(inputImage != null){
      final List<Pose> poses = await poseDetector.processImage(inputImage);
      print("pose="+poses.length.toString());
      _scanResults = poses;
      if(poses.length>0){
        if(widget.exerciseDataModel.type== ExcerciseType.PushUps){
          detectPushUp(poses.first.landmarks);
        }else if(widget.exerciseDataModel== ExcerciseType.Squats){
          detectSquat(poses.first.landmarks);
        }else if(widget.exerciseDataModel.type==ExcerciseType.DownwardDogPlank){
          detectPlankToDownwardDog(poses.first);
        }else if(widget.exerciseDataModel.type==ExcerciseType.JumpingJack){
          detectJumpingJack(poses.first);
        }else if(widget.exerciseDataModel.type==ExcerciseType.HighKnees){
          detectHighKnees(poses.first.landmarks);
        }
      }

    }
    setState(() {
      _scanResults;
      isBusy = false;
    });
  }

  //close all resources
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;

    if (isInitializing) {
      // Hiển thị loading khi đang khởi tạo
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      // Hiển thị thông báo lỗi nếu có
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _initializeResources,
                child: Text("Thử lại"),
              )
            ],
          ),
        ),
      );
    }

    if (isInSimulator) {
      // Hiển thị giao diện giả cho simulator
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 100, color: Colors.white54),
                  SizedBox(height: 20),
                  Text(
                    "Camera không hoạt động trong máy ảo\nChạy trên thiết bị thật để sử dụng",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 40),
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white24,
                    ),
                    width: 70,
                    height: 70,
                    child: Center(
                      child: Text(
                        "$pushUpCount",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Bạn đang ở chế độ Demo",
                    style: TextStyle(color: Colors.yellow, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Mô phỏng đếm push-up trong simulator
                      setState(() {
                        pushUpCount++;
                      });
                    },
                    child: Text("Mô phỏng Push-up"),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } else if (controller != null && controller!.value.isInitialized) {
      // Hiển thị camera thật
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: CameraPreview(controller!),
          ),
        ),
      );

      stackChildren.add(
        Positioned(
            top: 0.0,
            left: 0.0,
            width: size.width,
            height: size.height,
            child: buildResult()
        ),
      );

      stackChildren.add(
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: widget.exerciseDataModel.color,
              ),
              width: 70,
              height: 70,
              child: Center(
                child: Text(
                  widget.exerciseDataModel == ExcerciseType.PushUps?
                  "$pushUpCount":widget.exerciseDataModel.type == ExcerciseType.Squats?
                  "$squatCount":widget.exerciseDataModel == ExcerciseType.DownwardDogPlank?
                  "$plankToDownwardDogCount":widget.exerciseDataModel.type==ExcerciseType.HighKnees?"$highKneesCount":"$jumpingJackCount",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          )
      );

      stackChildren.add(
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.only(top: 50, left: 20, right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: widget.exerciseDataModel.color,
            ),
            width: MediaQuery.of(context).size.width,
            height: 70,
            child: Center(
              child: Row(
                children: [
                  Text(
                    widget.exerciseDataModel.title,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 4), // Optional spacing
                  Image.asset("assets/images/${widget.exerciseDataModel.image}", height: 30),
                ],mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              ),
            ),
          ),
        ),
      );


      // Thêm nút Back ở góc trên bên trái cho camera thật
      stackChildren.add(
          Positioned(
            top: 40.0,
            left: 20.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              width: 50,
              height: 50,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          )
      );
    }

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackChildren,
        ),
      ),
      floatingActionButton: isInSimulator ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Icon(Icons.arrow_back),
        backgroundColor: Colors.blueAccent,
      ) : null,
    );
  }
  int pushUpCount = 0;
  bool isLowered = false;
  void detectPushUp(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return; // Skip if any landmark is missing
    }

    // Calculate elbow angles
    double leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightElbowAngle =
    calculateAngle(rightShoulder, rightElbow, rightWrist);
    double avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate torso alignment (ensuring a straight plank)
    double torsoAngle =
    calculateAngle(leftShoulder, leftHip, leftKnee ?? rightKnee!);
    bool inPlankPosition =
        torsoAngle > 160 && torsoAngle < 180; // Slight flexibility

    if (avgElbowAngle < 90 && inPlankPosition) {
      // User is in the lowered push-up position
      isLowered = true;
    } else if (avgElbowAngle > 160 && isLowered && inPlankPosition) {
      // User returns to the starting position
      pushUpCount++;
      isLowered = false;

      // Update UI
      setState(() {});
    }
  }

  int squatCount = 0;
  bool isSquatting = false;
  void detectSquat(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return; // Skip detection if any key landmark is missing
    }

    // Calculate angles
    double leftKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;

    bool deepSquat = avgKneeAngle < 90; // Ensuring squat is deep enough

    if (deepSquat && hipY > kneeY) {
      if (!isSquatting) {
        isSquatting = true;
      }
    } else if (!deepSquat && isSquatting) {
      squatCount++;
      isSquatting = false;

      // Update UI
      setState(() {});
    }
  }

  int plankToDownwardDogCount = 0;
  bool isInDownwardDog = false;
  void detectPlankToDownwardDog(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any key landmark is missing
    }

    // **Step 1: Detect Plank Position**
    bool isPlank = (leftHip.y - leftShoulder.y).abs() < 30 &&
        (rightHip.y - rightShoulder.y).abs() < 30 &&
        (leftHip.y - leftAnkle.y).abs() > 100 &&
        (rightHip.y - rightAnkle.y).abs() > 100;

    // **Step 2: Detect Downward Dog Position**
    bool isDownwardDog = (leftHip.y < leftShoulder.y - 50) &&
        (rightHip.y < rightShoulder.y - 50) &&
        (leftAnkle.y > leftHip.y) &&
        (rightAnkle.y > rightHip.y);

    // **Step 3: Count Repetitions**
    if (isDownwardDog && !isInDownwardDog) {
      isInDownwardDog = true;
    } else if (isPlank && isInDownwardDog) {
      plankToDownwardDogCount++;
      isInDownwardDog = false;

      // Print count
      print("Plank to Downward Dog Count: $plankToDownwardDogCount");
    }
  }

  int jumpingJackCount = 0;
  bool isJumping = false;
  bool isJumpingJackOpen = false;
  void detectJumpingJack(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftAnkle == null ||
        rightAnkle == null ||
        leftHip == null ||
        rightHip == null ||
        leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return; // Skip detection if any landmark is missing
    }

    // Calculate distances
    double legSpread = (rightAnkle.x - leftAnkle.x).abs();
    double armHeight = (leftWrist.y + rightWrist.y) / 2; // Average wrist height
    double hipHeight = (leftHip.y + rightHip.y) / 2; // Average hip height
    double shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();

    // Define thresholds based on shoulder width
    double legThreshold =
        shoulderWidth * 1.2; // Legs should be ~1.2x shoulder width apart
    double armThreshold =
        hipHeight - shoulderWidth * 0.5; // Arms should be above shoulders

    // Check if arms are raised and legs are spread
    bool armsUp = armHeight < armThreshold;
    bool legsApart = legSpread > legThreshold;

    // Detect full jumping jack cycle
    if (armsUp && legsApart && !isJumpingJackOpen) {
      isJumpingJackOpen = true;
    } else if (!armsUp && !legsApart && isJumpingJackOpen) {
      jumpingJackCount++;
      isJumpingJackOpen = false;

      // Print the count
      print("Jumping Jack Count: $jumpingJackCount");
    }
  }

  int highKneesCount = 0;
  bool isLeftKneeUp = false;
  bool isRightKneeUp = false;
  String lastKnee = ''; // To alternate between knees

  void detectHighKnees(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null) {
      return;
    }

    double hipY = (leftHip.y + rightHip.y) / 2;

    // Threshold: Knee must go above hip level (with margin)
    double thresholdY = hipY - 0.05;

    if (leftKnee.y < thresholdY && !isLeftKneeUp && lastKnee != 'left') {
      highKneesCount++;
      isLeftKneeUp = true;
      isRightKneeUp = false;
      lastKnee = 'left';
      setState(() {});
    } else if (rightKnee.y < thresholdY && !isRightKneeUp && lastKnee != 'right') {
      highKneesCount++;
      isRightKneeUp = true;
      isLeftKneeUp = false;
      lastKnee = 'right';
      setState(() {});
    }

    // Reset if knees are down
    if (leftKnee.y >= hipY) isLeftKneeUp = false;
    if (rightKnee.y >= hipY) isRightKneeUp = false;
  }


  // Function to calculate angle between three points (shoulder, elbow, wrist)
  double calculateAngle(
      PoseLandmark shoulder, PoseLandmark elbow, PoseLandmark wrist) {
    double a = distance(elbow, wrist);
    double b = distance(shoulder, elbow);
    double c = distance(shoulder, wrist);

    double angle = acos((b * b + a * a - c * c) / (2 * b * a)) * (180 / pi);
    return angle;
  }

// Helper function to calculate Euclidean distance
  double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage() {
    if (img == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
    final camera = cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(img!.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (img!.planes.length != 1) return null;
    final plane = img!.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img!.width.toDouble(), img!.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  //Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null ||
        controller == null ||
        !controller!.value.isInitialized) {
      return Text('');
    }
    final Size imageSize = Size(
      controller!.value.previewSize!.height,
      controller!.value.previewSize!.width,
    );
    CustomPainter painter = PosePainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }
}

// PosePainter class để vẽ landmarks trên camera feed
class PosePainter extends CustomPainter {
  PosePainter(this.absoluteImageSize, this.poses);

  final Size absoluteImageSize;
  final List<Pose> poses;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final Paint jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 10.0
      ..color = Colors.red;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(landmark.x * scaleX, landmark.y * scaleY),
            1,
            jointPaint);
      });

      // Draw lines connecting the landmarks
      void drawLine(
          PoseLandmark? start, PoseLandmark? end, Canvas canvas, Paint paint) {
        if (start == null || end == null) return;
        canvas.drawLine(
          Offset(start.x * scaleX, start.y * scaleY),
          Offset(end.x * scaleX, end.y * scaleY),
          paint,
        );
      }

      // Draw body lines
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      // Draw torso
      drawLine(leftShoulder, rightShoulder, canvas, paint);
      drawLine(leftShoulder, leftHip, canvas, paint);
      drawLine(rightShoulder, rightHip, canvas, paint);
      drawLine(leftHip, rightHip, canvas, paint);

      // Draw arms
      drawLine(leftShoulder, leftElbow, canvas, paint);
      drawLine(leftElbow, leftWrist, canvas, paint);
      drawLine(rightShoulder, rightElbow, canvas, paint);
      drawLine(rightElbow, rightWrist, canvas, paint);

      // Draw legs
      drawLine(leftHip, leftKnee, canvas, paint);
      drawLine(leftKnee, leftAnkle, canvas, paint);
      drawLine(rightHip, rightKnee, canvas, paint);
      drawLine(rightKnee, rightAnkle, canvas, paint);
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}