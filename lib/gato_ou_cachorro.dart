import 'package:camera/camera.dart';
import 'package:deal_ml/main.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:keep_screen_on/keep_screen_on.dart';

class GatoOuCachorro extends StatefulWidget {
  const GatoOuCachorro({super.key});

  @override
  State<GatoOuCachorro> createState() => _GatoOuCachorroState();
}

class _GatoOuCachorroState extends State<GatoOuCachorro> {
  final ValueNotifier<String> _result = ValueNotifier<String>('');
  late ImageLabeler labeler;

  late CameraController _cameraController;

  @override
  initState() {
    super.initState();
    labeler = GoogleMlKit.vision.imageLabeler(ImageLabelerOptions(
      confidenceThreshold: 0.5,
    ));
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
    )..initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    KeepScreenOn.turnOn(true);
  }

  @override
  dispose() {
    _cameraController.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gato ou Cachorro'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: CameraPreview(_cameraController),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: () async {
                    _capturarFotografia();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Identificar'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<String>(
              valueListenable: _result,
              builder: (_, value, __) {
                if (value.isEmpty) {
                  return const SizedBox();
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        style: Theme.of(context)
                            .textTheme
                            .headline6!
                            .apply(color: Colors.white),
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  void _capturarFotografia() {
    _cameraController.takePicture().then((image) async {
      _cameraController.pausePreview();
      Future.delayed(const Duration(seconds: 3)).then((_) {
        _cameraController.resumePreview();
      });
      labeler.processImage(InputImage.fromFilePath(image.path)).then((labels) {
        if (labels.first.label == 'Cat') {
          _result.value = "Gatinho";
        } else if (labels.first.label == 'Dog') {
          _result.value = "Cachorro";
        } else {
          _result.value = "Nenhum nem outro";
        }
      });
    });
  }
}
