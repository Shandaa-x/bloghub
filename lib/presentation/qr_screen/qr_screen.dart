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
  String? leaveTime;     // ✅ NEW
  String? leaveType;     // ✅ NEW

  AttendanceEntry({
    required this.date,
    required this.arrivedTime,
    this.leftTime,
    this.workedTime,
    this.latitude,
    this.longitude,
    this.leftLatitude,
    this.leftLongitude,
    this.leaveTime,           // ✅ NEW
    this.leaveType,           // ✅ NEW
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

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      date: json['date'] ?? '',
      arrivedTime: json['arrived_time'] ?? '',
      leftTime: json['left_time'],
      workedTime: json['worked_time'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      leftLatitude: (json['left_latitude'] as num?)?.toDouble(),
      leftLongitude: (json['left_longitude'] as num?)?.toDouble(),
      leaveTime: json['leave_time'],        // ✅ NEW
      leaveType: json['leave_type'],        // ✅ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'arrived_time': arrivedTime,
      'left_time': leftTime,
      'worked_time': workedTime,
      'latitude': latitude,
      'longitude': longitude,
      'left_latitude': leftLatitude,
      'left_longitude': leftLongitude,
      'leave_time': leaveTime,             // ✅ NEW
      'leave_type': leaveType,             // ✅ NEW
    };
  }
}

class WeekData {
  final DateTime startDate;
  final DateTime endDate;
  final List<AttendanceEntry> entries;
  final int totalMinutes;
  final int uniqueDaysWorked;
  final List<LeaveRequest> leaveRequests; // ✅ new field

  WeekData({
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.totalMinutes,
    required this.uniqueDaysWorked,
    this.leaveRequests = const [], // ✅ optional param
  });

  String get weekTitle =>
      "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')} - "
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

  String get totalWorkedTime =>
      "${totalMinutes ~/ 60} цаг ${totalMinutes % 60} мин";
}

class LeaveRequest {
  final String date; // format: yyyy-MM-dd
  final String reason;
  final DateTime start; // leave start datetime
  final DateTime end;   // leave end datetime

  LeaveRequest({
    required this.date,
    required this.reason,
    required this.start,
    required this.end,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      date: json['date'],
      reason: json['reason'] ?? 'Чөлөө',
      start: (json['start'] is DateTime) ? json['start'] : (json['start'] as Timestamp).toDate(),
      end: (json['end'] is DateTime) ? json['end'] : (json['end'] as Timestamp).toDate(),
    );
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

  List<Map<String, dynamic>> leaveRequests = [];


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

      final snapshot = await FirebaseFirestore.instance.collection('attendance').where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth)).where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth)).orderBy('createdAt', descending: true).get();

      final leaveSnap = await FirebaseFirestore.instance.collection('leave_requests').get();
      leaveRequests = leaveSnap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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

      // Filter leave requests for this week
      final weekLeaveRequests = leaveRequests.where((leave) {
        final start = leave['start'] is DateTime ? leave['start'] : (leave['start'] as Timestamp).toDate();
        final end = leave['end'] is DateTime ? leave['end'] : (leave['end'] as Timestamp).toDate();
        return (start.isBefore(weekEnd.add(const Duration(days: 1))) && end.isAfter(weekStart.subtract(const Duration(days: 1))));
      }).map((leave) => LeaveRequest(
        date: (leave['start'] is DateTime ? leave['start'] : (leave['start'] as Timestamp).toDate()).toString().split(' ')[0],
        reason: leave['type'] ?? 'Чөлөө',
        start: leave['start'] is DateTime ? leave['start'] : (leave['start'] as Timestamp).toDate(),
        end: leave['end'] is DateTime ? leave['end'] : (leave['end'] as Timestamp).toDate(),
      )).toList();

      weeks.add(WeekData(
        startDate: weekStart,
        endDate: weekEnd,
        entries: entry.value,
        totalMinutes: totalMinutes,
        uniqueDaysWorked: uniqueDates.length,
        leaveRequests: weekLeaveRequests,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => LeaveRequestDialog(onSubmit: _submitLeaveRequest),
              );
            },
            child: const Text("Чөлөө авах"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: hasArrived ? _markLeft : _markArrived,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasArrived ? Colors.purple : Colors.green,
            ),
            child: Text(hasArrived ? 'Явлаа' : 'Ирлээ', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthNames = ['1-р сар', '2-р сар', '3-р сар', '4-р сар', '5-р сар', '6-р сар', '7-р сар', '8-р сар', '9-р сар', '10-р сар', '11-р сар', '12-р сар'];
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

  Future<void> _submitLeaveRequest(String type, DateTime start, DateTime end) async {
    try {
      await FirebaseFirestore.instance.collection('leave_requests').add({
        'type': type,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Чөлөө илгээгдлээ")));
    } catch (e) {
      _handleError("Чөлөө илгээхэд алдаа гарлаа: $e");
    }
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
                  Text(getMonthlyTotalWorkedTime(), style: const TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ажилласан өдөр:', style: TextStyle(fontSize: 13)),
                  Text('${getWorkedDaysCount()} өдөр', style: const TextStyle(color: Colors.blue, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WeekDetailScreen(
                weekData: week,
              ),
            ),
          ),
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(week.weekTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ажилласан өдөр: ${week.uniqueDaysWorked}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(week.totalWorkedTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
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

class LeaveRequestDialog extends StatefulWidget {
  final Function(String, DateTime, DateTime) onSubmit;

  const LeaveRequestDialog({required this.onSubmit, super.key});

  @override
  State<LeaveRequestDialog> createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends State<LeaveRequestDialog> {
  String selectedType = 'Чөлөө';
  DateTime? startDateTime;
  DateTime? endDateTime;

  Future<void> _pickDateTime({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        startDateTime = fullDateTime;
      } else {
        endDateTime = fullDateTime;
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    final time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    return "$date $time";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Чөлөөний хүсэлт"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedType,
            items: ['Чөлөө', 'Өвчтэй'].map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (val) => setState(() => selectedType = val!),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _pickDateTime(isStart: true),
            child: Text(startDateTime == null
                ? "Эхлэх огноо + цаг"
                : "Эхлэх: ${_formatDateTime(startDateTime)}"),
          ),
          ElevatedButton(
            onPressed: () => _pickDateTime(isStart: false),
            child: Text(endDateTime == null
                ? "Дуусах огноо + цаг"
                : "Дуусах: ${_formatDateTime(endDateTime)}"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Болих"),
        ),
        ElevatedButton(
          onPressed: () {
            if (startDateTime != null && endDateTime != null) {
              widget.onSubmit(selectedType, startDateTime!, endDateTime!);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Огноо болон цагийг бүрэн сонгоно уу")),
              );
            }
          },
          child: const Text("Илгээх"),
        ),
      ],
    );
  }
}
