import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'controllers/detection_controller.dart';
import 'detector_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  bool isFirst;

  FaceDetectorView({Key? key, required this.isFirst}) : super(key: key);

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        minFaceSize: 0.99,
        performanceMode: FaceDetectorMode.accurate),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;
  var detectController = Get.find<DetectionController>();
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _canProcess = true;
    _isBusy = false;
  }
  @override
  void dispose() async {
    _canProcess = false;
    _faceDetector.close();
    await detectController.controller.stopImageStream();
    detectController.setBorderColor(Colors.blue);
    detectController.controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Face Detector',
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      onDetectorViewModeChanged: (v) {
        detectController.setBorderColor(Colors.blue);
      },
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final faces = await _faceDetector.processImage(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      if (faces.isNotEmpty &&
          faces[0].boundingBox.size.width <
              MediaQuery.of(context).size.width / 1.4) {
        detectController.setBorderColor(Colors.green);
        final takePicture = await detectController.controller.takePicture();
        final Uint8List bytes = await takePicture.readAsBytes();
        setState(faces.clear);
        detectController.setImage(widget.isFirst, bytes);
        bytes.clear();
        detectController.faceDetector.close();

      } else {
        detectController.setBorderColor(Colors.blue);
        setState(faces.clear);
      }
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
