import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/book_post_job_request_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/bidder_item_component.dart';
import 'package:booking_system_flutter/screens/jobRequest/post_voice_player.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../../utils/common.dart';
import '../zoom_image_screen.dart';

class MyPostDetailScreen extends StatefulWidget {
  final int postRequestId;
  final PostJobData? postJobData;
  final VoidCallback callback;

  MyPostDetailScreen(
      {required this.postRequestId, this.postJobData, required this.callback});

  @override
  _MyPostDetailScreenState createState() => _MyPostDetailScreenState();
}

class _MyPostDetailScreenState extends State<MyPostDetailScreen> {
  Future<PostJobDetailResponse>? future;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    LiveStream().on(LIVESTREAM_UPDATE_BIDER, (p0) {
      init();
      setState(() {});
    });

    init();
  }

  void init() async {
    future = getPostJobDetail(
        {PostJob.postRequestId: widget.postRequestId.validate()});
  }

  Widget titleWidget(
      {required String title,
      required String detail,
      bool isReadMore = false,
      required TextStyle detailTextStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.validate(), style: secondaryTextStyle()),
        4.height,
        if (isReadMore)
          ReadMoreText(
            detail,
            style: detailTextStyle,
            colorClickableText: context.primaryColor,
          )
        else
          Text(detail.validate(), style: boldTextStyle(size: 12)),
        20.height,
      ],
    );
  }

  Widget postJobDetailWidget({required PostJobData data}) {
    return Container(
      padding: EdgeInsets.all(16),
      width: context.width(),
      decoration: boxDecorationWithRoundedCorners(
          backgroundColor: context.cardColor,
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.validate().isNotEmpty)
            titleWidget(
              title: language.postJobTitle,
              detail: data.title.validate(),
              detailTextStyle: boldTextStyle(),
            ),
          if (data.description.validate().isNotEmpty)
            titleWidget(
              title: 'City',
              detail: data.description.validate(),
              detailTextStyle: primaryTextStyle(),
              isReadMore: true,
            ),
          Text(
              data.status.validate() == JOB_REQUEST_STATUS_ASSIGNED
                  ? language.jobPrice
                  : language.estimatedPrice,
              style: secondaryTextStyle()),
          4.height,
          PriceWidget(
            price: data.status.validate() == JOB_REQUEST_STATUS_ASSIGNED
                ? data.jobPrice.validate()
                : data.price.validate(),
            isHourlyService: false,
            color: textPrimaryColorGlobal,
            isFreeService: false,
            size: 14,
          ),
          if (data.jobVoiceNote!.isNotEmpty)
            Text(language.voiceNote, style: secondaryTextStyle())
                .paddingOnly(top: 16, bottom: 4),
          if (data.jobVoiceNote!.isNotEmpty)
            PostVoicePlayer(
              path: data.jobVoiceNote.validate(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.services, style: boldTextStyle(size: LABEL_TEXT_SIZE))
            .paddingOnly(left: 16, right: 16),
        8.height,
        AnimatedListView(
          itemCount: serviceList.length,
          padding: EdgeInsets.all(8),
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(data.name.validate(),
                          style: boldTextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      // Text(" ", style: secondaryTextStyle()),
                      // if ((data.categoryName.validate().isNotEmpty))
                      //   Text('(${data.categoryName.validate()})',
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
                    itemCount: data.attachments.validate().length,
                    itemBuilder: (context, i) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          if (data.attachments.validate()[i].contains("http"))
                            GestureDetector(
                                    onTap: () {
                                      ZoomImageScreen(
                                              galleryImages:
                                                  data.attachments.validate(),
                                              index: i)
                                          .launch(context,
                                              pageRouteAnimation:
                                                  PageRouteAnimation.Fade,
                                              duration: 200.milliseconds);
                                    },
                                    child: CachedImageWidget(
                                        url: data.attachments.validate()[i],
                                        placeHolderImage: videoThumb,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover))
                                .cornerRadiusWithClipRRect(defaultRadius),
                        ],
                      );
                    },
                  )
                      .paddingBottom(16)
                      .visible(data.attachments.validate() .isNotEmpty),
                ],
              ),
              // Row(
              //   children: [
              //     InkWell(
              //       onTap: (){(data.attachments!.first.isImage) ?
              //       ZoomImageScreen(galleryImages: [data.attachments!.first], index: 0).launch(context) : viewFiles(data.attachments!.first);},
              //       child: CachedImageWidget(
              //         url: data.attachments.validate().isNotEmpty
              //             ? data.attachments!.first.validate()
              //             : "",
              //         fit: BoxFit.cover,
              //         height: 50,
              //         width: 50,
              //         radius: defaultRadius,
              //       ),
              //      ),
              //     16.width,
              //     Text(data.name.validate(),
              //             style: primaryTextStyle(),
              //             maxLines: 2,
              //             overflow: TextOverflow.ellipsis)
              //         .expand(),
              //   ],
              // ),
            );
          },
        ),
      ],
    );
  }

  Widget bidderWidget(List<BidderData> bidderList,
      {required PostJobDetailResponse postJobDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.bidder,
          list: bidderList,
          onTap: () {
            //
          },
        ).paddingSymmetric(horizontal: 16),
        AnimatedListView(
          itemCount: bidderList.length > 4
              ? bidderList.take(4).length
              : bidderList.length,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            return BidderItemComponent(
              data: bidderList[i],
              postRequestId: widget.postRequestId.validate(),
              postJobData: postJobDetailResponse.postRequestDetail!,
              postJobDetailResponse: postJobDetailResponse,
            );
          },
        ),
      ],
    );
  }

  Widget providerWidget(List<BidderData> bidderList, num? providerId) {
    try {
      BidderData? bidderData =
          bidderList.firstWhere((element) => element.providerId == providerId);
      UserData? user = bidderData.provider;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Text(language.assignedProvider,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          InkWell(
            onTap: () {
              ProviderInfoScreen(providerId: user.id.validate())
                  .launch(context);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedImageWidget(
                        url: user!.profileImage.validate(),
                        fit: BoxFit.cover,
                        height: 60,
                        width: 60,
                        circle: true,
                      ),
                      8.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Marquee(
                                directionMarguee: DirectionMarguee.oneDirection,
                                child: Text(
                                  user.displayName.validate(),
                                  style: boldTextStyle(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ).expand(),
                            ],
                          ),
                          4.height,
                          if (user.email.validate().isNotEmpty)
                            Marquee(
                              directionMarguee: DirectionMarguee.oneDirection,
                              child: Text(
                                user.email.validate(),
                                style: primaryTextStyle(size: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          6.height,
                          if (user.providersServiceRating != null)
                            DisabledRatingBarWidget(
                                rating: user.providersServiceRating.validate(),
                                size: 14),
                        ],
                      ).expand(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ).paddingOnly(left: 16, right: 16);
    } catch (e) {
      log(e);
      return Offstage();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_UPDATE_BIDER);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myPostDetail,
      child: SnapHelperWidget<PostJobDetailResponse>(
        future: future,
        onSuccess: (data) {
          return Stack(
            children: [
              AnimatedScrollView(
                padding: EdgeInsets.only(bottom: 60),
                physics: AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  postJobDetailWidget(data: data.postRequestDetail!)
                      .paddingAll(16),
                  if (data.postRequestDetail!.service.validate().isNotEmpty)
                    postJobServiceWidget(
                        serviceList:
                            data.postRequestDetail!.service.validate()),
                  if (data.postRequestDetail!.providerId != null)
                    providerWidget(
                      data.biderData.validate(),
                      data.postRequestDetail!.providerId.validate(),
                    ),
                  16.height,
                  if (data.biderData.validate().isNotEmpty)
                    bidderWidget(data.biderData.validate(),
                        postJobDetailResponse: data),
                ],
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
              ),
              if (data.postRequestDetail!.status.validate() ==
                  JOB_REQUEST_STATUS_ASSIGNED)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AppButton(
                    child: Text(language.bookTheService,
                        style: boldTextStyle(color: white)),
                    color: context.primaryColor,
                    width: context.width(),
                    onTap: () async {
                      BookPostJobRequestScreen(
                        postJobDetailResponse: data,
                        providerId:
                            data.postRequestDetail!.providerId.validate(),
                        jobPrice: data.postRequestDetail!.jobPrice.validate(),
                      ).launch(context);
                    },
                  ),
                ),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading))
            ],
          );
        },
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
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
    );
  }
}
