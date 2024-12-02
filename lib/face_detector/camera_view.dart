import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'controllers/detection_controller.dart';
import 'widgets/circle_clipper.dart';
import '../main.dart';

class CameraView extends StatefulWidget {
  CameraView({
    Key? key,
    required this.customPaint,
    required this.onImage,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
  }) : super(key: key);

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with TickerProviderStateMixin {
  static List<CameraDescription> _cameras = [];

  int _cameraIndex = -1;

  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  final bool _changingCameraLens = false;

var detectController =Get.put(DetectionController());
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initialize();
    detectController.initFaceDetector();
  }

  // Initialize AnimationController and Animation
  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 2), // Adjust duration for speed of the animation
    )..repeat(reverse: true); // Repeat with reverse to create a pulsing effect

    _sizeAnimation = Tween(begin: 0.85, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.ease,
      ),
    );
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    detectController.faceDetector.close();
    detectController.stopLiveFeed();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();

    if (detectController.controller.value.isInitialized == false) return Container();
    return ColoredBox(
      color: Colors.black,
      child: GetBuilder<DetectionController>(
        init: DetectionController(),
        builder: (controller) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Center(
                  child: _changingCameraLens
                      ? Center(
                          child: const Text('Changing camera lens'),
                        )
                      : Center(
                          child: ClipRRect(
                          child: SizedOverflowBox(
                            size: Size(Get.width / 1.1, Get.width / 1.1),
                            alignment: Alignment.center,
                            child: CameraPreview(
                              detectController.controller,
                              child: widget.customPaint,
                            ),
                          ),
                        ))),
              ClipPath(
                clipper: CircleClipper(),
                child: Container(
                  color: Colors.white,
                ),
              ),
              // Animated blue circle using AnimatedBuilder
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: _sizeAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: controller.borderColor,
                              width: 2,
                            ),
                          ),
                          width: MediaQuery.of(context).size.width / 1.1,
                          height: MediaQuery.of(context).size.width / 1.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Powered by',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    SvgPicture.asset(
                      'assets/blue_logo.svg',
                      height: 20,
                      color: Color(0xFF203BD1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future _startLiveFeed() async {

    final camera = _cameras[_cameraIndex];
    detectController.controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    detectController.controller.initialize().then((_) {
      detectController.controller.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }



  void _processCameraImage(CameraImage image) async {

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[detectController.controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
