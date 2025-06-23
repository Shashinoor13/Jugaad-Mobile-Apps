import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../networks/rest_apis.dart';
import '../utils/app_configuration.dart';

class WalletBalanceComponent extends StatefulWidget {
  const WalletBalanceComponent({Key? key}) : super(key: key);

  @override
  State<WalletBalanceComponent> createState() => _WalletBalanceComponentState();
}

class _WalletBalanceComponentState extends State<WalletBalanceComponent> {
  Future<num>? futureWalletBalance;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  void loadBalance() {
    futureWalletBalance = getUserWalletBalance();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Wallet Balance', style: primaryTextStyle(size: 25)),
        1.height,
        SnapHelperWidget(
          future: futureWalletBalance,
          onSuccess: (balance) => Text(
            '${isCurrencyPositionLeft ? appConfigurationStore.currencySymbol : ''}${balance.toStringAsFixed(appConfigurationStore.priceDecimalPoint)}${isCurrencyPositionRight ? appConfigurationStore.currencySymbol : ''}',
            style: boldTextStyle(color: Colors.green, size: 36),
          ),
          useConnectionStateForLoader: true,
          errorBuilder: (p0) {
            return IconButton(
              onPressed: () {
                loadBalance();
                setState(() {});
              },
              icon: Icon(Icons.refresh_rounded),
            );
          },
        ),
      ],
    ));
  }
}
