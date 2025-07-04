import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/wallet_history_list_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/wallet/shimmer/wallet_history_shimmer.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/empty_error_state_widget.dart';
import '../../components/price_widget.dart';
import '../../utils/app_configuration.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';

class WalletHistoryScreen extends StatefulWidget {
  @override
  WalletHistoryScreenState createState() => WalletHistoryScreenState();
}

class WalletHistoryScreenState extends State<WalletHistoryScreen> {
  Future<List<WalletHistory>>? future;
  List<WalletHistory> walletHistoryList = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    future = getWalletHistory(
      page: page,
      list: walletHistoryList,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblWalletHistory,
      body: SnapHelperWidget<List<WalletHistory>>(
        future: future,
        initialData: cachedWalletList,
        onSuccess: (snap) {
          return AnimatedListView(
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            slideConfiguration: SlideConfiguration(duration: 400.milliseconds, delay: 50.milliseconds),
            padding: EdgeInsets.all(8),
            itemCount: snap.length,
            itemBuilder: (BuildContext context, index) {
              WalletHistory data = snap[index];

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: EdgeInsets.all(8),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: context.dividerColor),
                  backgroundColor: context.scaffoldBackgroundColor,
                ),
                width: context.width(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.activityMessage.validate(), style: boldTextStyle()),
                        8.height,
                        Text(formatDate(data.datetime.validate(), format: DATE_FORMAT_2), style: secondaryTextStyle()),
                      ],
                    ).flexible(),
                    Text(
                      '${isCurrencyPositionLeft ? appConfigurationStore.currencySymbol : ''}${snap[index].activityData!.creditDebitAmount.validate().toStringAsFixed(appConfigurationStore.priceDecimalPoint)}${isCurrencyPositionRight ? appConfigurationStore.currencySymbol : ''}',
                      style: boldTextStyle(color: snap[index].activityData!.transactionType!.toLowerCase().contains('debit') ? Colors.redAccent : Colors.green),
                    ),
                  ],
                ),
              );
            },
            onSwipeRefresh: () async {
              page = 1;

              init();
              setState(() {});

              return await 2.seconds.delay;
            },
            onNextPage: () {
              if (!isLastPage) {
                page++;
                appStore.setLoading(true);

                init();
                setState(() {});
              }
            },
            emptyWidget: NoDataWidget(
              title: languages.noWalletHistoryTitle,
              subTitle: languages.noWalletHistorySubTitle,
              imageWidget: EmptyStateWidget(),
            ),
          );
        },
        loadingWidget: WalletHistoryShimmer(),
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
    );
  }
}
