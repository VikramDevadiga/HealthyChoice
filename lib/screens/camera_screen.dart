import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projectapp/screens/results_page.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ✅ Initialize the back camera only
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    // Use back camera only
    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => CameraDescription(
        name: 'NoBackCamera',
        lensDirection: CameraLensDirection.external,
        sensorOrientation: 0,
      ),
    );

    if (backCamera.name == 'NoBackCamera') {
      _showError('No back camera found');
      return;
    }

    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showError('Camera permission denied');
      return;
    }

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });

      // Start image stream for barcode scanning
      await _controller!.startImageStream((CameraImage image) {
        _processImage(image);
      });

    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  // ✅ Display error message and return to the previous screen
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  // ✅ Toggle flash on and off
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      _showError('Failed to toggle flash: $e');
    }
  }

  // ✅ Handle barcode scanning and navigate with beep sound
  void _onBarcodeScanned(String barcode) async {
    if (!isScanning) return;  // Prevent multiple scans
    setState(() {
      isScanning = false;
    });

    // ✅ Play Beep Sound
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));

    // ✅ Navigate to ResultsPage with the barcode
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsPage(barcode: barcode)),
    ).then((_) {
      setState(() {
        isScanning = true; // Reset scanning state after returning
      });
    });
  }

  // ✅ Process the image and detect barcode
  Future<void> _processImage(CameraImage image) async {
    if (_isScanning) return;

    _isScanning = true;

    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        if (barcode.rawValue != null) {
          _onBarcodeScanned(barcode.rawValue!);
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      // ✅ Cooldown delay to prevent continuous scanning
      await Future.delayed(const Duration(milliseconds: 1500));
      _isScanning = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Camera preview
          CameraPreview(_controller!),

          // ✅ Scanning overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // ✅ Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _toggleFlash,
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      final image = await _controller!.takePicture();
                      debugPrint('Image captured: ${image.path}');
                    } catch (e) {
                      _showError('Failed to capture image: $e');
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Scanner overlay with improved rendering
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.width * 0.8,
    );

    // Draw semi-transparent overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            scanArea,
            const Radius.circular(12),
          )),
      ),
      paint,
    );

    // Draw scanning frame
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
