import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/ChatScreen.dart';
import '../screens/RideDetailScreen.dart';
import '../utils/images.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../../main.dart';
import 'Extensions/Loader.dart';
import 'Extensions/app_common.dart';

Widget dotIndicator(list, i) {
  return SizedBox(
    height: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        list.length,
        (ind) {
          return Container(
            height: 8,
            width: 8,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: i == ind ? Colors.white : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(defaultRadius)),
          );
        },
      ),
    ),
  );
}

InputDecoration inputDecoration(BuildContext context,
    {String? label, Widget? prefixIcon, Widget? suffixIcon}) {
  return InputDecoration(
    prefixIcon: prefixIcon,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.black)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.red)),
    alignLabelWithHint: true,
    filled: false,
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: primaryTextStyle(),
    suffixIcon: suffixIcon,
  );
}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}

EdgeInsets dynamicAppButtonPadding(BuildContext context) {
  return EdgeInsets.symmetric(vertical: 14, horizontal: 16);
}

Widget inkWellWidget({Function()? onTap, required Widget child}) {
  return InkWell(
      onTap: onTap,
      child: child,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent);
}

bool get isRTL => rtlLanguage.contains(appStore.selectedLanguage);

Widget commonCachedNetworkImage(String? url,
    {double? height,
    double? width,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool usePlaceholderIfUrlEmpty = true,
    double? radius}) {
  if (url != null && url.isEmpty) {
    return placeHolderWidget(
        height: height,
        width: width,
        fit: fit,
        alignment: alignment,
        radius: radius);
  } else if (url.validate().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment as Alignment? ?? Alignment.center,
      errorWidget: (_, s, d) {
        return placeHolderWidget(
            height: height,
            width: width,
            fit: fit,
            alignment: alignment,
            radius: radius);
      },
      placeholder: (_, s) {
        if (!usePlaceholderIfUrlEmpty) return SizedBox();
        return placeHolderWidget(
            height: height,
            width: width,
            fit: fit,
            alignment: alignment,
            radius: radius);
      },
    );
  } else {
    return Image.network(url!,
        height: height,
        width: width,
        fit: fit,
        alignment: alignment ?? Alignment.center);
  }
}

Widget placeHolderWidget(
    {double? height,
    double? width,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    double? radius}) {
  return Image.asset('images/placeholder.jpg',
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      alignment: alignment ?? Alignment.center);
}

List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [
    BoxShadow(
      color: shadowColor ?? Colors.grey.withOpacity(0.2),
      blurRadius: blurRadius ?? 4.0,
      spreadRadius: spreadRadius ?? 1.0,
      offset: offset,
    )
  ];
}

/// Hide soft keyboard
void hideKeyboard(context) => FocusScope.of(context).requestFocus(FocusNode());

const double degrees2Radians = pi / 180.0;

double radians(double degrees) => degrees * degrees2Radians;

const default_Language = 'fr';

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

Widget loaderWidget() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0.0, 0.0)),
        ],
      ),
      width: 50,
      height: 50,
      child: CircularProgressIndicator(strokeWidth: 3),
    ),
  );
}

void afterBuildCreated(Function()? onCreated) {
  makeNullable(SchedulerBinding.instance)!
      .addPostFrameCallback((_) => onCreated?.call());
}

T? makeNullable<T>(T? value) => value;

String printDate(String date) {
  return DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal()) +
      " at " +
      DateFormat('hh:mm a').format(DateTime.parse(date).toLocal());
}

Widget emptyWidget() {
  return Center(
      child: Image.asset('images/no_data.png', width: 150, height: 250));
}

String statusTypeIcon({String? type}) {
  String icon = ic_history_img1;
  if (type == NEW_RIDE_REQUESTED) {
    icon = ic_history_img1;
  } else if (type == ACCEPTED) {
    icon = ic_history_img2;
  } else if (type == ARRIVING) {
    icon = ic_history_img3;
  } else if (type == ARRIVED) {
    icon = ic_history_img4;
  } else if (type == IN_PROGRESS) {
    icon = ic_history_img5;
  } else if (type == CANCELED) {
    icon = ic_history_img6;
  } else if (type == COMPLETED) {
    icon = ic_history_img7;
  }
  return icon;
}

Widget scheduleOptionWidget(
    BuildContext context, bool isSelected, String imagePath, String title) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(
          color: isSelected
              ? primaryColor
              : appStore.isDarkMode
                  ? Colors.transparent
                  : borderColor),
    ),
    child: Row(
      children: [
        ImageIcon(AssetImage(imagePath),
            size: 20, color: isSelected ? primaryColor : Colors.grey),
        SizedBox(width: 16),
        Text(title, style: boldTextStyle()),
      ],
    ),
  );
}

Widget totalCount({String? title, num? amount, bool? isTotal = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
          child: Text(title.toString(),
              style: isTotal == true
                  ? boldTextStyle(color: Colors.green, size: 18)
                  : secondaryTextStyle())),
      Text(printAmount(amount!.toStringAsFixed(digitAfterDecimal)),
          style: isTotal == true
              ? boldTextStyle(color: Colors.green, size: 18)
              : boldTextStyle(size: 14)),
    ],
  );
}

Future<bool> checkPermission() async {
  // Request app level location permission
  LocationPermission locationPermission = await Geolocator.requestPermission();

  if (locationPermission == LocationPermission.whileInUse ||
      locationPermission == LocationPermission.always) {
    await Geolocator.getCurrentPosition().then((value) {
      sharedPref.setDouble(LATITUDE, value.latitude);
      sharedPref.setDouble(LONGITUDE, value.longitude);
    });
    // Check system level location permission
    if (!await Geolocator.isLocationServiceEnabled()) {
      return await Geolocator.openLocationSettings()
          .then((value) => false)
          .catchError((e) => false);
    } else {
      return true;
    }
  } else {
    toast(language.pleaseEnableLocationPermission);

    // Open system level location permission
    await Geolocator.openAppSettings();

    return false;
  }
}

/// Handle error and loading widget when using FutureBuilder or StreamBuilder
Widget snapWidgetHelper<T>(
  AsyncSnapshot<T> snap, {
  Widget? errorWidget,
  Widget? loadingWidget,
  String? defaultErrorMessage,
  @Deprecated('Do not use this') bool checkHasData = false,
  Widget Function(String)? errorBuilder,
}) {
  if (snap.hasError) {
    log(snap.error);
    if (errorBuilder != null) {
      return errorBuilder.call(defaultErrorMessage ?? snap.error.toString());
    }
    return Center(
      child: errorWidget ??
          Text(
            defaultErrorMessage ?? snap.error.toString(),
            style: primaryTextStyle(),
          ),
    );
  } else if (!snap.hasData) {
    return loadingWidget ?? Loader();
  } else {
    return SizedBox();
  }
}

String statusName({String? status}) {
  if (status == NEW_RIDE_REQUESTED) {
    status = language.newRideRequested;
  } else if (status == ACCEPTED) {
    status = language.accepted;
  } else if (status == ARRIVING) {
    status = language.arriving;
  } else if (status == ARRIVED) {
    status = language.arrived;
  } else if (status == IN_PROGRESS) {
    status = language.inProgress;
  } else if (status == CANCELED) {
    status = language.cancelled;
  } else if (status == COMPLETED) {
    status = language.completed;
  }
  return status!;
}

String paymentStatus(String paymentStatus) {
  if (paymentStatus.toLowerCase() == PAYMENT_PENDING.toLowerCase()) {
    return language.pending;
  } else if (paymentStatus.toLowerCase() == PAYMENT_FAILED.toLowerCase()) {
    return language.failed;
  } else if (paymentStatus == PAYMENT_PAID) {
    return language.paid;
  } else if (paymentStatus == CASH) {
    return language.cash;
  } else if (paymentStatus == Wallet) {
    return language.wallet;
  }
  return language.pending;
}

String changeStatusText(String? status) {
  if (status == COMPLETED) {
    return language.completed;
  } else if (status == CANCELED) {
    return language.cancelled;
  }
  return '';
}

String changeGender(String? name) {
  if (name == MALE) {
    return language.male;
  } else if (name == FEMALE) {
    return language.female;
  } else if (name == OTHER) {
    return language.other;
  }
  return '';
}

String printAmount(String amount) {
  return appStore.currencyPosition == LEFT
      ? '${appStore.currencyCode} ${amountRounded(amount)}'
      : '${amountRounded(amount)} ${appStore.currencyCode}';
}

String amountRounded(amount) {
  int facteurArrondi = 100; // Facteur pour l'arrondi (1700)
  // Appliquer l'arrondi
  return ((double.parse(amount) / facteurArrondi).ceilToDouble() *
          facteurArrondi)
      .toStringAsFixed(digitAfterDecimal);
}

String getMessageFromErrorCode(FirebaseException error) {
  switch (error.code) {
    case "ERROR_EMAIL_ALREADY_IN_USE":
    case "account-exists-with-different-credential":
    case "email-already-in-use":
      return "The email address is already in use by another account.";
    case "ERROR_WRONG_PASSWORD":
    case "wrong-password":
      return "Wrong email/password combination.";
    case "ERROR_USER_NOT_FOUND":
    case "user-not-found":
      return "No user found with this email.";
    case "ERROR_USER_DISABLED":
    case "user-disabled":
      return "User disabled.";
    case "ERROR_TOO_MANY_REQUESTS":
    case "operation-not-allowed":
      return "Too many requests to log into this account.";
    case "ERROR_OPERATION_NOT_ALLOWED":
    case "operation-not-allowed":
      return "Server error, please try again later.";
    case "ERROR_INVALID_EMAIL":
    case "invalid-email":
      return "Email address is invalid.";
    default:
      return error.message.toString();
  }
}

Widget socialWidget({String? image, String? text}) {
  return Image.asset(image.validate(),
      fit: BoxFit.cover, height: 30, width: 30);
}

oneSignalSettings() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);
  OneSignal.consentRequired(false);

  OneSignal.Notifications.requestPermission(true);

  OneSignal.initialize(mOneSignalAppIdDriver);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print(
        'NOTIFICATION WILL DISPLAY LISTENER CALLED WITH 1: ${event.notification.body}');

    event.preventDefault();
    event.notification.display();
  });

  saveOneSignalPlayerId();
  if (appStore.isLoggedIn) {
    updatePlayerId();
  }

  OneSignal.Notifications.addClickListener((notification) async {
    var notId = notification.notification.additionalData!["id"];
    log("$notId---" +
        notification.notification.additionalData!['type'].toString());
    var notType = notification.notification.additionalData!['type'];
    if (notId != null) {
      if (notId.toString().contains('CHAT')) {
        LoginResponse user = await getUserDetail(
            userId: int.parse(notId.toString().replaceAll("CHAT_", "")));
        launchScreen(getContext, ChatScreen(userData: user.data));
      } else if (notType == 'payment_status_message') {
        launchScreen(getContext, RideDetailScreen(orderId: notId));
      }
    }
  });
}

Future<void> saveOneSignalPlayerId() async {
  // await OneSignal.shared.getDeviceState().then((value) async {
  // });
  print("PLAYER ID ONE SIGNAL");
  OneSignal.User.pushSubscription.addObserver((state) async {
    print("==PLAYER ID ONE SIGNAL");
    print(OneSignal.User.pushSubscription.optedIn);
    print("Player Id" + OneSignal.User.pushSubscription.id.toString());
    print(OneSignal.User.pushSubscription.token);
    print(state.current.jsonRepresentation());

    if (OneSignal.User.pushSubscription.id.validate().isNotEmpty)
      await sharedPref.setString(
          PLAYER_ID, OneSignal.User.pushSubscription.id.validate());
  });
}

Color paymentStatusColor(String paymentStatus) {
  Color color = textPrimaryColor;

  switch (paymentStatus) {
    case PAYMENT_PAID:
      color = Colors.green;
    case PAYMENT_FAILED:
      color = Colors.red;
    case PAYMENT_PENDING:
      color = Colors.grey;
  }
  return color;
}
