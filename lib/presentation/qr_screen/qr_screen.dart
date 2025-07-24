import 'dart:convert';

import 'package:bloghub/presentation/qr_screen/qr_scanner_screen.dart';
import 'package:bloghub/presentation/qr_screen/weekly/week_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class AttendanceEntry {
  final String date;
  final String arrivedTime;
  String? leftTime;
  String? workedTime;
  final double? latitude;
  final double? longitude;
  final double? leftLatitude;
  final double? leftLongitude;

  AttendanceEntry({
    required this.date,
    required this.arrivedTime,
    this.latitude,
    this.longitude,
    this.leftLatitude,
    this.leftLongitude,
  });

  DateTime? get dateTime {
    try {
      return DateTime.parse("$date $arrivedTime");
    } catch (e) {
      // fallback: try to fix single-digit seconds
      final fixedTime = _fixTimeFormat(arrivedTime);
      try {
        return DateTime.parse("$date $fixedTime");
      } catch (e) {
        return null;
      }
    }
  }

  String _fixTimeFormat(String? time) {
    if (time == null) return '';
    final parts = time.split(':');
    if (parts.length == 3) {
      parts[2] = parts[2].padLeft(2, '0');
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2]}";
    }
    return time;
  }
}

class WeekData {
  final DateTime startDate;
  final DateTime endDate;
  final List<AttendanceEntry> entries;
  final int totalMinutes;
  final int uniqueDaysWorked;

  WeekData({
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.totalMinutes,
    required this.uniqueDaysWorked,
  });

  String get weekTitle {
    return "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} - ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
  }

  String get totalWorkedTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "$hours цаг $minutes мин";
  }
}

class _QRScreenState extends State<QRScreen> {
  List<AttendanceEntry> attendanceList = [];
  bool isLoading = true;
  bool hasArrived = false;
  String? arrivedDocId;
  DateTime currentMonth = DateTime.now();
  bool showLocationMap = false;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => isLoading = true);
    try {
      final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
      final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('createdAt', descending: true)
          .get();

      _updateAttendanceList(snapshot);
    } catch (e) {
      _handleError('Ирцийн мэдээллийг ачааллахад алдаа гарлаа');
    }
  }

  int parseWorkedTimeToMinutes(String workedTime) {
    final regex = RegExp(r"(\d+)ц\s+(\d+)мин");
    final match = regex.firstMatch(workedTime);
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }

  String getMonthlyTotalWorkedTime() {
    int totalMinutes = 0;
    for (var e in attendanceList) {
      if (e.workedTime != null) {
        totalMinutes += parseWorkedTimeToMinutes(e.workedTime!);
      }
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "$hours цаг $minutes мин";
  }

  int getWorkedDaysCount() {
    // Count unique dates (worked days), not total entries
    final uniqueDates = <String>{};
    for (var entry in attendanceList) {
      uniqueDates.add(entry.date);
    }
    return uniqueDates.length;
  }

  List<WeekData> _groupByWeeks() {
    final weeks = <WeekData>[];
    final Map<String, List<AttendanceEntry>> weekGroups = {};

    for (final entry in attendanceList) {
      final date = entry.dateTime;
      if (date != null) {
        // Get the start of the week (Monday)
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekStartFormatted = "${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}";

        weekGroups.putIfAbsent(weekStartFormatted, () => []).add(entry);
      }
    }

    // Convert to WeekData objects
    for (final entry in weekGroups.entries) {
      final weekStart = DateTime.parse(entry.key);
      final weekEnd = weekStart.add(const Duration(days: 6));

      int totalMinutes = 0;
      final uniqueDatesInWeek = <String>{};

      for (final attendance in entry.value) {
        // Count unique dates for worked days
        uniqueDatesInWeek.add(attendance.date);

        // Sum worked time
        if (attendance.workedTime != null) {
          totalMinutes += parseWorkedTimeToMinutes(attendance.workedTime!);
        }
      }

      weeks.add(WeekData(
        startDate: weekStart,
        endDate: weekEnd,
        entries: entry.value,
        totalMinutes: totalMinutes,
        uniqueDaysWorked: uniqueDatesInWeek.length, // Add this field
      ));
    }

    // Sort weeks by start date (most recent first)
    weeks.sort((a, b) => b.startDate.compareTo(a.startDate));
    return weeks;
  }

  void _changeMonth(int monthOffset) {
    final newMonth = DateTime(currentMonth.year, currentMonth.month + monthOffset, 1);

    // Don't allow future months
    final now = DateTime.now();
    if (newMonth.isAfter(DateTime(now.year, now.month, 1))) {
      return;
    }

    setState(() {
      currentMonth = newMonth;
    });
    _fetchAttendanceData();
  }

  String get monthTitle {
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return "${monthNames[currentMonth.month - 1]} ${currentMonth.year}";
  }

  bool get canGoPreviousMonth {
    // Check if there's attendance data in the previous month
    // For now, just allow going back 12 months
    final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365));
    return currentMonth.isAfter(twelveMonthsAgo);
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw Exception("GPS is disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      throw Exception("Location permission not granted.");
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _groupByWeeks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ирц бүртгэл', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Month navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: canGoPreviousMonth ? () => _changeMonth(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: currentMonth.month < DateTime.now().month || currentMonth.year < DateTime.now().year
                      ? () => _changeMonth(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Monthly summary
          _buildMonthlySummary(),

          // Weeks list
          Expanded(
            child: attendanceList.isEmpty
                ? const Center(child: Text('Энэ сард ирц байхгүй байна'))
                : RefreshIndicator(
              onRefresh: _fetchAttendanceData,
              child: ListView.builder(
                itemCount: weeks.length,
                itemBuilder: (context, index) {
                  return _buildWeekCard(weeks[index]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: hasArrived ? _markLeft : _markArrived,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasArrived ? Colors.purple : Colors.green,
          ),
          child: Text(hasArrived ? 'Явлаа' : 'Ирлээ', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final total = getMonthlyTotalWorkedTime();
    final daysWorked = getWorkedDaysCount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Сарын нийт ажилласан цаг:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ажилласан өдөр:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('$daysWorked өдөр', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCard(WeekData week) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeekDetailScreen(weekData: week),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  week.weekTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ажилласан өдөр: ${week.uniqueDaysWorked}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      week.totalWorkedTime,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markArrived() async {
    try {
      final pos = await _getLocation();
      final now = DateTime.now();
      final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final time = _formatTime(now);

      final doc = await FirebaseFirestore.instance.collection('attendance').add({
        'arrived': true,
        'currentDate': date,
        'arrivedTime': time,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        hasArrived = true;
        arrivedDocId = doc.id;
        currentPosition = pos;
        showLocationMap = true;
      });
      _fetchAttendanceData();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  Future<void> _markLeft() async {
    if (arrivedDocId == null) return;

    try {
      final pos = await _getLocation();
      final now = DateTime.now();
      final time = _formatTime(now);

      final doc = await FirebaseFirestore.instance.collection('attendance').doc(arrivedDocId!).get();
      final dt = DateTime.parse("${doc['currentDate']} ${doc['arrivedTime']}");
      final diff = now.difference(dt);
      final worked = "${diff.inHours}ц ${diff.inMinutes.remainder(60)}мин";

      await FirebaseFirestore.instance.collection('attendance').doc(arrivedDocId!).update({
        'leftTime': time,
        'leftLatitude': pos.latitude,
        'leftLongitude': pos.longitude,
        'workedTime': worked,
      });

      setState(() {
        hasArrived = false;
        arrivedDocId = null;
        showLocationMap = false;
      });
      _fetchAttendanceData();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _updateAttendanceList(QuerySnapshot snapshot) {
    attendanceList = snapshot.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return AttendanceEntry(
        date: d['currentDate'],
        arrivedTime: d['arrivedTime'],
        latitude: d['latitude']?.toDouble(),
        longitude: d['longitude']?.toDouble(),
        leftLatitude: d['leftLatitude']?.toDouble(),
        leftLongitude: d['leftLongitude']?.toDouble(),
      )
        ..leftTime = d['leftTime']
        ..workedTime = d['workedTime'];
    }).toList();
    setState(() => isLoading = false);
  }

  void _handleError(String msg) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}