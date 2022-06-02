import 'package:camera/camera.dart';
import 'package:deal_ml/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:keep_screen_on/keep_screen_on.dart';

class DetectorDeObjetos extends StatefulWidget {
  const DetectorDeObjetos({super.key});

  @override
  State<DetectorDeObjetos> createState() => _DetectorDeObjetosState();
}

class _DetectorDeObjetosState extends State<DetectorDeObjetos> {
  final ValueNotifier<MlResult?> _object = ValueNotifier<MlResult?>(null);
  double _imageHeight = 320;
  double _imageWidth = 240;

  late ObjectDetector objectDetector;
  late ImageLabeler labeler;

  late CameraController _cameraController;

  bool _isCameraImageStream = false;

  @override
  Widget build(BuildContext context) {
    return CameraPreview(
      _cameraController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            ValueListenableBuilder<MlResult?>(
              valueListenable: _object,
              builder: (_, value, __) => Stack(
                children: [
                  if (value != null && value.object != null)
                    Positioned(
                      top: _vertical(value.object!.boundingBox.top) - 22,
                      height: _vertical(value.object!.boundingBox.height) + 22,
                      left: _horizontal(value.object!.boundingBox.left),
                      width: _horizontal(value.object!.boundingBox.width),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Text(
                              value.object!.labels.isEmpty
                                  ? 'Objeto'
                                  : value.object!.labels
                                      .map((e) => e.text)
                                      .join(', '),
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                          Container(
                            width: _horizontal(value.object!.boundingBox.width),
                            height: _vertical(value.object!.boundingBox.height),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.05),
                              border: Border.all(color: Colors.white),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _streamCamera,
          tooltip: 'Inicia a stream',
          child: const Icon(Icons.camera),
        ),
      ),
    );
  }

  @override
  dispose() {
    _cameraController.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    objectDetector = GoogleMlKit.vision.objectDetector(ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
    ));
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.low,
    )..initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    KeepScreenOn.turnOn(true);
  }

  /// Converte a imagem do camera para o formato de entrada do ML Kit
  InputImage _cameraToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: const {
          0: InputImageRotation.rotation0deg,
          90: InputImageRotation.rotation90deg,
          180: InputImageRotation.rotation180deg,
          270: InputImageRotation.rotation270deg,
        }[_cameraController.description.sensorOrientation]!,
        inputImageFormat: InputImageFormat.yuv420,
        planeData: image.planes
            .map((plane) => InputImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width))
            .toList(),
      ),
    );
  }

  /// Pega o tamanho horizontal atualizado de acordo com a proporção de tamanho da tela
  double _horizontal(double value) {
    return value / _imageWidth * MediaQuery.of(context).size.width;
  }

  /// Inicia/para a stream de imagens da camera
  _streamCamera() {
    if (_isCameraImageStream) {
      _cameraController.stopImageStream();
      _isCameraImageStream = false;
      _object.value = null;
      return;
    }
    _isCameraImageStream = true;
    _cameraController.startImageStream((CameraImage image) {
      _imageHeight = image.width.toDouble();
      _imageWidth = image.height.toDouble();
      final inputImage = _cameraToInputImage(image);
      objectDetector.processImage(inputImage).then((result) {
        if (result.isNotEmpty) {
          _object.value = MlResult(object: result.first);
        }
      });
    });
  }

  /// Pega o tamanho vertical atualizado de acordo com a proporção de tamanho da tela
  double _vertical(double value) {
    return value / _imageHeight * MediaQuery.of(context).size.height;
  }
}
