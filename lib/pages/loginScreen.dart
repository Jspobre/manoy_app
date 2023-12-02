import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manoy_app/pages/forgotPasswordForm.dart';
import 'package:manoy_app/pages/admin/admin_page.dart';
import 'package:manoy_app/pages/home/home.dart';
import 'package:manoy_app/pages/signup.dart';
import 'package:manoy_app/provider/isLoading/isLoading_provider.dart';
import 'package:manoy_app/provider/userDetails/address_provider.dart';
import 'package:manoy_app/provider/userDetails/birthday_provider.dart';
import 'package:manoy_app/provider/userDetails/email_provider.dart';
import 'package:manoy_app/provider/userDetails/fullname_provider.dart';
import 'package:manoy_app/provider/userDetails/gender_provider.dart';
import 'package:manoy_app/provider/userDetails/phoneNum_provider.dart';
import 'package:manoy_app/provider/userDetails/uid_provider.dart';
import 'package:manoy_app/widgets/styledButton.dart';
import 'package:manoy_app/widgets/styledTextfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';
import 'package:manoy_app/provider/suffixIcon/passwordToggle_provider.dart';

import '../provider/serviceProviderDetails/serviceProviderDetails_provider.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  final emailController =
      TextEditingController(); //* to access the input value for auth, usernameController.text
  final passwordController =
      TextEditingController(); //* passwordController.text

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);

    Future<void> storeUserDetailsInProvider(
      String fullname,
      int phoneNum,
      String address,
      String gender,
      Timestamp birthday,
      String uid,
      WidgetRef ref,
      String email,
    ) async {
      // Store user details in providers
      ref.read(fullnameProvider.notifier).state = fullname;
      ref.read(phoneNumProvider.notifier).state = phoneNum;
      ref.read(addressProvider.notifier).state = address;
      ref.read(genderProvider.notifier).state = gender;
      ref.read(birthdayProvider.notifier).state = birthday;
      ref.read(uidProvider.notifier).state = uid;
      ref.read(emailProvider.notifier).state = email;
    }

    Future<void> storeServiceProviderInProvider(
      String serviceName,
      String serviceAddress,
      String description,
      String businessHours,
      List<String> category,
      String profilePhoto,
      String coverPhoto,
    ) async {
      try {
        if (serviceName.isNotEmpty &&
            serviceAddress.isNotEmpty &&
            description.isNotEmpty &&
            businessHours.isNotEmpty &&
            category.isNotEmpty &&
            profilePhoto.isNotEmpty &&
            coverPhoto.isNotEmpty) {
          ref.read(serviceNameProvider.notifier).state = serviceName;
          ref.read(serviceAddressProvider.notifier).state = serviceAddress;
          ref.read(descriptionProvider.notifier).state = description;
          ref.read(businessHoursProvider.notifier).state = businessHours;
          ref.read(categoryProvider.notifier).state = category;
          ref.read(profilePhotoProvider.notifier).state = profilePhoto;
          ref.read(coverPhotoProvider.notifier).state = coverPhoto;
        }
      } catch (e) {
        print(e);
        print("Line 84");
      }
    }

    Future<bool> checkAdminAccess(String email, String uid) async {
      // Simulate an asynchronous check (you can replace this with actual logic)
      await Future.delayed(Duration(seconds: 2));

      // Check if the email and UID match the criteria for admin access
      return email == "admin@manoy.com" &&
          uid == "jyuds0USSQdUbu61aO6CKPONsBM2";
    }

    Future<void> handleSignIn(BuildContext context, WidgetRef ref) async {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(
            msg: "Please enter both email and password",
            gravity: ToastGravity.CENTER);
        return;
      }

      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final User? user = userCredential.user;
        if (user == null) {
          Fluttertoast.showToast(msg: "Incorrect email or password");
        } else {
          final uid = user.uid;
          final email = user.email;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('uid', uid);
          prefs.setString('email', email!);

          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          print(userSnapshot);
          print("line 128");

          String fullname =
              userSnapshot['First Name'] + " " + userSnapshot['Last Name'];
          int phoneNum = userSnapshot['Phone Number'];
          String address = userSnapshot['Address'];
          String gender = userSnapshot['Gender'];
          Timestamp birthday = userSnapshot['Birthday'];

          print(fullname);
          print("line 138");

          prefs.setString('fullname', fullname);
          prefs.setInt('phoneNum', phoneNum);
          prefs.setString('address', address);

          storeUserDetailsInProvider(
            fullname,
            phoneNum,
            address,
            gender,
            birthday,
            uid,
            ref,
            email,
          );

          DocumentSnapshot serviceSnapshot = await FirebaseFirestore.instance
              .collection('service_provider')
              .doc(uid)
              .get();

          if (serviceSnapshot.exists) {
            // ! CHECK FIRST IF SERVICE PROVIDER IS APPROVED
            String serviceStatus = serviceSnapshot['Status'];

            if (serviceStatus == 'Approved') {
              String serviceName = serviceSnapshot['Service Name'];
              String serviceAddress = serviceSnapshot['Service Address'];
              String description = serviceSnapshot['Description'];
              String businessHours = serviceSnapshot['Business Hours'];
              List<dynamic> category = serviceSnapshot['Category'];
              List<String> stringList =
                  category.map((item) => item.toString()).toList();
              String profilePhoto = serviceSnapshot['Profile Photo'];
              String coverPhoto = serviceSnapshot['Cover Photo'];

              prefs.setString('serviceName', serviceName);
              prefs.setString('serviceAddress', serviceAddress);
              prefs.setString('description', description);
              prefs.setString('businessHours', businessHours);
              prefs.setStringList('category', stringList);
              prefs.setString('profilePhoto', profilePhoto);
              prefs.setString('coverPhoto', coverPhoto);

              storeServiceProviderInProvider(
                  serviceName,
                  serviceAddress,
                  description,
                  businessHours,
                  stringList,
                  profilePhoto,
                  coverPhoto);
            }
          }

          try {
            await Future.delayed(
                Duration(milliseconds: 100)); // Add a slight delay
            if (context.mounted) {
              // Perform navigation here
              // SchedulerBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    if (email == "admin@manoy.com" &&
                        uid == "jyuds0USSQdUbu61aO6CKPONsBM2") {
                      // Navigate to the admin panel page
                      return AdminPage();
                    } else {
                      return HomePage();
                    }
                  },
                ),
              );
              // });
            }
          } catch (e) {
            print(e);
            print("line 204");
          }
        }
      } catch (e) {
        print(e);
        print("Line 209");
        Fluttertoast.showToast(msg: "Incorrect email or password");
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Image.asset(
                        "lib/images/logo.png",
                        scale: 2,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Welcome to Manoy!".toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    StyledTextField(
                        controller: emailController,
                        hintText: "Enter your email",
                        obscureText: false),
                    const SizedBox(
                      height: 10,
                    ),
                    StyledTextField(
                        controller: passwordController,
                        hintText: "Enter your Password",
                        obscureText: true),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 250,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (BuildContext context) {
                              return ForgotPassPage();
                            }),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(letterSpacing: 1),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    StyledButton(
                      btnText: "SIGN IN",
                      onClick: () async {
                        try {
                          ref.read(isLoadingProvider.notifier).state = true;
                          await handleSignIn(context, ref);
                        } finally {
                          ref.read(isLoadingProvider.notifier).state = false;
                        }
                      },
                      btnWidth: 250,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(letterSpacing: 1),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        GestureDetector(
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                                letterSpacing: 1, fontWeight: FontWeight.w700),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (BuildContext) {
                                return SignupPage();
                              }),
                            );
                          },
                        ),
                      ],
                    )
                  ]),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00A2FF),
              ),
            )
        ],
      ),
    );
  }
}
