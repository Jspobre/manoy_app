import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manoy_app/pages/profile/profileView.dart';
import 'package:manoy_app/pages/profile/shopView.dart';
import 'package:manoy_app/provider/bookmark/isBookmark_provider.dart';
import 'package:manoy_app/provider/bottomNav/currentIndex_provider.dart';
import 'package:manoy_app/provider/userDetails/uid_provider.dart';

import '../provider/bookmark/bookmarkData_provider.dart';

class ShopCard extends ConsumerWidget {
  final String name;
  final String address;
  final String? uid;
  final String image;
  final String category;
  final String businessHours;
  final String description;
  final String coverPhoto;
  // final bool? isBookmarked;
  final double? height;
  const ShopCard({
    super.key,
    required this.name,
    required this.address,
    this.height,
    this.uid,
    required this.image,
    required this.category,
    required this.businessHours,
    required this.description,
    required this.coverPhoto,
    // this.isBookmarked
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(uidProvider);
    void handleTap() {
      if (userId == uid) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (BuildContext context) {
            return ProfileView(
              fromShopCard: true,
            );
          }),
        );
      } else {
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

        bool isCurrentlyBookmarked =
            bookmarks.any((shop) => shop["Service Name"] == name);
        ref.read(isBookmarkProvider.notifier).state = isCurrentlyBookmarked;

        Navigator.of(context).push(
          MaterialPageRoute(builder: (BuildContext context) {
            // if (isBookmarked == true) {
            //   ref.read(isBookmarkProvider.notifier).state = true;
            // }
            return ShopView(
              userId: userId,
              name: name,
              address: address,
              uid: uid,
              businessHours: businessHours,
              category: category,
              description: description,
              profilePhoto: image,
              coverPhoto: coverPhoto,
              // isBookmarked: isBookmarked,
            );
          }),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        handleTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: double.infinity,
          height: height ?? 100,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: image!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        "No Ratings Yet",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        address,
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Accessories & Repair Services",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
