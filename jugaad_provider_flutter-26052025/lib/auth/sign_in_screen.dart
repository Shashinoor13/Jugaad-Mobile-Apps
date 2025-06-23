import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/auth/auth_user_services.dart';
import 'package:handyman_provider_flutter/auth/forgot_password_dialog.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/selected_item_widget.dart';
import 'package:handyman_provider_flutter/handyman/handyman_dashboard_screen.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import 'otp_login_screen.dart';

class SignInScreen extends StatefulWidget {
  final bool isRegeneratingToken;

  SignInScreen({this.isRegeneratingToken = false});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Text Field Controller
  TextEditingController mobileCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();

  /// FocusNodes
  FocusNode mobileFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isRemember = true;
  Country selectedCountry = defaultCountry();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRemember = getBoolAsync(IS_REMEMBERED, defaultValue: true);
    if (isRemember) {
      mobileCont.text = getStringAsync(USERNAME);
      passwordCont.text = getStringAsync(USER_PASSWORD);
    }
    if (widget.isRegeneratingToken) {
      mobileCont.text = appStore.userName;
      passwordCont.text = getStringAsync(USER_PASSWORD);

      _handleLogin(isDirectLogin: true);
    }
  }

  //region Widgets
  Widget _buildTopWidget() {
    return Column(
      children: [
        32.height,
        Text(languages.lblLoginTitle, style: boldTextStyle(size: 18)).center(),
        16.height,
        Text(
          languages.lblLoginSubtitle,
          style: secondaryTextStyle(size: 14),
          textAlign: TextAlign.center,
        ).paddingSymmetric(horizontal: 32).center(),
        64.height,
      ],
    );
  }

  Widget _buildFormWidget() {
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.commit,
      child: Column(
        children: [
          AppTextField(
            textFieldType: TextFieldType.PHONE,
            controller: mobileCont,
            focus: mobileFocus,
            nextFocus: passwordFocus,
            errorThisFieldRequired: languages.hintRequired,
            decoration: inputDecoration(context, hint: languages.hintEmailAddressTxt),
            suffix: ic_message.iconImage(size: 10).paddingAll(14),
            autoFillHints: [AutofillHints.telephoneNumber],
          ),
          16.height,
          AppTextField(
            textFieldType: TextFieldType.PASSWORD,
            controller: passwordCont,
            focus: passwordFocus,
            errorThisFieldRequired: languages.hintRequired,
            suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(14),
            suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10).paddingAll(14),
            errorMinimumPasswordLength: "${languages.errorPasswordLength} $passwordLengthGlobal",
            decoration: inputDecoration(context, hint: languages.hintPassword),
            autoFillHints: [AutofillHints.password],
            onFieldSubmitted: (s) {
              _handleLogin();
            },
          ),
          8.height,
        ],
      ),
    );
  }

  Widget _buildForgotRememberWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                2.width,
                SelectedItemWidget(isSelected: isRemember).onTap(() async {
                  await setValue(IS_REMEMBERED, isRemember);
                  isRemember = !isRemember;
                  setState(() {});
                }),
                TextButton(
                  onPressed: () async {
                    await setValue(IS_REMEMBERED, isRemember);
                    isRemember = !isRemember;
                    setState(() {});
                  },
                  child: Text(languages.rememberMe, style: secondaryTextStyle()),
                ),
              ],
            ),
            TextButton(
              child: Text(
                languages.forgotPassword,
                style: boldTextStyle(color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
            ).flexible()
          ],
        ),
        32.height,
      ],
    );
  }

  Widget _buildButtonWidget() {
    return Column(
      children: [
        AppButton(
          text: languages.signIn,
          height: 40,
          color: primaryColor,
          textStyle: boldTextStyle(color: white),
          width: context.width() - context.navigationBarHeight,
          onTap: () {
            _handleLogin();
          },
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(languages.doNotHaveAccount, style: secondaryTextStyle()),
            TextButton(
              onPressed: () {
                // SignUpScreen().launch(context);
                // otpSignIn;
                OTPLoginScreen().launch(context);
              },
              child: Text(
                languages.signUp,
                style: boldTextStyle(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          ],
        ),
        24.height,
        //   AppButton(
        //     text: '',
        //     color: context.cardColor,
        //     padding: EdgeInsets.all(8),
        //     textStyle: boldTextStyle(),
        //     width: context.width() - context.navigationBarHeight,
        //     child: Row(
        //       children: [
        //         Container(
        //           padding: EdgeInsets.all(8),
        //           decoration: boxDecorationWithRoundedCorners(
        //             backgroundColor: primaryColor.withOpacity(0.1),
        //             boxShape: BoxShape.circle,
        //           ),
        //           child: ic_fill_profile.iconImage(size: 18, color: primaryColor).paddingAll(4),
        //         ),
        //         Text('Sign In With Mobile Number', style: boldTextStyle(size: 12), textAlign: TextAlign.center).expand(),
        //       ],
        //     ),
        //     onTap: otpSignIn,
        //   ),
        // if (appConfigurationStore.otpLoginStatus) 16.height,
      ],
    );
  }

  //endregion

  //region Methods
  void _handleLogin({bool isDirectLogin = false}) {
    if (isDirectLogin) {
      _handleLoginUsers();
    } else {
      hideKeyboard(context);
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        _handleLoginUsers();
      }
    }
  }
  void otpSignIn() async {
    hideKeyboard(context);

    OTPLoginScreen().launch(context);
  }
  void _handleLoginUsers() async {
    hideKeyboard(context);
    Map<String, dynamic> request = {
      'contact_number': mobileCont.text.trim(),
      'password': passwordCont.text.trim(),
      'player_id': getStringAsync(PLAYERID),
    };

    log(request);

    await loginCurrentUsers(context, isSocialLogin:false, req: request).then((value) async {
      if (isRemember) {
        setValue(USERNAME, mobileCont.text);
        setValue(USER_PASSWORD, passwordCont.text);
        setValue(IS_REMEMBERED, isRemember);
      }

      saveDataToPreference(context, userData: value, onRedirectionClick: () {
        redirectWidget(res: value);
      });
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void redirectWidget({required UserData res}) async {
    TextInput.finishAutofillContext();

    // if (res.status.validate() == 1) {
      await appStore.setLoggedIn(true);
      await appStore.setToken(res.apiToken.validate());
      appStore.setTester(res.email == DEFAULT_PROVIDER_EMAIL || res.email == DEFAULT_HANDYMAN_EMAIL);

      if (res.userType.validate().trim() == USER_TYPE_PROVIDER) {
        ProviderDashboardScreen(index: 0).launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else if (res.userType.validate().trim() == USER_TYPE_HANDYMAN) {
        HandymanDashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        toast(languages.cantLogin, print: true);
      }
    // } else {
    //   appStore.setLoading(false);
    //   toast(languages.lblWaitForAcceptReq);
    // }
  }

  //endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        "",
        elevation: 0,
        showBack: false,
        color: context.scaffoldBackgroundColor,
        systemUiOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: getStatusBrightness(val: appStore.isDarkMode), statusBarColor: context.scaffoldBackgroundColor),
      ),
      body: SizedBox(
        width: context.width(),
        child: Stack(
          children: [
            Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopWidget(),
                    AutofillGroup(
                      onDisposeAction: AutofillContextAction.commit,
                      child: Column(
                        children: [
                          // AppTextField(
                          //   textFieldType: TextFieldType.EMAIL_ENHANCED,
                          //   controller: mobileCont,
                          //   focus: emailFocus,
                          //   nextFocus: passwordFocus,
                          //   isValidationRequired:false,
                          //   errorThisFieldRequired: languages.hintRequired,
                          //   decoration: inputDecoration(context, hint: languages.hintEmailAddressTxt),
                          //   suffix: ic_message.iconImage(size: 10).paddingAll(14),
                          //   autoFillHints: [AutofillHints.email],
                          // ),
                          AppTextField(
                            textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                            controller: mobileCont,
                            focus: mobileFocus,
                            isValidationRequired: false,
                            buildCounter: (_,
                                {required int currentLength,
                                  required bool isFocused,
                                  required int? maxLength}) {
                              return Visibility(
                                  visible: false,
                                  child: TextButton(
                                    child: Text(languages.lblChangeCountry,
                                        style: primaryTextStyle(size: 12)),
                                    onPressed: () {
                                      changeCountry();
                                    },
                                  ));
                            },
                            errorThisFieldRequired: languages.hintRequired,
                            nextFocus: passwordFocus,
                            decoration: inputDecoration(context,
                                hint: '${languages.hintContactNumberTxt}')
                                .copyWith(
                              // hintText: '${languages.lblExample}: ${selectedCountry.example}',
                              // hintText: '${selectedCountry.example}',
                              // hintStyle: secondaryTextStyle(),
                              // prefixText: '+${selectedCountry.phoneCode} ',
                            ),
                            maxLength: 10,
                            suffix: calling.iconImage(size: 10).paddingAll(14),
                          ),
                          16.height,
                          AppTextField(
                            textFieldType: TextFieldType.PASSWORD,
                            controller: passwordCont,
                            focus: passwordFocus,
                            errorThisFieldRequired: languages.hintRequired,
                            suffixPasswordVisibleWidget: ic_show.iconImage(size: 10).paddingAll(14),
                            suffixPasswordInvisibleWidget: ic_hide.iconImage(size: 10).paddingAll(14),
                            errorMinimumPasswordLength: "${languages.errorPasswordLength} $passwordLengthGlobal",
                            decoration: inputDecoration(context, hint: languages.hintPassword),
                            autoFillHints: [AutofillHints.password],
                            onFieldSubmitted: (s) {
                              _handleLogin();
                            },
                          ),
                          8.height,
                        ],
                      ),
                    ),
                    _buildForgotRememberWidget(),
                    _buildButtonWidget(),
                    16.height,
                    // SnapHelperWidget<bool>(
                    //     future: isIqonicProduct,
                    //     onSuccess: (data) {
                    //       if (data) {
                    //         return UserDemoModeScreen(
                    //           onChanged: (email, password) {
                    //             if (email.isNotEmpty && password.isNotEmpty) {
                    //               emailCont.text = email;
                    //               passwordCont.text = password;
                    //             } else {
                    //               emailCont.clear();
                    //               passwordCont.clear();
                    //             }
                    //           },
                    //         );
                    //       }
                    //       return Offstage();
                    //     }),
                  ],
                ),
              ),
            ),
            Observer(
              builder: (_) => LoaderWidget().center().visible(appStore.isLoading),
            ),
          ],
        ),
      ),
    );
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
}
