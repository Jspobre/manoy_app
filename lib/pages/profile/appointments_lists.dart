import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manoy_app/widgets/styledDropdown.dart';

class AppointmentsListsPage extends StatefulWidget {
  const AppointmentsListsPage({Key? key}) : super(key: key);

  @override
  State<AppointmentsListsPage> createState() => _AppointmentsListsPageState();
}

class _AppointmentsListsPageState extends State<AppointmentsListsPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  // final String shopId = FirebaseAuth.instance.currentUser!.uid;
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('APPOINTMENTS'),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('shopId', isEqualTo: userId)
                  // .where('status', isNotEqualTo: 'Cancelled') // Add this filter
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final appointments = snapshot.data!.docs;

                final containerWidth = MediaQuery.of(context).size.width * 0.9;

                return Column(
                  children: appointments.map((appointment) {
                    final appointmentData =
                        appointment.data() as Map<String, dynamic>;
                    final date = appointmentData['date'] as Timestamp;
                    final email = appointmentData['email'] as String;
                    final time = appointmentData['time'] as String;
                    final status = appointmentData['status'] as String;

                    final DateTime dateTime = date.toDate();
                    final year = dateTime.year;
                    final month = dateTime.month;
                    final day = dateTime.day;

                    final formattedDate = '$year-$month-$day';

                    return GestureDetector(
                      onTap: () {
                        if (status != 'Cancelled') {
                          _showConfirmationDialog(
                              context, appointment.id, status);
                        }
                      },
                      child: Container(
                        width: containerWidth,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: $formattedDate'),
                            Text('Email: $email'),
                            Text('Time: $time'),
                            Row(
                              children: [
                                Text('Status: '),
                                Text(
                                  '$status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String docId, String status) async {
    bool? isConfirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Appointment'),
          content: Text(
              'Do you want to confirm, reject, or delete the appointment?'),
          actions: [
            TextButton(
              onPressed: () {
                _updateAppointmentStatus(docId, 'Confirmed', null);
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment Confirmed')));
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _showRejectReasonDialog(context, docId, status);
              },
              child: Text('Reject'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _showDoneConfirmation(context, docId, status);
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );

    if (isConfirmed != null && !isConfirmed) {
      // Do nothing, as the reject reason dialog or delete confirmation dialog
      // will handle the corresponding action.
    }
  }

  Future<void> _showDoneConfirmation(
      BuildContext context, String docId, String status) async {
    bool showDoneButton = status != 'Rejected';

    if (status == 'Confirmed') {
      bool? isConfirmed = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Done Appointment'),
            content:
                Text('If the appointment was successful, please click on done'),
            actions: [
              if (showDoneButton)
                TextButton(
                  onPressed: () {
                    _markAppointmentAsDone(docId);
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Appointment Done')));
                  },
                  child: Text('Done'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (isConfirmed != null && isConfirmed && showDoneButton) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment status successfully updated')));
      }
    }
  }

  Future<void> _markAppointmentAsDone(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({
        'status': 'Done',
      });

      print('Appointment marked as done successfully');
    } catch (error) {
      print('Error marking appointment as done: $error');
    }
  }

  Future<void> _showRejectReasonDialog(
      BuildContext context, String docId, String status) async {
    String? selectedReason = await showDialog(
      context: context,
      builder: (context) {
        // String reason1 = 'Scheduling Conflict';
        // String reason2 = 'Unavailable Services';
        // String reason3 = 'Fully Booked';

        return AlertDialog(
          title: Text('Reject Appointment'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select a reason for rejection:'),
                  StyledDropdown(
                    value: _selectedReason,
                    onChange: (newValue) {
                      setState(() {
                        _selectedReason = newValue;
                      });
                    },
                    hintText: 'Select a reason',
                    items: const [
                      'Scheduling Conflict',
                      'Unavailable Services',
                      'Fully Booked',
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateAppointmentStatus(docId, 'Rejected', _selectedReason);
                Navigator.of(context).pop(_selectedReason);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment Rejected')));
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Back'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAppointmentStatus(
      String docId, String newStatus, String? reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({
        'status': newStatus,
        'rejectionReason': reason, // Add the rejection reason if provided
      });

      print('Appointment status updated successfully');
    } catch (error) {
      print('Error updating appointment status: $error');
    }
  }
}
