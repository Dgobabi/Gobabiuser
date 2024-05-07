import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'images.dart';

//region App name
const mAppName = "Go'Babi";
//endregion

//region Google map key
const GOOGLE_MAP_API_KEY = 'AIzaSyBibRbnq25DAjKKNtew4lvis8uYbwDptwU';
//endregion

//const DOMAIN_URL = 'http://192.168.1.4:8000';

//region DomainUrl
const DOMAIN_URL = 'http://appgobabi.com';
// Don't add slash at the end of the url

// const DOMAIN_URL =
//     'http://test.appgobabi.com'; // Don't add slash at the end of the url

//const DOMAIN_URL = 'http://192.168.10.52:8081/gobabi';
//endregion

const DOMAIN_URL_API = 'http://loutche.com/apigobabi/mobileP.php?typeoperation';

//const DOMAIN_URL_API =
// 'http://192.168.10.52:8081/api/mobileP.php?typeoperation';

//region MQTT port and unique name
//Don't add underscore at the end of the url
final client = MqttServerClient.withPort(
    "n90cde42.ala.dedicated.gcp.emqxcloud.com", "", 8883);

// final client = MqttServerClient.withPort("207.180.198.147", "", 1883);
const MQTT_UNIQUE_TOPIC_NAME = 'gobabi';
//endregion
//endregion

//region OneSignal Keys
//You have to generate 2 onesignal account one for rider and one for driver
const mOneSignalAppIdDriver = '950ba739-e930-4805-804e-9caba5902a99';
const mOneSignalRestKeyDriver =
    'NTg0ZjdmYTktZjMwOC00MDdlLWIzMmEtMjU3NzNiNGQzYTMy';

const mOneSignalAppIdRider = '1702ab9c-ff13-467c-a798-7cb7bb2b402d';
const mOneSignalRestKeyRider =
    'ODM1MDYyOTQtZjQyZi00NTkxLWJhNGItMmIwMzIxNGRiMTVi';
//endregion

//region Currency & country code
const currencySymbol = '\F';
const currencyNameConst = 'F CFA';
const defaultCountryCode = '+225';
const defaultCountry = 'CI';
const digitAfterDecimal = 0;
//endregion

//region top up default value
const PRESENT_TOP_UP_AMOUNT_CONST = '10|20|30';
//endregion

//region PDF configuration
const PDF_NAME = "GO'BABI ";
const PDF_ADDRESS = 'Abidjan, Angré nouveau chu';
const PDF_CONTACT_NUMBER = '+2250700532612';
//endregion

//region walkthrough text
const walkthrough_title_1 = 'Select your Ride';
const walkthrough_subtitle_1 =
    'Request a ride get picked up by\na nearby community driver';
const walkthrough_image_1 = ic_walk1;

const walkthrough_title_2 = 'Navigating Your Ride';
const walkthrough_subtitle_2 =
    "Seamless Travel, Smart Choices\nStress-Free Journeys";
const walkthrough_image_2 = ic_walk2;

const walkthrough_title_3 = 'Track your Ride';
const walkthrough_subtitle_3 =
    "Know your Service and be able to view\ncurrent location in real time on the map";
const walkthrough_image_3 = ic_walk3;
//endregion

//region url
const mBaseUrl = "$DOMAIN_URL/api/";
const mMQTT_UNIQUE_TOPIC_NAME = MQTT_UNIQUE_TOPIC_NAME + '_';
//endregion

//region userType
const ADMIN = 'admin';
const DRIVER = 'driver';
const RIDER = 'rider';
double DRIVERLONGITUDE = 0.0;
double DRIVERLATITUDE = 0.0;

//endregion

const PER_PAGE = 15;
const passwordLengthGlobal = 7;
const defaultRadius = 10.0;
const defaultSmallRadius = 6.0;

const textPrimarySizeGlobal = 16.00;
const textBoldSizeGlobal = 16.00;
const textSecondarySizeGlobal = 14.00;

double tabletBreakpointGlobal = 600.0;
double desktopBreakpointGlobal = 720.0;
double statisticsItemWidth = 230.0;
double defaultAppButtonElevation = 4.0;

bool enableAppButtonScaleAnimationGlobal = true;
int? appButtonScaleAnimationDurationGlobal;
ShapeBorder? defaultAppButtonShapeBorder;

var customDialogHeight = 140.0;
var customDialogWidth = 220.0;

enum ThemeModes { SystemDefault, Light, Dark }

//region loginType
const LoginTypeApp = 'app';
const LoginTypeGoogle = 'google';
const LoginTypeOTP = 'otp';
const LoginTypeApple = 'apple';
//endregion

//region SharedReference keys
const REMEMBER_ME = 'REMEMBER_ME';
const IS_FIRST_TIME = 'IS_FIRST_TIME';
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const LEFT = 'left';

const USER_ID = 'USER_ID';
const FIRST_NAME = 'FIRST_NAME';
const LAST_NAME = 'LAST_NAME';
const TOKEN = 'TOKEN';
const USER_EMAIL = 'USER_EMAIL';
const USER_TOKEN = 'USER_TOKEN';
const USER_PROFILE_PHOTO = 'USER_PROFILE_PHOTO';
const USER_TYPE = 'USER_TYPE';
const USER_NAME = 'USER_NAME';
const USER_PASSWORD = 'USER_PASSWORD';
const USER_ADDRESS = 'USER_ADDRESS';
const STATUS = 'STATUS';
const CONTACT_NUMBER = 'CONTACT_NUMBER';
const PLAYER_ID = 'PLAYER_ID';
const UID = 'UID';
const ADDRESS = 'ADDRESS';
const IS_OTP = 'IS_OTP';
const IS_GOOGLE = 'IS_GOOGLE';
const GENDER = 'GENDER';
const IS_TIME = 'IS_TIME';
const REMAINING_TIME = 'REMAINING_TIME';
const LOGIN_TYPE = 'login_type';
const COUNTRY = 'COUNTRY';
const LATITUDE = 'LATITUDE';
const LONGITUDE = 'LONGITUDE';
//endregion

//region Taxi Status
const ACTIVE = 'active';
const IN_ACTIVE = 'inactive';
const PENDING = 'pending';
const BANNED = 'banned';
const REJECT = 'reject';
//endregion

//region Wallet keys
const CREDIT = 'credit';
const DEBIT = 'debit';
const OTHERS = 'Others';
//endregion

//region paymentType
const PAYMENT_TYPE_STRIPE = 'stripe';
const PAYMENT_TYPE_RAZORPAY = 'razorpay';
const PAYMENT_TYPE_PAYSTACK = 'paystack';
const PAYMENT_TYPE_FLUTTERWAVE = 'flutterwave';
const PAYMENT_TYPE_PAYPAL = 'paypal';
const PAYMENT_TYPE_PAYTABS = 'paytabs';
const PAYMENT_TYPE_MERCADOPAGO = 'mercadopago';
const PAYMENT_TYPE_PAYTM = 'paytm';
const PAYMENT_TYPE_MYFATOORAH = 'myfatoorah';

const stripeURL = 'https://api.stripe.com/v1/payment_intents';
//endregion

var errorThisFieldRequired = 'This field is required';

//region Ride Status
const UPCOMING = 'upcoming';
const NEW_RIDE_REQUESTED = 'new_ride_requested';
const ACCEPTED = 'accepted';
const ARRIVING = 'arriving';
const ARRIVED = 'arrived';
const IN_PROGRESS = 'in_progress';
const CANCELED = 'canceled';
const COMPLETED = 'completed';
const SUCCESS = 'payment_status_message';
const AUTO = 'auto';
const COMPLAIN_COMMENT = "complaintcomment";
//endregion

///fix Decimal
const fixedDecimal = digitAfterDecimal;

//region
const CHARGE_TYPE_FIXED = 'fixed';
const CHARGE_TYPE_PERCENTAGE = 'percentage';
const CASH_WALLET = 'cash_wallet';
const CASH = 'cash';
const MALE = 'male';
const FEMALE = 'female';
const OTHER = 'other';
const Wallet = 'wallet';
//endregion

//region app setting key
const CLOCK = 'clock';
const PRESENT_TOPUP_AMOUNT = 'preset_topup_amount';
const PRESENT_TIP_AMOUNT = 'preset_tip_amount';
const RIDE_FOR_OTHER = 'RIDE_FOR_OTHER';
const MAX_TIME_FOR_RIDER_MINUTE =
    'max_time_for_find_drivers_for_regular_ride_in_minute';
const MAX_TIME_FOR_DRIVER_SECOND =
    'ride_accept_decline_duration_for_driver_in_second';
const MIN_AMOUNT_TO_ADD = 'min_amount_to_add';
const MAX_AMOUNT_TO_ADD = 'max_amount_to_add';
//endregion

//region FireBase Collection Name
const MESSAGES_COLLECTION = "messages";
const USER_COLLECTION = "users";
const CONTACT_COLLECTION = "contact";
const CHAT_DATA_IMAGES = "chatImages";
//endregion

const IS_ENTER_KEY = "IS_ENTER_KEY";
const SELECTED_WALLPAPER = "SELECTED_WALLPAPER";
const PER_PAGE_CHAT_COUNT = 50;

const TEXT = "TEXT";
const IMAGE = "IMAGE";

const VIDEO = "VIDEO";
const AUDIO = "AUDIO";

const FIXED_CHARGES = "fixed_charges";
const MIN_DISTANCE = "min_distance";
const MIN_WEIGHT = "min_weight";
const PER_DISTANCE_CHARGE = "per_distance_charges";
const PER_WEIGHT_CHARGE = "per_weight_charges";
const PAID = 'paid';

const PAYMENT_PENDING = 'pending';
const PAYMENT_FAILED = 'failed';
const PAYMENT_PAID = 'paid';
const SELECTED_LANGUAGE_CODE = 'selected_language_code';
const THEME_MODE_INDEX = 'theme_mode_index';
const CHANGE_LANGUAGE = 'CHANGE_LANGUAGE';
const CHANGE_MONEY = 'CHANGE_MONEY';

//chat
List<String> rtlLanguage = ['fr', 'en'];

enum MessageType { TEXT, IMAGE, VIDEO, AUDIO }

extension MessageExtension on MessageType {
  String? get name {
    switch (this) {
      case MessageType.TEXT:
        return 'TEXT';
      case MessageType.IMAGE:
        return 'IMAGE';
      case MessageType.VIDEO:
        return 'VIDEO';
      case MessageType.AUDIO:
        return 'AUDIO';
      default:
        return null;
    }
  }
}

var errorSomethingWentWrong = 'Something Went Wrong';

var demoEmail = 'joy58@gmail.com';
const mRazorDescription = 'Mighty Rider';
const mStripeIdentifier = 'IN';

// SERVICES

List<String> servicesName = ["", "", "ECO", "", "BUSINESS"];
