import 'dart:convert';

import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/colors.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/configs.dart';
import '../components/back_widget.dart';
import '../components/base_scaffold_body.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController numberController = TextEditingController();

  Country selectedCountry = defaultCountry();

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() => init());
  }

  Future<void> init() async {
    appStore.setLoading(false);
  }

  //region Methods
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryFilter: ['IN', 'NP'],
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      showPhoneCode:
          true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountry = country;
        log(jsonEncode(selectedCountry.toJson()));
        setState(() {});
      },
    );
  }

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      appStore.setLoading(true);

      toast('sendingOTP');

      await authService
          .loginWithOTP(context,
              phoneNumber: numberController.text.trim(),
              countryCode: selectedCountry.phoneCode,
              countryISOCode: selectedCountry.countryCode)
          .then((value) {
        print("Ater Login with OTP");
        print(value);
        //
      }).catchError(
        (e) {
          appStore.setLoading(false);
          print("Error in authService");
          toast(e.toString(), print: true);
        },
      );
    }
  }

  // endregion

  Widget _buildMainWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter Phone Number!', style: boldTextStyle()),
        16.height,
        Form(
          key: formKey,
          child: AppTextField(
            controller: numberController,
            textFieldType: TextFieldType.PHONE,
            decoration: inputDecoration(context).copyWith(
              prefixText: '+${selectedCountry.phoneCode} ',
              hintText: '${'Example'}: ${selectedCountry.example}',
              hintStyle: secondaryTextStyle(),
            ),
            autoFocus: true,
            onFieldSubmitted: (s) {
              sendOTP();
            },
          ),
        ),
        30.height,
        AppButton(
          onTap: () {
            sendOTP();
          },
          text: 'Send Otp',
          color: primaryColor,
          textColor: Colors.white,
          width: context.width(),
        ),
        16.height,
        AppButton(
          onTap: () {
            changeCountry();
          },
          text: 'Change Country',
          textStyle: boldTextStyle(),
          width: context.width(),
        ),
      ],
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.scaffoldBackgroundColor,
        leading: Navigator.of(context).canPop()
            ? BackWidget(color: context.iconColor)
            : null,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                appStore.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarColor: context.scaffoldBackgroundColor),
      ),
      body: Body(
        child: Container(
          padding: EdgeInsets.all(16),
          child: _buildMainWidget(),
        ),
      ),
    );
  }
}
