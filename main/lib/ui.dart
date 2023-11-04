import 'package:flutter/material.dart';
import 'package:test/api_integration.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/models.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  CaptureScreenState createState() => CaptureScreenState();
}

class CaptureScreenState extends State<CaptureScreen> {
  late CameraController _cameraController;
  final APIIntegration apiIntegration = APIIntegration();

  bool isIdentifying = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(firstCamera, ResolutionPreset.high);
    await _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (!_cameraController.value.isInitialized || isIdentifying) {
      return;
    }

    setState(() {
      isIdentifying = true;
    });
    _cameraController.setFlashMode(FlashMode.off);

    final XFile file = await _cameraController.takePicture();
    final imageBytes = File(file.path).readAsBytesSync();
    final imageBase64 = base64Encode(Uint8List.fromList(imageBytes));

    final List<Plant>? identifiedPlants = await apiIntegration.identifyPlant(imageBase64);

    Navigator.pushNamed(context, '/results', arguments: identifiedPlants);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identification'),
        backgroundColor: const Color(0xFF0E6A11),
      ),
      body: Container(
        color: const Color(0xFF0E6A11),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_cameraController.value.isInitialized)
                  AspectRatio(
                    aspectRatio: 30.0 / 40.0,
                    child: CameraPreview(_cameraController),
                  ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: takePicture,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: const Color(0xFF0E6A11),
                    padding: const EdgeInsets.all(16.0),
                  ),
                  child: const Text(
                    'Identify Plant',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
                if (isIdentifying) const SizedBox(height: 16.0),
                if (isIdentifying) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final identifiedPlants =
        ModalRoute.of(context)!.settings.arguments as List<Plant>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identification Results'),
        backgroundColor: const Color(0xFF0A5D0D),
      ),
      body: Container(
        color: const Color(0xFF0A5D0D),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (identifiedPlants.isEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16.0),
                    child: const Card(
                      elevation: 4.0,
                      color: Color(0xFFED5656),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No plants identified.',
                          style: TextStyle(fontSize: 18.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                for (var plant in identifiedPlants)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.lightGreen,
                      elevation: 4.0,
                      child: Column(
                        children: [
                          const SizedBox(height: 8.0),
                          Text(
                            'Name: ${plant.plantName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Probability: ${plant.probability.toStringAsFixed(2)}%',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
