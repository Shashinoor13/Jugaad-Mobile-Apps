import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/components/bid_price_dialog.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/models/post_job_detail_response.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';
import '../../screens/zoom_image_screen.dart';
import '../../utils/images.dart';
import 'models/bidder_data.dart';
import 'models/post_job_data.dart';
import 'post_voice_player.dart';

class JobPostDetailScreen extends StatefulWidget {
  final PostJobData postJobData;

  JobPostDetailScreen({required this.postJobData});

  @override
  _JobPostDetailScreenState createState() => _JobPostDetailScreenState();
}

class _JobPostDetailScreenState extends State<JobPostDetailScreen> {
  late Future<PostJobDetailResponse> future;

  int page = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getPostJobDetail(
        {PostJob.postRequestId: widget.postJobData.id.validate()});
  }

  Widget titleWidget({required String title, required String detail, bool isReadMore = false, required TextStyle detailTextStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.validate(), style: secondaryTextStyle()),
        8.height,
        if (isReadMore)
          ReadMoreText(detail, style: detailTextStyle, colorClickableText: context.primaryColor,)
        else
          Text(detail.validate(), style: detailTextStyle),
        16.height,
      ],
    );
  }

  Widget postJobDetailWidget({required PostJobData data}) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
          backgroundColor: context.cardColor,
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.validate().isNotEmpty)
            titleWidget(title: languages.postJobTitle, detail: data.title.validate(), detailTextStyle: boldTextStyle(),),
          if (data.description.validate().isNotEmpty)
            titleWidget(title: "City", detail: data.description.validate(), detailTextStyle: primaryTextStyle(), isReadMore: true,
            ),
          if (data.voiceNote.validate().isNotEmpty)
          Text(languages.voiceNote, style: secondaryTextStyle()).paddingOnly(top: 0, bottom: 4),
          if (data.voiceNote.validate().isNotEmpty)
          PostVoicePlayer(path: data.voiceNote.validate(),
            callback: (v) {
              setState(() {
                print("audioPath: " + v);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget postJobServiceWidget({required List<ServiceData> serviceList}) {
    if (serviceList.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        Text(languages.lblServices, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingOnly(left: 16, right: 16),
        AnimatedListView(
          itemCount: serviceList.length,
          padding: EdgeInsets.all(8),
          shrinkWrap: true,
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
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
                      Text(data.name.validate(), style: boldTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(" ", style: secondaryTextStyle()),
                      if ((data.categoryName.validate().isNotEmpty))
                        Text('(${data.categoryName.validate()})',
                          style: secondaryTextStyle(size: 10),
                        ).expand(),
                    ],
                    // multi images video batavana
                  ),
                  8.height,
                  if ((data.description.validate().isNotEmpty))
                    Text(data.description.validate(), style: secondaryTextStyle()),
                  8.height,
                  HorizontalList(
                    itemCount: data.imageAttachments.validate().length,
                    itemBuilder: (context, i) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          if (data.imageAttachments.validate()[i].contains("http"))
                            GestureDetector(
                                onTap: () {
                                  ZoomImageScreen(galleryImages: data.imageAttachments.validate(), index: i).launch(context, pageRouteAnimation: PageRouteAnimation.Fade, duration: 200.milliseconds);
                                },
                                child:  CachedImageWidget(url: data.imageAttachments.validate()[i], placeHolderImage: selectVideo, height: 50, width: 50, fit: BoxFit.cover)).cornerRadiusWithClipRRect(defaultRadius),
                        ],
                      );
                    },
                  )
                      .paddingBottom(16)
                      .visible(data.imageAttachments.validate().isNotEmpty),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget providerWidget(List<BidderData> bidderList) {
    try {
      if (bidderList.any((element) => element.providerId == appStore.userId)) {
        BidderData? bidderData = bidderList
            .firstWhere((element) => element.providerId == appStore.userId);
        UserData? user = bidderData.provider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(languages.myBid, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            16.height,
            Container(
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Row(
                children: [
                  CachedImageWidget(url: user!.profileImage.validate(), fit: BoxFit.cover, height: 60, width: 60, circle: true),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Marquee(
                        directionMarguee: DirectionMarguee.oneDirection,
                        child: Text(user.displayName.validate(), style: boldTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      4.height,
                      PriceWidget(price: bidderData.price.validate()),
                    ],
                  ).expand(),
                ],
              ),
            ),
            16.height,
          ],
        ).paddingOnly(left: 16, right: 16);
      }
    } catch (e) {
      print(e);
    }

    return Offstage();
  }

  Widget customerWidget(PostJobData? postJobData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(languages.lblAboutCustomer, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Row(
            children: [
              CachedImageWidget(url: postJobData!.customerProfile.validate(), fit: BoxFit.cover, height: 60, width: 60, circle: true),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Marquee(
                    directionMarguee: DirectionMarguee.oneDirection,
                    child: Text(postJobData.customerName.validate(), style: boldTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  4.height,
                  Text(postJobData.status.validate() ==
                              JOB_REQUEST_STATUS_ACCEPTED
                          ? languages.jobPrice
                          : languages.estimatedPrice,
                      style: secondaryTextStyle()),
                  4.height,
                  PriceWidget(price: postJobData.price.validate()),
                ],
              ).expand(),
            ],
          ),
        ),
        16.height,
      ],
    ).paddingOnly(left: 16, right: 16);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: '${widget.postJobData.title}',
      body: Stack(
        children: [
          SnapHelperWidget<PostJobDetailResponse>(
            future: future,
            initialData: cachedPostJobList
                .firstWhere(
                    (element) =>
                        element?.$1 == widget.postJobData.id.validate(),
                    orElse: () => null)
                ?.$2,
            onSuccess: (data) {
              return Stack(
                children: [
                  AnimatedScrollView(
                    padding: EdgeInsets.only(bottom: 60),
                    physics: AlwaysScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                    onSwipeRefresh: () async {
                      page = 1;
                      init();
                      setState(() {});
                      return await 2.seconds.delay;
                    },
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          postJobDetailWidget(data: data.postRequestDetail!).paddingAll(16),
                          customerWidget(data.postRequestDetail!),
                          providerWidget(data.bidderData.validate()),
                          postJobServiceWidget(serviceList: data.postRequestDetail!.service.validate()),
                          24.height,
                        ],
                      ),
                    ],
                  ),
                  if (data.postRequestDetail!.canBid.validate())
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: AppButton(
                        child: Text(languages.bid, style: boldTextStyle(color: white)),
                        color: context.primaryColor,
                        width: context.width(),
                        onTap: () async {
                          bool? res = await showInDialog(
                            context,
                            contentPadding: EdgeInsets.zero,
                            hideSoftKeyboard: true,
                            backgroundColor: context.cardColor,
                            builder: (_) =>
                                BidPriceDialog(data: widget.postJobData),
                          );

                          if (res ?? false) {
                            init();
                            setState(() {});
                          }
                        },
                      ),
                    ),
                ],
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: languages.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);
                  init();
                  setState(() {});
                },
              );
            },
            loadingWidget: LoaderWidget(),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
    );
  }
}
