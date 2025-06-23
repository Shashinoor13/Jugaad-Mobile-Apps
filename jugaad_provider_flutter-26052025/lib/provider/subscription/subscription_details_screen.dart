import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/plan_request_model.dart';
import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/payment/payment_screen.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionDetailsScreenState createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  Future<ProviderSubscriptionModel>? future;

  ProviderSubscriptionModel? selectedPricingPlan;

  int currentSelectedPlan = -1;
  int page = 1;

  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getSubscriptionDetails();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblCurrentPlan,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SnapHelperWidget<ProviderSubscriptionModel>(
            future: future,
            loadingWidget: LoaderWidget(),
            onSuccess: (data) {
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  data.id != null
                      ? AnimatedContainer(
                          duration: 500.milliseconds,
                          margin: EdgeInsets.all(8),
                          width: context.width(),
                          padding: EdgeInsets.all(4),
                          child: Column(
                            children: [
                              if (data.planLimitation != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: boxDecorationWithRoundedCorners(
                                        backgroundColor: context.cardColor,
                                        borderRadius: radius(),
                                      ),
                                      padding: EdgeInsets.all(16),
                                      width: context.width(),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('\n' + languages.lblCurrentPlan,
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              Text(
                                                  appStore.planTitle
                                                      .validate()
                                                      .capitalizeFirstLetter(),
                                                  style: boldTextStyle()),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Image.asset(
                                                  data.isVerifiedPlan!
                                                      ? pricing_plan_accept
                                                      : pricing_plan_reject,
                                                  width: 12,
                                                  height: 12),
                                              8.width,
                                              Flexible(
                                                  child: RichTextWidget(
                                                list: [
                                                  TextSpan(
                                                      text: 'E-Home Verified Provider',
                                                      style: secondaryTextStyle(size: 10)),
                                                ],
                                              )),
                                            ],
                                          ),
                                          8.height,
                                          Divider(thickness: 1.5, color: context.dividerColor),
                                          8.height,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(languages.hintDuration,
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              Text(
                                                  '${data.duration}-${data.type.validate().capitalizeFirstLetter()}',
                                                  style: boldTextStyle()),
                                            ],
                                          ),
                                          8.height,
                                          Divider(thickness: 1.5, color: context.dividerColor),
                                          8.height,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(languages.lblValidTill,
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              Text(
                                                formatDate(appStore.planEndDate.validate(),
                                                    format: DATE_FORMAT_2),
                                                style: boldTextStyle(),
                                              ),
                                            ],
                                          ),
                                          8.height,
                                          Divider(thickness: 1.5, color: context.dividerColor),
                                          8.height,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(languages.lblServices,
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              RichTextWidget(
                                                list: [
                                                  TextSpan(
                                                      text: data.remainingService! >= 0
                                                          ? '${data.remainingService} '
                                                          : languages.unlimited,
                                                      style: boldTextStyle()),
                                                  TextSpan(
                                                      text: data.remainingService! >= 0
                                                          ? ' left'
                                                          : '',
                                                      style: secondaryTextStyle()),
                                                ],
                                              )
                                            ],
                                          ),
                                          8.height,
                                          Divider(thickness: 1.5, color: context.dividerColor),
                                          8.height,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Quotations',
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              RichTextWidget(
                                                list: [
                                                  TextSpan(
                                                      text: data.remainingQuotation! >= 0
                                                          ? '${data.remainingQuotation} '
                                                          : languages.unlimited,
                                                      style: boldTextStyle()),
                                                  TextSpan(
                                                      text: data.remainingQuotation! >= 0
                                                          ? ' left'
                                                          : '',
                                                      style: secondaryTextStyle()),
                                                ],
                                              )
                                            ],
                                          ),
                                          8.height,
                                          Divider(thickness: 1.5, color: context.dividerColor),
                                          8.height,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Service Men',
                                                  style: secondaryTextStyle(
                                                      size: 14,
                                                      color: appStore.isDarkMode
                                                          ? white
                                                          : appTextSecondaryColor)),
                                              RichTextWidget(
                                                list: [
                                                  TextSpan(
                                                      text: data.remainingHandyman! >= 0
                                                          ? '${data.remainingHandyman} '
                                                          : languages.unlimited,
                                                      style: boldTextStyle()),
                                                  TextSpan(
                                                      text: data.remainingHandyman! >= 0
                                                          ? ' left'
                                                          : '',
                                                      style: secondaryTextStyle()),
                                                ],
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                            ],
                          ))
                      : NoDataWidget(
                          title: languages.noSubscriptionPlan,
                          imageWidget: EmptyStateWidget(),
                        ),
                  96.height,
                ],
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
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
          ),
          Observer(builder: (_) => LoaderWidget().center().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
