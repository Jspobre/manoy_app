import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manoy_app/pages/loginScreen.dart';
import 'package:manoy_app/pages/settings/applyProvider.dart';
import 'package:manoy_app/provider/bottomNav/currentIndex_provider.dart';
import 'package:manoy_app/provider/serviceProviderDetails/serviceProviderDetails_provider.dart';
import 'package:manoy_app/provider/userDetails/uid_provider.dart';
import 'package:manoy_app/widgets/bottomNav.dart';
import 'package:manoy_app/widgets/styled_settings_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/userDetails/address_provider.dart';
import '../../provider/userDetails/birthday_provider.dart';
import '../../provider/userDetails/fullname_provider.dart';
import '../../provider/userDetails/gender_provider.dart';
import '../../provider/userDetails/phoneNum_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = ref.watch(fullnameProvider);
    final uid = ref.watch(uidProvider);
    final serviceName = ref.watch(serviceNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'lib/images/settings_logo.png',
              width: 70,
              height: 70,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.account_circle_rounded,
                        size: 80,
                      )
                      // CircleAvatar(
                      //   radius: 60,
                      //   backgroundImage: AssetImage(
                      //     'lib/images/avatar.png',
                      //   ),
                      // ),
                      ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 40),
                    child: Text(
                      fullName ?? "User",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            StyledSettingsButton(
              buttonText: 'Apply Service Provider Account',
              onPressed: serviceName == null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                          return ApplyProvider(uid: uid!);
                        }),
                      );
                    }
                  : null,
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Contact Information',
              onPressed: () {
                // TODO NAVIGATE TO CHANGE CONTACT INFO FORM
                // TODO 1 textfield for phone number & 1 button
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Change Profile Picture',
              onPressed: () {
                // TODO NAVIGATE TO CHANGE PROFILE PHOTO FORM
                // TODO import uploadImage_input.dart and button
                // TODO PASS BELOW AS PARAMETER FOR TEXT & ONPRESSED
                // ? import Imagepicker package
                /* 
                String? selectedImagePath;

                Future<void> _pickImage() async {
                final ImagePicker _picker = ImagePicker();
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

                if (image != null) {
                  setState(() {
                    selectedImagePath1 = image.path; // Store the selected image path
                  });
                }
              }

                */
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Change Password',
              onPressed: () {
                // TODO NAVIGATE TO CHANGE PASSWORD FORM
                // TODO 1 styledtextfield for email & 1 button
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Contact Us',
              onPressed: () {
                // TODO NAVIGATE TO CONTACT US
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Terms and Condition',
              onPressed: () {
                // TODO NAVIGATE TO TERMS AND CONDITION PAGE
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Help',
              onPressed: () {
                // TODO NAVIGATE TO HELP PAGE
              },
            ),
            SizedBox(
              height: 5,
            ),
            StyledSettingsButton(
              buttonText: 'Log out',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                // RESET STATES
                ref.read(currentIndexProvider.notifier).state = 0;
                ref.read(fullnameProvider.notifier).state = null;
                ref.read(phoneNumProvider.notifier).state = null;
                ref.read(addressProvider.notifier).state = null;
                ref.read(genderProvider.notifier).state = null;
                ref.read(birthdayProvider.notifier).state = null;
                ref.read(serviceNameProvider.notifier).state = null;
                ref.read(serviceAddressProvider.notifier).state = null;
                ref.read(descriptionProvider.notifier).state = null;
                ref.read(businessHoursProvider.notifier).state = null;
                ref.read(categoryProvider.notifier).state = null;
                ref.read(profilePhotoProvider.notifier).state = null;
                ref.read(coverPhotoProvider.notifier).state = null;

                // store role in sharedPreferences
                // SharedPreferences prefs = await SharedPreferences.getInstance();
                // prefs.setBool('isLogged', false);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
