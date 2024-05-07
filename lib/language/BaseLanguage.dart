import 'package:flutter/material.dart';

abstract class BaseLanguage {
  static BaseLanguage? of(BuildContext context) => Localizations.of<BaseLanguage>(context, BaseLanguage);

  String get appName;

  String get thisFieldRequired;

  String get email;

  String get password;

  String get forgotPassword;

  String get logIn;

  String get orLogInWith;

  String get donHaveAnAccount;

  String get signUp;

  String get createAccount;

  String get firstName;

  String get lastName;

  String get userName;

  String get phoneNumber;

  String get alreadyHaveAnAccount;

  String get changePassword;

  String get oldPassword;

  String get newPassword;

  String get confirmPassword;

  String get passwordDoesNotMatch;

  String get passwordInvalid;

  String get yes;

  String get no;

  String get writeMessage;

  String get enterTheEmailAssociatedWithYourAccount;

  String get submit;

  String get language;

  String get notification;

  String get useInCaseOfEmergency;

  String get notifyAdmin;

  String get notifiedSuccessfully;

  String get complain;

  String get pleaseEnterSubject;

  String get writeDescription;

  String get saveComplain;

  String get editProfile;

  String get address;

  String get updateProfile;

  String get notChangeUsername;

  String get notChangeEmail;

  String get profileUpdateMsg;

  String get emergencyContact;

  String get areYouSureYouWantDeleteThisNumber;

  String get addContact;

  String get save;

  String get availableBalance;

  String get recentTransactions;

  String get moneyDeposited;

  String get addMoney;

  String get cancel;

  String get pleaseSelectAmount;

  String get amount;

  String get capacity;

  String get paymentMethod;

  String get chooseYouPaymentLate;

  String get enterPromoCode;

  String get confirm;

  String get forInstantPayment;

  String get bookNow;

  String get wallet;

  String get paymentDetail;

  String get rideId;

  String get viewHistory;

  String get paymentDetails;

  String get paymentType;

  String get paymentStatus;

  String get priceDetail;

  String get basePrice;

  String get distancePrice;

  String get waitTime;

  String get extraCharges;

  String get couponDiscount;

  String get total;

  String get payment;

  String get cash;

  String get updatePaymentStatus;

  String get waitingForDriverConformation;

  String get continueNewRide;

  String get payToPayment;

  String get tip;

  String get pay;

  String get howWasYourRide;

  String get wouldYouLikeToAddTip;

  String get addMoreTip;

  String get addMore;

  String get addReviews;

  String get writeYourComments;

  String get continueD;

  String get aboutDriver;

  String get rideHistory;

  String get emergencyContacts;

  String get logOut;

  String get areYouSureYouWantToLogoutThisApp;

  String get whatWouldYouLikeToGo;

  String get enterYourDestination;

  String get currentLocation;

  String get destinationLocation;

  String get chooseOnMap;

  String get profile;

  String get privacyPolicy;

  String get helpSupport;

  String get termsConditions;

  String get aboutUs;

  String get lookingForNearbyDrivers;

  String get weAreLookingForNearDriversAcceptsYourRide;

  String get get;

  String get rides;

  String get people;

  String get done;

  String get availableOffers;

  String get off;

  String get sendOTP;

  String get carModel;

  String get sos;

  String get driverReview;

  String get signInUsingYourMobileNumber;

  String get otp;

  String get newRideRequested;

  String get accepted;

  String get arriving;

  String get arrived;

  String get inProgress;

  String get cancelled;

  String get completed;

  String get pleaseEnableLocationPermission;

  String get pending;

  String get failed;

  String get paid;

  String get male;

  String get female;

  String get other;

  String get deleteAccount;

  String get account;

  String get areYouSureYouWantPleaseReadAffect;

  String get deletingAccountEmail;

  String get areYouSureYouWantDeleteAccount;

  String get yourInternetIsNotWorking;

  String get allow;

  String get mostReliableMightyRiderApp;

  String get toEnjoyYourRideExperiencePleaseAllowPermissions;

  String get txtURLEmpty;

  String get lblFollowUs;

  String get duration;

  String get paymentVia;

  String get demoMsg;

  String get findPlace;

  String get pleaseWait;

  String get selectPlace;

  String get placeNotInArea;

  String get youCannotChangePhoneNumber;

  String get complainList;

  String get writeMsg;

  String get pleaseEnterMsg;

  String get viewAll;

  String get pleaseSelectRating;

  String get moneyDebit;

  String get pleaseAcceptTermsOfServicePrivacyPolicy;

  String get rememberMe;

  String get iAgreeToThe;

  String get driverInformation;

  String get nameFieldIsRequired;

  String get phoneNumberIsRequired;

  String get enterName;

  String get enterContactNumber;

  String get invoice;

  String get customerName;

  String get sourceLocation;

  String get invoiceNo;

  String get invoiceDate;

  String get orderedDate;

  String get lblCarNumberPlate;

  String get lblRide;

  String get lblRideInformation;

  String get lblWhereAreYou;

  String get lblDropOff;

  String get lblDistance;

  String get lblSomeoneElse;

  String get lblYou;

  String get lblWhoRidingMsg;

  String get lblNext;

  String get lblLessWalletAmount;

  String get lblPayWhenEnds;

  String get maximum;

  String get required;

  String get minimum;

  String get withDraw;

  String get withdrawHistory;

  String get approved;

  String get requested;

  String get minimumFare;

  String get cancelRide;

  String get cancelledReason;

  String get selectReason;

  String get writeReasonHere;

  String get driverGoingWrongDirection;

  String get pickUpTimeTakingTooLong;

  String get driverAskedMeToCancel;

  String get others;

  String get baseFare;

  String get perDistance;

  String get perMinDrive;

  String get perMinWait;

  String get min;

  String get unsupportedPlateForm;

  String get invoiceCapital;

  String get description;

  String get price;

  String get gallery;

  String get camera;

  String get bankInfoUpdated;

  String get bankInfo;

  String get bankName;

  String get bankCode;

  String get accountHolderName;

  String get accountNumber;

  String get updateBankDetail;

  String get addBankDetail;

  String get locationNotAvailable;

  String get servicesNotFound;

  String get paymentFailed;

  String get checkConsoleForError;

  String get transactionFailed;

  String get transactionSuccessful;

  String get payWithCard;

  String get success;

  String get skip;

  String get declined;

  String get validateOtp;

  String get otpCodeHasBeenSentTo;

  String get pleaseEnterOtp;

  String get selectSources;

  String get whoWillBeSeated;

  String get via;

  String get status;

  String get riderInformation;

  String get minutePrice;

  String get waitingTimePrice;

  String get additionalFees;

  String get settings;

  String get welcome;

  String get signContinue;

  String get passwordLength;

  String get bothPasswordNotMatch;

  String get missingBankDetail;

  String get close;
  String get copied;
  String get defineStopPoints;
  String get noStopPoints;
}
