import 'dart:convert';

import 'package:bloghub/presentation/qr_screen/qr_scanner_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  DateTime get dateTime => DateTime.parse("$date $arrivedTime");
}

enum ViewMode { all, monthly, weekly }

class _QRScanScreenState extends State<QRScreen> {
  List<AttendanceEntry> attendanceList = [];
  MobileScannerController cameraController = MobileScannerController();
  bool isLoading = true;
  ViewMode viewMode = ViewMode.all;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance.collection('attendance').orderBy('createdAt', descending: true).get();

      _updateAttendanceListFromSnapshot(snapshot);
      viewMode = ViewMode.all;
    } catch (e) {
      _handleFetchError(e);
    }
  }

  Future<void> _fetchWeeklyAttendance() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));

    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance.collection('attendance').where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek)).orderBy('createdAt', descending: true).get();

      _updateAttendanceListFromSnapshot(snapshot);
      viewMode = ViewMode.weekly;
    } catch (e) {
      _handleFetchError(e);
    }
  }

  Future<void> _fetchMonthlyAttendance() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);

    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance.collection('attendance').where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonth)).orderBy('createdAt', descending: true).get();

      _updateAttendanceListFromSnapshot(snapshot);
      viewMode = ViewMode.monthly;
    } catch (e) {
      _handleFetchError(e);
    }
  }

  Map<String, List<AttendanceEntry>> _groupAttendance(ViewMode mode) {
    Map<String, List<AttendanceEntry>> grouped = {};

    for (var entry in attendanceList) {
      final date = entry.dateTime;
      String key;

      if (mode == ViewMode.monthly) {
        key = "${date.year}.${date.month.toString().padLeft(2, '0')}";
      } else if (mode == ViewMode.weekly) {
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final friday = monday.add(const Duration(days: 4));
        key = "${monday.year}.${monday.month.toString().padLeft(2, '0')}.${monday.day.toString().padLeft(2, '0')} - "
            "${friday.year}.${friday.month.toString().padLeft(2, '0')}.${friday.day.toString().padLeft(2, '0')}";
      } else {
        key = 'Бүгдийг харах';
      }

      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ирц бүртгэл', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              if (value == 'week') {
                _fetchWeeklyAttendance();
              } else if (value == 'month') {
                _fetchMonthlyAttendance();
              } else {
                _fetchAttendanceData();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'week', child: Text('7 хоногоор харах')),
              PopupMenuItem(value: 'month', child: Text('Сараар харах')),
              PopupMenuItem(value: 'all', child: Text('Бүгдийг харах')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceList.isEmpty
              ? const Center(child: Text('Ирц бүртгэл байхгүй байна'))
              : RefreshIndicator(
                  onRefresh: _fetchAttendanceData,
                  child: ListView(
                    children: _groupAttendance(viewMode).entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (viewMode != ViewMode.all)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10, top: 2),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                            ...entry.value.map((e) => _buildAttendanceEntry(e)).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: InkWell(
        onTap: () => _scanQRCode(context),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
          child: const Icon(Icons.qr_code, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAttendanceEntry(AttendanceEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${entry.date}, ${entry.arrivedTime}"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green[300], borderRadius: BorderRadius.circular(4)),
              child: const Text('Ирсэн', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        entry.leftTime != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${entry.date}, ${entry.leftTime}"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.purple[200], borderRadius: BorderRadius.circular(4)),
                    child: const Text('Явсан', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _confirmLeaveDialog(attendanceList.indexOf(entry)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[200]),
                  child: const Text('Явсан'),
                ),
              ),
        if (entry.workedTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Text("Нийт ажилласан цаг: "),
                Text("${entry.workedTime}", style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const Divider(color: Colors.black, thickness: 1),
      ],
    );
  }

  void _updateAttendanceListFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<AttendanceEntry> fetchedList = snapshot.docs.map((doc) {
      final data = doc.data();
      return AttendanceEntry(
        date: data['currentDate'] ?? '',
        arrivedTime: data['arrivedTime'] ?? '',
      )
        ..leftTime = data['leftTime']
        ..workedTime = data['workedTime'];
    }).toList();

    setState(() {
      attendanceList = fetchedList;
      isLoading = false;
    });
  }

  void _handleFetchError(dynamic e) {
    debugPrint('Error fetching attendance: $e');
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ирцийн мэдээллийг ачааллахад алдаа гарлаа')),
      );
    }
  }

  void _confirmLeaveDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Баталгаажуулах'),
          content: const Text('Та ажлаа орхихдоо итгэлтэй байна уу?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Үгүй')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markAsLeft(index);
                },
                child: const Text('Тийм')),
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
            const SnackBar(content: Text('QR код хүчингүй болсон байна')),
          );
          return;
        }

        if (data['arrived'] == true) {
          await FirebaseFirestore.instance.collection('attendance').add({
            'arrived': true,
            'currentDate': data['currentDate'],
            'arrivedTime': data['arrivedTime'],
            'expiresAt': data['expiresAt'],
            'leftTime': null,
            'workedTime': null,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await _fetchAttendanceData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ирц амжилттай бүртгэгдлээ')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR код хүчингүй болсон байна')),
        );
      }
    }
  }

  void _markAsLeft(int index) async {
    final now = DateTime.now();
    final entry = attendanceList[index];

    final arrivedDateTime = DateTime.parse("${entry.date} ${entry.arrivedTime}");
    final workedDuration = now.difference(arrivedDateTime);
    final formattedWorkedTime = "${workedDuration.inHours}ц ${workedDuration.inMinutes.remainder(60)}мин";

    final leftTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final snapshot = await FirebaseFirestore.instance.collection('attendance').where('currentDate', isEqualTo: entry.date).where('arrivedTime', isEqualTo: entry.arrivedTime).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('attendance').doc(docId).update({
        'leftTime': leftTime,
        'workedTime': formattedWorkedTime,
      });

      setState(() {
        entry.leftTime = leftTime;
        entry.workedTime = formattedWorkedTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Гарсан цаг амжилттай бүртгэгдлээ')),
      );
    }
  }
}
