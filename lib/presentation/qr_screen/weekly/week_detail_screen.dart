import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../qr_screen.dart';

class WeekDetailScreen extends StatelessWidget {
  final WeekData weekData;

  const WeekDetailScreen({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {
    final dailyEntries = _groupEntriesByDay();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          weekData.weekTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildWeekSummary(),
          Expanded(
            child: dailyEntries.isEmpty
                ? const Center(
              child: Text(
                'Энэ долоо хоногт ирц байхгүй байна',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dailyEntries.length,
              itemBuilder: (context, index) {
                final entry = dailyEntries.entries.elementAt(index);
                return _buildDayCard(entry.key, entry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    final uniqueDays = weekData.entries
        .where((e) => e.dateTime != null)
        .map((e) => DateTime(e.dateTime!.year, e.dateTime!.month, e.dateTime!.day))
        .toSet();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Долоо хоногийн тойм',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Нийт цаг', weekData.totalWorkedTime, Colors.green),
                  _buildSummaryItem('Ажилласан өдөр', '${uniqueDays.length} өдөр', Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Map<DateTime, List<AttendanceEntry>> _groupEntriesByDay() {
    final Map<DateTime, List<AttendanceEntry>> grouped = {};
    for (var entry in weekData.entries) {
      if (entry.dateTime == null) continue;
      final key = DateTime(entry.dateTime!.year, entry.dateTime!.month, entry.dateTime!.day);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  Widget _buildDayCard(DateTime date, List<AttendanceEntry> entries) {
    final dayNames = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];
    final dayName = dayNames[date.weekday - 1];
    final dateString = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blueAccent.shade100, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(dateString, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  Chip(
                    label: Text('${entries.length} удаа'),
                    backgroundColor: Colors.blue,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...entries.map((e) => _buildEntryCard(e)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(AttendanceEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.arrivedTime.isNotEmpty && entry.latitude != null && entry.longitude != null)
          _buildAttendanceDetail(
            'Ирсэн цаг',
            entry.arrivedTime,
            Icons.login,
            location: LatLng(entry.latitude!, entry.longitude!),
          ),
        if (entry.leftTime != null && entry.leftLatitude != null && entry.leftLongitude != null)
          _buildAttendanceDetail(
            'Явсан цаг', 
            entry.leftTime!,
            Icons.logout,
            location: LatLng(entry.leftLatitude!, entry.leftLongitude!),
          ),
        if (entry.workedTime != null)
          _buildAttendanceDetail(
            'Ажилласан',
            entry.workedTime!,
            Icons.access_time,
            isHighlight: true,
          ),
        const Divider(),
      ],
    );
  }

  Widget _buildAttendanceDetail(String label, String value, IconData icon,
      {bool isHighlight = false, LatLng? location}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isHighlight ? Colors.green : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.green : Colors.black,
                ),
              ),
              if (location != null)
                Text(
                  '(${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
