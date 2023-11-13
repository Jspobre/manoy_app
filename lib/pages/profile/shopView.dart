import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manoy_app/pages/profile/shopView_message.dart';
import 'package:manoy_app/pages/profile/viewReview.dart';
import 'package:manoy_app/provider/bookmark/bookmarkData_provider.dart';
import 'package:manoy_app/provider/bookmark/isBookmark_provider.dart';
import 'package:manoy_app/provider/isLoading/isLoading_provider.dart';
import 'package:manoy_app/provider/ratedShops/ratedShops_provider.dart';
import 'package:manoy_app/widgets/styledButton.dart';
import 'package:manoy_app/widgets/styledTextfield.dart';
import '../../provider/rating/averageRating_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:manoy_app/pages/profile/appointment_page.dart';
import 'package:manoy_app/provider/rating/averageRating_provider.dart'
    as avgRatingProvider;

class ShopView extends ConsumerWidget {
  final String? uid;
  final String name;
  final String address;
  final String businessHours;
  final List<String> category;
  final String description;
  final String profilePhoto;
  final String coverPhoto;
  final String? userId;
  final bool showButtons;

  // bool? isBookmarked;
  const ShopView({
    super.key,
    this.userId,
    this.uid,
    required this.name,
    required this.address,
    required this.businessHours,
    required this.category,
    required this.description,
    required this.profilePhoto,
    required this.coverPhoto,
    required this.showButtons,

    // this.isBookmarked
  });

  Future<void> openMap(String lat, String long) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$long';
    await canLaunchUrlString(googleUrl)
        ? await launchUrlString(googleUrl)
        : throw 'could not launch $googleUrl';
  }

  // Check if a shop has been rated by the user
  Future<bool> hasRatedShop(String shopId) async {
    final shopRated = await FirebaseFirestore.instance
        .collection('shop_ratings')
        .where('user_id', isEqualTo: userId)
        .get();
    final List<String> ratedShopIds =
        shopRated.docs.map<String>((doc) => doc['shop_id'] as String).toList();

    return ratedShopIds.contains(shopId);
  }

  Future<void> rateModal(BuildContext context, WidgetRef ref) async {
    double userRating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Rate & Review"),
              ),
              const Divider(
                height: 0,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RatingBar(
                  // unratedColor: Colors.yellow,
                  ratingWidget: RatingWidget(
                    full: Icon(
                      Icons.star,
                      color: Colors.yellow.shade700,
                    ),
                    half: Icon(
                      Icons.star_half,
                      color: Colors.yellow.shade700,
                    ),
                    empty: Icon(
                      Icons.star_border,
                      color: Colors.yellow.shade700,
                    ),
                  ),
                  onRatingUpdate: (double rating) {
                    userRating = rating;
                  },
                  minRating: 1,
                  maxRating: 5,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              StyledTextField(
                controller: reviewController,
                hintText: "Write a Review",
                obscureText: false,
              ),
              const SizedBox(
                height: 10,
              ),
              StyledButton(
                btnText: "SUBMIT",
                onClick: () async {
                  final currentRating = userRating;
                  final review = reviewController.text;
                  if (userRating > 0 && review.isNotEmpty) {
                    try {
                      final shopId = uid!;
                      final id = userId;

                      await FirebaseFirestore.instance
                          .collection('shop_ratings')
                          .add({
                        'user_id': id,
                        'shop_id': shopId,
                        'rating': currentRating,
                        'review': review,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      ref.read(isRatedProvider.notifier).state = true;
                      ref.refresh(averageRatingsProvider);
                      // ref.read(averageRatingsProvider.notifier).refresh();
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Error submitting rating and review: $e');
                    }
                  }
                },
              ),
              const SizedBox(
                height: 15,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> fetchUserLocation(String userId) async {
    final userLocationRef =
        FirebaseFirestore.instance.collection('service_locations');
    final userLocationSnapshot = await userLocationRef.doc(userId).get();

    if (userLocationSnapshot.exists) {
      return userLocationSnapshot.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final serviceLocationsStream = ref.watch(serviceLocationsProvider);
    final bookmarkData = ref.watch(bookmarkDataProvider);
    final List bookmarks = bookmarkData.when(
      data: (data) {
        final shopsArray = data['shops'] ?? [];
        return shopsArray;
      }, // Extract the value from AsyncValue.data
      error: (error, stackTrace) {
        // Handle error state, e.g., show an error message
        return [];
      }, // Handle error state
      loading: () {
        // Handle loading state, e.g., show a loading indicator
        return [];
      }, // Handle loading state
    );

    handleBookmark() async {
      // await fetchBookmarks();

      final shopData = {
        'uid': uid,
        'Service Name': name,
        'Service Address': address,
        'Business Hours': businessHours,
        'Category': category,
        'Description': description,
        'Profile Photo': profilePhoto,
        'Cover Photo': coverPhoto,
      };

      if (bookmarks.isEmpty) {
        bookmarks.add(shopData);

        await FirebaseFirestore.instance
            .collection('bookmarks')
            .doc(userId)
            .set({'shops': bookmarks});
      } else {
        // REMOVE THE SHOP FROM THE BOOKMARK
        int index = bookmarks.indexWhere((bookmark) {
          return bookmark['Service Name'] == name;
        });

        if (index != -1) {
          bookmarks.removeAt(index);
          await FirebaseFirestore.instance
              .collection('bookmarks')
              .doc(userId)
              .set({'shops': bookmarks});
        } else {
          bookmarks.add(shopData);
          await FirebaseFirestore.instance
              .collection('bookmarks')
              .doc(userId)
              .set({'shops': bookmarks});
        }
      }
    }

    Future<String?> getUserEmail() async {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user != null) {
        return user.email;
      } else {
        return null; // User is not authenticated or user data not available
      }
    }

    final isBookmark = ref.watch(isBookmarkProvider);
    final isRated = ref.watch(isRatedProvider);

    final averageRatingsInfo = ref.watch(averageRatingsProvider);

    final Map<String, Map<String, dynamic>>? ratingsInfo =
        averageRatingsInfo.when(
      data: (data) => data,
      loading: () => null,
      error: (error, stackTrace) => null,
    );

    if (ratingsInfo != null && ratingsInfo.containsKey(uid)) {
      final averageRating = ratingsInfo[uid]!['averageRating'] as double;
      final totalRatings = ratingsInfo[uid]!['totalRatings'] as int;
      // Use averageRating and totalRatings in your UI
    }

    Future<void> approveServiceProvider(uid) async {
      final CollectionReference serviceProvidersCollection =
          FirebaseFirestore.instance.collection('service_provider');

      try {
        await serviceProvidersCollection.doc(uid).update({
          'Status': 'Approved',
        });

        print('Service provider status updated to "Approved"');
      } catch (e) {
        print('Error updating service provider status: $e');
      }
    }

    Future<void> rejectServiceProvider(uid) async {
      final CollectionReference serviceProvidersCollection =
          FirebaseFirestore.instance.collection('service_provider');

      try {
        await serviceProvidersCollection.doc(uid).update({
          'Status': 'Rejected',
        });

        print('Service provider status updated to "Rejected"');
      } catch (e) {
        print('Error updating service provider status: $e');
      }
    }

    Future approveModal() {
      bool isChecked = false;
      return showDialog(
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
                      "Are you sure you want to approve this service provider?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome to Manoy Admin Panel,\n\n"
                      "Our platform is dedicated to connecting reliable automobile service providers with potential customers. As an administrator, your role is crucial in ensuring the quality and integrity of our services. Please review and approve service provider registrations in adherence to our guidelines.\n\n"
                      "Here are some key responsibilities:\n\n"
                      "1. Registration Accuracy:\n"
                      "   - Verify the accuracy of service provider registrations.\n"
                      "   - Ensure that all required information is provided.\n\n"
                      "2. Service Listings:\n"
                      "   - Confirm that service listings accurately represent the services offered.\n"
                      "   - Verify that service providers' listings meet our quality standards.\n\n"
                      "3. User Interaction:\n"
                      "   - Service providers should be easily reachable by users.\n"
                      "   - Encourage respectful conduct in all interactions between service providers and users.\n\n"
                      "4. Verification:\n"
                      "   - All service providers must undergo a verification process.\n"
                      "   - Ensure that service providers meet our verification criteria.\n\n"
                      "5. Privacy:\n"
                      "   - Respect and protect user data in accordance with our Privacy Policy.\n\n"
                      "6. Intellectual Property:\n"
                      "   - Remind service providers that all content on our platform is our intellectual property.\n"
                      "   - Unauthorized use is strictly prohibited.\n\n"
                      "7. Account Termination:\n"
                      "   - Be prepared to take action, including account termination, for violations of our guidelines.\n\n"
                      "Your role is essential in maintaining the quality and legitimacy of our platform. Please stay informed about updates to our terms and guidelines. Your commitment to these principles ensures a positive experience for all users.\n\n"
                      "Thank you for your dedication to Manoy Admin.",
                    ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StyledButton(
                              btnText: "CONFIRM",
                              onClick: isChecked
                                  ? () async {
                                      ref
                                          .read(isLoadingProvider.notifier)
                                          .state = true;
                                      try {
                                        Navigator.pop(context);
                                        await approveServiceProvider(uid!);
                                      } finally {
                                        ref
                                            .read(isLoadingProvider.notifier)
                                            .state = false;
                                      }
                                    }
                                  : null,
                            ),
                            StyledButton(
                                btnText: "CANCEL",
                                onClick: () {
                                  Navigator.pop(context);
                                }),
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

    Future rejectModal() {
      bool isChecked = false;
      return showDialog(
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
                      "Are you sure you want to reject this service provider?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                        "Please note that the rejection or termination of a service provider's account does not affect user accounts. We take non-compliance seriously to maintain the trust and quality of our platform. Users can continue to enjoy our services without disruption due to actions taken against non-compliant service providers. We encourage all service providers to carefully review and adhere to our guidelines and policies to ensure a positive experience for all users."),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StyledButton(
                              btnText: "CONFIRM",
                              onClick: isChecked
                                  ? () async {
                                      ref
                                          .read(isLoadingProvider.notifier)
                                          .state = true;
                                      try {
                                        Navigator.pop(context);
                                        await rejectServiceProvider(uid!);
                                      } finally {
                                        ref
                                            .read(isLoadingProvider.notifier)
                                            .state = false;
                                      }
                                    }
                                  : null,
                            ),
                            StyledButton(
                                btnText: "CANCEL",
                                onClick: () {
                                  Navigator.pop(context);
                                }),
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

    Future<String?> fetchShopStatus() async {
      try {
        // Replace 'shops' with the actual collection name
        var shopSnapshot = await FirebaseFirestore.instance
            .collection('shop_status')
            .doc(uid)
            .get();

        if (shopSnapshot.exists) {
          String status = shopSnapshot['status'];
          print('Shop Status: $status');
          return status; // Return the status here
        } else {
          print('Shop not found');
          return null; // Return null if the shop is not found
        }
      } catch (error) {
        print('Error fetching shop status: $error');
        return null;
      }
    }

    return FutureBuilder<bool>(
      future: hasRatedShop(uid ?? FirebaseAuth.instance.currentUser!.uid),
      builder: (context, hasRatedShopSnapshot) {
        if (hasRatedShopSnapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (hasRatedShopSnapshot.hasError) {
          return Text('Error: ${hasRatedShopSnapshot.error}');
        } else {
          final hasRatedThisShop = hasRatedShopSnapshot.data ?? false;

          return FutureBuilder<String?>(
            future: fetchShopStatus(),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (statusSnapshot.hasError) {
                return Text('Error: ${statusSnapshot.error}');
              } else {
                final status = statusSnapshot.data;

                return WillPopScope(
                  onWillPop: () async {
                    ref.read(isRatedProvider.notifier).state = false;
                    return true;
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text("Worker Profile"),
                      titleTextStyle:
                          TextStyle(color: Colors.white, fontSize: 20),
                      centerTitle: true,
                      backgroundColor: Colors.blue,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          ref.read(isBookmarkProvider.notifier).state = false;
                          ref.read(isRatedProvider.notifier).state = false;
                          Navigator.of(context).pop();
                        },
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
                                        imageUrl: coverPhoto,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: CachedNetworkImage(
                                            imageUrl: profilePhoto,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () {
                                    handleBookmark();

                                    if (isBookmark == true) {
                                      ref
                                          .read(isBookmarkProvider.notifier)
                                          .state = false;
                                    } else {
                                      ref
                                          .read(isBookmarkProvider.notifier)
                                          .state = true;
                                    }

                                    ref.refresh(bookmarkDataProvider);
                                  },
                                  icon: isBookmark == true
                                      ? const Icon(
                                          Icons.bookmark,
                                          size: 35,
                                        )
                                      : const Icon(
                                          Icons.bookmark_add_outlined,
                                          size: 35,
                                        ),
                                ),
                              ),
                              const SizedBox(
                                height: 0,
                              ),
                              SizedBox(
                                width: 300,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ref.watch(averageRatingsProvider).when(
                                        data: (ratingsInfo) {
                                          if (ratingsInfo.containsKey(uid)) {
                                            final averageRating = ratingsInfo[
                                                    uid]!['averageRating']
                                                as double;
                                            final totalRatings = ratingsInfo[
                                                uid]!['totalRatings'] as int;
                                            return Row(
                                              children: [
                                                Text(
                                                  "${averageRating.toStringAsFixed(1)}/5",
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                Icon(
                                                  Icons.star,
                                                  color: Colors.yellow.shade700,
                                                  size: 16,
                                                ),
                                                Text("($totalRatings)"),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            ViewReviewPage(
                                                          uid: uid,
                                                          name: name,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons
                                                      .remove_red_eye_outlined),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return Text("No ratings available");
                                          }
                                        },
                                        loading: () =>
                                            CircularProgressIndicator(),
                                        error: (error, stackTrace) =>
                                            Text("Error: $error"),
                                      ),
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(address),
                              const SizedBox(
                                height: 5,
                              ),
                              Text("Business Hours: $businessHours"),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Text("Category: "),
                                  for (final cat in category)
                                    Row(
                                      children: [
                                        Text(cat),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                      ],
                                    )
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              const Divider(
                                height: 0,
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(description),
                              const SizedBox(
                                height: 5,
                              ),
                              const Divider(
                                height: 0,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StyledButton(
                                    btnText: hasRatedThisShop || isRated
                                        ? "RATED"
                                        : "RATE",
                                    onClick: hasRatedThisShop || isRated
                                        ? null
                                        : () {
                                            rateModal(context, ref);
                                            // ref.read(isRatedProvider.notifier).state = true;
                                          },
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  StyledButton(
                                    btnText: "MESSAGE",
                                    onClick: () {
                                      if (uid != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (BuildContext context) {
                                            return MessagePage(
                                              name: name,
                                              receiverId: uid!,
                                            );
                                          }),
                                        );
                                      } else {
                                        print('null');
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StyledButton(
                                    btnText: "MAKE APPOINTMENT",
                                    onClick: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) => AppointmentPage(
                                          name: name,
                                          shopId: uid!,
                                        ),
                                      ));
                                    },
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  StyledButton(
                                    btnText: 'LOCATION',
                                    onClick: () async {
                                      final shopLocationDoc =
                                          await FirebaseFirestore.instance
                                              .collection('service_locations')
                                              .doc(uid)
                                              .get();

                                      if (shopLocationDoc.exists) {
                                        final shopLocationData = shopLocationDoc
                                            .data() as Map<String, dynamic>;

                                        final double lat =
                                            shopLocationData['latitude'];
                                        final double long =
                                            shopLocationData['longitude'];
                                        print('$lat, $long');
                                        await openMap(
                                            lat.toString(), long.toString());
                                      } else {
                                        print('Location data not found');
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 50,
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Shop Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      '${status ?? "Not Available"}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: status == 'Open'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }
}
