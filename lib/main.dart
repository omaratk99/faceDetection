//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'face_detector/face_detector_view.dart';
//
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Home(),
//     );
//   }
// }
//
// class Home extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Face Detection'),
//         centerTitle: true,
//         elevation: 1,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 children: [
//                   CustomCard('Face Detection', FaceDetectorView()),
//
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CustomCard extends StatelessWidget {
//   final String _label;
//   final Widget _viewPage;
//   final bool featureCompleted;
//
//   const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 5,
//       margin: EdgeInsets.only(bottom: 10),
//       child: ListTile(
//         tileColor: Theme.of(context).primaryColor,
//         title: Text(
//           _label,
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         onTap: () {
//           if (!featureCompleted) {
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                 content:
//                     const Text('This feature has not been implemented yet')));
//           } else {
//             Navigator.push(
//                 context, MaterialPageRoute(builder: (context) => _viewPage));
//           }
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_face_api/face_api.dart' as Regula;
import 'dart:io' as io;

import 'face_detector/controllers/detection_controller.dart';
import 'face_detector/face_detector_view.dart';

void main() => runApp(GetMaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<MyApp> {
  // Uint8List? _imageBytes1;
  // Uint8List? _imageBytes2;
  String? _result;
  var controller = Get.put(DetectionController());

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    const EventChannel('flutter_face_api/event/video_encoder_completion')
        .receiveBroadcastStream()
        .listen((event) {
      var completion =
          Regula.VideoEncoderCompletion.fromJson(json.decode(event))!;
      print("VideoEncoderCompletion:");
      print("    success:  ${completion.success}");
      print("    transactionId:  ${completion.transactionId}");
    });
    const EventChannel('flutter_face_api/event/onCustomButtonTappedEvent')
        .receiveBroadcastStream()
        .listen((event) {
      print("Pressed button with id: $event");
    });
    const EventChannel('flutter_face_api/event/livenessNotification')
        .receiveBroadcastStream()
        .listen((event) {
      var notification =
          Regula.LivenessNotification.fromJson(json.decode(event));
      print("LivenessProcessStatus: ${notification!.status}");
    });
  }

  showAlertDialog(BuildContext context, bool first) => showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(title: Text("Select option"), actions: [
            // ignore: deprecated_member_use
            TextButton(
                child: Text("Use gallery"),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  ImagePicker().pickImage(source: ImageSource.gallery).then(
                      (value) => {
                            controller.setImagem(
                                first, io.File(value!.path).readAsBytesSync())
                          });
                }),
            // ignore: deprecated_member_use
            TextButton(
                child: Text("Use camera"),
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(FaceDetectorView(
                    isFirst: first,
                  ));
                  // Regula.FaceSDK.presentFaceCaptureActivity().then((result) {
                  //   var response = Regula.FaceCaptureResponse.fromJson(
                  //       json.decode(result))!;
                  //   if (response.image != null &&
                  //       response.image!.bitmap != null)
                  //     setImage(
                  //         first,
                  //         base64Decode(
                  //             response.image!.bitmap!.replaceAll("\n", "")));
                  // });
                }),
          ]));

   setImage(bool first, Uint8List? imageFile) {
    if (imageFile == null) return;
    // setState(() => _similarity = "nil");
    if (first) {
      // image1.bitmap = base64Encode(imageFile);
      // image1.imageType = type;
      setState(() {
        // img1 = Image.memory(imageFile);
        // _liveness = "nil";

        controller.imageBytes1 = imageFile;
      });
    } else {
      controller.imageBytes2 = imageFile;

      setState(() => controller.imageBytes2 = imageFile);
    }
  }

  Future<void> initPlatformState() async {
    Regula.FaceSDK.init().then((json) {
      var response = jsonDecode(json);
      if (!response["success"]) {
        print("Init failed: ");
        print(json);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GetBuilder<DetectionController>(
              init: DetectionController(),
              builder: (controller){
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  controller.imageBytes1 != null
                      ? Image.memory(
                    controller.imageBytes1!,
                    height: 200,
                    width: 200,
                  ) // Display the picked image
                      : const Text("No image selected."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => showAlertDialog(context, true),
                    child: const Text('Pick Image1'),
                  ),
                  controller.imageBytes2 != null
                      ? Image.memory(
                    controller.imageBytes2!,
                    height: 200,
                    width: 200,
                  ) // Display the picked image
                      : const Text("No image selected."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => showAlertDialog(context, false),
                    //pickAndConvertImage2,
                    // Call the function on button press
                    child: const Text('Pick image2'),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: matchImage,
                    // Call the function on button press
                    child: const Text('Match'),
                  ),
                  const SizedBox(height: 40),
                  Text(_result != null ? _result! : ''),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // _showDialog(BuildContext context) {
  //   VoidCallback continueCallBack = () => {
  //     Navigator.of(context).pop(),
  //   };
  //   BlurryDialog alert = BlurryDialog("Missing Images",
  //       "Please Fill images before matching", continueCallBack);
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return alert;
  //     },
  //   );
  // }

  Future<void> sendImages(
      Uint8List? imageBytes1, Uint8List? imageBytes2) async {
    if (imageBytes1 == null || imageBytes2 == null) {
      print("Error: One or both images are null.");
      // _showDialog(context);
      return;
    }
    LoadingIndicatorDialog.singleton.show(context);
    // Create the multipart request
    var uri = Uri.parse("http://192.168.9.75:5000/compare");
    var request = http.MultipartRequest('POST', uri);

    // Add images to the request
    request.files.add(http.MultipartFile.fromBytes(
      'image1',
      imageBytes1,
      filename: 'image1.png',
      contentType: MediaType('image', 'png'),
    ));

    request.files.add(http.MultipartFile.fromBytes(
      'image2',
      imageBytes2,
      filename: 'image2.png',
      contentType: MediaType('image', 'png'),
    ));

    try {
      // Send the request
      var response = await request.send();
      // Check the response status
      if (response.statusCode == 200) {
        print("Images uploaded successfully.");
        var responseData = await response.stream.bytesToString();
        print("Server response: $responseData");
        var jsonResponse = jsonDecode(responseData);
        // Access fields in JSON
        bool match = jsonResponse['match'] ?? false;
        String error = jsonResponse['error'] ?? '';
        double confidence = jsonResponse['confidence'] ?? 0.0;

        // Handle response
        print("Match: $match");
        print("Error: $error");
        print("Confidence: $confidence");

        setState(() {
          _result = "Match: $match , Confidence: $confidence, Error: $error";
        });
      } else {
        print("Failed to upload images. Status code: ${response.statusCode}");
        setState(() {
          _result =
              "Failed to upload images. Status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      LoadingIndicatorDialog.singleton.dismiss();

      print("Error uploading images: $e");
      setState(() {
        _result = "Error uploading images: $e";
      });
    }

    LoadingIndicatorDialog.singleton.dismiss();
  }

  getImageFromLink(link) async {
    if (link != null && link != "") {
      http.Response response = await http.get(Uri.parse(link));
      final bytes = response.bodyBytes;
      final imageEncoded = base64.encode(bytes);
      controller.imageBytes2 = base64Decode(imageEncoded.replaceAll("\n", ""));
    }
  }

  // Future<void> pickAndConvertImage1() async {
  //   // Use ImagePicker to pick an image
  //   final picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(
  //     source: ImageSource.camera,
  //     preferredCameraDevice: CameraDevice.front,
  //   );
  //
  //   if (pickedFile != null) {
  //     // Convert picked image to bytes
  //     Uint8List imageBytes = await pickedFile.readAsBytes();
  //     // Convert to Bitmap using the image package
  //     controller.setImage1(imageBytes);
  //     // setState(() {
  //     //   _imageBytes1 = imageBytes;
  //     //   // sendImages(_imageBytes1,_imageBytes2);
  //     // });
  //   } else {
  //     print("No image selected.");
  //   }
  // }

  // Future<void> pickAndConvertImage2() async {
  //   // Use ImagePicker to pick an image
  //   final picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(
  //       source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
  //
  //   if (pickedFile != null) {
  //     // Convert picked image to bytes
  //     Uint8List imageBytes = await pickedFile.readAsBytes();
  //     // Convert to Bitmap using the image package
  //     setState(() {
  //       controller.imageBytes2 = imageBytes;
  //       // sendImages(_imageBytes1,_imageBytes2);
  //     });
  //   } else {
  //     print("No image selected.");
  //   }
  // }

  matchImage() {
    // Use ImagePicker to pick an image
    sendImages(controller.imageBytes1, controller.imageBytes2);
  }
}

class LoadingIndicatorDialog {
  static final LoadingIndicatorDialog singleton =
      LoadingIndicatorDialog._internal();
  late BuildContext _context;
  bool isDisplayed = false;

  factory LoadingIndicatorDialog() {
    return singleton;
  }

  LoadingIndicatorDialog._internal();

  show(BuildContext context, {String text = 'Loading...'}) {
    if (isDisplayed) {
      return;
    }
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          _context = context;
          isDisplayed = true;
          return WillPopScope(
            onWillPop: () async => false,
            child: SimpleDialog(
              backgroundColor: Colors.white,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 16, right: 16),
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(text),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  dismiss() {
    if (isDisplayed) {
      Navigator.of(_context).pop();
      isDisplayed = false;
    }
  }
}
