import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:user/screens/SignInScreen.dart';
import 'package:user/service/AuthService1.dart';
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
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OTPDialog extends StatefulWidget {
  final String? verificationId;
  final String? phoneNumber;
  final String? firstController;
  final String? lastNameController;
  final String? emailController;
  final String? userNameController;
  final String? phoneController;
  final String? passController;
  final String? countryCode;
  final String? otp;
  final bool socialLogin;
  final String? userName;
  final bool isOtp;

  final String? privacyPolicyUrl;
  final String? termsConditionUrl;

  OTPDialog({
    required this.verificationId,
    required this.phoneNumber,
    required this.firstController,
    required this.lastNameController,
    required this.emailController,
    required this.userNameController,
    required this.phoneController,
    required this.passController,
    required this.countryCode,
    required this.otp,
    this.socialLogin = false,
    this.userName,
    this.isOtp = false,
    this.privacyPolicyUrl,
    this.termsConditionUrl,
  });

  @override
  OTPDialogState createState() => OTPDialogState();
}

class OTPDialogState extends State<OTPDialog> {
  OtpFieldController otpController = OtpFieldController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController countryCodeController = TextEditingController();
  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController userName = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthServices authService = AuthServices();
  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode confirmPass = FocusNode();
  String verId = '';
  String otpCode = defaultCountryCode;
  bool mIsCheck = false;
  bool isAcceptedTc = false;
  List<Map<String, dynamic>> publications = [];
  final scaffoldKey = GlobalKey();
  late OTPTextEditController controller;
  int myInteger = 123456;
  TextEditingController txt1 = TextEditingController();
  TextEditingController txt2 = TextEditingController();
  TextEditingController txt3 = TextEditingController();
  TextEditingController txt4 = TextEditingController();
  TextEditingController txt5 = TextEditingController();
  TextEditingController txt6 = TextEditingController();

  @override
  void dispose() {
    controller.stopListen();
    super.dispose();
  }

  Future<void> submit() async {
    appStore.setLoading(true);

    AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId!,
      smsCode: verId.validate(),
    );

    print(widget.phoneNumber!.replaceAll(" ", ""));

    await FirebaseAuth.instance
        .signInWithCredential(credential)
        .then((result) async {
      Map req = {
        "email": "",
        "login_type": "mobile",
        "user_type": RIDER,
        "username": widget.phoneNumber!.split(" ").last,
        'accessToken': widget.phoneNumber!.split(" ").last,
        'contact_number': widget.phoneNumber!.replaceAll(" ", ""),
        "player_id": sharedPref.getString(PLAYER_ID).validate(),
      };

      log(req);

      await logInApi(req, isSocialLogin: true).then((value) async {
        appStore.setLoading(false);

        if (value.data == null) {
          Navigator.pop(context);
          launchScreen(
            context,
            SignUpScreen(
              countryCode: widget.phoneNumber!.split(" ").first,
              userName: widget.phoneNumber!.split(" ").last,
              socialLogin: true,
            ),
          );
        } else {
          updatePlayerId();
          Navigator.pop(context);
          launchScreen(context, DashBoardScreen(), isNewTask: true);
        }
      }).catchError((e) {
        Navigator.pop(context);
        toast(e.toString());
        appStore.setLoading(false);
      });
    }).catchError((e) {
      Navigator.pop(context);
      toast(e.toString());
      appStore.setLoading(false);
    });
  }

  Future<void> register() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);
      print("looooooo");

      if (isAcceptedTc) {
        appStore.setLoading(true);
        print("bonjour felicien" + emailController.text.trim());

        Map<String, dynamic> req = {
          'first_name': firstController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'username': widget.socialLogin
              ? widget.userNameController
              : userNameController.text.trim(),
          'email': emailController.text.trim(),
          "user_type": "rider",
          "contact_number": widget.socialLogin
              ? '${widget.countryCode}${widget.userNameController}'
              : '${widget.countryCode}${phoneController.text.trim()}',
          'password': widget.socialLogin
              ? widget.userNameController
              : passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
        };

        try {
          // Effectue l'inscription
          await signUpApi(req);

          // Effectue l'inscription avec email/password
          await authService.signUpWithEmailPassword(
            getContext,
            mobileNumber: widget.socialLogin
                ? '${widget.countryCode}${widget.userName}'
                : '${widget.countryCode}${phoneController.text.trim()}',
            email: emailController.text.trim(),
            fName: firstController.text.trim(),
            lName: lastNameController.text.trim(),
            userName: widget.socialLogin
                ? widget.userName
                : userNameController.text.trim(),
            password: widget.socialLogin
                ? widget.userName
                : passController.text.trim(),
            userType: RIDER,
            isOtpLogin: widget.socialLogin,
          );

          // Exécute la vérification OTP après une inscription réussie
          //   await vericationotpweb();

          // Faites quelque chose ici si nécessaire après la vérification OTP
        } catch (error) {
          appStore.setLoading(false);
          toast('$error');
        }
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  Future<void> vericationotpweb() async {
    try {
      final response = await http.get(
        Uri.parse('$DOMAIN_URL_API=code_otp=$verId'),
      );
      print('$DOMAIN_URL_API=code_otp=$verId');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);
        if (jsonData['success'] == 'true') {
          await statutactif();
          setState(() {
            publications =
                List<Map<String, dynamic>>.from(jsonData['otp_validations']);
          });
        }
      } else {
        throw Exception('Failed to load publications');
      }
    } catch (e) {
      print('Error fetching publications: $e');
    }
  }

  Future<void> statutactif() async {
    try {
      // Assurez-vous de formatter correctement le numéro de téléphone
      String formattedPhoneNumber =
          "${widget.countryCode}${widget.phoneController?.trim() ?? ""}";
      String url =
          '$DOMAIN_URL_API=statut_active&contact_number=$formattedPhoneNumber';
      print(url);
      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData);

        if (jsonData['success'] == true) {
          // Vérifiez le format correct du booléen dans la réponse JSON`
          setState(() {
            // Effectuez les traitements nécessaires avec les données de la réponse
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

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      appStore.setLoading(true);

      // Format the phone number with the country code
      String number = '$otpCode ${widget.phoneController?.trim()}';
      print(number);

      await loginWithOTP(context, number).then((value) {}).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.phoneController);
    countryCodeController = TextEditingController(text: widget.countryCode);
    otpController = OtpFieldController();
    widget.otp;
    txt1.text = widget.otp![0];
    txt2.text = widget.otp![1];
    txt3.text = widget.otp![2];
    txt4.text = widget.otp![3];
    txt5.text = widget.otp![4];
    txt6.text = widget.otp![5];

    print(phoneController.text);

    if (phoneController.text.isNotEmpty) {
      print(
        'Phone Number: ${countryCodeController.text.trim()}${phoneController.text.trim()}',
      );
      sendOTP();
    } else {
      print('Phone Number is null or empty');
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.cancel_outlined, color: Colors.black),
              ),
            ),
            Icon(Icons.message, color: primaryColor, size: 50),
            SizedBox(height: 16),
            Text(language.validateOtp, style: boldTextStyle(size: 18)),
            SizedBox(height: 16),
            /* OTPTextField(
              controller: otpController,
              length: 6,
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
                vericationotpweb(); // Ne pas appeler la méthode register ici
              },
            ),*/
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                myInputBox(context, txt1),
                SizedBox(height: 2),
                myInputBox(context, txt2),
                SizedBox(height: 2),
                myInputBox(context, txt3),
                SizedBox(height: 2),
                myInputBox(context, txt4),
                SizedBox(height: 2),
                myInputBox(context, txt5),
                SizedBox(height: 2),
                myInputBox(context, txt6),
              ],
            ),
            SizedBox(
              height: 16,
            ), // Ajout d'un espace entre le champ OTP et le bouton
            ElevatedButton(
              onPressed: () async {
                String enteredOTP =
                    "${txt1.text}${txt2.text}${txt3.text}${txt4.text}${txt5.text}${txt6.text}";
                print(widget.otp);
                print(widget.verificationId);
                print(enteredOTP);

                if (widget.otp == enteredOTP) {
                  Fluttertoast.showToast(
                    msg: 'Bonjour',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );

                  await statutactif();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: 'Veillez mettre le bon OTP',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
                // Appel de la méthode register ici
                // register();
              },
              child: Text('Register'),
            ),
          ],
        ),
        Observer(
          builder: (context) => Positioned.fill(
            child: Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            ),
          ),
        ),
      ],
    );
  }
}

Widget myInputBox(BuildContext context, TextEditingController controller) {
  return Container(
    height: 50,
    width: 40,
    decoration: BoxDecoration(
      border: Border.all(width: 1),
      borderRadius: const BorderRadius.all(
        Radius.circular(10),
      ),
    ),
    child: TextField(
      controller: controller,
      maxLength: 1,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 42),
      decoration: const InputDecoration(
        counterText: '',
      ),
      onChanged: (value) {
        if (value.length == 1) {
          FocusScope.of(context).nextFocus();
        }
      },
    ),
  );
}
