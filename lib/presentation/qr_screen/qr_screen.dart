import 'dart:convert';

import 'package:bloghub/presentation/qr_screen/weekly/week_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    } catch (_) {
      final fixedTime = _fixTimeFormat(arrivedTime);
      try {
        return DateTime.parse("$date $fixedTime");
      } catch (_) {
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

  String get weekTitle =>
      "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} - ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

  String get totalWorkedTime =>
      "${totalMinutes ~/ 60} цаг ${totalMinutes % 60} мин";
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
    return "${totalMinutes ~/ 60} цаг ${totalMinutes % 60} мин";
  }

  int getWorkedDaysCount() {
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
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final key = "${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}";
        weekGroups.putIfAbsent(key, () => []).add(entry);
      }
    }

    for (final entry in weekGroups.entries) {
      final weekStart = DateTime.parse(entry.key);
      final weekEnd = weekStart.add(const Duration(days: 6));
      int totalMinutes = 0;
      final uniqueDates = <String>{};

      for (final att in entry.value) {
        uniqueDates.add(att.date);
        if (att.workedTime != null) {
          totalMinutes += parseWorkedTimeToMinutes(att.workedTime!);
        }
      }

      weeks.add(WeekData(
        startDate: weekStart,
        endDate: weekEnd,
        entries: entry.value,
        totalMinutes: totalMinutes,
        uniqueDaysWorked: uniqueDates.length,
      ));
    }

    weeks.sort((a, b) => b.startDate.compareTo(a.startDate));
    return weeks;
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw Exception("GPS is disabled.");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) throw Exception("Location permission not granted.");
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
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

  void _handleError(String msg) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          _buildMonthNavigation(),
          _buildMonthlySummary(),
          if (showLocationMap && currentPosition != null) _buildMapView(),
          Expanded(
            child: attendanceList.isEmpty
                ? const Center(child: Text('Энэ сард ирц байхгүй байна'))
                : RefreshIndicator(
              onRefresh: _fetchAttendanceData,
              child: ListView.builder(
                itemCount: weeks.length,
                itemBuilder: (context, index) => _buildWeekCard(weeks[index]),
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

  Widget _buildMonthNavigation() {
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            "${monthNames[currentMonth.month - 1]} ${currentMonth.year}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: currentMonth.month < DateTime.now().month ? () => _changeMonth(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int offset) {
    final newMonth = DateTime(currentMonth.year, currentMonth.month + offset, 1);
    if (newMonth.isAfter(DateTime.now())) return;
    setState(() => currentMonth = newMonth);
    _fetchAttendanceData();
  }

  Widget _buildMonthlySummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Сарын нийт ажилласан цаг:', style: TextStyle(fontSize: 13)),
                  Text(getMonthlyTotalWorkedTime(), style: const TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ажилласан өдөр:', style: TextStyle(fontSize: 13)),
                  Text('${getWorkedDaysCount()} өдөр', style: const TextStyle(color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("current"),
                position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                infoWindow: const InfoWindow(title: "Миний байршил"),
              ),
            },
            zoomControlsEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCard(WeekData week) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => WeekDetailScreen(weekData: week),
          )),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(week.weekTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ажилласан өдөр: ${week.uniqueDaysWorked}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(week.totalWorkedTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
