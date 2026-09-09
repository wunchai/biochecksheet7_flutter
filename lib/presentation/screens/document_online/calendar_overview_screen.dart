import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:biochecksheet7_flutter/data/network/api_response_models.dart';
import 'package:biochecksheet7_flutter/presentation/screens/document_online/calendar_overview_viewmodel.dart';
import 'package:biochecksheet7_flutter/data/network/document_online_api_service.dart';

class CalendarOverviewScreen extends StatefulWidget {
  final String userId;
  const CalendarOverviewScreen({super.key, required this.userId});

  @override
  State<CalendarOverviewScreen> createState() => _CalendarOverviewScreenState();
}

class _CalendarOverviewScreenState extends State<CalendarOverviewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    
    // Fetch data for the current month when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForMonth(_focusedDay);
    });
  }

  void _loadDataForMonth(DateTime month) {
    Provider.of<CalendarOverviewViewModel>(context, listen: false)
        .loadCalendarData(widget.userId, month.year, month.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปฏิทินสรุปเอกสารออนไลน์'),
      ),
      body: Consumer<CalendarOverviewViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => _loadDataForMonth(_focusedDay),
                    child: const Text('ลองใหม่'),
                  )
                ],
              ),
            );
          }

          return Container(
            color: Colors.grey[50], // Soft background for the entire page
            child: Column(
              children: [
              // Calendar Card
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar<CalendarJobSummary>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadDataForMonth(focusedDay);
                    },
                    eventLoader: (day) {
                      return viewModel.getEventsForDay(day);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(76),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      markerMargin: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 2.0),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox();
                        
                        return Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(4).map((event) { // Max 4 dots
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 6.0,
                                height: 6.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: viewModel.getColorForJob(event.jobId),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const Divider(),
              
              // Legend Area
              if (viewModel.getLegend().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('สัญลักษณ์แยกตาม Job:', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: viewModel.getLegend().entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.value.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: entry.value.withAlpha(76)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: entry.value,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(entry.key, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),

              // Selected Day Details
              Expanded(
                child: _buildEventList(viewModel),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventList(CalendarOverviewViewModel viewModel) {
    if (_selectedDay == null) return const Center(child: Text('กรุณาเลือกวันที่'));
    
    final events = viewModel.getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('ไม่มีข้อมูลเอกสารในวันนี้', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.only(bottom: 16.0),
      itemBuilder: (context, index) {
        final event = events[index];
        final color = viewModel.getColorForJob(event.jobId);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pop(context, {
                'jobId': event.jobId,
                'jobName': event.jobName,
                'date': _selectedDay,
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.jobName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Job ID: ${event.jobId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description, size: 14, color: Colors.blueGrey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${event.documentCount}',
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
