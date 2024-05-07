import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:user/screens/SignInScreen.dart';
import 'package:user/screens/otp/sign_in.dart';
import '../components/OTPDialog.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/StringExtensions.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import '../../service/AuthService1.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../network/RestApis.dart';
import '../utils/Constants.dart';
import '../utils/images.dart';
import 'TermsConditionScreen.dart';

class SignUpScreen extends StatefulWidget {
  final bool socialLogin;
  final String? userName;
  final bool isOtp;
  final String? countryCode;
  final String? privacyPolicyUrl;
  final String? termsConditionUrl;

  SignUpScreen(
      {this.socialLogin = false,
      this.userName,
      this.isOtp = false,
      this.countryCode,
      this.privacyPolicyUrl,
      this.termsConditionUrl});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthServices authService = AuthServices();

  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode confirmPass = FocusNode();

  bool mIsCheck = false;
  bool isAcceptedTc = false;
  bool shouldShowOTPDialog = true;

  String countryCode = defaultCountryCode;

  List<Map<String, dynamic>> publications = [];

  bool loadRegister = false;

  @override
  void initState() {
    passController.text = '12345678';
    confirmPassController.text = '12345678';
    super.initState();
    init();
  }

  void init() async {
    await saveOneSignalPlayerId().then((value) {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> register() async {
    setState(() {
      loadRegister = true;
    });
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);
      if (isAcceptedTc) {
        appStore.setLoading(true);

        Map<String, dynamic> req = {
          'first_name': firstController.text.trim(),
          'last_name': lastNameController.text.trim(),
          "user_type": "rider",
          "contact_number": '$countryCode${phoneController.text.trim()}',
          "email": phoneController.text.trim().toLowerCase() + "@gmail.com",
          "username": '$countryCode${phoneController.text.trim()}',
          'password':
              widget.socialLogin ? widget.userName : passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          if (widget.socialLogin) 'login_type': 'mobile',
        };
        // Effectue l'inscription
        await signUp2Api(req).then((value) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) {
              return AlertDialog(
                contentPadding: EdgeInsets.all(16),
                content: OTPDialog(
                  isCodeSent: true,
                  isClose: false,
                  phoneNumber: countryCode + phoneController.text.trim(),
                ),
              );
            },
          );
        }).catchError((onError) {
          appStore.setLoading(false);
          //  toast('$error');
          // Vérifiez si l'erreur contient "cancel"
          if (onError.toString().toLowerCase().contains("cancel")) {
            shouldShowOTPDialog = true;
          } else {
            shouldShowOTPDialog = false;
            toast('Le numéro existe déjà.');
            return;
          }
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  Future<void> vericationotpweb() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$DOMAIN_URL_API=liste_user_id&receiver=${countryCode.replaceAll('+', '')}${phoneController.text.trim()}'),
      );
      print(
          '$DOMAIN_URL_API=liste_user_id&receiver=${countryCode.replaceAll('+', '')}${phoneController.text.trim()}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
        if (jsonData['success'] == 'True') {
          setState(() {
            publications =
                List<Map<String, dynamic>>.from(jsonData['otp_validations']);
            print('id_otp: ${publications[0]['id_otp']}');
            print('receiver: ${publications[0]['receiver']}');
            print('id_users: ${publications[0]['id_users']}');
            print('otp: ${publications[0]['otp']}');
          });
        }
      } else {
        throw Exception('Failed to load publications');
      }
    } catch (e) {
      print('Error fetching publications: $e');
    }
  }

  Future<void> statutinactif() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$DOMAIN_URL_API=statut_inactive&contact_number=${countryCode.replaceAll('+', '+')}${phoneController.text.trim()}'),
      );
      print(
          '$DOMAIN_URL_API=statut_inactive&contact_number=${countryCode.replaceAll('+', '+')}${phoneController.text.trim()}');
      print('ok');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
        if (jsonData['success'] == 'True') {
          setState(() {
            publications =
                List<Map<String, dynamic>>.from(jsonData['otp_validations']);
            print('id_otp: ${publications[0]['id_otp']}');
            print('receiver: ${publications[0]['receiver']}');
            print('id_users: ${publications[0]['id_users']}');
            print('otp: ${publications[0]['otp']}');
          });
        }
      } else {
        throw Exception('Failed to load publications');
      }
    } catch (e) {
      print('Error fetching publications: $e');
    }
  }

  Future<void> statut_active() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$DOMAIN_URL_API=statut_inactive&contact_number=${countryCode.replaceAll('+', '+')}${phoneController.text.trim()}'),
      );
      print(
          '$DOMAIN_URL_API=statut_inactive&contact_number=${countryCode.replaceAll('+', '+')}${phoneController.text.trim()}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
        if (jsonData['success'] == 'True') {
          setState(() {
            publications =
                List<Map<String, dynamic>>.from(jsonData['otp_validations']);
            print('id_otp: ${publications[0]['id_otp']}');
            print('receiver: ${publications[0]['receiver']}');
            print('id_users: ${publications[0]['id_users']}');
            print('otp: ${publications[0]['otp']}');
          });
        }
      } else {
        throw Exception('Failed to load publications');
      }
    } catch (e) {
      print('Error fetching publications: $e');
    }
  }

  bool validateFields() {
    if (formKey.currentState!.validate()) {
      if (!isAcceptedTc) {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: context.statusBarHeight + 16),
                  ClipRRect(
                      borderRadius: radius(50),
                      child: Image.asset(ic_app_logo, width: 100, height: 100)),
                  SizedBox(height: 16),
                  Text(language.createAccount, style: boldTextStyle(size: 22)),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: 'Sign up to get started ',
                            style: primaryTextStyle(size: 14)),
                        TextSpan(text: '🚗', style: primaryTextStyle(size: 20)),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: firstController,
                          focus: firstNameFocus,
                          nextFocus: lastNameFocus,
                          autoFocus: false,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: errorThisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.firstName),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: AppTextField(
                          controller: lastNameController,
                          focus: lastNameFocus,
                          nextFocus: userNameFocus,
                          autoFocus: false,
                          textFieldType: TextFieldType.OTHER,
                          errorThisFieldRequired: errorThisFieldRequired,
                          decoration: inputDecoration(context,
                              label: language.lastName),
                        ),
                      ),
                    ],
                  ),
                  if (widget.socialLogin != true) SizedBox(height: 20),
                  if (widget.socialLogin != true)
                    /*     AppTextField(
                      controller: userNameController,
                      focus: userNameFocus,
                      nextFocus: emailFocus,
                      autoFocus: false,
                      textFieldType: TextFieldType.USERNAME,
                      errorThisFieldRequired: errorThisFieldRequired,
                      decoration:
                          inputDecoration(context, label: language.userName),
                    ),
                  SizedBox(height: 20),
                   AppTextField(
                    controller: emailController,
                    // focus: emailFocus,
                    nextFocus: phoneFocus,
                    //  autoFocus: false,
                    textFieldType: TextFieldType.EMAIL,
                    // keyboardType: TextInputType.emailAddress,
                    //  errorThisFieldRequired: errorThisFieldRequired,
                    decoration: inputDecoration(context, label: language.email),
                  ),*/
                    //if (widget.socialLogin != true) SizedBox(height: 20),
                    if (widget.socialLogin != true)
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
                                            color: Theme.of(context)
                                                .dividerColor)),
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
                          if (value!.trim().isEmpty)
                            return errorThisFieldRequired;
                          return null;
                        },
                      ),
                  if (widget.socialLogin != true) SizedBox(height: 20),
                  // if (widget.socialLogin != true)
                  //   Row(
                  //     children: [
                  //       Expanded(
                  //         child: AppTextField(
                  //           controller: passController,
                  //           focus: passFocus,
                  //           autoFocus: false,
                  //           nextFocus: confirmPass,
                  //           textFieldType: TextFieldType.PASSWORD,
                  //           errorThisFieldRequired: errorThisFieldRequired,
                  //           decoration: inputDecoration(context,
                  //               label: language.password),
                  //           validator: (String? value) {
                  //             if (value!.isEmpty) return errorThisFieldRequired;
                  //             if (value.length < passwordLengthGlobal)
                  //               return language.passwordLength;
                  //             return null;
                  //           },
                  //         ),
                  //       ),
                  //       if (widget.socialLogin != true) SizedBox(width: 16),
                  //       if (widget.socialLogin != true)
                  //         Expanded(
                  //           child: AppTextField(
                  //             controller: confirmPassController,
                  //             focus: confirmPass,
                  //             autoFocus: false,
                  //             textFieldType: TextFieldType.PASSWORD,
                  //             errorThisFieldRequired: errorThisFieldRequired,
                  //             decoration: inputDecoration(context,
                  //                 label: language.confirmPassword),
                  //             validator: (String? value) {
                  //               if (value!.isEmpty)
                  //                 return errorThisFieldRequired;
                  //               if (value.length < passwordLengthGlobal)
                  //                 return language.passwordLength;
                  //               if (value.trim() != passController.text.trim())
                  //                 return language.bothPasswordNotMatch;
                  //               return null;
                  //             },
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  SizedBox(height: 16),
                  Row(
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
                            isAcceptedTc = v!;
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: '${language.iAgreeToThe} ',
                                style: secondaryTextStyle()),
                            TextSpan(
                              text: language.termsConditions,
                              style:
                                  boldTextStyle(color: primaryColor, size: 14),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (widget.termsConditionUrl != null &&
                                      widget.termsConditionUrl!.isNotEmpty) {
                                    launchScreen(
                                        context,
                                        TermsConditionScreen(
                                            title: language.termsConditions,
                                            subtitle: widget.termsConditionUrl),
                                        pageRouteAnimation:
                                            PageRouteAnimation.Slide);
                                  } else {
                                    toast(language.txtURLEmpty);
                                  }
                                },
                            ),
                            TextSpan(text: ' & ', style: secondaryTextStyle()),
                            TextSpan(
                              text: language.privacyPolicy,
                              style:
                                  boldTextStyle(color: primaryColor, size: 14),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (widget.privacyPolicyUrl != null &&
                                      widget.privacyPolicyUrl!.isNotEmpty) {
                                    launchScreen(
                                        context,
                                        TermsConditionScreen(
                                            title: language.privacyPolicy,
                                            subtitle: widget.privacyPolicyUrl),
                                        pageRouteAnimation:
                                            PageRouteAnimation.Slide);
                                  } else {
                                    toast(language.txtURLEmpty);
                                  }
                                },
                            ),
                          ]),
                          textAlign: TextAlign.left,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 32),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: language.signUp,
                    onTap: () async {
                      if (validateFields()) {
                        // Exécute la fonction d'inscription
                        await register();

                        // Ouvre la fenêtre de dialogue OTP après l'inscription

                        /*   showDialog(
                          context: context,
                          builder: (_) {
                            if (shouldShowOTPDialog) {
                              return AlertDialog(
                                contentPadding: EdgeInsets.all(16),
                                content: OTPDialog(
                                  verificationId: publications.isNotEmpty
                                      ? publications[0]['id_otp'] ?? ''
                                      : '', // Utilisation de l'indice 0 car il y a un seul élément dans la liste
                                  phoneController: publications.isNotEmpty
                                      ? publications[0]['receiver'] ?? ''
                                      : '',
                                  passController: publications.isNotEmpty
                                      ? publications[0]['id_otp'] ?? ''
                                      : '',
                                  countryCode: countryCode,
                                  otp: publications.isNotEmpty
                                      ? publications[0]['otp'] ?? ''
                                      : '',
                                  phoneNumber: publications.isNotEmpty
                                      ? publications[0]['receiver'] ?? ''
                                      : '',
                                  firstController: firstController.text.trim(),
                                  lastNameController:
                                      lastNameController.text.trim(),
                                  emailController: emailController.text.trim(),
                                  userNameController: widget.socialLogin
                                      ? widget.userName
                                      : userNameController.text.trim(),
                                ),
                              );
                            } else {
                              return Container(); // Ne montre rien
                            }
                          },
                        );*/
                      }
                      appStore.setLoading(false);
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(top: context.statusBarHeight + 4, child: BackButton()),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.alreadyHaveAnAccount, style: primaryTextStyle()),
                SizedBox(width: 8),
                inkWellWidget(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(language.logIn,
                      style: boldTextStyle(color: primaryColor)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16)
        ],
      ),
    );
  }
}
