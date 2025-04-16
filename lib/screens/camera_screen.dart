import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'results_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isScanning = true;

  void _playBeep() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  }

  void _onBarcodeScanned(String barcode) async {
    if (!isScanning) return; // Prevent multiple scans
    setState(() {
      isScanning = false;
    });

    _playBeep(); // Play beep sound

    // Navigate to results page with the scanned barcode
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsPage(barcode: barcode)),
    ).then((_) {
      setState(() {
        isScanning = true; // Reset scanning after returning
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Product")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture capture) {
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null) {
                _onBarcodeScanned(barcode);
              }
            },
          ),
          Positioned(
            bottom: 50,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: const Text(
                "Align the barcode inside the frame to scan",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
