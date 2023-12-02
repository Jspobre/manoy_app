import 'package:flutter/material.dart';
import 'package:manoy_app/pages/profile/appointments_lists.dart';
import 'package:manoy_app/pages/profile/userAppointments.dart';
import 'package:manoy_app/widgets/styledButton.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentPage extends StatefulWidget {
  final String name;
  final String shopId;

  const AppointmentPage({Key? key, required this.name, required this.shopId})
      : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime today = DateTime.now();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  Map<String, dynamic>? businessHours;

  void onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
      startTime = null;
      endTime = null;
    });

    _selectTime(context, true);
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          startTime = pickedTime;
          _selectTime(context, false); // Automatically show end time picker
        } else {
          // Check if end time is before start time, if so, adjust it
          if (startTime != null && pickedTime.hour < startTime!.hour) {
            endTime =
                TimeOfDay(hour: startTime!.hour, minute: startTime!.minute);
          } else if (startTime != null &&
              pickedTime.hour == startTime!.hour &&
              pickedTime.minute < startTime!.minute) {
            endTime =
                TimeOfDay(hour: startTime!.hour, minute: startTime!.minute);
          } else {
            endTime = pickedTime;
          }
        }
      });
    }
  }

  void _showInvalidEndTimeSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Invalid end time. Please select a time after the start time.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isEndTimeValid(TimeOfDay startTime, TimeOfDay endTime) {
    final DateTime startDateTime =
        DateTime(0, 0, 0, startTime.hour, startTime.minute);
    final DateTime endDateTime =
        DateTime(0, 0, 0, endTime.hour, endTime.minute);
    return endDateTime.isAfter(startDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: calendar(),
      ),
    );
  }

  Widget calendar() {
    return Column(
      children: [
        const SizedBox(
          height: 30,
        ),
        const Text(
          'BOOK AN APPOINTMENT!',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 20,
        ),
        Image.asset(
          'lib/images/logo.png',
          height: 120,
          width: 120,
        ),
        SizedBox(height: 5),
        Center(
          child: SizedBox(
            height: 70, // Adjust the height as needed
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Warning: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Please select a time and date that align\nwith the business hours of the shop. Otherwise, the appointment will be rejected',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          child: TableCalendar(
            focusedDay: today,
            firstDay: DateTime.utc(2020, 7, 1),
            lastDay: DateTime.utc(2030, 7, 1),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, today),
            onDaySelected: onDaySelected,
          ),
        ),
        SizedBox(height: 16),
        Text('Selected Day: ${today.toString().split(' ')[0]}'),
        if (startTime != null)
          Text("Selected Start Time: ${startTime!.format(context)}"),
        if (endTime != null)
          Text("Selected End Time: ${endTime!.format(context)}"),
        const SizedBox(
          height: 30,
        ),
        StyledButton(
          btnText: 'CREATE APPOINTMENT',
          onClick: () async {
            final String userId = FirebaseAuth.instance.currentUser!.uid;
            final email = FirebaseAuth.instance.currentUser!.email;

            if (startTime != null &&
                endTime != null &&
                _isEndTimeValid(startTime!, endTime!)) {
              final String appointmentTime =
                  '${startTime!.format(context)} - ${endTime!.format(context)}';

              final DocumentReference appointmentRef =
                  FirebaseFirestore.instance.collection('appointments').doc();

              await appointmentRef.set({
                'date': today,
                'time': appointmentTime,
                'userId': userId,
                'email': email,
                'shopId': widget.shopId,
                'status': 'Pending',
                'shopName': widget.name,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment created successfully!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              _showInvalidEndTimeSnackBar();
            }
          },
        ),
        const SizedBox(
          height: 15,
        ),
        StyledButton(
            btnText: 'VIEW APPOINTMENTS',
            onClick: () {
              final String userId = FirebaseAuth.instance.currentUser!.uid;
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      UserAppointmentsPage(name: widget.name, userId: userId)));
            }),
      ],
    );
  }
}
