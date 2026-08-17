// A simple line chart of the blood sugar trend (made with fl_chart).


import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The blood sugar trend chart on the dashboard.
class BloodSugarChart extends StatelessWidget {
  /// Chart points (x = reading index, y = sugar level).
  final List<FlSpot> spots;

  const BloodSugarChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length > 1 ? spots.length - 1 : 1,
        minY: 80,
        maxY: 200,
        // Light horizontal lines so it's easier to read.
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        // The blue line with dots.
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        // Shows the value in mg/dL when you touch the chart.
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} mg/dL',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
