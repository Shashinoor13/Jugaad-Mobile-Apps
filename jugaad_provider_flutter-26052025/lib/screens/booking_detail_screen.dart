import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_common_dialog.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/basic_info_component.dart';
import 'package:handyman_provider_flutter/components/booking_history_bottom_sheet.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/countdown_widget.dart';
import 'package:handyman_provider_flutter/components/price_common_widget.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:handyman_provider_flutter/components/review_list_view_component.dart';
import 'package:handyman_provider_flutter/components/view_all_label_component.dart';
import 'package:handyman_provider_flutter/handyman/component/service_proof_list_widget.dart';
import 'package:handyman_provider_flutter/handyman/service_proof_screen.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/Package_response.dart';
import 'package:handyman_provider_flutter/models/booking_detail_response.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:handyman_provider_flutter/models/extra_charges_model.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/components/assign_handyman_screen.dart';
import 'package:handyman_provider_flutter/provider/handyman_info_screen.dart';
import 'package:handyman_provider_flutter/provider/services/service_detail_screen.dart';
import 'package:handyman_provider_flutter/screens/cash_management/component/cash_confirm_dialog.dart';
import 'package:handyman_provider_flutter/screens/cash_management/view/cash_payment_history_screen.dart';
import 'package:handyman_provider_flutter/screens/extra_charges/add_extra_charges_screen.dart';
import 'package:handyman_provider_flutter/screens/rating_view_all_screen.dart';
import 'package:handyman_provider_flutter/screens/zoom_image_screen.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../components/base_scaffold_widget.dart';
import '../components/empty_error_state_widget.dart';
import '../provider/jobRequest/post_voice_player.dart';
import '../provider/services/addons/component/service_addons_component.dart';
import '../utils/images.dart';
import 'shimmer/booking_detail_shimmer.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  BookingDetailScreen({required this.bookingId});

  @override
  BookingDetailScreenState createState() => BookingDetailScreenState();
}

class BookingDetailScreenState extends State<BookingDetailScreen> {
  late Future<BookingDetailResponse> future;

  UniqueKey _paymentUniqueKey = UniqueKey();

  GlobalKey countDownKey = GlobalKey();
  String? startDateTime = '';
  String? endDateTime = '';
  String? timeInterval = '0';
  String? paymentStatus = '';

  bool? confirmPaymentBtn = false;
  bool isCompleted = false;
  bool showBottomActionBar = false;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init({bool flag = false}) async {
    future = bookingDetail({CommonKeys.bookingId: widget.bookingId.toString()});
    if (flag) {
      _paymentUniqueKey = UniqueKey();
      setState(() {});
    }
  }

  BookingDetailResponse? initialData() {
    if (cachedBookingDetailList.any((element) =>
        element.bookingDetail!.id == widget.bookingId.validate())) {
      return cachedBookingDetailList.firstWhere(
          (element) => element.bookingDetail!.id == widget.bookingId);
    }
    return null;
  }

  //region Methods
  Future<void> confirmationRequestDialog(
      BuildContext context, String status, BookingDetailResponse res) async {
    if (status == BookingStatusKeys.complete &&
        res.bookingDetail!.paymentMethod == PAYMENT_METHOD_COD) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.all(0),
        builder: (p0) {
          return AppCommonDialog(
            title: languages.cashPaymentConfirmation,
            child: CashConfirmDialog(
              bookingId: res.bookingDetail!.id.validate(),
              bookingAmount: res.bookingDetail!.totalAmount.validate(),
              onAccept: (String remarks) {
                appStore.setLoading(true);
                updateBooking(res, '$remarks', BookingStatusKeys.complete);
              },
            ),
          );
        },
      );

      return;
    }
    showConfirmDialogCustom(
      context,
      title: languages.confirmationRequestTxt,
      primaryColor: status == BookingStatusKeys.rejected
          ? Colors.redAccent
          : primaryColor,
      positiveText: languages.lblYes,
      negativeText: languages.lblNo,
      onAccept: (context) async {
        if (status == BookingStatusKeys.pending) {
          appStore.setLoading(true);
          updateBooking(res, '', BookingStatusKeys.accept);
        } else if (status == BookingStatusKeys.rejected) {
          appStore.setLoading(true);
          updateBooking(res, '', BookingStatusKeys.rejected);
        } else if (status == BookingStatusKeys.complete) {
          if (res.bookingDetail!.paymentMethod == PAYMENT_METHOD_COD) {
            return;
          }
        }
      },
    );
  }

  Future<void> assignBookingDialog(
      BuildContext context, int? bookingId, int? addressId) async {
    AssignHandymanScreen(
      bookingId: bookingId,
      serviceAddressId: addressId,
      onUpdate: () {
        appStore.setLoading(true);
        init(flag: true);

        if (appStore.isLoading) appStore.setLoading(false);
      },
    ).launch(context);
  }

  Future<void> updateBooking(BookingDetailResponse bookDetail,
      String updateReason, String updatedStatus) async {
    DateTime now = DateTime.now();
    if (updatedStatus == BookingStatusKeys.inProgress) {
      startDateTime = DateFormat(BOOKING_SAVE_FORMAT).format(now);
      endDateTime = bookDetail.bookingDetail!.endAt.validate();
      timeInterval =
          bookDetail.bookingDetail!.durationDiff.validate().isEmptyOrNull
              ? "0"
              : bookDetail.bookingDetail!.durationDiff.validate();
      paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
          ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
          : bookDetail.bookingDetail!.paymentStatus.validate();
      //
    } else if (updatedStatus == BookingStatusKeys.hold) {
      String? currentDateTime = DateFormat(BOOKING_SAVE_FORMAT).format(now);
      startDateTime = bookDetail.bookingDetail!.startAt.validate();
      endDateTime = currentDateTime;
      var diff = DateTime.parse(currentDateTime)
          .difference(
              DateTime.parse(bookDetail.bookingDetail!.startAt.validate()))
          .inMinutes;
      num count =
          int.parse(bookDetail.bookingDetail!.durationDiff.validate()) + diff;
      timeInterval = count.toString();
      paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
          ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
          : bookDetail.bookingDetail!.paymentStatus.validate();
    } else if (updatedStatus == BookingStatusKeys.pendingApproval) {
      startDateTime = bookDetail.bookingDetail!.startAt.toString();
      endDateTime = bookDetail.bookingDetail!.endAt.toString();
      timeInterval = bookDetail.bookingDetail!.durationDiff.validate();
      paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
          ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
          : bookDetail.bookingDetail!.paymentStatus.validate();
    } else if (updatedStatus == BookingStatusKeys.complete) {
      if (bookDetail.bookingDetail!.paymentStatus == PENDING &&
          bookDetail.bookingDetail!.paymentMethod == PAYMENT_METHOD_COD) {
        startDateTime = bookDetail.bookingDetail!.startAt.toString();
        endDateTime = bookDetail.bookingDetail!.endAt.toString();
        timeInterval = "0";
        paymentStatus = PENDING_BY_ADMINS;
        confirmPaymentBtn = false;
        isCompleted = true;
      } else {
        endDateTime = DateFormat(BOOKING_SAVE_FORMAT).format(now);
        startDateTime = bookDetail.bookingDetail!.startAt.validate();
        var diff = DateTime.parse(endDateTime.validate())
            .difference(
                DateTime.parse(bookDetail.bookingDetail!.startAt.validate()))
            .inMinutes;
        num count =
            int.parse(bookDetail.bookingDetail!.durationDiff.validate()) + diff;
        timeInterval = count.toString();
        paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
            ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
            : bookDetail.bookingDetail!.paymentStatus.validate();
      }
      //
    } else if (updatedStatus == BookingStatusKeys.rejected ||
        updatedStatus == BookingStatusKeys.cancelled) {
      startDateTime = bookDetail.bookingDetail!.startAt.validate().isNotEmpty
          ? bookDetail.bookingDetail!.startAt.validate()
          : bookDetail.bookingDetail!.date.validate();
      endDateTime = DateFormat(BOOKING_SAVE_FORMAT).format(now);
      timeInterval = bookDetail.bookingDetail!.durationDiff.toString();
      paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
          ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
          : bookDetail.bookingDetail!.paymentStatus.validate();
      //
    } else {
      paymentStatus = bookDetail.bookingDetail!.isAdvancePaymentDone
          ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
          : bookDetail.bookingDetail!.paymentStatus.validate();
    }
    countDownKey = GlobalKey();
    setState(() {});

    hideKeyboard(context);

    var request = {
      CommonKeys.id: bookDetail.bookingDetail!.id,
      BookingUpdateKeys.startAt: startDateTime,
      BookingUpdateKeys.endAt: endDateTime,
      BookingUpdateKeys.durationDiff: timeInterval,
      BookingUpdateKeys.reason: updateReason,
      BookingUpdateKeys.status: updatedStatus,
      BookingUpdateKeys.paymentStatus: paymentStatus
    };

    await bookingUpdate(request).then((res) async {
      if (paymentStatus == PENDING_BY_ADMINS) {
        finish(context);
      }
      init(flag: true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _handlePendingApproval({
    required BookingDetailResponse val,
    bool isAddExtraCharges = false,
    bool isEditExtraCharges = false,
  }) async {
    appStore.setLoading(true);

    Map req = isEditExtraCharges
        ? {
            CommonKeys.id: val.bookingDetail!.id.validate(),
            BookingUpdateKeys.durationDiff: timeInterval,
            BookingUpdateKeys.paymentStatus:
                val.bookingDetail!.isAdvancePaymentDone
                    ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                    : val.bookingDetail!.paymentStatus.validate(),
            BookingUpdateKeys.status: BookingStatusKeys.complete,
          }
        : {
            CommonKeys.id: val.bookingDetail!.id.validate(),
            BookingUpdateKeys.startAt: val.bookingDetail!.startAt.toString(),
            BookingUpdateKeys.endAt: val.bookingDetail!.endAt.toString(),
            BookingUpdateKeys.status: BookingStatusKeys.complete,
            BookingUpdateKeys.durationDiff: timeInterval,
            BookingUpdateKeys.paymentStatus:
                val.bookingDetail!.isAdvancePaymentDone
                    ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                    : val.bookingDetail!.paymentStatus.validate(),
          };

    if (chargesList.isNotEmpty && isAddExtraCharges) {
      List<Map<String, dynamic>> charges = [];

      chargesList.forEach((element) {
        charges.add({
          "title": element.title.validate(),
          "qty": element.qty.validate(),
          "price": element.price.validate(),
        });
      });
      req.putIfAbsent(BookingServiceKeys.extraCharges, () => charges);
    }

    if (chargesList.isNotEmpty && isEditExtraCharges) {
      List<Map<String, dynamic>> charges = [];

      chargesList.forEach((element) {
        charges.add({
          "id": element.id.validate(),
          "title": element.title.validate(),
          "qty": element.qty.validate(),
          "price": element.price.validate(),
        });
      });
      req.putIfAbsent(BookingServiceKeys.extraCharges, () => charges);
    }

    await bookingUpdate(req).then((res) async {
      //
      init(flag: true);
    }).catchError((e) {
      toast(e.toString(), print: true);
    });

    appStore.setLoading(false);
  }

  //endregion

  //region Components
  Widget _serviceDetailWidget(
      {required BookingData bookingDetail,
      required ServiceData serviceDetail}) {
    return GestureDetector(
      onTap: () {
        if (bookingDetail.isPostJob || bookingDetail.isPackageBooking) {
          //
        } else {
          ServiceDetailScreen(serviceId: bookingDetail.serviceId.validate())
              .launch(context);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookingDetail.isPackageBooking)
                Text(
                  bookingDetail.bookingPackage!.name.validate(),
                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  bookingDetail.serviceName.validate(),
                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              12.height,
              if ((bookingDetail.date.validate().isNotEmpty))
                Row(
                  children: [
                    Text("${languages.lblDate}: ", style: secondaryTextStyle()),
                    Text(
                      formatDate(bookingDetail.date.validate(),
                          format: DATE_FORMAT_2),
                      style: boldTextStyle(size: 12),
                    ),
                  ],
                ),
              8.height,
              if ((bookingDetail.date.validate().isNotEmpty))
                Row(
                  children: [
                    Text("${languages.lblTime}: ", style: secondaryTextStyle()),
                    buildTimeWidget(bookingDetail: bookingDetail),
                  ],
                ),
            ],
          ).expand(),
          if (serviceDetail.attchments!.isNotEmpty &&
              !bookingDetail.isPackageBooking)
            CachedImageWidget(
              url: serviceDetail.attchments!.isNotEmpty
                  ? serviceDetail.attchments!.first.url.validate()
                  : "",
              height: 90,
              width: 90,
              fit: BoxFit.cover,
              radius: 8,
            )
          else
            CachedImageWidget(
              url: bookingDetail.bookingPackage != null
                  ? bookingDetail.bookingPackage!.imageAttachments
                          .validate()
                          .isNotEmpty
                      ? bookingDetail.bookingPackage!.imageAttachments
                              .validate()
                              .first
                              .validate()
                              .isNotEmpty
                          ? bookingDetail.bookingPackage!.imageAttachments
                              .validate()
                              .first
                              .validate()
                          : ''
                      : ''
                  : '',
              height: 90,
              width: 90,
              fit: BoxFit.cover,
              radius: 8,
            ),
        ],
      ),
    );
  }

  Widget _buildCounterWidget({required BookingDetailResponse value}) {
    if (value.bookingDetail!.isHourlyService &&
        (value.bookingDetail!.status == BookingStatusKeys.inProgress ||
            value.bookingDetail!.status == BookingStatusKeys.hold ||
            value.bookingDetail!.status == BookingStatusKeys.complete ||
            value.bookingDetail!.status == BookingStatusKeys.onGoing))
      return CountdownWidget(bookingDetailResponse: value, key: countDownKey)
          .paddingSymmetric(horizontal: 16);
    else
      return Offstage();
  }

  Widget _buildReasonWidget({required BookingDetailResponse snap}) {
    if ((snap.bookingDetail!.status == BookingStatusKeys.hold ||
            snap.bookingDetail!.status == BookingStatusKeys.cancelled ||
            snap.bookingDetail!.status == BookingStatusKeys.rejected ||
            snap.bookingDetail!.status == BookingStatusKeys.failed) &&
        ((snap.bookingDetail!.reason != null &&
            snap.bookingDetail!.reason!.isNotEmpty)))
      return Container(
        padding: EdgeInsets.all(16),
        color: redColor.withOpacity(0.05),
        width: context.width(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(languages.lblReason, style: secondaryTextStyle()),
            Text(snap.bookingDetail!.reason.validate(),
                style: primaryTextStyle(color: redColor)),
          ],
        ),
      );

    return Offstage();
  }

  Widget _customerReviewWidget(
      {required BookingDetailResponse bookingDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bookingDetailResponse.ratingData!.isNotEmpty)
          ViewAllLabel(
            label:
                '${languages.review} (${bookingDetailResponse.bookingDetail!.totalReview})',
            list: bookingDetailResponse.ratingData!,
            onTap: () {
              RatingViewAllScreen(serviceId: bookingDetailResponse.service!.id!)
                  .launch(context);
            },
          ),
        8.height,
        ReviewListViewComponent(
          ratings: bookingDetailResponse.ratingData!,
          padding: EdgeInsets.symmetric(vertical: 6),
          physics: NeverScrollableScrollPhysics(),
        ),
      ],
    )
        .paddingSymmetric(horizontal: 16)
        .visible(bookingDetailResponse.service!.totalRating != null);
  }

  Widget buildTimeWidget({required BookingData bookingDetail}) {
    if (bookingDetail.bookingSlot == null) {
      return Text(formatDate(bookingDetail.date.validate(), isTime: true),
          style: boldTextStyle(size: 12));
    }
    return Text(
      formatDate(
          getSlotWithDate(
              date: bookingDetail.date.validate(),
              slotTime: bookingDetail.bookingSlot.validate()),
          isTime: true),
      style: boldTextStyle(size: 12),
    );
  }

  Widget descriptionWidget({required BookingDetailResponse value}) {
    if (value.bookingDetail!.description.validate().isNotEmpty)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            8.height,
            Text(
                "${languages.lblBooking.split('s').join(' ')}${languages.hintDescription}",
                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            8.height,
            ReadMoreText(
              value.bookingDetail!.description.validate(),
              style: secondaryTextStyle(),
              colorClickableText: context.primaryColor,
            ),
            8.height,
          ],
        ),
      );
    else
      return Offstage();
  }

  Widget myServiceList({required List<ServiceData> serviceList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text(languages.lblMyService,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        AnimatedListView(
          itemCount: serviceList.length,
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius:
                      BorderRadius.all(Radius.circular(defaultRadius))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // InkWell(
                  //     onTap: () {
                  //       ZoomImageScreen(
                  //               galleryImages: [data.imageAttachments!.first],
                  //               index: 0)
                  //           .launch(context);
                  //     },
                  //     child: CachedImageWidget(
                  //         url: data.imageAttachments.validate().isNotEmpty
                  //             ? data.imageAttachments!.first.validate()
                  //             : "",
                  //         fit: BoxFit.cover,
                  //         height: 50,
                  //         width: 50,
                  //         radius: defaultRadius)),

                  Row(
                    children: [
                      Text(data.name.validate(),
                          style: boldTextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      // Text(" ", style: secondaryTextStyle()),
                      // if ((data.categoryName.validate().isNotEmpty))
                      //   Text(
                      //     '(${data.categoryName.validate()})',
                      //     style: boldTextStyle(size: 10),
                      //   ),
                    ],
                    // multi images video batavana
                  ),
                  if ((data.description.validate().isNotEmpty))
                    Text(data.description.validate(),
                        style: secondaryTextStyle()),
                  8.height,
                  HorizontalList(
                    itemCount: data.imageAttachments.validate().length,
                    itemBuilder: (context, i) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          if (data.imageAttachments
                              .validate()[i]
                              .contains("http"))
                            GestureDetector(
                                    onTap: () {
                                      ZoomImageScreen(
                                              galleryImages: data
                                                  .imageAttachments
                                                  .validate(),
                                              index: i)
                                          .launch(context,
                                              pageRouteAnimation:
                                                  PageRouteAnimation.Fade,
                                              duration: 200.milliseconds);
                                    },
                                    child: CachedImageWidget(
                                        url:
                                            data.imageAttachments.validate()[i],
                                        placeHolderImage: selectVideo,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover))
                                .cornerRadiusWithClipRRect(defaultRadius),
                        ],
                      );
                    },
                  )
                      .paddingBottom(16)
                      // .visible(data.imageAttachments.validate()[i].isNotEmpty),
                ],
              ),
            );
          },
        ),
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  Widget packageWidget({required PackageData package}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(languages.includedInThisPackage, style: boldTextStyle())
            .paddingSymmetric(horizontal: 16, vertical: 8),
        AnimatedListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemCount: package.serviceList!.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (_, i) {
            ServiceData data = package.serviceList![i];

            return Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(),
                backgroundColor: context.cardColor,
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedImageWidget(
                    url: data.imageAttachments!.isNotEmpty
                        ? data.imageAttachments!.first.validate()
                        : "",
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    radius: 8,
                  ),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name.validate(),
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      4.height,
                      if (data.subCategoryName.validate().isNotEmpty)
                        Marquee(
                          child: Row(
                            children: [
                              Text('${data.categoryName}',
                                  style: boldTextStyle(
                                      color: textSecondaryColorGlobal)),
                              Text('  >  ',
                                  style: boldTextStyle(
                                      color: textSecondaryColorGlobal)),
                              Text('${data.subCategoryName}',
                                  style: boldTextStyle(
                                      color: context.primaryColor)),
                            ],
                          ),
                        )
                      else
                        Text('${data.categoryName}',
                            style: secondaryTextStyle()),
                      4.height,
                      PriceWidget(
                        price: data.price.validate(),
                        hourlyTextColor: Colors.white,
                        size: 16,
                      ),
                    ],
                  ).flexible()
                ],
              ),
            ).onTap(() {
              ServiceDetailScreen(serviceId: data.id!).launch(context);
            });
          },
        )
      ],
    );
  }

  Widget _action({required BookingDetailResponse res}) {
    showBottomActionBar = false;
    if (isUserTypeProvider) {
      if (res.isMe.validate()) {
        return handleHandyman(res: res);
      } else {
        return handleProvider(res: res);
      }
    } else if (isUserTypeHandyman) {
      return handleHandyman(res: res);
    }

    return Offstage();
  }

  Widget handleProvider({required BookingDetailResponse res}) {
    if (res.bookingDetail!.status == BookingStatusKeys.pending) {
      showBottomActionBar = true;
      return Row(
        children: [
          AppButton(
            text: languages.accept,
            color: context.primaryColor,
            onTap: () async {
              /// If Auto Assign is enabled, Assign to current Provider it self
              if (appConfigurationStore.autoAssignStatus) {
                await showConfirmDialogCustom(
                  context,
                  title: languages.lblAreYouSureYouWantToAssignToYourself,
                  primaryColor: context.primaryColor,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblCancel,
                  onAccept: (c) async {
                    var request = {
                      CommonKeys.id: widget.bookingId.validate(),
                      CommonKeys.handymanId: [appStore.userId.validate()],
                    };
                    appStore.setLoading(true);

                    await assignBooking(request).then((res) async {
                      LiveStream().emit(LIVESTREAM_UPDATE_BOOKINGS);
                      init(flag: true);
                    }).catchError((e) {
                      toast(e.toString());
                    });
                  },
                );
              } else {
                await showConfirmDialogCustom(
                  context,
                  title: languages.wouldYouLikeToAssignThisBooking,
                  primaryColor: primaryColor,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblNo,
                  onAccept: (_) async {
                    var request = {
                      CommonKeys.id: res.bookingDetail!.id.validate(),
                      BookingUpdateKeys.status: BookingStatusKeys.accept,
                      BookingUpdateKeys.paymentStatus:
                          res.bookingDetail!.isAdvancePaymentDone
                              ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                              : res.bookingDetail!.paymentStatus.validate(),
                    };
                    appStore.setLoading(true);

                    bookingUpdate(request).then((res) async {
                      LiveStream().emit(LIVESTREAM_UPDATE_BOOKINGS);
                      init(flag: true);
                    }).catchError((e) {
                      toast(e.toString());
                    });
                  },
                );
              }
            },
          ).expand(),
          16.width,
          AppButton(
            text: languages.decline,
            textColor: textPrimaryColorGlobal,
            onTap: () {
              confirmationRequestDialog(
                  context, BookingStatusKeys.rejected, res);
            },
          ).expand(),
        ],
      );
    } else if (res.bookingDetail!.status == BookingStatusKeys.accept) {
      showBottomActionBar = true;

      if (res.handymanData.validate().isEmpty) {
        return AppButton(
          text: languages.lblAssignHandyman,
          color: context.primaryColor,
          onTap: () {
            assignBookingDialog(context, res.bookingDetail!.id,
                res.bookingDetail!.bookingAddressId);
          },
        );
      } else {
        return Text(
                '${res.handymanData!.first.displayName.validate()} ${languages.lblAssigned}',
                style: boldTextStyle())
            .center();
      }
    }

    return Offstage();
  }

  Widget handleHandyman({required BookingDetailResponse res}) {
    if (res.bookingDetail!.status == BookingStatusKeys.accept) {
      showBottomActionBar = true;

      return Container(
        child: Row(
          children: [
            AppButton(
              text: res.service!.isOnlineService.validate()
                  ? languages.start
                  : languages.lblStartDrive,
              color: startDriveButtonColor,
              onTap: () {
                showConfirmDialogCustom(
                  context,
                  title: languages.confirmationRequestTxt,
                  primaryColor: context.primaryColor,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblNo,
                  onAccept: (c) {
                    appStore.setLoading(true);
                    updateBooking(
                      res,
                      '',
                      res.service!.isOnlineService.validate()
                          ? BookingStatusKeys.inProgress
                          : BookingStatusKeys.onGoing,
                    );
                  },
                );
              },
            ).expand(),
            16.width,
            AppButton(
              text: languages.decline,
              textColor: textPrimaryColorGlobal,
              onTap: () {
                showConfirmDialogCustom(
                  context,
                  title: languages.confirmationRequestTxt,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblNo,
                  onAccept: (val) {
                    appStore.setLoading(true);
                    updateBooking(res, '', BookingStatusKeys.pending);
                  },
                  primaryColor: context.primaryColor,
                );
              },
            ).expand(),
          ],
        ),
      );
    } else if (res.bookingDetail!.status == BookingStatusKeys.pendingApproval) {
      showBottomActionBar = true;
      return Container(
        child: Row(
          children: [
            AppButton(
              text: languages.lblCompleted,
              textStyle: boldTextStyle(color: white),
              color: context.primaryColor,
              onTap: () {
                bool isAnyServiceAddonUnCompleted = res
                    .bookingDetail!.serviceaddon
                    .validate()
                    .any((element) => element.status.getBoolInt() == false);
                showConfirmDialogCustom(
                  context,
                  onAccept: (_) {
                    _handlePendingApproval(val: res, isAddExtraCharges: false);
                  },
                  primaryColor: context.primaryColor,
                  positiveText: languages.lblYes,
                  negativeText: languages.lblNo,
                  subTitle: isAnyServiceAddonUnCompleted
                      ? languages.pleaseNoteThatAllServiceMarkedCompleted
                      : null,
                  title: languages.confirmationRequestTxt,
                );
              },
            ).expand(),
            if (!res.bookingDetail!.isFreeService &&
                res.bookingDetail!.bookingPackage == null)
              AppButton(
                margin: EdgeInsets.only(left: 16),
                child: Text(
                  languages.lblAddExtraCharges,
                  style: boldTextStyle(color: Colors.white),
                ).fit(),
                color: addExtraCharge,
                onTap: () async {
                  chargesList.clear();
                  bool? a = await AddExtraChargesScreen().launch(context);

                  if (a ?? false) {
                    _handlePendingApproval(val: res, isAddExtraCharges: true);
                  }
                },
              ).expand(),
          ],
        ),
      );
    } else if (res.bookingDetail!.status == BookingStatusKeys.onGoing) {
      showBottomActionBar = true;

      return Text(languages.lblWaitingForResponse, style: boldTextStyle())
          .center();
    } else if (res.bookingDetail!.status == BookingStatusKeys.complete) {
      if (res.bookingDetail!.paymentMethod == PAYMENT_METHOD_COD &&
          res.bookingDetail!.paymentStatus == PENDING) {
        showBottomActionBar = true;
        return AppButton(
          text: languages.lblConfirmPayment,
          color: context.primaryColor,
          onTap: () {
            confirmationRequestDialog(context, BookingStatusKeys.complete, res);
          },
        );
      } else if (res.bookingDetail!.paymentStatus == PAID ||
          res.bookingDetail!.paymentStatus == PENDING_BY_ADMINS) {
        showBottomActionBar = true;
        return AppButton(
          text: languages.lblServiceProof,
          color: context.primaryColor,
          onTap: () {
            ServiceProofScreen(bookingDetail: res)
                .launch(context, pageRouteAnimation: PageRouteAnimation.Fade)
                .then((value) {
              init(flag: true);
            });
          },
        );
      }
    } else if (res.bookingDetail!.status == BookingStatusKeys.inProgress) {
      showBottomActionBar = true;

      return Text(res.bookingDetail!.statusLabel.validate(),
              style: boldTextStyle())
          .center();
    }
    return Offstage();
  }

  Widget extraChargesWidget(
      {required List<ExtraChargesModel> extraChargesList,
      required BookingDetailResponse res}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(languages.lblExtraCharges,
                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            IconButton(
              style: ButtonStyle(
                  padding: MaterialStatePropertyAll(EdgeInsets.zero)),
              icon: ic_edit_square.iconImage(size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                chargesList.clear();
                chargesList.addAll(extraChargesList);
                bool? a =
                    await AddExtraChargesScreen(isFromEditExtraCharge: true)
                        .launch(context);

                if (a ?? false) {
                  _handlePendingApproval(val: res, isEditExtraCharges: true);
                }
              },
            ),
          ],
        ).visible(res.bookingDetail!.paymentStatus != PAID),
        16.height,
        Container(
          decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor, borderRadius: radius()),
          padding: EdgeInsets.all(16),
          child: AnimatedListView(
            itemCount: extraChargesList.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              ExtraChargesModel data = extraChargesList[i];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.title.validate(),
                              style: secondaryTextStyle(size: 14))
                          .expand(),
                      16.width,
                      Row(
                        children: [
                          Text('${data.qty} * ${data.price.validate()} = ',
                              style: secondaryTextStyle()),
                          4.width,
                          PriceWidget(
                              price:
                                  '${data.price.validate() * data.qty.validate()}'
                                      .toDouble(),
                              size: 16,
                              color: textPrimaryColorGlobal,
                              isBoldText: true),
                        ],
                      ),
                    ],
                  ),
                  8.height,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  //endregion

  //region Body
  Widget buildBodyWidget(AsyncSnapshot<BookingDetailResponse> res) {
    if (res.hasError) {
      return NoDataWidget(
        title: res.error.toString(),
        imageWidget: ErrorStateWidget(),
        retryText: languages.reload,
        onRetry: () {
          appStore.setLoading(true);

          init();
          setState(() {});
        },
      );
    } else if (res.hasData) {
      countDownKey = GlobalKey();
      return Stack(
        fit: StackFit.expand,
        children: [
          Stack(
            children: [
              AnimatedScrollView(
                padding: EdgeInsets.only(bottom: 100),
                physics: AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Show Reason if booking is canceled
                  _buildReasonWidget(snap: res.data!),

                  /// Booking & Service Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      8.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages.lblBookingID,
                            style: boldTextStyle(
                                size: LABEL_TEXT_SIZE,
                                color: appStore.isDarkMode
                                    ? white
                                    : gray.withOpacity(0.8)),
                          ),
                          Text(
                              '#' +
                                  res.data!.bookingDetail!.id
                                      .toString()
                                      .validate(),
                              style:
                                  boldTextStyle(color: primaryColor, size: 16)),
                        ],
                      ),
                      16.height,
                      Divider(height: 0, color: context.dividerColor),
                      12.height,
                      _serviceDetailWidget(
                          serviceDetail: res.data!.service!,
                          bookingDetail: res.data!.bookingDetail!)
                    ],
                  ).paddingAll(16),

                  Divider(height: 0, color: context.dividerColor),
                  8.height,

                  /// Total Service Time
                  _buildCounterWidget(value: res.data!),

                  ///Description Widget
                  descriptionWidget(value: res.data!),
                  if (res.data!.postRequestDetail != null)
                    if (res.data!.postRequestDetail!.voiceNote
                        .validate()
                        .isNotEmpty)
                      Text(languages.voiceNote,
                              style: boldTextStyle(size: LABEL_TEXT_SIZE))
                          .paddingSymmetric(horizontal: 16, vertical: 4),
                  if (res.data!.postRequestDetail != null)
                    if (res.data!.postRequestDetail!.voiceNote
                        .validate()
                        .isNotEmpty)
                      PostVoicePlayer(
                        path: res.data!.postRequestDetail!.voiceNote.validate(),
                        callback: (v) {
                          setState(() {
                            print("audioPath: " + v);
                          });
                        },
                      ).paddingSymmetric(horizontal: 16),

                  /// My Service List
                  if (res.data!.postRequestDetail != null &&
                      res.data!.postRequestDetail!.service != null)
                    myServiceList(
                        serviceList: res.data!.postRequestDetail!.service!),

                  /// Package Info if User selected any Package
                  if (res.data!.bookingDetail!.bookingPackage != null)
                    packageWidget(
                        package: res.data!.bookingDetail!.bookingPackage!),

                  /// Service Proof Images
                  ServiceProofListWidget(
                      serviceProofList: res.data!.serviceProof!),

                  /// About Handyman Card
                  if (res.data!.handymanData!.isNotEmpty &&
                      appStore.userType != USER_TYPE_HANDYMAN)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        24.height,
                        Text(languages.lblAboutHandyman,
                            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                        16.height,
                        Container(
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: context.cardColor,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: res.data!.handymanData!.map(
                              (e) {
                                return BasicInfoComponent(
                                  1,
                                  handymanData: e,
                                  service: res.data!.service,
                                  bookingDetail: res.data!.bookingDetail!,
                                  bookingInfo: res.data!,
                                ).paddingOnly(bottom: 24).onTap(() {
                                  if (res.data!.bookingDetail!
                                      .canCustomerContact) {
                                    HandymanInfoScreen(
                                            handymanId: e.id,
                                            service: res.data!.service)
                                        .launch(context)
                                        .then((value) => null);
                                  }
                                });
                              },
                            ).toList(),
                          ),
                        ),
                      ],
                    ).paddingOnly(left: 16, right: 16),

                  /// About Customer Card
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      16.height,
                      // if(res.data!.bookingDetail!.canCustomerContact)
                      aboutCustomerWidget(
                          context: context,
                          bookingDetail: res.data!.bookingDetail),
                      16.height,
                      Container(
                        decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: context.cardColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BasicInfoComponent(
                              0,
                              customerData: res.data!.customer,
                              service: res.data!.service,
                              bookingDetail: res.data!.bookingDetail,
                            ),
                          ],
                        ),
                      ),

                      8.height,

                      ///Add-ons
                      if (res.data!.bookingDetail!.serviceaddon
                          .validate()
                          .isNotEmpty)
                        AddonComponent(
                          serviceAddon:
                              res.data!.bookingDetail!.serviceaddon.validate(),
                        ),
                    ],
                  ).paddingOnly(left: 16, right: 16, bottom: 16),

                  /// Price Detail Card
                  if (res.data!.bookingDetail != null &&
                      !res.data!.bookingDetail!.isFreeService)
                    PriceCommonWidget(
                      bookingDetail: res.data!.bookingDetail!,
                      serviceDetail: res.data!.service!,
                      taxes: res.data!.bookingDetail!.taxes.validate(),
                      couponData: res.data!.couponData != null
                          ? res.data!.couponData!
                          : null,
                      bookingPackage:
                          res.data!.bookingDetail!.bookingPackage != null
                              ? res.data!.bookingDetail!.bookingPackage
                              : null,
                    ).paddingOnly(bottom: 16, left: 16, right: 16),

                  /// Extra Charges
                  if (res.data!.bookingDetail!.extraCharges
                      .validate()
                      .isNotEmpty)
                    extraChargesWidget(
                            extraChargesList: res
                                .data!.bookingDetail!.extraCharges
                                .validate(),
                            res: res.data!)
                        .paddingOnly(left: 16, right: 16, bottom: 16),

                  /// Payment Detail Card
                  if (res.data!.bookingDetail!.paymentId != null &&
                      res.data!.bookingDetail!.paymentStatus != null &&
                      !res.data!.bookingDetail!.isFreeService)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ViewAllLabel(
                          label: languages.lblPaymentDetail,
                          list: [],
                        ),
                        8.height,
                        Container(
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: context.cardColor,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(languages.lblId,
                                      style: secondaryTextStyle(size: 14)),
                                  Text(
                                      "#" +
                                          res.data!.bookingDetail!.paymentId
                                              .toString(),
                                      style: boldTextStyle()),
                                ],
                              ),
                              4.height,
                              Divider(color: context.dividerColor),
                              4.height,
                              if (res.data!.bookingDetail!.paymentMethod
                                  .validate()
                                  .isNotEmpty)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(languages.lblMethod,
                                        style: secondaryTextStyle(size: 14)),
                                    Text(
                                      (res.data!.bookingDetail!.paymentMethod !=
                                                  null
                                              ? res.data!.bookingDetail!
                                                  .paymentMethod
                                                  .toString()
                                              : languages.notAvailable)
                                          .capitalizeFirstLetter(),
                                      style: boldTextStyle(),
                                    ),
                                  ],
                                ),
                              4.height,
                              Divider(color: context.dividerColor).visible(
                                  res.data!.bookingDetail!.paymentMethod !=
                                      null),
                              8.height,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(languages.lblStatus,
                                      style: secondaryTextStyle(size: 14)),
                                  Text(
                                    getPaymentStatusText(
                                        res.data!.bookingDetail!.paymentStatus
                                            .validate(value: languages.pending),
                                        res.data!.bookingDetail!.paymentMethod),
                                    style: boldTextStyle(),
                                  ),
                                ],
                              ),
                              4.height,
                              Divider(color: context.dividerColor).visible(
                                  res.data!.bookingDetail!.paymentMethod !=
                                      null),
                              8.height,
                              Row(
                                children: [
                                  Text(languages.transactionId,
                                      style: secondaryTextStyle(size: 14)),
                                  8.width,
                                  Row(
                                    children: [
                                      Text(
                                              res.data!.bookingDetail!.txnId
                                                  .validate(),
                                              textAlign: TextAlign.right,
                                              style: boldTextStyle(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis)
                                          .expand(),
                                      4.width,
                                      InkWell(
                                        onTap: () async {
                                          await res.data!.bookingDetail!.txnId
                                              .validate()
                                              .copyToClipboard();
                                          toast(languages.copied);
                                        },
                                        child: SizedBox(
                                            width: 23,
                                            height: 23,
                                            child: Icon(Icons.copy, size: 18)),
                                      ),
                                    ],
                                  ).expand(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).paddingOnly(left: 16, right: 16, bottom: 16),

                  CashPaymentHistoryScreen(
                    bookingId:
                        res.data!.bookingDetail!.id.validate().toString(),
                    key: _paymentUniqueKey,
                  ),

                  /// Customer Review Widget
                  if (res.data!.ratingData.validate().isNotEmpty)
                    _customerReviewWidget(bookingDetailResponse: res.data!),
                ],
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: context.width(),
                  decoration: BoxDecoration(color: context.cardColor),
                  child: _action(res: res.data!),
                  padding: showBottomActionBar
                      ? EdgeInsets.all(16)
                      : EdgeInsets.zero,
                ),
              )
            ],
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      );
    }
    return BookingDetailShimmer();
  }

  //endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingDetailResponse>(
      future: future,
      initialData: initialData(),
      builder: (context, snap) {
        return RefreshIndicator(
          onRefresh: () async {
            init(flag: true);
            return await 2.seconds.delay;
          },
          child: AppScaffold(
            appBarTitle: snap.hasData
                ? snap.data!.bookingDetail!.status.validate().toBookingStatus()
                : "",
            actions: [
              if (snap.hasData)
                TextButton(
                  child: Text(languages.lblCheckStatus,
                      style: boldTextStyle(color: white)),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      isScrollControlled: true,
                      isDismissible: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: radiusOnly(
                              topLeft: defaultRadius, topRight: defaultRadius)),
                      builder: (_) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.50,
                          minChildSize: 0.2,
                          maxChildSize: 1,
                          builder: (context, scrollController) =>
                              BookingHistoryBottomSheet(
                            data: snap.data!.bookingActivity!.reversed.toList(),
                            scrollController: scrollController,
                          ),
                        );
                      },
                    );
                  },
                ).paddingRight(16),
            ],
            body: buildBodyWidget(snap),
          ),
        );
      },
    );
  }
}
