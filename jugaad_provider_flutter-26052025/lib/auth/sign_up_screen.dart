import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/auth/auth_user_services.dart';
import 'package:handyman_provider_flutter/auth/sign_in_screen.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_type_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart' as launch;

bool isNew = false;

class SignUpScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? countryCode;
  final bool isOTPLogin;
  final String? uid;

  SignUpScreen(
      {Key? key,
      this.phoneNumber,
      this.isOTPLogin = false,
      this.countryCode,
      this.uid})
      : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController designationCont = TextEditingController();
  TextEditingController referralCodeCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode userTypeFocus = FocusNode();
  FocusNode typeFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode designationFocus = FocusNode();
  FocusNode referralCodeFocus = FocusNode();

  String? selectedUserTypeValue = USER_TYPE_PROVIDER;

  List<UserTypeData> userTypeList = [
    UserTypeData(name: languages.selectUserType, id: -1)
  ];
  UserTypeData? selectedUserTypeData;

  bool isAcceptedTc = false;
  Country selectedCountry = defaultCountry();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.phoneNumber != null) {
      selectedCountry = Country.parse(
          widget.countryCode.validate(value: selectedCountry.countryCode));

      mobileCont.text =
          widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
      // passwordCont.text = widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
      userNameCont.text =
          widget.phoneNumber != null ? widget.phoneNumber.toString() : "";
    }
    getUserType(type: selectedUserTypeValue!).then((value) {
      userTypeList = value.userTypeData.validate();
      setState(() {});
    }).catchError((e) {
      userTypeList = [
        UserTypeData(name: languages.selectUserType, id: -1)
      ];
      log(e.toString());
    });
  }

  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryFilter: ['IN','NP'],
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: languages.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      showPhoneCode: true,
      // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountry = country;
        setState(() {});
      },
    );
  }

  //region New Logic
  String buildMobileNumber() {
    return '${selectedCountry.phoneCode}-${mobileCont.text.trim()}';
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  //region Widgets

  Widget _buildTopWidget() {
    return Column(
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: boxDecorationWithRoundedCorners(
              boxShape: BoxShape.circle, backgroundColor: primaryColor),
          child: Image.asset(profile, height: 45, width: 45, color: white),
        ),
        16.height,
        Text(languages.lblSignupTitle, style: boldTextStyle(size: 18)),
        16.height,
        Text(
          languages.lblSignupSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32),
        32.height,
      ],
    );
  }

  Widget _buildFormWidget() {
    return Column(
      children: [
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: fNameCont,
          focus: fNameFocus,
          nextFocus: lNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration:
              inputDecoration(context, hint: languages.hintFirstNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: lNameCont,
          focus: lNameFocus,
          nextFocus: userNameFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintLastNameTxt),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        if (!widget.isOTPLogin) 16.height,
        Visibility(
          visible: widget.isOTPLogin.validate() ? false : true,
          child: AppTextField(
            textFieldType: TextFieldType.USERNAME,
            controller: userNameCont,
            focus: userNameFocus,
            nextFocus: emailFocus,
            readOnly: widget.isOTPLogin.validate() ? widget.isOTPLogin : false,
            errorThisFieldRequired: languages.hintRequired,
            decoration:
                inputDecoration(context, hint: languages.hintUserNameTxt),
            suffix: profile.iconImage(size: 10).paddingAll(14),
          ),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.EMAIL_ENHANCED,
          controller: emailCont,
          focus: emailFocus,
          nextFocus: mobileFocus,
          errorThisFieldRequired: languages.hintRequired,
          decoration:
              inputDecoration(context, hint: languages.hintEmailAddressTxt),
          suffix: ic_message.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        AppTextField(
          textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
          controller: mobileCont,
          focus: mobileFocus,
          readOnly: widget.isOTPLogin.validate() ? widget.isOTPLogin : false,
          isValidationRequired: false,
          buildCounter: (_,
              {required int currentLength,
              required bool isFocused,
              required int? maxLength}) {
            return Visibility(
                visible: widget.isOTPLogin.validate() ? false : true,
                child: TextButton(
                  child: Text(languages.lblChangeCountry,
                      style: primaryTextStyle(size: 12)),
                  onPressed: () {
                    if (!widget.isOTPLogin) changeCountry();
                  },
                ));
          },
          errorThisFieldRequired: languages.hintRequired,
          nextFocus: passwordFocus,
          decoration: inputDecoration(context,
                  hint: '${languages.hintContactNumberTxt}')
              .copyWith(
            hintText: '${languages.lblExample}: ${selectedCountry.example}',
            hintStyle: secondaryTextStyle(),
            prefixText: '+${selectedCountry.phoneCode} ',
          ),
          maxLength: 15,
          suffix: calling.iconImage(size: 10).paddingAll(14),
        ),
        8.height,
        AppTextField(
          textFieldType: TextFieldType.USERNAME,
          controller: designationCont,
          isValidationRequired: false,
          focus: designationFocus,
          nextFocus: passwordFocus,
          decoration: inputDecoration(context, hint: languages.lblDesignation),
          suffix: profile.iconImage(size: 10).paddingAll(14),
        ),
        16.height,
        DropdownButtonFormField<String>(
          items: [
            DropdownMenuItem(
              child: Text(languages.provider, style: primaryTextStyle()),
              value: USER_TYPE_PROVIDER,
            ),
            DropdownMenuItem(
              child: Text(languages.handyman, style: primaryTextStyle()),
              value: USER_TYPE_HANDYMAN,
            ),
          ],
          focusNode: userTypeFocus,
          dropdownColor: context.cardColor,
          decoration: inputDecoration(context, hint: languages.userRole),
          value: selectedUserTypeValue,
          validator: (value) {
            if (value == null) return errorThisFieldRequired;
            return null;
          },
          onChanged: (c) {
            hideKeyboard(context);
            selectedUserTypeValue = c.validate();

            userTypeList.clear();
            selectedUserTypeData = null;

            getUserType(type: selectedUserTypeValue!).then((value) {
              userTypeList = value.userTypeData.validate();
              setState(() {});
            }).catchError((e) {
              userTypeList = [
                UserTypeData(name: languages.selectUserType, id: -1)
              ];
              log(e.toString());
            });
          },
        ),
        16.height,
        DropdownButtonFormField<UserTypeData>(
          onChanged: (UserTypeData? val) {
            selectedUserTypeData = val;
            setState(() {});
          },
          validator: selectedUserTypeData == null
              ? (c) {
                  if (c == null) return errorThisFieldRequired;
                  return null;
                }
              : null,
          value: selectedUserTypeData,
          dropdownColor: context.cardColor,
          decoration:
              inputDecoration(context, hint: languages.lblSelectUserType),
          items: List.generate(
            userTypeList.length,
            (index) {
              UserTypeData data = userTypeList[index];

              return DropdownMenuItem<UserTypeData>(
                child: Text(data.name.toString(), style: primaryTextStyle()),
                value: data,
              );
            },
          ),
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.PASSWORD,
          controller: passwordCont,
          focus: passwordFocus,
          nextFocus: referralCodeFocus,
          suffixPasswordVisibleWidget:
              ic_show.iconImage(size: 10).paddingAll(14),
          suffixPasswordInvisibleWidget:
              ic_hide.iconImage(size: 10).paddingAll(14),
          errorThisFieldRequired: languages.hintRequired,
          decoration: inputDecoration(context, hint: languages.hintPassword),
          onFieldSubmitted: (s) {
            saveUser();
          },
        ),
        16.height,
        AppTextField(
          textFieldType: TextFieldType.NAME,
          controller: referralCodeCont,
          focus: referralCodeFocus,
          isValidationRequired: false,
          decoration: inputDecoration(context, hint: 'Referral Code'),
          suffix: ic_ticket.iconImage(size: 10).paddingAll(14),
        ),
        20.height,
        _buildTcAcceptWidget(),
        8.height,
        AppButton(
          text: languages.lblSignup,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            saveUser();
          },
        ),
      ],
    );
  }

  Widget _buildFooterWidget() {
    return Column(
      children: [
        16.height,
        RichTextWidget(
          list: [
            TextSpan(
                text: "${languages.alreadyHaveAccountTxt}? ",
                style: secondaryTextStyle()),
            TextSpan(
              text: languages.signIn,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  finish(context);
                },
            ),
          ],
        ),
        30.height,
      ],
    );
  }

  Widget _buildTcAcceptWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SelectedItemWidget(isSelected: isAcceptedTc).onTap(() async {
          isAcceptedTc = !isAcceptedTc;
          setState(() {});
        }),
        16.width,
        RichTextWidget(
          list: [
            TextSpan(
                text: '${languages.lblIAgree} ', style: secondaryTextStyle()),
            TextSpan(
              text: languages.lblTermsOfService,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launch.launchUrl(Uri.parse(TERMS_CONDITION_URL));
                },
            ),
            TextSpan(text: ' & ', style: secondaryTextStyle()),
            TextSpan(
              text: languages.lblPrivacyPolicy,
              style: boldTextStyle(color: primaryColor),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launch.launchUrl(Uri.parse(PRIVACY_POLICY_URL));
                },
            ),
          ],
        ).flexible(flex: 2),
      ],
    ).paddingAll(16);
  }

  //endregion

  //region Methods
  void saveUser() async {
    if (formKey.currentState!.validate()) {
      if (selectedUserTypeData != null && selectedUserTypeData!.id == -1) {
        return toast(languages.pleaseSelectUserType);
      }

      formKey.currentState!.save();

      hideKeyboard(context);

      if (isAcceptedTc) {
        appStore.setLoading(true);

        var request = {
          UserKeys.firstName: fNameCont.text.trim(),
          UserKeys.lastName: lNameCont.text.trim(),
          UserKeys.userName: userNameCont.text.trim(),
          UserKeys.userType: selectedUserTypeValue,
          UserKeys.login_type: selectedUserTypeValue,
          UserKeys.contactNumber: buildMobileNumber(),
          UserKeys.email: emailCont.text.trim(),
          UserKeys.password: passwordCont.text.trim(),
          UserKeys.designation: designationCont.text.trim(),
          UserKeys.referralCode: referralCodeCont.text,
          UserKeys.status: 0,
        };

        if (selectedUserTypeValue == USER_TYPE_PROVIDER) {
          request.putIfAbsent(UserKeys.providerTypeId,
              () => selectedUserTypeData!.id.toString());
        } else {
          request.putIfAbsent(UserKeys.handymanTypeId,
              () => selectedUserTypeData!.id.toString());
        }

        log(request);

        await registerUser(request).then((userRegisterData) async {
          appStore.setLoading(false);
          userRegisterData.data!.password = passwordCont.text.trim();
          userRegisterData.data!.userType = selectedUserTypeValue;

          if (userRegisterData.message.validate().contains(
              'Email Verification link has been sent to your email')) {
            if (!widget.isOTPLogin) toast(userRegisterData.message.validate());
            push(SignInScreen(),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
          } else
            saveDataToPreference(context, userData: userRegisterData.data!,
                onRedirectionClick: () {
              toast(languages.lblLoginAgain);

              push(SignInScreen(),
                  isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
            });
        }).catchError((e) {
          toast(e.toString(), print: true);
          appStore.setLoading(false);
        });
      } else {
        toast(languages.lblTermCondition);
        appStore.setLoading(false);
      }
    }
  }

  //endregion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        "",
        elevation: 0,
        color: context.scaffoldBackgroundColor,
        systemUiOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                getStatusBrightness(val: appStore.isDarkMode),
            statusBarColor: context.scaffoldBackgroundColor),
      ),
      body: SizedBox(
        width: context.width(),
        child: Stack(
          children: [
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTopWidget(),
                    _buildFormWidget(),
                    _buildFooterWidget(),
                  ],
                ),
              ),
            ),
            Observer(
                builder: (context) =>
                    LoaderWidget().center().visible(appStore.isLoading))
          ],
        ),
      ),
    );
  }
}
