import 'dart:convert';

import 'package:bloghub/presentation/qr_screen/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScanScreenState();
}

class AttendanceEntry {
  final String date;
  final String arrivedTime;
  String? leftTime;
  String? workedTime;

  AttendanceEntry({required this.date, required this.arrivedTime});
}

class _QRScanScreenState extends State<QRScreen> {
  List<AttendanceEntry> attendanceList = [];
  MobileScannerController cameraController = MobileScannerController();

  String? _errorMessage;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ирц бүртгэл', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: attendanceList.length,
        itemBuilder: (context, index) {
          final entry = attendanceList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                // Ирсэн row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${entry.date}, ${entry.arrivedTime}"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Ирсэн', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Явсан row
                entry.leftTime != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${entry.date}, ${entry.leftTime}"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Явсан', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _confirmLeaveDialog(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[200],
                          ),
                          child: const Text('Явсан'),
                        ),
                      ),

                // Worked time
                if (entry.workedTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text("Нийт ажилласан цаг: "),
                        Text("${entry.workedTime}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                const Divider(color: Colors.black, thickness: 1),
              ],
            ),
          );
        },
      ),
      floatingActionButton: InkWell(
        onTap: () {
          _scanQRCode(context);
        },
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
          child: const Icon(Icons.qr_code, color: Colors.white),
        ),
      ),
    );
  }

  void _confirmLeaveDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Баталгаажуулах'),
          content: const Text('Та ажлаа орхихдоо итгэлтэй байна уу?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Үгүй'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                _markAsLeft(index); // proceed with leave
              },
              child: const Text('Тийм'),
            ),
          ],
        );
      },
    );
  }

  void _scanQRCode(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      try {
        final data = json.decode(result);

        if (data['error'] == 'Expired') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR код хүчингүй болсон байна')),
          );

          setState(() {
            _errorMessage = data['message'];
          });
          return;
        }

        if (data['arrived'] == true) {
          setState(() {
            _errorMessage = null;
            attendanceList.add(AttendanceEntry(
              date: data['currentDate'],
              arrivedTime: data['arrivedTime'],
            ));
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR код хүчингүй болсон байна')),
        );
      }
    }
  }

  void _markAsLeft(int index) {
    final now = DateTime.now();
    final entry = attendanceList[index];

    final arrivedDateTime = DateTime.parse("${entry.date} ${entry.arrivedTime}");
    final workedDuration = now.difference(arrivedDateTime);
    final formattedWorkedTime = "${workedDuration.inHours}ц ${workedDuration.inMinutes.remainder(60)}мин";

    setState(() {
      entry.leftTime = "${now.hour}:${now.minute}:${now.second}";
      entry.workedTime = formattedWorkedTime;
    });
  }
}
