import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';

class CalendarOverviewViewModel extends ChangeNotifier {
  final DocumentOnlineApiService _apiService;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Store data mapped by DateTime (year, month, day)
  Map<DateTime, List<CalendarJobSummary>> _events = {};
  Map<DateTime, List<CalendarJobSummary>> get events => _events;

  // Store job color mappings
  final Map<String, Color> _jobColors = {};
  final Map<String, String> _jobNames = {};

  CalendarOverviewViewModel(this._apiService);

  // Use a predefined list of vibrant colors for jobs
  final List<Color> _palette = [
    Colors.redAccent,
    Colors.green,
    Colors.blueAccent,
    Colors.orange,
    Colors.purpleAccent,
    Colors.teal,
    Colors.pink,
    Colors.amber[700]!,
    Colors.indigo,
    Colors.cyan,
  ];
  int _paletteIndex = 0;

  Future<void> loadCalendarData(String userId, int year, int month) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getCalendarSummary(userId, year, month);
      
      if (response != null && response.status == 'success') {
        _events.clear(); // clear old month data or we can append if we want
        
        for (var dayData in response.data) {
          try {
            // Parse 'YYYY-MM-DD'
            final parts = dayData.date.split('-');
            if (parts.length == 3) {
              final date = DateTime.utc(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              _events[date] = dayData.jobs;
              
              // Assign colors and save names
              for (var job in dayData.jobs) {
                _jobNames[job.jobId] = job.jobName;
                if (!_jobColors.containsKey(job.jobId)) {
                  _jobColors[job.jobId] = _palette[_paletteIndex % _palette.length];
                  _paletteIndex++;
                }
              }
            }
          } catch (e) {
            print('Error parsing date: ${dayData.date}');
          }
        }
      } else {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลปฏิทินได้';
      }
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาด: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Color getColorForJob(String jobId) {
    return _jobColors[jobId] ?? Colors.grey;
  }
  
  Map<String, Color> getLegend() {
    Map<String, Color> legend = {};
    _jobNames.forEach((id, name) {
      legend[name] = _jobColors[id] ?? Colors.grey;
    });
    return legend;
  }
  
  List<CalendarJobSummary> getEventsForDay(DateTime day) {
    // Return events for the specific day (normalizing time)
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }
}
