import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manoy_app/pages/home/home.dart';
import 'package:manoy_app/pages/main_page.dart';
import 'package:manoy_app/widgets/styledButton.dart';
import 'package:manoy_app/widgets/styledDropdown.dart';
import 'package:manoy_app/widgets/styledTextfield.dart';
import 'package:manoy_app/widgets/timePicker.dart';
import 'package:manoy_app/widgets/uploadImage_input.dart';
import 'package:uuid/uuid.dart';

class ApplyProvider extends StatefulWidget {
  final String uid;
  ApplyProvider({super.key, required this.uid});

  @override
  State<ApplyProvider> createState() => _ApplyProviderState();
}

class _ApplyProviderState extends State<ApplyProvider> {
  final providerNameController = TextEditingController();

  final providerAddressController = TextEditingController();

  final providerDescriptionController = TextEditingController();

  TimeOfDay? selectedTime1;
  TimeOfDay? selectedTime2;

  String? category;

  String? selectedImagePath1;
  String? selectedImagePath2;

  void _showTimePicker1() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((value) {
      setState(() {
        selectedTime1 = value;
      });
    });
  }

  void _showTimePicker2() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((value) {
      setState(() {
        selectedTime2 = value;
      });
    });
  }

  Future<void> _pickImage1() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImagePath1 = image.path; // Store the selected image path
      });
    }
  }

  Future<void> _pickImage2() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImagePath2 = image.path; // Store the selected image path
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? time1 = selectedTime1?.format(context).toString();
    String? time2 = selectedTime2?.format(context).toString();

    Future addProvider() async {
      try {
        final serviceName = providerNameController.text;
        final serviceAddress = providerAddressController.text;
        final description = providerDescriptionController.text;
        final businessHours = '$time1 - $time2';
        final categoryName = category;

        if (serviceName.isEmpty ||
            serviceAddress.isEmpty ||
            description.isEmpty ||
            time1 == null ||
            time2 == null ||
            categoryName == null ||
            selectedImagePath1 == null ||
            selectedImagePath2 == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please fill up all the details above!"),
            ),
          );

          return;
        }

        final file1 = File(selectedImagePath1!);
        final file2 = File(selectedImagePath2!);

        // Generate a unique image name using UUID
        final imageName1 = Uuid().v4(); // Generates a random UUID
        final imageName2 = Uuid().v4(); // Generates a random UUID

        final storageRef1 = FirebaseStorage.instance
            .ref()
            .child('provider_profile')
            .child('$imageName1.jpg'); // Use the unique image name
        final storageRef2 = FirebaseStorage.instance
            .ref()
            .child('provider_profile')
            .child('$imageName2.jpg'); // Use the unique image name

        // final metadata = SettableMetadata(
        //   contentType: 'image/jpeg', // Set the content type to image/jpeg
        //   cacheControl: 'max-age=0', // Disable caching for the updated image
        // );

        final uploadTask1 = storageRef1.putFile(file1);
        final uploadTask2 = storageRef2.putFile(file2);

        // Wait for the upload to complete and get the download URL
        final TaskSnapshot snapshot1 = await uploadTask1;
        final imageUrl1 = await snapshot1.ref.getDownloadURL();
        final TaskSnapshot snapshot2 = await uploadTask2;
        final imageUrl2 = await snapshot2.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('service_provider')
            .doc(widget.uid)
            .set({
          'Service Name': serviceName,
          'Service Address': serviceAddress,
          'Description': description,
          'Business Hours': businessHours,
          'Category': categoryName,
          'Profile Photo': imageUrl1,
          'Cover Photo': imageUrl2,
        }).then((value) {
          SnackBar(
            content: Text("Created Successfully!"),
          );
        }).catchError((error) {
          print(error);
        });
      } catch (e) {
        print(e);
      }
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const Text(
                "APPLY AS",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),
              const Text(
                "SERVICE PROVIDER",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                  width: 250,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Shop/Service Name:"))),
              StyledTextField(
                  controller: providerNameController,
                  hintText: "Enter Name",
                  obscureText: false),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                  width: 250,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Shop/Service Address:"))),
              StyledTextField(
                  controller: providerAddressController,
                  hintText: "Enter Address",
                  obscureText: false),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                  width: 250,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Description:"))),
              StyledTextField(
                  controller: providerDescriptionController,
                  hintText: "Enter Description",
                  obscureText: false),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 250,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Business Hours:")),
              ),
              SizedBox(
                width: 250,
                child: Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: TimePicker(
                          onTap: _showTimePicker1,
                          selectedTime: time1,
                        )),
                    SizedBox(
                      width: 5,
                    ),
                    Text("TO"),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                        flex: 1,
                        child: TimePicker(
                          onTap: _showTimePicker2,
                          selectedTime: time2,
                        )),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 250,
                child: Align(
                    alignment: Alignment.centerLeft, child: Text("Category:")),
              ),
              StyledDropdown(
                  value: category,
                  onChange: (newValue) {
                    setState(() {
                      category = newValue;
                    });
                  },
                  hintText: "Select Category",
                  items: const [
                    "Maintenance and Repairs",
                    "Parts and accessories",
                    "Car Wash and Detailing",
                    "Fuel and charging station",
                    "Inspection and emissions",
                  ]),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 250,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Shop/Service Profile Photo:")),
              ),
              UploadImage(
                onPressed: _pickImage1,
                text: selectedImagePath1,
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 250,
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Shop/Service Cover Photo:")),
              ),
              UploadImage(
                onPressed: _pickImage2,
                text: selectedImagePath2,
              ),
              const SizedBox(
                height: 20,
              ),
              StyledButton(
                  btnText: "CONFIRM",
                  onClick: () {
                    addProvider();
                    // print("executed");
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => MainPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  })
            ],
          ),
        ),
      )),
    );
  }
}
