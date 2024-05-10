import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:user/service/notifi_service.dart';
import '../components/OTPDialog.dart';
import '../utils/Extensions/context_extension.dart';
import '../model/LoginResponse.dart';
import '../utils/Extensions/StringExtensions.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../main.dart';
import '../../network/RestApis.dart';
import '../../screens/ForgotPasswordScreen.dart';
import '../../service/AuthService1.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../service/AuthService.dart';
import '../utils/images.dart';
import 'SignUpScreen.dart';
import 'DashBoardScreen.dart';
import 'package:permission_handler/permission_handler.dart';

class SignInScreen extends StatefulWidget {
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserModel userModel = UserModel();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthServices authService = AuthServices();
  GoogleAuthServices googleAuthService = GoogleAuthServices();
  TextEditingController phoneController = TextEditingController();

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();

  bool mIsCheck = true;
  bool isAcceptedTc = false;
  String? privacyPolicy;
  String? termsCondition;
  String countryCode = defaultCountryCode;
  // NotificationService2 notificationService = NotificationService2();

  @override
  void initState() {
    passController.text = "0000000000";
    super.initState();
    _requestNotificationPermission();
    init();
  }

  voirNotifTest() {
    NotificationService2().showNotification(
      id: 0,
      body: "Bienvenue !",
      title: "Gobabi",
    );
  }

  void init() async {
    appSetting();
    print("player id ${sharedPref.getString(PLAYER_ID)}");
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId().then((value) {
        print("player id enregistrement ");
      });
    } else {
      print("player id not empty");
    }

    mIsCheck = sharedPref.getBool(REMEMBER_ME) ?? false;
    if (mIsCheck) {
      emailController.text = sharedPref.getString(USER_EMAIL).validate();
      passController.text = sharedPref.getString(USER_PASSWORD).validate();
    }
  }

  Future<void> _requestNotificationPermission() async {
    print("DEMANDE NOTIF");
    final status = await Permission.notification.request();
    if (status == PermissionStatus.denied) {
      // L'utilisateur a refusé les notifications, vous pouvez afficher un message
      print("NOTIFICATION REFUSEE");
    }
  }

  Future<void> logIn() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      appStore.setLoading(true);

      Map req = {
        //  'email': emailController.text.trim(),
        'contact_number': countryCode + phoneController.text.trim(),
        'password': passController.text.trim(),
        "player_id": sharedPref.getString(PLAYER_ID).validate(),
        'user_type': RIDER,
      };
      print('reqs $req ');
      await logInOtpApi(req).then((value) {
        //userModel = value.data!;
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (_) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(16),
              content: OTPDialog(
                isCodeSent: true,
                phoneNumber: countryCode + phoneController.text.trim(),
              ),
            );
          },
        );
        // auth
        //     .signInWithEmailAndPassword(
        //         email: emailController.text, password: passController.text)
        //     .then((value) {
        //   sharedPref.setString(UID, value.user!.uid);
        //   updateProfileUid();
        //   appStore.setLoading(false);
        //   launchScreen(context, DashBoardScreen(),
        //       isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        // }).catchError((e) {
        //   if (e.toString().contains('user-not-found')) {
        //     authService.signUpWithEmailPassword(
        //       context,
        //       mobileNumber: userModel.contactNumber,
        //       email: userModel.email,
        //       fName: userModel.firstName,
        //       lName: userModel.lastName,
        //       userName: userModel.username,
        //       password: passController.text,
        //       userType: RIDER,
        //     );
        //     print('51');
        //   } else {
        //     launchScreen(context, DashBoardScreen(),
        //         isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        //   }
        //   log(e.toString());
        // });
        appStore.setLoading(false);
      }).catchError((error) {
        appStore.isLoading = false;
        toast(error.toString());
        //  toast(error.toString());
      });
    }
  }

  Future<void> appSetting() async {
    await getAppSettingApi().then((value) {
      if (value.privacyPolicyModel!.value != null)
        privacyPolicy = value.privacyPolicyModel!.value;
      if (value.termsCondition!.value != null)
        termsCondition = value.termsCondition!.value;
    }).catchError((error) {
      log(error.toString());
    });
  }

  void googleSignIn() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    await googleAuthService.signInWithGoogle(context).then((value) async {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
      print(e.toString());
    });
  }

  appleLoginApi() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await appleLogIn().then((value) {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
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
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: context.statusBarHeight + 16),
                  InkWell(
                    onTap: () => voirNotifTest(),
                    child: ClipRRect(
                        borderRadius: radius(50),
                        child:
                            Image.asset(ic_app_logo, width: 100, height: 100)),
                  ),
                  SizedBox(height: 16),
                  Text(language.welcome, style: boldTextStyle(size: 22)),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: '${language.signContinue} ',
                            style: primaryTextStyle(size: 14)),
                        TextSpan(text: '🚗', style: primaryTextStyle(size: 20)),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  AppTextField(
                    controller: phoneController,
                    textFieldType: TextFieldType.PHONE,
                    focus: phoneFocus,
                    nextFocus: passFocus,
                    decoration: inputDecoration(
                      context,
                      label: language.phoneNumber,
                      prefixIcon: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CountryCodePicker(
                              padding: EdgeInsets.zero,
                              initialSelection: countryCode,
                              showCountryOnly: false,
                              dialogSize: Size(
                                  MediaQuery.of(context).size.width - 60,
                                  MediaQuery.of(context).size.height * 0.6),
                              showFlag: true,
                              showFlagDialog: true,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                              textStyle: primaryTextStyle(),
                              dialogBackgroundColor:
                                  Theme.of(context).cardColor,
                              barrierColor: Colors.black12,
                              dialogTextStyle: primaryTextStyle(),
                              searchDecoration: InputDecoration(
                                iconColor: Theme.of(context).dividerColor,
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).dividerColor)),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: primaryColor)),
                              ),
                              searchStyle: primaryTextStyle(),
                              onInit: (c) {
                                countryCode = c!.dialCode!;
                              },
                              onChanged: (c) {
                                countryCode = c.dialCode!;
                              },
                            ),
                            VerticalDivider(
                                color: Colors.grey.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value!.trim().isEmpty) return errorThisFieldRequired;
                      return null;
                    },
                  ),
                  //    AppTextField(
                  //      controller: emailController,
                  //      nextFocus: passFocus,
                  //      autoFocus: false,
                  //      textFieldType: TextFieldType.EMAIL,
                  //      keyboardType: TextInputType.emailAddress,
                  //      errorThisFieldRequired: language.thisFieldRequired,
                  //     decoration: inputDecoration(context, label: language.email),
                  //   ),
                  SizedBox(height: 16),
                  // AppTextField(
                  //   controller: passController,
                  //   focus: passFocus,
                  //   autoFocus: false,
                  //   textFieldType: TextFieldType.PASSWORD,
                  //   errorThisFieldRequired: language.thisFieldRequired,
                  //   decoration:
                  //       inputDecoration(context, label: language.password),
                  // ),
                  SizedBox(height: 16),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Row(
                  //       children: [
                  //         SizedBox(
                  //           height: 18.0,
                  //           width: 18.0,
                  //           child: Checkbox(
                  //             materialTapTargetSize:
                  //                 MaterialTapTargetSize.shrinkWrap,
                  //             activeColor: primaryColor,
                  //             value: mIsCheck,
                  //             shape: RoundedRectangleBorder(
                  //                 borderRadius: radius(4)),
                  //             onChanged: (v) async {
                  //               mIsCheck = v!;
                  //               if (!mIsCheck) {
                  //                 sharedPref.remove(REMEMBER_ME);
                  //               } else {
                  //                 await sharedPref.setBool(
                  //                     REMEMBER_ME, mIsCheck);
                  //                 await sharedPref.setString(
                  //                     USER_EMAIL, emailController.text);
                  //                 await sharedPref.setString(
                  //                     USER_PASSWORD, passController.text);
                  //               }
                  //
                  //               setState(() {});
                  //             },
                  //           ),
                  //         ),
                  //         SizedBox(width: 8),
                  //         inkWellWidget(
                  //           onTap: () async {
                  //             mIsCheck = !mIsCheck;
                  //             setState(() {});
                  //           },
                  //           child: Text(language.rememberMe,
                  //               style: primaryTextStyle(size: 14)),
                  //         ),
                  //       ],
                  //     ),
                  //     // inkWellWidget(
                  //     //   onTap: () {
                  //     //     launchScreen(context, ForgotPasswordScreen(),
                  //     //         pageRouteAnimation:
                  //     //             PageRouteAnimation.SlideBottomTop);
                  //     //   },
                  //     //   child: Text(language.forgotPassword,
                  //     //       style: primaryTextStyle()),
                  //     // ),
                  //   ],
                  // ),
                  SizedBox(height: 45),
                  /* Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: Checkbox(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          activeColor: primaryColor,
                          value: isAcceptedTc,
                          shape:
                              RoundedRectangleBorder(borderRadius: radius(4)),
                          onChanged: (v) async {
                            print(v);
                            isAcceptedTc = v!;
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                  text: language.iAgreeToThe + " ",
                                  style: primaryTextStyle(size: 40)),
                              TextSpan(
                                text:
                                    language.termsConditions.splitBefore(' &'),
                                style: boldTextStyle(
                                    color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (termsCondition != null &&
                                        termsCondition!.isNotEmpty) {
                                      launchScreen(
                                          context,
                                          TermsConditionScreen(
                                              title: language.termsConditions,
                                              subtitle: termsCondition),
                                          pageRouteAnimation:
                                              PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                              TextSpan(
                                  text: ' & ',
                                  style: primaryTextStyle(size: 12)),
                              TextSpan(
                                text: language.privacyPolicy,
                                style: boldTextStyle(
                                    color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (privacyPolicy != null &&
                                        privacyPolicy!.isNotEmpty) {
                                      launchScreen(
                                          context,
                                          TermsConditionScreen(
                                              title: language.privacyPolicy,
                                              subtitle: privacyPolicy),
                                          pageRouteAnimation:
                                              PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                      )
                    ],
                  ),*/
                  SizedBox(height: 16),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: language.logIn,
                    onTap: () async {
                      logIn();
                    },
                  ),
                  SizedBox(height: 30),
                  //    socialWidget(),
                  AppButtonWidget(
                    color: Colors.orange,
                    width: MediaQuery.of(context).size.width,
                    text: language.signUp,
                    onTap: () async {
                      // hideKeyboard(context);
                      launchScreen(
                          context,
                          SignUpScreen(
                              privacyPolicyUrl: privacyPolicy,
                              termsConditionUrl: termsCondition));
                    },
                  ),
                  SizedBox(height: 50),
                  Center(
                    child: Text(
                      "1.8.3",
                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    ),
                  )
                ],
              ),
            ),
          ),
          Observer(
            builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Text(language.donHaveAnAccount, style: primaryTextStyle()),
          //       SizedBox(width: 8),
          //       inkWellWidget(
          //         onTap: () {
          //           hideKeyboard(context);
          //           launchScreen(
          //               context,
          //               SignUpScreen(
          //                   privacyPolicyUrl: privacyPolicy,
          //                   termsConditionUrl: termsCondition));
          //         },
          //         child: Text(language.signUp, style: boldTextStyle()),
          //       ),
          //     ],
          //   ),
          // ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  /* Widget socialWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Divider(color: dividerColor)),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Text(language.orLogInWith, style: primaryTextStyle()),
              ),
              Expanded(child: Divider(color: dividerColor)),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inkWellWidget(
              onTap: () async {
                googleSignIn();
              },
              child: socialWidgetComponent(img: ic_google),
            ),
            SizedBox(width: 12),
            inkWellWidget(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(16),
                      content: OTPDialog(),
                    );
                  },
                );
                appStore.setLoading(false);
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                    borderRadius: radius(defaultRadius)),
                child: Image.network(
                    'https://cdn-icons-png.flaticon.com/128/8034/8034759.png',
                    fit: BoxFit.cover,
                    height: 30,
                    width: 30),
              ),
            ),
            if (Platform.isIOS) SizedBox(width: 12),
            if (Platform.isIOS)
              inkWellWidget(
                onTap: () async {
                  appleLoginApi();
                },
                child: socialWidgetComponent(img: ic_apple),
              ),
          ],
        ),
      ],
    );
  }*/

  /* Widget socialWidgetComponent({required String img}) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: radius(defaultRadius)),
      child: Image.asset(img, fit: BoxFit.cover, height: 30, width: 30),
    );
  }*/
}
