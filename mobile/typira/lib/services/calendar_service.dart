import 'package:device_calendar/device_calendar.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

enum CalendarResult { success, permissionDenied, noCalendars, error }

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  final Logger _logger = Logger();

  Future<CalendarResult> createEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // 1. Explicit Permission Request via permission_handler
      var status = await Permission.calendarFullAccess.status;
      _logger.i('Initial Permission Status (Handler): $status');

      if (!status.isGranted) {
        status = await Permission.calendarFullAccess.request();
        _logger.i('Post-Request Permission Status: $status');
        
        if (!status.isGranted) {
           _logger.e('Calendar permission denied by user (or OS policy).');
           return CalendarResult.permissionDenied;
        }
      }

      // 2. Fetch calendars
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
        _logger.e('No calendars found');
        return CalendarResult.noCalendars;
      }

      // 3. Pick the first writable calendar (usually the default one)
      final calendar = calendarsResult.data!.firstWhere(
        (c) => c.isReadOnly == false,
        orElse: () => calendarsResult.data!.first,
      );

      // 4. Create the event
      final event = Event(
        calendar.id,
        title: title,
        description: description,
        start: TZDateTime.from(start, local),
        end: TZDateTime.from(end, local),
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return (result?.isSuccess ?? false) ? CalendarResult.success : CalendarResult.error;
    } catch (e) {
      _logger.e('Error creating calendar event: $e');
      return CalendarResult.error;
    }
  }
}
