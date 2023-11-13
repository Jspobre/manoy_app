import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manoy_app/pages/home/home.dart';
import 'package:manoy_app/pages/profile/appointments_lists.dart';
import 'package:manoy_app/pages/profile/edit_profile.dart';
import 'package:manoy_app/pages/profile/profileView_messageInbox.dart';
import 'package:manoy_app/provider/isLoading/isLoading_provider.dart';
import 'package:manoy_app/provider/selectedCategory/selectedCategory_provider.dart';
import 'package:manoy_app/provider/serviceProviderDetails/deletingSeriviceProvider_provider.dart';
import 'package:manoy_app/provider/serviceProviderDetails/serviceProviderDetails_provider.dart';
import 'package:manoy_app/provider/timepicker/selectedTime_provider.dart';
import 'package:manoy_app/provider/uploadIage/selectedImage_provider.dart';
import 'package:manoy_app/provider/userDetails/uid_provider.dart';
import 'package:manoy_app/widgets/bottomNav.dart';
import 'package:manoy_app/widgets/styledButton.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manoy_app/widgets/styledTextfield.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manoy_app/pages/profile/createPost.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manoy_app/provider/rating/averageRating_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:manoy_app/pages/profile/viewReview.dart';
import 'package:manoy_app/widgets/toggleStatus.dart';

class ProfileView extends ConsumerWidget {
  final bool? fromShopCard;

  const ProfileView({super.key, this.fromShopCard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final uid = auth.currentUser!.uid;
    final isLoading = ref.watch(isLoadingProvider);
    final serviceName = ref.watch(serviceNameProvider);
    final serviceAddress = ref.watch(serviceAddressProvider);
    final description = ref.watch(descriptionProvider);
    final businessHours = ref.watch(businessHoursProvider);
    final category = ref.watch(categoryProvider);
    final profilePhoto = ref.watch(profilePhotoProvider);
    final coverPhoto = ref.watch(coverPhotoProvider);
    bool isPasswordVisible = false;
    final name =
        serviceName ?? ''; // Default to an empty string if serviceName is null
    late bool servicePermission = false;
    late LocationPermission permission;

    String? lat;
    String? long;

    Future<Map<String, double>> getUserLocation(String userId) async {
      final userLocationRef =
          FirebaseFirestore.instance.collection('user_locations');
      final userLocationSnapshot = await userLocationRef.doc(userId).get();

      if (userLocationSnapshot.exists) {
        final userLocationData =
            userLocationSnapshot.data() as Map<String, dynamic>;
        final double latitude = userLocationData['latitude'];
        final double longitude = userLocationData['longitude'];
        return {'latitude': latitude, 'longitude': longitude};
      } else {
        return {
          'latitude': 0.0,
          'longitude': 0.0
        }; // Default location or handle accordingly
      }
    }

    Future<Position> getCurrentLocation() async {
      servicePermission = await Geolocator.isLocationServiceEnabled();
      if (!servicePermission) {
        print('service disabled');
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition();
    }

    void liveLocation() {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {});
    }

    Future<void> openMap(String lat, String long) async {
      String googleUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$long';
      await canLaunchUrlString(googleUrl)
          ? await launchUrlString(googleUrl)
          : throw 'could not launch $googleUrl';
    }

    Future<void> setUserLocationInFirestore(
        String userId, double lat, double long) async {
      final userLocationRef =
          FirebaseFirestore.instance.collection('service_locations');
      await userLocationRef.doc(userId).set({
        'latitude': lat,
        'longitude': long,
      });
    }

    // Fetch average ratings from the provider
    final averageRatingsInfo = ref.watch(averageRatingsProvider);
    final averageRatings = averageRatingsInfo.when(
      data: (ratings) {
        return ratings[uid!] ?? {'averageRating': 0.0, 'totalRatings': 0};
      },
      loading: () => {'averageRating': 0.0, 'totalRatings': 0},
      error: (error, stackTrace) => {'averageRating': 0.0, 'totalRatings': 0},
    );

    final averageRating = averageRatings['averageRating'] as double;
    final totalRatings = averageRatings['totalRatings'] as int;

    Future<void> deleteServiceProvider(BuildContext context) async {
      try {
        // Get the current user
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Get the Firestore document reference using the user's UID as the document ID
          DocumentReference serviceProviderDoc = FirebaseFirestore.instance
              .collection('service_provider')
              .doc(user.uid);

          // Delete the document
          await serviceProviderDoc.delete();

          print('Document deleted successfully');
        } else {
          print('User not logged in');
        }
      } catch (e) {
        print('Error deleting document: $e');
      }
      ref.read(isLoadingProvider.notifier).state = false;
    }

    Future<void> termsModal(BuildContext context) async {
      bool isChecked = false;
      final User? user = FirebaseAuth.instance.currentUser;
      final TextEditingController passwordController = TextEditingController();

      if (user == null) {
        // User is not logged in
        return;
      }

      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Would you like to remove $serviceName? ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    Text(
                        "Deleting $serviceName means your shop won't be available to users anymore, and all your shop data will be gone for good. This decision can't be undone so think wisely. However, it's also a chance to start something new in your business journey. As you step into this fresh chapter, remember that every ending is a chance for a new beginning. Embrace the future with confidence, and your next adventure could be your best one yet."),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  isChecked = value!;
                                });
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I have read and understood",
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  " the Terms & Conditions",
                                  style: TextStyle(fontSize: 14),
                                )
                              ],
                            ),
                          ],
                        ),
                        if (isChecked)
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                'Verify Identity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              StyledTextField(
                                controller: passwordController,
                                hintText: 'Enter your password',
                                obscureText: true,
                              )
                            ],
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StyledButton(
                              btnText: "CONFIRM",
                              onClick: isChecked
                                  ? () async {
                                      if (isChecked) {
                                        try {
                                          // Show loading indicator

                                          // Perform reauthentication before deletion
                                          final AuthCredential credential =
                                              EmailAuthProvider.credential(
                                            email: user.email!,
                                            password: passwordController.text,
                                          );
                                          await user
                                              .reauthenticateWithCredential(
                                                  credential);

                                          // User reauthenticated successfully,
                                          // Perform the delete account function here
                                          // Call your delete account function
                                          await deleteServiceProvider(context);

                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (context) => HomePage(),
                                            ),
                                            (Route<dynamic> route) => false,
                                          );

                                          // Clear the form values
                                          ref
                                              .read(
                                                  serviceNameProvider.notifier)
                                              .state = null;
                                          ref
                                              .read(serviceAddressProvider
                                                  .notifier)
                                              .state = null;
                                          ref
                                              .read(
                                                  descriptionProvider.notifier)
                                              .state = null;
                                          ref
                                              .read(businessHoursProvider
                                                  .notifier)
                                              .state = null;
                                          ref
                                              .read(categoryProvider.notifier)
                                              .state = [];
                                          ref
                                              .read(
                                                  profilePhotoProvider.notifier)
                                              .state = null;
                                          ref
                                              .read(coverPhotoProvider.notifier)
                                              .state = null;

                                          // Close the dialog
                                        } catch (error) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                'Password incorrect, please try again'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ));
                                          print(
                                              'Reauthentication error: $error');
                                          // Handle reauthentication error here
                                        }
                                      }
                                    }
                                  : null,
                            ),
                            if (isLoading)
                              Center(
                                child: CircularProgressIndicator(),
                              ),
                            StyledButton(
                                btnText: "CANCEL",
                                onClick: () {
                                  Navigator.pop(context);
                                })
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shop/Service"),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: CachedNetworkImageProvider(profilePhoto ??
                        "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.stickpng.com%2Fimg%2Ficons-logos-emojis%2Fusers%2Fsimple-user-icon&psig=AOvVaw0RX_ZkmXovuLhGMin_rCbW&ust=1695041921601000&source=images&cd=vfe&opi=89978449&ved=0CBAQjRxqFwoTCIim4q3ZsYEDFQAAAAAdAAAAABAE"),
                  ),
                  SizedBox(height: 10),
                  Text(
                    serviceName!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Profile"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => EditProfileForm(
                    uid: uid,
                    name: serviceName,
                  ),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text("Messages"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) {
                    return MessageInbox();
                  }),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text("Map"),
              onTap: () {
                if (lat != null && long != null) {
                  openMap(lat!, long!);
                } else {
                  print('error');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Location"),
              onTap: () async {
                final uid = ref.read(uidProvider);
                if (uid != null) {
                  getCurrentLocation().then((value) async {
                    lat = '${value.latitude}';
                    long = '${value.longitude}';
                    print('$lat, $long');
                    await setUserLocationInFirestore(
                      uid,
                      double.parse(lat!),
                      double.parse(long!),
                    );
                  });
                  liveLocation();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.post_add),
              title: Text("Create Post"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CreatePostPage(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Appointments"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AppointmentsListsPage(),
                ));
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.remove_circle_rounded),
            //   title: Text("Remove Shop"),
            //   onTap: () {
            //     termsModal(context);
            //     // Navigator.of(context).push(MaterialPageRoute(
            //     //   builder: (context) => AppointmentsListsPage(),
            //     // ));
            //   },
            // ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: coverPhoto!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ), // PROFILE PHOTO
                    Positioned(
                      bottom: -50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white, // Border color
                            width: 4, // Border width
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CachedNetworkImage(
                              imageUrl: profilePhoto ??
                                  "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.stickpng.com%2Fimg%2Ficons-logos-emojis%2Fusers%2Fsimple-user-icon&psig=AOvVaw0RX_ZkmXovuLhGMin_rCbW&ust=1695041921601000&source=images&cd=vfe&opi=89978449&ved=0CBAQjRxqFwoTCIim4q3ZsYEDFQAAAAAdAAAAABAE",
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 60,
                ),

                SizedBox(
                  width: 300,
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // Display average rating and total ratings
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${averageRating.toStringAsFixed(1)}/5",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade700,
                      size: 20,
                    ),
                    Text(" ($totalRatings)"),
                    const SizedBox(
                      width: 5,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => ViewReviewPage(
                              uid: uid,
                              name: name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(serviceAddress!, style: TextStyle(fontSize: 15)),
                const SizedBox(
                  height: 10,
                ),
                Text('Business Hours: $businessHours',
                    style: TextStyle(fontSize: 15)),
                const SizedBox(
                  height: 10,
                ),
                Text("Category: $category", style: TextStyle(fontSize: 15)),

                const SizedBox(
                  height: 5,
                ),
                const Divider(
                  height: 0,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(description!, style: TextStyle(fontSize: 15)),
                const SizedBox(
                  height: 5,
                ),
                const Divider(
                  height: 0,
                ),

                const SizedBox(
                  height: 25,
                ),
                ToggleStatusWidget(),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: fromShopCard == true ? null : const BottomNav(),
    );
  }
}
