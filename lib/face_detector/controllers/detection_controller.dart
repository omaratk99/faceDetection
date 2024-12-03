import 'package:camera/camera.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:typed_data';

import '../../main.dart';

class DetectionController extends GetxController {
  // late CameraController cameraController;
  late Future<void> initializeControllerFuture;
  late AnimationController controllerAnimation;
  late Animation<double> animation;
  int selectedCameraIndex = 1;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;
  int frameCount = 0; // To limit the number of frames processed

  @override
  void onInit() async {
    super.onInit();
  }

  var detectedFaces = <Face>[];

  // Method to update faces detected
  void updateDetectedFace(List<Face> faces) {
    detectedFaces = faces;
    update(); // Notify listeners to update UI
  }

  Color borderColor = Color(0xFF536DFB);

  setBorderColor(Color newColor) {
    borderColor = newColor;
    update();
  }

  setImage1(Uint8List val) {
    imageBytes1 = val;
    update();
  }

  setImage2(Uint8List val) {
    imageBytes2 = val;
    update();
  }

  late CameraController controller;
  Uint8List? imageBytes1;
  Uint8List? imageBytes2;
  String? imagePath;

  setImagem(bool first, Uint8List? imageFile) {
    if (imageFile == null) return;
    // setState(() => _similarity = "nil");
    if (first) {
      imageBytes1 = imageFile;
      update();
    } else {
      imageBytes2 = imageFile;
      update();
    }
  }

  setImage(bool first, Uint8List? imageFile )async {
    if (imageFile == null) return;
    if (first) {
      setImage1(imageFile);
      update();
    } else {
      setImage2(imageFile);
    }
    Get.to(MyApp());
    await stopLiveFeed();
  }

  Future<void> pickAndConvertImage1() async {
    // Use ImagePicker to pick an image
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      setImage1(imageBytes);
    } else {
      print("No image selected.");
    }
  }

  late FaceDetector faceDetector;

  initFaceDetector() {
    faceDetector = FaceDetector(
        options:
            FaceDetectorOptions(enableContours: true, enableLandmarks: true));
  }

  Future stopLiveFeed() async {
    await controller.stopImageStream();
    await controller.dispose();
  }



}
