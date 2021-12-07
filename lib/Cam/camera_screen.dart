import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as img2;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:lsapp/DB/dbhelper.dart';
import 'package:lsapp/DB/picture.dart';

import 'box_widget.dart';
import 'classifier.dart';
import 'recognition.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);
  final CameraDescription camera;

  @override
  TakePicture createState() => TakePicture();
}

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

class TakePicture extends State<CameraScreen> {
  late Classifier _classifier;

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isCameraReady = false;
  bool showCapturedPhoto = false;

  // var ImagePath;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    // _classifier = ClassifierQuant();
    // Create an instance of classifier to load model and labels
    _classifier = Classifier();
    log('CLASSIFIER INITT');
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          //defining scale here cuz .aspectRatio can only be called when initialize is done
          if (snapshot.connectionState == ConnectionState.done) {
            final scale = 1 / (_controller.value.aspectRatio * MediaQuery.of(context).size.aspectRatio);
            // If the Future is complete, display the preview.
            return Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: CameraPreview(_controller),
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path, classifier: _classifier,
                  // imagePath: image.readAsBytes(), classifier: _classifier,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            log('$e');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  static Future<img2.Image> bytesToImage(Future<Uint8List> imgBytes) async {
    final imageData = await imgBytes;
    final imageDecoded = imageData.buffer.asUint8List();
    img2.Codec codec = await img2.instantiateImageCodec(imageDecoded);
    img2.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  // final Future<Uint8List> imagePath;
  final Classifier classifier;

  const DisplayPictureScreen({Key? key, required this.imagePath, required this.classifier}) : super(key: key);

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
                result: e,
              ))
          .toList(),
    );
  }

  void push2DB(String label, Uint8List im) {
    Picture pic = Picture(label, im);
    var dbHelper = DBHelper();
    dbHelper.savePicture(pic);
    log("🌋🌋🌋🌋 Data saved Successfully");
  }

  @override
  Widget build(BuildContext context) {
    File? _image = File(imagePath);
    // Uint8List u8 = _image.readAsBytesSync();
    log("🟢🟢🟢🟢 display builder");
    img.Image imageInput = img.decodeImage(_image.readAsBytesSync())!;
    // final imageInput =  bytesToImage(imagePath);
    // Image imm = Image.file(_image);
    // push2DB("aaaaaaa", _image.readAsBytesSync());
    // Image im1 = I
    // var color = const Color(0xFF0099FF);
    // var pred = classifier.predict(imageInput);
    Map<String, dynamic>? results = classifier.predict(imageInput, context);
    // log(results!["recognitions"].toString());
    List<Recognition> pos = results!["recognitions"];
    for (Recognition rec in pos) {
      push2DB(rec.label, _image.readAsBytesSync());
      log("laaaab " + rec.label);
    }
    return Scaffold(
        body: Stack(
      children: <Widget>[
        // imm,
        Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
        boundingBoxes(pos),
      ],
    ));
  }
}