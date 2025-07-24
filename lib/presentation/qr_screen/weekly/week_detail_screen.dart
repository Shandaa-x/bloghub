import 'package:flutter/material.dart';

import '../qr_screen.dart';

// Import the AttendanceEntry and WeekData classes from your main QR screen file
// or move them to a separate models file

class WeekDetailScreen extends StatelessWidget {
  final WeekData weekData;

  const WeekDetailScreen({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {
    final dailyAttendance = _groupByDays();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${weekData.weekTitle}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Week summary
          _buildWeekSummary(),

          // Daily attendance list
          Expanded(
            child: dailyAttendance.isEmpty
                ? const Center(
              child: Text(
                'Энэ долоо хоногт ирц байхгүй байна',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dailyAttendance.length,
              itemBuilder: (context, index) {
                final entry = dailyAttendance.entries.elementAt(index);
                return _buildDayCard(entry.key, entry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    final totalDaysWorked = weekData.entries.length; // Count all entries (arrived days)

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
                  _buildSummaryItem('Ажилласан өдөр', '$totalDaysWorked өдөр', Colors.blue),
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
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Map<DateTime, AttendanceEntry?> _groupByDays() {
    final Map<DateTime, AttendanceEntry?> dailyMap = {};

    // Generate all 7 days of the week
    for (int i = 0; i < 7; i++) {
      final day = weekData.startDate.add(Duration(days: i));
      dailyMap[day] = null;
    }

    // Fill in actual attendance data
    for (final entry in weekData.entries) {
      final entryDate = entry.dateTime;
      if (entryDate != null) {
        final dayOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
        dailyMap[dayOnly] = entry;
      }
    }

    return dailyMap;
  }

  Widget _buildDayCard(DateTime date, AttendanceEntry? attendance) {
    final dayNames = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];
    final dayName = dayNames[date.weekday - 1];
    final dateString = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";

    final bool hasAttendance = attendance != null;
    final bool isComplete = hasAttendance && attendance.leftTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasAttendance
                ? (isComplete ? Colors.green : Colors.orange)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and day header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dateString,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasAttendance
                          ? (isComplete ? Colors.green : Colors.orange)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasAttendance
                          ? (isComplete ? 'Гүйцэт' : 'Дутуу')
                          : 'Ирсэнгүй',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),

              if (hasAttendance) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Attendance details
                _buildAttendanceDetail('Ирсэн цаг', attendance.arrivedTime, Icons.login),

                if (attendance.leftTime != null) ...[
                  const SizedBox(height: 8),
                  _buildAttendanceDetail('Явсан цаг', attendance.leftTime!, Icons.logout),
                ],

                if (attendance.workedTime != null) ...[
                  const SizedBox(height: 8),
                  _buildAttendanceDetail('Ажилласан цаг', attendance.workedTime!, Icons.access_time, isHighlight: true),
                ],
              ] else ...[
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Энэ өдөр ирц байхгүй',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceDetail(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlight ? Colors.green : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}