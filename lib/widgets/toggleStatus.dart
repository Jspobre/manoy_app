import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ToggleStatusWidget extends StatefulWidget {
  @override
  _ToggleStatusWidgetState createState() => _ToggleStatusWidgetState();
}

class _ToggleStatusWidgetState extends State<ToggleStatusWidget> {
  bool isOpen = false; // Initial status

  void toggleStatus(bool value) {
    setState(() {
      isOpen = value;
    });

    // Call the function to update the status in Firestore
    updateFirestoreStatus(isOpen);

    // Show a Snackbar based on the toggle status
    final snackBarMessage = isOpen ? 'Shop is now Open' : 'Shop is now Closed';
    showStatusSnackBar(snackBarMessage);
  }

  Future<void> updateFirestoreStatus(bool isOpen) async {
    try {
      // Replace 'yourUserId' with the actual user ID
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Reference to the user document in Firestore
      final userRef =
          FirebaseFirestore.instance.collection('shop_status').doc(userId);

      // Update the 'status' field with the new status
      await userRef.set({'status': isOpen ? 'Open' : 'Closed'});
    } catch (error) {
      print('Error updating Firestore: $error');
    }
  }

  void showStatusSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isOpen ? 'OPEN' : 'CLOSED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOpen ? Colors.green : Colors.red,
            fontSize: 25,
          ),
        ),
        Switch(
          value: isOpen,
          onChanged: toggleStatus,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
      ],
    );
  }
}
