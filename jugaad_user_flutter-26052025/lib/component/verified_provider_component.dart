import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../model/user_data_model.dart';
import '../network/rest_apis.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import 'cached_image_widget.dart';

class VerifiedProviderComponent extends StatefulWidget {
  final double width;
  final UserData? data;
  final Function? onUpdate;
  final bool isFavouriteProvider;

  VerifiedProviderComponent(
      {required this.width, this.data, this.onUpdate, this.isFavouriteProvider = true});

  @override
  State<VerifiedProviderComponent> createState() => _FavouriteProviderComponentState();
}

class _FavouriteProviderComponentState extends State<VerifiedProviderComponent> {
  //Favourite provider
  Future<bool> addProviderToWishList({required int providerId}) async {
    Map req = {"id": "", "provider_id": providerId, "user_id": appStore.userId};
    return await addProviderWishList(req).then((res) {
      toast(language.providerAddedToFavourite);
      return true;
    }).catchError((error) {
      toast(error.toString());
      return false;
    });
  }

  Future<bool> removeProviderToWishList({required int providerId}) async {
    Map req = {"user_id": appStore.userId, 'provider_id': providerId};

    return await removeProviderWishList(req).then((res) {
      toast(language.providerRemovedFromFavourite);
      return true;
    }).catchError((error) {
      toast(error.toString());
      return false;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.width,
          decoration: boxDecorationWithRoundedCorners(
              borderRadius: radius(),
              backgroundColor:
                  appStore.isDarkMode ? context.cardColor : context.cardColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius),
                  color: primaryColor.withOpacity(0.2),
                ),
                child: CachedImageWidget(
                  url: widget.data!.profileImage.validate(),
                  width: context.width(),
                  height: 120,
                  fit: BoxFit.cover,
                  circle: false,
                ).cornerRadiusWithClipRRectOnly(
                    topRight: defaultRadius.toInt(), topLeft: defaultRadius.toInt()),
              ),
              16.height,
              Marquee(
                directionMarguee: DirectionMarguee.oneDirection,
                child:
                    Text(widget.data!.displayName.validate(), style: boldTextStyle(), maxLines: 1),
              ).center(),
              16.height,

              /// Hide email and calling function
              /*8.height,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.data!.contactNumber.validate().isNotEmpty)
                        TextIcon(
                          onTap: () {
                            launchCall(widget.data!.contactNumber.validate());
                          },
                          prefix: Container(
                            padding: EdgeInsets.all(8),
                            decoration: boxDecorationWithRoundedCorners(
                              boxShape: BoxShape.circle,
                              backgroundColor: primaryColor.withOpacity(0.1),
                            ),
                            child: Image.asset(ic_calling, color: primaryColor, height: 14, width: 14),
                          ),
                        ),
                      if (widget.data!.email.validate().isNotEmpty)
                        TextIcon(
                          onTap: () {
                            launchMail(widget.data!.email.validate());
                          },
                          prefix: Container(
                            padding: EdgeInsets.all(8),
                            decoration: boxDecorationWithRoundedCorners(
                              boxShape: BoxShape.circle,
                              backgroundColor: primaryColor.withOpacity(0.1),
                            ),
                            child: ic_message.iconImage(size: 14, color: primaryColor),
                          ),
                        ),
                    ],
                  ),*/
            ],
          ),
        ),
        Positioned(
            top: 8,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.only(right: 8),
              decoration: boxDecorationWithShadow(
                  boxShape: BoxShape.circle, backgroundColor: context.dividerColor),
              child: Image.asset(ic_verified, height: 12, width: 12, color: verifyAcColor))
            ),
      ],
    ).onTap(() {
      ProviderInfoScreen(
        providerId: widget.data!.providerId.validate(),
        canCustomerContact: true,
        onUpdate: () {
          widget.onUpdate!.call();
        },
      ).launch(context);
    });
  }
}
