
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/constant.dart';
import '../components/app_widgets.dart';
import '../components/back_widget.dart';
import '../utils/configs.dart';

class OtpDialogComponent extends StatefulWidget {
  final Function(String? otpCode) onTap;

  OtpDialogComponent({required this.onTap});

  @override
  State<OtpDialogComponent> createState() => _OtpDialogComponentState();
}

class _OtpDialogComponentState extends State<OtpDialogComponent> {
  @override
  Widget build(BuildContext context) {
    String otpCode = '';

    void submitOtp() {
      if (otpCode.validate().isNotEmpty) {
        if (otpCode.validate().length >= 6) {
          hideKeyboard(context);
          appStore.setLoading(true);
          widget.onTap.call(otpCode);
        } else {
          toast('Please Enter Valid OTP!');
        }
      } else {
        toast('Please Enter Valid OTP!');
      }
    }

    return Scaffold(
      appBar: appBarWidget(
        'Confirm OTP',
        backWidget: BackWidget(color: context.iconColor),
        textSize: APP_BAR_TEXT_SIZE,
        elevation: 0,
        color: context.scaffoldBackgroundColor,
        systemUiOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark, statusBarColor: context.scaffoldBackgroundColor),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                32.height,
                OTPTextField(
                  pinLength: 6,
                  textStyle: primaryTextStyle(),
                  decoration: inputDecoration(context).copyWith(
                    counter: Offstage(),
                  ),
                  onChanged: (s) {
                    // otpCode = s;
                    // log(otpCode);
                  },
                  onCompleted: (pin) {
                    otpCode = pin;
                    submitOtp();
                  },
                ).fit(),
                30.height,
                AppButton(
                  onTap: () {
                    submitOtp();
                  },
                  text: 'Confirm',
                  color: primaryColor,
                  textColor: Colors.white,
                  width: context.width(),
                ),
              ],
            ),
          ),
          Observer(builder: (context) {
            return LoaderWidget().visible(appStore.isLoading);
          }),
        ],
      ),
    );
  }
}
