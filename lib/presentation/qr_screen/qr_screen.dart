import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  String? _scannedCode;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display scanned result
            if (_scannedCode != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Scanned QR Code:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _scannedCode!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else
              const Text(
                'Press the button to scan a QR code',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            const SizedBox(height: 30),
            // Scan QR Code Button
            ElevatedButton.icon(
              onPressed: () {
                _scanQRCode(context);
              },
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text(
                'Scan QR Code',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Function to navigate to the scanner view
  void _scanQRCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Code'),
            backgroundColor: Colors.blueAccent,
          ),
          body: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    _scannedCode = code;
                  });
                  // Stop the camera and pop the scanner screen
                  cameraController.stop();
                  Navigator.pop(context);
                }
              }
            },
          ),
        ),
      ),
    );
  }
}