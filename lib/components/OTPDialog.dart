import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/StringExtensions.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../screens/SignUpScreen.dart';
import '../screens/DashBoardScreen.dart';
import '../service/AuthService.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';

class OTPDialog extends StatefulWidget {
  final String? verificationId;
  final String? phoneNumber;
  final bool? isCodeSent;
  final bool? isClose;
  final PhoneAuthCredential? credential;

  OTPDialog(
      {this.verificationId,
      this.isClose = true,
      this.isCodeSent,
      this.phoneNumber,
      this.credential});

  @override
  OTPDialogState createState() => OTPDialogState();
}

class OTPDialogState extends State<OTPDialog> {
  OtpFieldController otpController = OtpFieldController();
  TextEditingController phoneController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String verId = '';
  String otpCode = defaultCountryCode;

  String? otpRecup = '';

  Future<void> submit() async {
    appStore.setLoading(true);

    //AuthCredential credential = PhoneAuthProvider.credential(verificationId: widget.verificationId!, smsCode: verId.validate());

    //await FirebaseAuth.instance.signInWithCredential(credential).then((result) async {
    Map req = {
      "email": "",
      "login_type": "mobile",
      "user_type": RIDER,
      "otp": verId,
      "username": widget.phoneNumber!.split(" ").last,
      'accessToken': widget.phoneNumber!.split(" ").last,
      'contact_number': widget.phoneNumber!.replaceAll(" ", ""),
      "player_id": sharedPref.getString(PLAYER_ID).validate(),
    };

    log(req);
    await logInOtpValidateApi(req, isSocialLogin: false).then((value) async {
      appStore.setLoading(false);
      //appStore.isLoggedIn = true;
      updatePlayerId();
      Navigator.pop(context);
      launchScreen(context, DashBoardScreen(), isNewTask: true);
    }).catchError((e) {
      Navigator.pop(context);
      toast(e.toString());
      appStore.setLoading(false);
    });
    // }).catchError((e) {
    // Navigator.pop(context);
    // toast(e.toString());
    //  appStore.setLoading(false);
    // });
  }

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      appStore.setLoading(true);

      String number = '$otpCode ${phoneController.text.trim()}';

      log('$otpCode${phoneController.text.trim()}');
      await loginWithOTP(context, number).then((value) {}).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _configureOneSignal();
  }

  void _configureOneSignal() {
    // OneSignal.shared.setNotificationReceivedHandler((OSNotification notification) {
    //   if (notification.payload != null && notification.payload!.additionalData != null) {
    //     final Map<String, dynamic> data = notification.payload!.additionalData!;
    //     if (data.containsKey('otp')) {
    //       setState(() {
    //         otpCode = data['otp'];
    //       });
    //     }
    //   }
    // });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // print("notification will $event ");
      print(
          "NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: 2 ${event.notification.body}");

      /// Display Notification, preventDefault to not display
      event.preventDefault();

      /// Do async work

      /// notification.display() to display after preventing default
      event.notification.display();

      this.setState(() {
        otpRecup = getLastWord(event.notification.body!);
        otpController.setValue(otpRecup![0], 0);
        otpController.setValue(otpRecup![1], 1);
        otpController.setValue(otpRecup![2], 2);
        otpController.setValue(otpRecup![3], 3);
        var _debugLabelString =
            "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
      print("NOTIFICATION WILL  3 $otpRecup");
    });
  }

  String getLastWord(String str) {
    // Supprimez les espaces en début et fin de la chaîne
    str = str.trim();

    // Divisez la chaîne en mots en utilisant l'espace comme délimiteur
    List<String> words = str.split(' ');

    // Obtenez le dernier mot de la liste
    String lastWord = words.isNotEmpty ? words.last : '';

    return lastWord;
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCodeSent.validate()) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.signInUsingYourMobileNumber,
                  style: boldTextStyle()),
              widget.isCodeSent.validate()
                  ? IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.cancel_outlined, color: Colors.black),
                    )
                  : Center()
            ],
          ),
          SizedBox(height: 30),
          Form(
            key: formKey,
            child: AppTextField(
              controller: phoneController,
              textFieldType: TextFieldType.PHONE,
              decoration: inputDecoration(
                context,
                label: language.phoneNumber,
                prefixIcon: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCodePicker(
                        padding: EdgeInsets.zero,
                        initialSelection: otpCode,
                        showCountryOnly: false,
                        dialogSize: Size(MediaQuery.of(context).size.width - 60,
                            MediaQuery.of(context).size.height * 0.6),
                        showFlag: true,
                        showFlagDialog: true,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        textStyle: primaryTextStyle(),
                        dialogBackgroundColor: Theme.of(context).cardColor,
                        barrierColor: Colors.black12,
                        dialogTextStyle: primaryTextStyle(),
                        searchDecoration: InputDecoration(
                          iconColor: Theme.of(context).dividerColor,
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor)),
                        ),
                        searchStyle: primaryTextStyle(),
                        onInit: (c) {
                          otpCode = c!.dialCode!;
                        },
                        onChanged: (c) {
                          otpCode = c.dialCode!;
                        },
                      ),
                      VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
              validator: (value) {
                if (value!.trim().isEmpty) return language.thisFieldRequired;
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              AppButtonWidget(
                onTap: () {
                  if (phoneController.text.trim().isEmpty) {
                    return toast(language.thisFieldRequired);
                  } else {
                    hideKeyboard(context);
                    sendOTP();
                  }
                },
                text: language.sendOTP,
                color: primaryColor,
                textStyle: boldTextStyle(color: Colors.white),
                width: MediaQuery.of(context).size.width,
              ),
              Positioned(
                child: Observer(builder: (context) {
                  return Visibility(
                    visible: appStore.isLoading,
                    child: loaderWidget(),
                  );
                }),
              ),
            ],
          )
        ],
      );
    } else {
      return Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.cancel_outlined, color: Colors.black)),
              ),
              Icon(Icons.message, color: primaryColor, size: 50),
              SizedBox(height: 16),
              Text(language.validateOtp, style: boldTextStyle(size: 18)),
              SizedBox(height: 10),
              Column(
                children: [
                  Text(language.otpCodeHasBeenSentTo,
                      style: secondaryTextStyle(size: 16),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(widget.phoneNumber.validate(), style: boldTextStyle()),
                  SizedBox(height: 10),
                  Text(language.pleaseEnterOtp,
                      style: secondaryTextStyle(size: 16),
                      textAlign: TextAlign.center),
                ],
              ),
              SizedBox(height: 10),
              OTPTextField(
                controller: otpController,
                length: 4,
                width: MediaQuery.of(context).size.width,
                fieldWidth: 35,
                style: primaryTextStyle(),
                textFieldAlignment: MainAxisAlignment.spaceAround,
                fieldStyle: FieldStyle.box,
                onChanged: (s) {
                  verId = s;
                },
                onCompleted: (pin) {
                  verId = pin;
                },
              ),
              SizedBox(height: 10),
              SizedBox(height: 10),
              Observer(
                builder: (context) => Visibility(
                  visible: !appStore.isLoading,
                  child: Container(
                    // height: 45,
                    child: InkWell(
                        onTap: () {
                          hideKeyboard(context);
                          submit();
                        },
                        child: Text(
                          "${language.sendOTP}",
                          style: boldTextStyle(color: primaryColor),
                        )),

                    //  AppButtonWidget(
                    //   height: 45,
                    //   onTap: () {
                    //     hideKeyboard(context);
                    //     submit();
                    //   },
                    //   text: language.sendOTP,
                    //   color: primaryColor,
                    //   textStyle: boldTextStyle(color: Colors.white),
                    //   width: MediaQuery.of(context).size.width,
                    // ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Observer(
                builder: (context) => Visibility(
                  visible: appStore.isLoading,
                  child: loaderWidget(),
                ),
              )
            ],
          ),
        ],
      );
    }
  }
}
