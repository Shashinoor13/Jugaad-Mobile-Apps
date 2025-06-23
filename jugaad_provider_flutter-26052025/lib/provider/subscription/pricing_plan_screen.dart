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

class PricingPlanScreen extends StatefulWidget {
  const PricingPlanScreen({Key? key}) : super(key: key);

  @override
  _PricingPlanScreenState createState() => _PricingPlanScreenState();
}

class _PricingPlanScreenState extends State<PricingPlanScreen> {
  Future<List<ProviderSubscriptionModel>>? future;

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
    future = getPricingPlanList();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblPricingPlan,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SnapHelperWidget<List<ProviderSubscriptionModel>>(
            future: future,
            loadingWidget: LoaderWidget(),
            onSuccess: (res) {
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  42.height,
                  Text(languages.lblSelectPlan, style: boldTextStyle(size: 16)).center(),
                  8.height,
                  Text(languages.selectPlanSubTitle, style: secondaryTextStyle()).center(),
                  24.height,
                  AnimatedListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 90, top: 8, right: 8, left: 8),
                    itemCount: res.length,
                    itemBuilder: (_, index) {
                      ProviderSubscriptionModel data = res[index];

                      return AnimatedContainer(
                        duration: 500.milliseconds,
                        decoration: boxDecorationWithRoundedCorners(
                          borderRadius: radius(),
                          backgroundColor: context.scaffoldBackgroundColor,
                          border:
                              Border.all(color: currentSelectedPlan == index ? primaryColor : context.dividerColor, width: 1.5),
                        ),
                        margin: EdgeInsets.all(8),
                        width: context.width(),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    currentSelectedPlan == index
                                        ? AnimatedContainer(
                                            duration: 500.milliseconds,
                                            decoration: BoxDecoration(
                                              color: context.primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            padding: EdgeInsets.all(2),
                                            child: Icon(Icons.check, color: Colors.white, size: 16),
                                          )
                                        : AnimatedContainer(
                                            duration: 500.milliseconds,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            padding: EdgeInsets.all(2),
                                            child: Icon(Icons.check, color: Colors.transparent, size: 16),
                                          ),
                                    16.width,
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('${data.identifier.capitalizeFirstLetter()}', style: boldTextStyle())
                                                .flexible(),
                                            if (data.trialPeriod.validate() != 0 && data.identifier == FREE)
                                              RichText(
                                                text: TextSpan(
                                                  text: ' ( ${languages.lblTrialFor} ',
                                                  style: secondaryTextStyle(),
                                                  children: <TextSpan>[
                                                    TextSpan(text: '${data.trialPeriod.validate()}', style: boldTextStyle()),
                                                    TextSpan(
                                                        text: '${data.duration}  ${languages.lblDays} )',
                                                        style: secondaryTextStyle()),
                                                  ],
                                                ),
                                              )
                                            else
                                              Text(' (${data.duration}-${data.type.validate().capitalizeFirstLetter()})',
                                                  style: primaryTextStyle()),
                                          ],
                                        ),
                                        8.height,
                                        Text(data.title.validate().capitalizeFirstLetter(), style: secondaryTextStyle()),
                                      ],
                                    ).expand(),
                                  ],
                                ).expand(),
                                if (data.plansVerifiedProviders != null)
                                  Container(
                                    decoration: BoxDecoration(color: context.primaryColor, borderRadius: radius()),
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Text(
                                      data.identifier == FREE
                                          ? '${languages.lblFreeTrial}'
                                          : isVerified
                                              ? (int.tryParse(data.plansVerifiedProviders!.verifiedProviderAmount!)! +
                                                      data.amount!)
                                                  .validate()
                                                  .toPriceFormat()
                                              : data.amount!.validate().toPriceFormat(),
                                      style: boldTextStyle(color: white, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                            if (data.planLimitation != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  16.height,
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
                                          children: [
                                            Image.asset(getPlanStatusImage(limitData: data.planLimitation!.service!),
                                                width: 14, height: 14),
                                            8.width,
                                            getPlanStatus(limitData: data.planLimitation!.service!, name: 'Services'),
                                          ],
                                        ),
                                        8.height,
                                        Row(
                                          children: [
                                            Image.asset(
                                                getPlanStatusImage(limitData: data.planLimitation!.quotationLimitation!),
                                                width: 14,
                                                height: 14),
                                            8.width,
                                            getPlanStatus(
                                                limitData: data.planLimitation!.quotationLimitation!,
                                                name: 'Quotation Limitation'),
                                          ],
                                        ),
                                        8.height,
                                        Row(
                                          children: [
                                            Image.asset(getPlanStatusImage(limitData: data.planLimitation!.handyman!),
                                                width: 14, height: 14),
                                            8.width,
                                            getPlanStatus(limitData: data.planLimitation!.handyman!, name: 'ServiceMan'),
                                          ],
                                        ),
                                        8.height,
                                        Row(
                                          children: [
                                            Image.asset(
                                                isVerified
                                                    ? getPlanStatusImage(limitData: data.planLimitation!.handyman!)
                                                    : pricing_plan_reject,
                                                width: 14,
                                                height: 14),
                                            8.width,
                                            Flexible(
                                                child: RichTextWidget(
                                              list: [
                                                TextSpan(text: 'E-Home Verified Provider', style: primaryTextStyle()),
                                                // TextSpan(text: ' for', style: primaryTextStyle()),
                                                // TextSpan(text: ' ${data.plansVerifiedProviders!.verifiedProviderDuration!}', style: boldTextStyle(color: primaryColor)),
                                                // TextSpan(text: ' ${data.plansVerifiedProviders!.verifiedProviderType!}', style: primaryTextStyle()),
                                              ],
                                            )),
                                          ],
                                        ),
                                        // Row(
                                        //   children: [
                                        //     Image.asset(getPlanStatusImage(limitData: data.planLimitation!.featuredService!), width: 14, height: 14),
                                        //     8.width,
                                        //     getPlanStatus(limitData: data.planLimitation!.featuredService!, name: 'Featured Services'),
                                        //   ],
                                        // )
                                      ],
                                    ),
                                  ),
                                  // 16.height,
                                  // if(selectedPricingPlan != null && selectedPricingPlan!.id == data.id && data.plansVerifiedProviders!=null)
                                  // Container(
                                  //   decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius()),
                                  //   padding: EdgeInsets.only(left: 4, right: 0),
                                  //   child: Theme(
                                  //       data: ThemeData(
                                  //         unselectedWidgetColor: appStore.isDarkMode ? context.dividerColor : context.iconColor,
                                  //       ),
                                  //       child: SwitchListTile(
                                  //         // checkboxShape: RoundedRectangleBorder(borderRadius: radius(16)),
                                  //         autofocus: false,
                                  //         activeColor: context.primaryColor,
                                  //         // checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
                                  //         value: isVerified,
                                  //         inactiveThumbColor: appStore.isDarkMode ? context.iconColor : context.iconColor,
                                  //         inactiveTrackColor: appStore.isDarkMode ? context.iconColor : context.dividerColor,
                                  //         controlAffinity: ListTileControlAffinity.leading,
                                  //         contentPadding: EdgeInsets.zero,
                                  //         shape: RoundedRectangleBorder(borderRadius: radius(), side: BorderSide(color: context.primaryColor)),
                                  //         title: RichTextWidget(
                                  //           list: [
                                  //             TextSpan(text: 'Add-on: E-home Verified Provider', style: primaryTextStyle()),
                                  //           ],
                                  //         ),
                                  //         subtitle:RichTextWidget(
                                  //           list: [
                                  //             TextSpan(text: int.tryParse(data.plansVerifiedProviders!.verifiedProviderAmount!).validate().toPriceFormat(), style: boldTextStyle(color: primaryColor)),
                                  //             TextSpan(text: ' for', style: primaryTextStyle()),
                                  //             TextSpan(text: ' ${data.plansVerifiedProviders!.verifiedProviderDuration!}', style: boldTextStyle(color: primaryColor)),
                                  //             TextSpan(text: ' ${data.plansVerifiedProviders!.verifiedProviderType!}', style: primaryTextStyle()),
                                  //           ],
                                  //         ),
                                  //         onChanged: (bool? v) {
                                  //           isVerified = v.validate();
                                  //           setState(() {});
                                  //         },
                                  //       )),
                                  // ),
                                ],
                              )
                          ],
                        ).onTap(() {
                          selectedPricingPlan = data;
                          currentSelectedPlan = index;

                          setState(() {});
                        }),
                      );
                    },
                    emptyWidget: NoDataWidget(
                      title: languages.noSubscriptionPlan,
                      imageWidget: EmptyStateWidget(),
                    ),
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
          if (selectedPricingPlan != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor, borderRadius: radius(0)),
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Theme(
                    data: ThemeData(
                      unselectedWidgetColor: appStore.isDarkMode ? context.dividerColor : context.iconColor,
                    ),
                    child: Column(
                      children: [
                        16.height,
                        SwitchListTile(
                          // checkboxShape: RoundedRectangleBorder(borderRadius: radius(16)),
                          autofocus: false,
                          activeColor: context.primaryColor,
                          // checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
                          value: isVerified,
                          inactiveThumbColor: appStore.isDarkMode ? context.iconColor : context.iconColor,
                          inactiveTrackColor: appStore.isDarkMode ? context.dividerColor : context.dividerColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: radius(), side: BorderSide(color: context.primaryColor)),
                          title: RichTextWidget(
                            list: [
                              TextSpan(text: 'Add-on: E-home Verified Provider', style: boldTextStyle()),
                            ],
                          ),
                          onChanged: (bool? v) {
                            isVerified = v.validate();
                            setState(() {});
                          },
                        ),
                        16.height,
                        AppButton(
                          width: double.infinity,
                          child: Text(selectedPricingPlan!.identifier == FREE ? languages.lblProceed : languages.lblMakePayment,
                              style: boldTextStyle(color: white)),
                          color: primaryColor,
                          onTap: () async {
                            selectedPricingPlan!.isVerifiedPlan = isVerified;
                            if (selectedPricingPlan!.identifier == FREE) {
                              PlanRequestModel planRequestModel = PlanRequestModel()
                                ..amount = selectedPricingPlan!.amount
                                ..description = selectedPricingPlan!.description
                                ..duration = selectedPricingPlan!.duration
                                ..identifier = selectedPricingPlan!.identifier
                                ..otherTransactionDetail = ''
                                ..paymentStatus = PAID
                                ..paymentType = PAYMENT_METHOD_COD
                                ..planId = selectedPricingPlan!.id
                                ..planLimitation = selectedPricingPlan!.planLimitation
                                ..planType = selectedPricingPlan!.planType
                                ..title = selectedPricingPlan!.title
                                ..txnId = ''
                                ..type = selectedPricingPlan!.type
                                ..userId = appStore.userId;

                              log('Request : ${planRequestModel.toJson()}');
                              appStore.setLoading(true);

                              await saveSubscription(planRequestModel.toJson()).then((value) {
                                appStore.setLoading(false);
                                toast("${selectedPricingPlan!.title.validate()} ${languages.lblSuccessFullyActivated}");

                                push(ProviderDashboardScreen(index: 0),
                                    isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
                              }).catchError((e) {
                                appStore.setLoading(false);
                                log(e.toString());
                              });
                            } else {
                              PaymentScreen(selectedPricingPlan!).launch(context);
                            }
                          },
                        ),
                        16.height,
                      ],
                    )),
              ),
            ),
          Observer(builder: (_) => LoaderWidget().center().visible(appStore.isLoading)),
        ],
      ),
    );
  }

  Widget getPlanStatus({required LimitData limitData, required String name}) {
    if (limitData.isChecked == null) {
      return RichTextWidget(
        list: [
          TextSpan(text: '${languages.hintAdd} $name ${languages.unlimited}', style: primaryTextStyle()),
        ],
      );
    } else if (limitData.isChecked.validate() == 'on' && (limitData.limit == null || limitData.limit == "0")) {
      return RichTextWidget(
        list: [
          TextSpan(
              text: '${languages.hintAdd} $name ${languages.upTo} ',
              style: primaryTextStyle(decoration: TextDecoration.lineThrough)),
          TextSpan(text: '0', style: boldTextStyle(color: primaryColor, decoration: TextDecoration.lineThrough)),
        ],
      );
    } else {
      return RichTextWidget(
        list: [
          TextSpan(text: '${languages.hintAdd} $name ${languages.upTo} ', style: primaryTextStyle()),
          TextSpan(text: '${limitData.limit.validate()}', style: boldTextStyle(color: primaryColor)),
        ],
      );
    }
  }

  String getPlanStatusImage({required LimitData limitData}) {
    if (limitData.isChecked == null) {
      return pricing_plan_accept;
    } else if (limitData.isChecked.validate() == 'on' && (limitData.limit == null || limitData.limit == "0")) {
      return pricing_plan_reject;
    } else {
      return pricing_plan_accept;
    }
  }
}
