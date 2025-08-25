// lib/ui/documentrecord/widgets/record_line_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart library
import 'package:biochecksheet7_flutter/data/database/app_database.dart'; // สำหรับ DbJob
//import 'package:biochecksheet7_flutter/data/database/tables/job_tag_table.dart'; // For DbJobTag

/// Widget สำหรับแสดงกราฟเส้นของข้อมูล Record
class RecordLineChart extends StatelessWidget {
  final Stream<List<FlSpot>> chartDataStream;
  final DbJobTag? jobTag; // Job Tag info for title/labels

  const RecordLineChart({
    super.key,
    required this.chartDataStream,
    this.jobTag,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FlSpot>>(
      stream: chartDataStream, // Listen to the chart data stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('ข้อผิดพลาดในการโหลดกราฟ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีข้อมูลสำหรับกราฟนี้.'));
        } else {
          final spots = snapshot.data!;

          // Parse specMin and specMax from jobTag
          final double? specMin = double.tryParse(jobTag?.specMin ?? '');
          final double? specMax = double.tryParse(jobTag?.specMax ?? '');

          // Determine min/max Y values for chart scaling
          double minY =
              spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
          double maxY =
              spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

          // Adjust minY and maxY to include specMin/specMax if they exist
          if (specMin != null) {
            minY = minY < specMin ? minY : specMin;
          }
          if (specMax != null) {
            maxY = maxY > specMax ? maxY : specMax;
          }

          // Add a little padding to min/max Y for better visualization
          minY =
              (minY * 0.95).clamp(0.0, double.infinity); // 5% padding below min
          maxY = maxY * 1.05; // 5% padding above max

          // Ensure minY is always less than maxY
          if (minY >= maxY) {
            minY = maxY -
                1.0; // Prevent invalid chart range if all values are same
            if (minY < 0) minY = 0.0;
          }

          List<LineChartBarData> lineBarsData = [
            // Main data line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue, // Color for the actual data line
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ];

          // Add specMin line if it exists
          if (specMin != null) {
            lineBarsData.add(
              LineChartBarData(
                spots: [
                  FlSpot(0, specMin),
                  FlSpot(
                      (spots.length - 1).toDouble().clamp(0.0, double.infinity),
                      specMin),
                ],
                isCurved: false, // Straight line
                color: Colors.orange, // Color for specMin line
                barWidth: 1.5,
                dotData: const FlDotData(show: false), // No dots for this line
                belowBarData: BarAreaData(show: false),
              ),
            );
          }

          // Add specMax line if it exists
          if (specMax != null) {
            lineBarsData.add(
              LineChartBarData(
                spots: [
                  FlSpot(0, specMax),
                  FlSpot(
                      (spots.length - 1).toDouble().clamp(0.0, double.infinity),
                      specMax),
                ],
                isCurved: false, // Straight line
                color: Colors.red, // Color for specMax line
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toStringAsFixed(0)), // Y-axis labels
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString()), // X-axis labels (index)
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(0.0, double.infinity),
                minY: minY,
                maxY: maxY,
                lineBarsData: lineBarsData, // Pass the list of all lines
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueAccent,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${jobTag?.tagName ?? 'Value'}: ${spot.y.toStringAsFixed(2)}\nIndex: ${spot.x.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                    tooltipBorder: const BorderSide(color: Colors.blueAccent),
                    tooltipMargin: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
