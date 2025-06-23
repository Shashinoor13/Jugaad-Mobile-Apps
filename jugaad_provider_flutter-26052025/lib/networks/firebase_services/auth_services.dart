import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../auth/auth_user_services.dart';
import '../../auth/opt_dialog_component.dart';
import '../../auth/sign_up_screen.dart';
import '../../handyman/handyman_dashboard_screen.dart';
import '../../provider/provider_dashboard_screen.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthService {
  //region Email

  Future<String> signUpWithEmailPassword(BuildContext context,
      {required UserData userData}) async {
    return await _auth
        .createUserWithEmailAndPassword(
            email: userData.email.validate(),
            password: DEFAULT_PASSWORD_FOR_FIREBASE)
        .then((userCredential) async {
      User currentUser = userCredential.user!;

      userData.uid = currentUser.uid.validate();
      userData.createdAt = Timestamp.now().toDate().toString();
      userData.updatedAt = Timestamp.now().toDate().toString();
      userData.playerId = getStringAsync(PLAYERID);

      log("Step 1 ${userData.toFirebaseJson()}");

      return await setRegisterData(userData: userData);
    }).catchError((e) {
      throw "User is Not Registered in Firebase";
    });
  }

  Future<String> setRegisterData({required UserData userData}) async {
    return await userService
        .addDocumentWithCustomId(
            userData.uid.validate(), userData.toFirebaseJson())
        .then((value) async {
      return value.id.validate();
    }).catchError((e) {
      throw false;
    });
  }

  Future<String> signInWithEmailPassword({required String email}) async {
    return await _auth
        .signInWithEmailAndPassword(
            email: email, password: DEFAULT_PASSWORD_FOR_FIREBASE)
        .then((value) async {
      return value.user!.uid.validate();
    }).catchError((e) async {
      appStore.setLoading(false);
      log(e.toString());
      FirebaseAuth.instance.currentUser?.delete();
      throw "User Not Found";
    });
  }
//endregion

//region Google OTP
  Future loginWithOTP(BuildContext context,
      {String phoneNumber = "",
      String? countryCode,
      String? countryISOCode}) async {
    log("PHONE NUMBER VERIFIED +$countryCode$phoneNumber");

    return await _auth.verifyPhoneNumber(
      phoneNumber: "+$countryCode$phoneNumber",
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        toast('Verified');
      },
      verificationFailed: (FirebaseAuthException e) {
        appStore.setLoading(false);
        if (e.code == 'invalid-phone-number') {
          toast('The Entered Code Is Invalid Please Try Again!', print: true);
        } else {
          toast(e.toString(), print: true);
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        toast('otp Code Is Sent To Your Mobile Number');

        appStore.setLoading(false);

        /// Opens a dialog when the code is sent to the user successfully.
        await OtpDialogComponent(
          onTap: (otpCode) async {
            if (otpCode != null) {
              AuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: otpCode);
              print(credential.signInMethod);
              await _auth
                  .signInWithCredential(credential)
                  .then((credentials) async {
                log("UID ${credentials.user!.uid}");
                toast('confirm OTP');
                appStore.setLoading(false);
                finish(context);
                SignUpScreen(
                        isOTPLogin: true,
                        phoneNumber: phoneNumber,
                        countryCode: countryISOCode,
                        uid: credentials.user!.uid.validate())
                    .launch(context);

                // Map<String, dynamic> request = {
                //   'username': phoneNumber,
                //   'password': phoneNumber,
                //   'player_id': getStringAsync(PLAYERID, defaultValue: ""),
                //   'login_type': LOGIN_TYPE_OTP,
                //   "uid": credentials.user!.uid.validate(),
                // };
                //
                // log("OTP REQUEST $request");
                //
                // await loginCurrentUsers(context, req: request, isSocialLogin: true).then((loginResponse) async {
                //   log("=============================== ${loginResponse.toJson()}");
                //
                //   if (loginResponse == null) {
                //     if (loginResponse.status == 0) {
                //       toast('contact Admin!');
                //     } else {
                //       loginResponse.uid = credentials.user!.uid.validate();
                //       saveDataToPreference(context, userData: loginResponse, onRedirectionClick: () {
                //         // DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
                //         if (loginResponse.userType.validate().trim() == USER_TYPE_PROVIDER) {
                //           ProviderDashboardScreen(index: 0).launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
                //         } else if (loginResponse.userType.validate().trim() == USER_TYPE_HANDYMAN) {
                //           HandymanDashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
                //         } else {
                //           toast(languages.cantLogin, print: true);
                //         }
                //       });
                //     }
                //   } else {
                //     toast('confirm OTP');
                //     appStore.setLoading(false);
                //     finish(context);
                //     SignUpScreen(isOTPLogin: true, phoneNumber: phoneNumber, countryCode: countryISOCode, uid: credentials.user!.uid.validate()).launch(context);
                //   }
                // }).catchError((e) {
                //   appStore.setLoading(false);
                //   toast(e.toString(), print: true);
                // });
              }).catchError((e) {
                if (e.code.toString() == 'invalid-verification-code') {
                  toast('the Entered Code Is Invalid Please Try Again!',
                      print: true);
                } else {
                  print(e.message.toString());
                  toast(e.message.toString(), print: true);
                }
                appStore.setLoading(false);
              });
            }
          },
        ).launch(context);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //
      },
    );
  }
}
