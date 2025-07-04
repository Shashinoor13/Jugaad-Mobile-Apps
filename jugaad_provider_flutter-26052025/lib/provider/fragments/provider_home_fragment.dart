import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/dashboard_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/components/chart_component.dart';
import 'package:handyman_provider_flutter/provider/components/handyman_list_component.dart';
import 'package:handyman_provider_flutter/provider/components/handyman_recently_online_component.dart';
import 'package:handyman_provider_flutter/provider/components/job_list_component.dart';
import 'package:handyman_provider_flutter/provider/components/services_list_component.dart';
import 'package:handyman_provider_flutter/provider/components/total_component.dart';
import 'package:handyman_provider_flutter/provider/fragments/shimmer/provider_dashboard_shimmer.dart';
import 'package:handyman_provider_flutter/provider/subscription/pricing_plan_screen.dart';
import 'package:handyman_provider_flutter/screens/cash_management/component/today_cash_component.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../auth/auth_user_services.dart';
import '../../components/app_widgets.dart';
import '../../components/empty_error_state_widget.dart';
import '../../networks/network_utils.dart';
import '../../utils/model_keys.dart';
import '../components/upcoming_booking_component.dart';

class ProviderHomeFragment extends StatefulWidget {
  @override
  _ProviderHomeFragmentState createState() => _ProviderHomeFragmentState();
}

class _ProviderHomeFragmentState extends State<ProviderHomeFragment> {
  int page = 1;

  int currentIndex = 0;

  late Future<DashboardResponse> future;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = providerDashboard().whenComplete(() {
      setState(() {});
    });

    refreshToken();
  }

  Widget _buildHeaderWidget(DashboardResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text("${languages.lblHello}, ${appStore.userFullName}",
                style: boldTextStyle(size: 16))
            .paddingLeft(16),
        8.height,
        Text(languages.lblWelcomeBack, style: secondaryTextStyle(size: 14))
            .paddingLeft(16),
        16.height,
      ],
    );
  }

  Widget planBanner(DashboardResponse data) {
    if (data.isPlanExpired.validate()) {
      return subSubscriptionPlanWidget(
        planBgColor:
            appStore.isDarkMode ? context.cardColor : Colors.red.shade50,
        planTitle: languages.lblPlanExpired,
        planSubtitle: languages.lblPlanSubTitle,
        planButtonTxt: languages.btnTxtBuyNow,
        btnColor: Colors.red,
        onTap: () {
          PricingPlanScreen().launch(context);
        },
      );
    } else if (data.userNeverPurchasedPlan.validate()) {
      return subSubscriptionPlanWidget(
        planBgColor:
            appStore.isDarkMode ? context.cardColor : Colors.red.shade50,
        planTitle: languages.lblChooseYourPlan,
        planSubtitle: languages.lblRenewSubTitle,
        planButtonTxt: languages.btnTxtBuyNow,
        btnColor: Colors.red,
        onTap: () {
          PricingPlanScreen().launch(context);
        },
      );
    } else if (data.isPlanAboutToExpire.validate()) {
      int days = getRemainingPlanDays();

      if (days != 0 && days <= PLAN_REMAINING_DAYS) {
        return subSubscriptionPlanWidget(
          planBgColor:
              appStore.isDarkMode ? context.cardColor : Colors.orange.shade50,
          planTitle: languages.lblReminder,
          planSubtitle: languages.planAboutToExpire(days),
          planButtonTxt: languages.lblRenew,
          btnColor: Colors.orange,
          onTap: () {
            PricingPlanScreen().launch(context);
          },
        );
      } else {
        return Offstage();
      }
    } else {
      return Offstage();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<DashboardResponse>(
            initialData: cachedProviderDashboardResponse,
            future: future,
            builder: (context, snap) {
              if (snap.hasData) {
                return AnimatedScrollView(
                  padding: EdgeInsets.only(bottom: 16),
                  physics: AlwaysScrollableScrollPhysics(),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  children: [
                    if (appStore.earningTypeSubscription)
                      planBanner(snap.data!),
                    _buildHeaderWidget(snap.data!),
                    TodayCashComponent(
                        todayCashAmount: snap.data!.todayCashAmount.validate()),
                    TotalComponent(snap: snap.data!),
                    ChartComponent(),
                    JobListComponent(list: snap.data!.myPostJobData.validate())
                        .paddingOnly(left: 16, right: 16, top: 8),
                    UpcomingBookingComponent(
                        bookingData: snap.data!.upcomingBookings.validate()),
                    ServiceListComponent(list: snap.data!.service.validate()),
                    HandymanListComponent(list: snap.data!.handyman.validate()),
                    HandymanRecentlyOnlineComponent(
                        images: snap.data!.onlineHandyman.validate()),
                  ],
                  onSwipeRefresh: () async {
                    page = 1;
                    appStore.setLoading(true);

                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                );
              }

              return snapWidgetHelper(
                snap,
                loadingWidget: ProviderDashboardShimmer(),
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
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
    );
  }

  Future<void> refreshToken() async {
    print('Refreshing...');
    if (appStore.userStatus == 0) {
      Map req = {
        UserKeys.contactNumber: getStringAsync(USERNAME),
        UserKeys.password: getStringAsync(USER_PASSWORD),
        UserKeys.playerId: appStore.playerId,
      };

      return await loginUser(req).then((value) async {
        await appStore.setToken(value.data!.apiToken.validate());
        saveDataToPreference(context,
            userData: value.data!, onRedirectionClick: () {});
      }).catchError((e) {
        throw e;
      });
    }
  }
}
