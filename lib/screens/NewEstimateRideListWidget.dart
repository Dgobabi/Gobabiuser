import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/components/OrderDialogWidget.dart';
import '../screens/WalletScreen.dart';
import '../utils/Extensions/context_extension.dart';
import '../screens/ReviewScreen.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../../components/CouPonWidget.dart';
import '../../components/RideAcceptWidget.dart';
import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../components/BookingWidget.dart';
import '../components/CarDetailWidget.dart';
import '../model/CurrentRequestModel.dart';
import '../model/EstimatePriceModel.dart';
import '../utils/images.dart';
import 'DashBoardScreen.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NewEstimateRideListWidget extends StatefulWidget {
  final LatLng sourceLatLog;
  final LatLng destinationLatLog;
  final String sourceTitle;
  final String destinationTitle;
  bool isCurrentRequest;
  final int? servicesId;
  final int? id;

  NewEstimateRideListWidget(
      {required this.sourceLatLog,
      required this.destinationLatLog,
      required this.sourceTitle,
      required this.destinationTitle,
      this.isCurrentRequest = false,
      this.servicesId,
      this.id});

  @override
  NewEstimateRideListWidgetState createState() =>
      NewEstimateRideListWidgetState();
}

class NewEstimateRideListWidgetState extends State<NewEstimateRideListWidget> {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _googleMapController;
  final Set<Marker> markers = {};
  String countryCode = defaultCountryCode;
  Set<Polyline> _polyLines = Set<Polyline>();

  late PolylinePoints polylinePoints;
  late Marker sourceMarker;
  late Marker destinationMarker;
  late LatLng userLatLong;
  late DateTime scheduleData;

  double locationDistance = 0.0;
  String? distanceUnit = 'KM';
  double? durationOfDrop = 0.0;

  double? distance = 0;

  TextEditingController promoCode = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool isBooking = false;
  bool isRideSelection = false;
  bool isOther = true;

  int selectedIndex = 0;
  int rideRequestId = 0;
  num mTotalAmount = 0;
  String _myVariable = "";
  String? mSelectServiceAmount;

  List<String> cashList = ['cash', 'wallet'];
  List<ServicesListData> serviceList = [];
  List<LatLng> polylineCoordinates = [];

  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destinationIcon;
  late BitmapDescriptor driverIcon;

  LatLng? driverLatitudeLocation;

  String paymentMethodType = '';

  ServicesListData? servicesListData;
  OnRideRequest? rideRequest;
  Driver? driverData;
  Timer? timer;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    init();
    Timer.periodic(Duration(seconds: 40), (Timer timer) {
      updateLogic();
      //  locationPermission();
      //getCurrentRequest();
    });
  }

  Future<void> speakText(String text) async {
    print("PARLE");
    await flutterTts.setLanguage("fr-fr");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("$text");
  }

  void updateLogic() {
    // Your logic to be updated every 5 seconds
    // For example, you can call getCurrentRequest() or any other logic you want.
    //   locationPermission();
    /// getCurrentRequest();
    //   getCurrentUserLocation();
    // getCurrentUserLocation();
    //getCurrentRequest();
    // locationPermission();
    // Add other logic as needed

    // init();
  }

  void init() async {
    _loadVariable();
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), SourceIcon);
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), DestinationIcon);
    driverIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), DriverIcon);
    getServiceList();
    getCurrentRequest();
    mqttForUser();
    if (!widget.isCurrentRequest) getNewService();
    isBooking = widget.isCurrentRequest;
    print("current req is booking $isBooking");
    getWalletData().then((value) {
      mTotalAmount = value.totalAmount!;
    }).catchError((error) {
      log('${error.toString()}');
    });
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) {
      if (value.rideRequest != null || value.onRideRequest != null) {
        rideRequest = value.rideRequest ?? value.onRideRequest;
      }
      if (value.driver != null) {
        driverData = value.driver!;
      }

      if (rideRequest != null) {
        setState(() {});
        if (driverData != null && rideRequest!.status != COMPLETED) {
          timer = Timer.periodic(
              Duration(seconds: 10), (Timer t) => getUserDetailLocation());
          if (rideRequest!.status == ACCEPTED) {
            speakText("Un chauffeur a pris en charge votre course");
          } else if (rideRequest!.status == ARRIVED) {
            speakText("Votre chauffeur est arrivé");
          }
        } else {
          timer?.cancel();
          timer = null;
        }
      }
      if (rideRequest!.status == COMPLETED &&
          rideRequest != null &&
          driverData != null) {
        timer!.cancel();
        timer = null;
        launchScreen(context,
            ReviewScreen(rideRequest: rideRequest!, driverData: driverData),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            isNewTask: true);
      }
    }).catchError((error) {
      log(error.toString());
    });
  }

  void _loadVariable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _myVariable = prefs.getString('myVariable') ?? "";
      mSelectServiceAmount = _myVariable;
    });
  }

  void _updateVariable(String newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('myVariable', newValue);
    setState(() {
      _myVariable = newValue;
    });
  }

  Future<void> getServiceList() async {
    markers.clear();
    polylinePoints = PolylinePoints();
    setPolyLines(
      sourceLocation:
          LatLng(widget.sourceLatLog.latitude, widget.sourceLatLog.longitude),
      destinationLocation: LatLng(widget.destinationLatLog.latitude,
          widget.destinationLatLog.longitude),
      driverLocation: driverLatitudeLocation,
    );
    MarkerId id = MarkerId('Source');
    markers.add(
      Marker(
        markerId: id,
        position:
            LatLng(widget.sourceLatLog.latitude, widget.sourceLatLog.longitude),
        infoWindow: InfoWindow(title: widget.sourceTitle),
        icon: sourceIcon,
      ),
    );
    MarkerId id2 = MarkerId('DriverLocation');
    markers.remove(id2);

    if (rideRequest != null &&
        rideRequest!.stopLatitude != null &&
        rideRequest!.stopLatitude!.isNotEmpty) {
      MarkerId idStop = MarkerId('stopLocation');
      markers.add(
        Marker(
          markerId: idStop,
          position: LatLng(double.parse(rideRequest!.stopLatitude!),
              double.parse(rideRequest!.stopLongitude!)),
          infoWindow: InfoWindow(title: rideRequest!.stopAddress!),
          icon: destinationIcon,
        ),
      );
    }

    MarkerId id3 = MarkerId('Destination');
    markers.remove(id3);
    rideRequest != null &&
            (rideRequest!.status == ACCEPTED ||
                rideRequest!.status == ARRIVING ||
                rideRequest!.status == ARRIVED)
        ? markers.add(
            Marker(
              markerId: id2,
              position: driverLatitudeLocation!,
              icon: driverIcon,
            ),
          )
        : markers.add(
            Marker(
              markerId: id3,
              position: LatLng(widget.destinationLatLog.latitude,
                  widget.destinationLatLog.longitude),
              infoWindow: InfoWindow(title: widget.destinationTitle),
              icon: destinationIcon,
            ),
          );
    setState(() {});
  }

  Future<void> getNewService({bool coupon = false}) async {
    appStore.setLoading(true);
    Map req = {
      "pick_lat": widget.sourceLatLog.latitude,
      "pick_lng": widget.sourceLatLog.longitude,
      "drop_lat": widget.destinationLatLog.latitude,
      "drop_lng": widget.destinationLatLog.longitude,
      if (coupon) "coupon_code": promoCode.text.trim(),
    };
    await estimatePriceList(req).then((value) {
      appStore.setLoading(false);
      serviceList.clear();
      value.data!.sort((a, b) => a.totalAmount!.compareTo(b.totalAmount!));
      serviceList.addAll(value.data!);
      if (serviceList.isNotEmpty) {
        locationDistance = serviceList[0].dropoffDistanceInKm!.toDouble();

        if (serviceList[0].distanceUnit == 'km') {
          locationDistance = serviceList[0].dropoffDistanceInKm!.toDouble();
          distanceUnit = 'km';
        } else {
          locationDistance =
              serviceList[0].dropoffDistanceInKm!.toDouble() * 0.621371;
          distanceUnit = 'mile';
        }
        durationOfDrop = serviceList[0].duration!.toDouble();
      }

      if (serviceList.isNotEmpty) servicesListData = serviceList[0];
      if (serviceList.isNotEmpty)
        paymentMethodType = serviceList[0].paymentMethod!;
      if (serviceList.isNotEmpty)
        cashList = paymentMethodType == 'cash_wallet'
            ? cashList = ['cash', 'wallet']
            : cashList = [paymentMethodType];
      if (serviceList.isNotEmpty) {
        if (serviceList[0].discountAmount != 0) {
          mSelectServiceAmount =
              serviceList[0].subtotal!.toStringAsFixed(fixedDecimal);
        } else {
          mSelectServiceAmount =
              serviceList[0].totalAmount!.toStringAsFixed(fixedDecimal);
        }
      }
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString(), print: true);
    });
  }

  Future<void> getCouponNewService() async {
    appStore.setLoading(true);
    Map req = {
      "pick_lat": widget.sourceLatLog.latitude,
      "pick_lng": widget.sourceLatLog.longitude,
      "drop_lat": widget.destinationLatLog.latitude,
      "drop_lng": widget.destinationLatLog.longitude,
      "coupon_code": promoCode.text.trim(),
    };
    await estimatePriceList(req).then((value) {
      appStore.setLoading(false);
      serviceList.clear();
      value.data!.sort((a, b) => a.totalAmount!.compareTo(b.totalAmount!));
      serviceList.addAll(value.data!);
      if (serviceList.isNotEmpty) {
        locationDistance =
            serviceList[selectedIndex].dropoffDistanceInKm!.toDouble();

        if (serviceList[selectedIndex].distanceUnit == 'km') {
          locationDistance =
              serviceList[selectedIndex].dropoffDistanceInKm!.toDouble();
          distanceUnit = 'km';
        } else {
          locationDistance =
              serviceList[selectedIndex].dropoffDistanceInKm!.toDouble() *
                  0.621371;
          distanceUnit = 'mile';
        }
        durationOfDrop = serviceList[selectedIndex].duration!.toDouble();
      }
      if (serviceList.isNotEmpty) servicesListData = serviceList[selectedIndex];
      if (serviceList.isNotEmpty)
        cashList = paymentMethodType == 'cash_wallet'
            ? cashList = ['cash', 'wallet']
            : cashList = [paymentMethodType];
      if (serviceList.isNotEmpty) {
        if (serviceList[selectedIndex].discountAmount != 0) {
          mSelectServiceAmount = serviceList[selectedIndex]
              .subtotal!
              .toStringAsFixed(fixedDecimal);
        } else {
          mSelectServiceAmount = serviceList[selectedIndex]
              .totalAmount!
              .toStringAsFixed(fixedDecimal);
        }
      }
      setState(() {});
      Navigator.pop(context);
    }).catchError((error) {
      promoCode.clear();
      Navigator.pop(context);
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  Future<void> setPolyLines(
      {required LatLng sourceLocation,
      required LatLng destinationLocation,
      LatLng? driverLocation}) async {
    _polyLines.clear();
    polylineCoordinates.clear();
    var result2 = null;
    var result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAP_API_KEY,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      rideRequest != null &&
              (rideRequest!.status == ACCEPTED ||
                  rideRequest!.status == ARRIVING ||
                  rideRequest!.status == ARRIVED)
          ? PointLatLng(driverLocation!.latitude, driverLocation.longitude)
          : PointLatLng(
              destinationLocation.latitude, destinationLocation.longitude),
    );
    if (rideRequest != null && rideRequest!.stopLatitude != null) {
      result2 = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAP_API_KEY,
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(double.parse(rideRequest!.stopLatitude!),
            double.parse(rideRequest!.stopLongitude!)),
      );
    }
    if (result.points.isNotEmpty) {
      result.points.forEach((element) {
        polylineCoordinates.add(LatLng(element.latitude, element.longitude));
      });
      _polyLines.add(Polyline(
        visible: true,
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
      ));
      setState(() {});
    }
    if (result2.points.isNotEmpty) {
      polylineCoordinates.clear();
      result2.points.forEach((element) {
        polylineCoordinates.add(LatLng(element.latitude, element.longitude));
      });
      _polyLines.add(Polyline(
        visible: true,
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
      ));
      polylineCoordinates.add(
          LatLng(result2.points.last.latitude, result2.points.last.longitude));
      polylineCoordinates.add(
          LatLng(result.points.last.latitude, result.points.last.longitude));

      _polyLines.add(Polyline(
        visible: true,
        width: 5,
        polylineId: PolylineId('poly'),
        color: Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
      ));
      setState(() {});
    }
  }

  onMapCreated(GoogleMapController controller) async {
    _googleMapController = controller;
    _controller.complete(controller);
    await Future.delayed(Duration(milliseconds: 50));
    _googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(
                widget.sourceLatLog.latitude <=
                        widget.destinationLatLog.latitude
                    ? widget.sourceLatLog.latitude
                    : widget.destinationLatLog.latitude,
                widget.sourceLatLog.longitude <=
                        widget.destinationLatLog.longitude
                    ? widget.sourceLatLog.longitude
                    : widget.destinationLatLog.longitude),
            northeast: LatLng(
                widget.sourceLatLog.latitude <=
                        widget.destinationLatLog.latitude
                    ? widget.destinationLatLog.latitude
                    : widget.sourceLatLog.latitude,
                widget.sourceLatLog.longitude <=
                        widget.destinationLatLog.longitude
                    ? widget.destinationLatLog.longitude
                    : widget.sourceLatLog.longitude)),
        100));
    setState(() {});
  }

// ACTION DU BOUTON SUIVANT APRES LE CHOIX DU TAXI ET DE LA PERSONNE QUI PART
  Future<void> saveBookingData() async {
    if (isOther == false && nameController.text.isEmpty) {
      return toast(language.nameFieldIsRequired);
    } else if (isOther == false && phoneController.text.isEmpty) {
      return toast(language.phoneNumberIsRequired);
    }
    appStore.setLoading(true);
    Map req = {
      "rider_id": sharedPref.getInt(USER_ID).toString(),
      "service_id": servicesListData!.id.toString(),
      "datetime": DateTime.now().toString(),
      "start_latitude": widget.sourceLatLog.latitude.toString(),
      "start_longitude": widget.sourceLatLog.longitude.toString(),
      "start_address": widget.sourceTitle,
      "end_latitude": widget.destinationLatLog.latitude.toString(),
      "end_longitude": widget.destinationLatLog.longitude.toString(),
      "end_address": widget.destinationTitle,
      "seat_count": servicesListData!.capacity.toString(),
      "status": NEW_RIDE_REQUESTED,
      "montant": amountRounded(mSelectServiceAmount),
      // "montant": "1000",
      "payment_type": isOther == false
          ? 'cash'
          : paymentMethodType == 'cash_wallet'
              ? 'cash'
              : paymentMethodType,
      if (promoCode.text.isNotEmpty) "coupon_code": promoCode.text,
      "is_schedule": 0,
      if (isOther == false) "is_ride_for_other": 1,
      if (isOther == false)
        "other_rider_data": {
          "name": nameController.text.trim(),
          "contact_number": '$countryCode${phoneController.text.trim()}',
        }
    };

    log('la requete $req');
    await saveRideRequest(req).then((value) async {
      rideRequestId = value.rideRequestId!;
      widget.isCurrentRequest = true;
      isBooking = true;
      appStore.setLoading(false);
      setState(() {});
      _updateVariable(mSelectServiceAmount!);
      print("la requete succes");
    }).catchError((error) {
      print("la requete erreur");
      appStore.setLoading(false);
      //toast(error.toString());
    });
  }

  mqttForUser() async {
    client.setProtocolV311();
    client.logging(on: true);
    client.keepAlivePeriod = 120;
    client.autoReconnect = true;
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;

    try {
      await client.connect('gobabi', '7evh6AP9njS2Kt');
      //await client.connect();
    } on NoConnectionException catch (e) {
      debugPrint(e.toString());
      client.connect('gobabi', '7evh6AP9njS2Kt');
      // client.connect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.onSubscribed = onSubscribed;

      debugPrint('connected');
    } else if (client.connectionStatus!.state ==
        MqttConnectionState.disconnected) {
      client.connect('gobabi', '7evh6AP9njS2Kt');
      //client.connect();
      debugPrint('connected');
    } else if (client.connectionStatus!.state ==
        MqttConnectionState.disconnecting) {
      client.connect('gobabi', '7evh6AP9njS2Kt');
      //  client.connect();
      debugPrint('connected');
    } else if (client.connectionStatus!.state == MqttConnectionState.faulted) {
      client.connect('gobabi', '7evh6AP9njS2Kt');
      // client.connect();
      debugPrint('connected');
    }

    void onconnected() {
      debugPrint('connected');
    }

    client.subscribe(
        mMQTT_UNIQUE_TOPIC_NAME +
            'ride_request_status_' +
            sharedPref.getInt(USER_ID).toString(),
        MqttQos.atLeastOnce);

    print(mMQTT_UNIQUE_TOPIC_NAME);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print("jsonDecode(pt)['success_type']" +
          jsonDecode(pt)['success_type'].toString());

      if (jsonDecode(pt)['success_type'] == ACCEPTED ||
          jsonDecode(pt)['success_type'] == ARRIVING ||
          jsonDecode(pt)['success_type'] == ARRIVED ||
          jsonDecode(pt)['success_type'] == IN_PROGRESS) {
        isBooking = true;
        getCurrentRequest();

        var statut = jsonDecode(pt)['success_type'] == ACCEPTED;

        // else if (statut == IN_PROGRESS) {
        //   speakText("La course a débuté");
        // }
      } else if (jsonDecode(pt)['success_type'] == CANCELED) {
        launchScreen(context, DashBoardScreen(), isNewTask: true);
      } else if (jsonDecode(pt)['success_type'] == COMPLETED) {
        if (timer != null) timer!.cancel();
        getCurrentRequest();
        if (timer != null) timer!.cancel();
      } else if (appStore.isRiderForAnother == "1" &&
          jsonDecode(pt)['success_type'] == SUCCESS) {
        if (timer != null) timer!.cancel();
        launchScreen(context, DashBoardScreen(), isNewTask: true);
      }
    });
    client.onConnected = onconnected;
  }

  void onConnected() {
    log('Connected');
  }

  void onSubscribed(String topic) {
    log('Subscription confirmed for topic $topic');
  }

  Future<void> getUserDetailLocation() async {
    if (rideRequest!.status != COMPLETED) {
      getUserDetail(userId: driverData!.id).then((value) {
        driverLatitudeLocation = LatLng(double.parse(value.data!.latitude!),
            double.parse(value.data!.longitude!));
        getServiceList();
      }).catchError((error) {
        log(error.toString());
      });
    } else {
      if (timer != null) timer?.cancel();
    }
  }

  Future<void> cancelRequest() async {
    Map req = {
      "id": rideRequestId == 0 ? widget.id : rideRequestId,
      "cancel_by": RIDER,
      "status": CANCELED,
    };
    await rideRequestUpdate(
            request: req,
            rideId: rideRequestId == 0 ? widget.id : rideRequestId)
        .then((value) async {
      launchScreen(context, DashBoardScreen(), isNewTask: true);

      toast(value.message);
    }).catchError((error) {
      log(error.toString());
    });
  }

  @override
  void dispose() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((value) {
      polylineSource = LatLng(value.latitude, value.longitude);
    });
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mSomeOnElse() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child:
                    Text(language.lblRideInformation, style: boldTextStyle()),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              controller: nameController,
              autoFocus: false,
              isValidationRequired: false,
              textFieldType: TextFieldType.NAME,
              keyboardType: TextInputType.name,
              errorThisFieldRequired: language.thisFieldRequired,
              decoration: inputDecoration(context, label: language.enterName),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              controller: phoneController,
              autoFocus: false,
              isValidationRequired: false,
              textFieldType: TextFieldType.PHONE,
              keyboardType: TextInputType.number,
              errorThisFieldRequired: language.thisFieldRequired,
              decoration: inputDecoration(
                context,
                label: language.enterContactNumber,
                prefixIcon: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCodePicker(
                        padding: EdgeInsets.zero,
                        initialSelection: countryCode,
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
                          countryCode = c!.dialCode!;
                        },
                        onChanged: (c) {
                          countryCode = c.dialCode!;
                        },
                      ),
                      VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              text: language.done,
              textStyle: boldTextStyle(color: Colors.white),
              color: primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  double calculateTotalAmount({required ServicesListData? serviceList}) {
    num? baseFare = serviceList!.baseFare;
    num? perDistance = serviceList.perDistance;
    num? perMinuteDrive = serviceList.perMinuteDrive;
    num? distance = serviceList.distance;
    num? duration = serviceList.duration;
    num? discountAmount = serviceList.discountAmount;
    log("discountAmount 0-----$discountAmount");

    num? distancePrice = distance! * perDistance!;

    num? timePrice = duration! * perMinuteDrive!;
    num? totalAmount = baseFare! + distancePrice + timePrice;
    if (totalAmount < serviceList.minimumFare!) {
      totalAmount = serviceList.minimumFare!;
    }
    if (promoCode.text.isNotEmpty) {
      log("Total amaount $totalAmount");
      totalAmount = totalAmount - discountAmount!;
    }
    return totalAmount.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leadingWidth: 40,
        leading: Visibility(
          visible: !isBooking,
          child: inkWellWidget(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.all(0),
              decoration: BoxDecoration(
                  color: context.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dividerColor)),
              child: Icon(Icons.close, color: context.iconColor, size: 20),
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            // height: !isBooking
            //     ? (isRideSelection == false && appStore.isRiderForAnother == "1" ? MediaQuery.of(context).size.height * 0.65 : MediaQuery.of(context).size.height * 0.55)
            //     : MediaQuery.of(context).size.height * 0.55,
            height: MediaQuery.of(context).size.height,
            child: GoogleMap(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.25),
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.sourceLatLog ??
                    LatLng(sharedPref.getDouble(LATITUDE)!,
                        sharedPref.getDouble(LONGITUDE)!),
                zoom: 17,
              ),
              markers: markers,
              mapType: MapType.normal,
              polylines: _polyLines,
            ),
          ),
          !isBooking
              // VOIT SI ON EST ENCORE EN TRAIN DE BOOKER LA COURSE OU SI LE CHAUFFEUR A ACCEPTE
              ? bookRideWidget()
              : Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(defaultRadius),
                          topRight: Radius.circular(defaultRadius))),
                  child: rideRequest != null
                      ? rideRequest!.status == NEW_RIDE_REQUESTED
                          ? BookingWidget(id: widget.id, isLast: true)
                          : OrderDialogWidget(
                              rideRequest: rideRequest,
                              driverData: driverData,
                              travelPrice: mSelectServiceAmount)
                      // RideAcceptWidget(
                      //     rideRequest: rideRequest,
                      //     driverData: driverData,
                      //     travelPrice: mSelectServiceAmount)
                      : BookingWidget(
                          id: rideRequestId == 0 ? widget.id : rideRequestId,
                          isLast: true),
                ),
          Observer(builder: (context) {
            return Visibility(
                visible: appStore.isLoading, child: loaderWidget());
          }),
        ],
      ),
    );
  }

  Widget bookRideWidget() {
    print("current req bookride");
    return Stack(
      children: [
        Visibility(
          visible: serviceList.isNotEmpty,
          child: Container(
            // height: isRideSelection == false && appStore.isRiderForAnother == "1" ? MediaQuery.of(context).size.height * 0.35 : MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(defaultRadius),
                    topRight: Radius.circular(defaultRadius))),
            child: SingleChildScrollView(
              child:
                  isRideSelection == false && appStore.isRiderForAnother == "1"
                      ? serviceSelectWidget()
                      : riderSelectionWidget(),
            ),
          ),
        ),
        Visibility(
          visible: !appStore.isLoading && serviceList.isEmpty,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(defaultRadius),
                    topRight: Radius.circular(defaultRadius))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                emptyWidget(),
                Text(language.servicesNotFound, style: boldTextStyle()),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget riderSelectionWidget() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: 16),
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          Text(language.whoWillBeSeated, style: primaryTextStyle(size: 18)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              inkWellWidget(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: commonCachedNetworkImage(
                                appStore.userProfile.validate(),
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover),
                          ),
                          if (isOther)
                            Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54),
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(language.lblYou, style: primaryTextStyle()),
                    ],
                  ),
                  onTap: () {
                    isOther = true;
                    setState(() {});
                  }),
              SizedBox(width: 30),
              inkWellWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: textSecondaryColorGlobal, width: 1)),
                            padding: EdgeInsets.all(12),
                            child: Image.asset(ic_add_user, fit: BoxFit.fill),
                          ),
                          if (!isOther)
                            Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54),
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(language.lblSomeoneElse, style: primaryTextStyle()),
                    ],
                  ),
                  onTap: () {
                    isOther = false;
                    showDialog(
                      context: context,
                      builder: (_) {
                        return StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.all(0),
                            content: mSomeOnElse(),
                          );
                        });
                      },
                    ).then((value) {
                      setState(() {});
                    });
                    setState(() {});
                  }),
            ],
          ),
          SizedBox(height: 12),
          Text(language.lblWhoRidingMsg, style: secondaryTextStyle()),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: AppButtonWidget(
              onTap: () {
                saveBookingData();
              },
              text: language.bookNow,
              textStyle: boldTextStyle(color: Colors.white),
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceSelectWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(bottom: 8, top: 16),
            height: 5,
            width: 70,
            decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(defaultRadius)),
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.only(left: 8, right: 8),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: serviceList.map((e) {
              return GestureDetector(
                onTap: () {
                  if (e.discountAmount != 0) {
                    mSelectServiceAmount =
                        e.subtotal!.toStringAsFixed(fixedDecimal);
                  } else {
                    mSelectServiceAmount =
                        e.totalAmount!.toStringAsFixed(fixedDecimal);
                  }
                  selectedIndex = serviceList.indexOf(e);
                  servicesListData = e;
                  if (e.distanceUnit == 'km') {
                    locationDistance = e.dropoffDistanceInKm!.toDouble();
                    distanceUnit = 'KM';
                  } else {
                    locationDistance =
                        e.dropoffDistanceInKm!.toDouble() * 0.621371;
                    distanceUnit = 'Mile';
                  }
                  durationOfDrop = serviceList[0].duration!.toDouble();
                  paymentMethodType = e.paymentMethod!;
                  cashList = paymentMethodType == 'cash_wallet'
                      ? cashList = ['cash', 'wallet']
                      : cashList = [paymentMethodType];
                  print('LEPRIX:${mSelectServiceAmount}');
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  margin: EdgeInsets.only(top: 16, left: 8, right: 8),
                  decoration: BoxDecoration(
                    color: selectedIndex == serviceList.indexOf(e)
                        ? primaryColor
                        : Colors.white,
                    border: Border.all(color: dividerColor),
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      commonCachedNetworkImage(e.serviceImage.validate(),
                          height: 50,
                          width: 100,
                          fit: BoxFit.cover,
                          alignment: Alignment.center),
                      SizedBox(height: 6),
                      Text(e.name.validate(),
                          style: boldTextStyle(
                              color: selectedIndex == serviceList.indexOf(e)
                                  ? Colors.white
                                  : textPrimaryColorGlobal)),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /*    Text(language.capacity,
                              style: secondaryTextStyle(
                                  size: 12,
                                  color: selectedIndex == serviceList.indexOf(e)
                                      ? Colors.white
                                      : textPrimaryColorGlobal)),
                          SizedBox(width: 4),
                          Text(e.capacity.toString() + " + 1",
                              style: secondaryTextStyle(
                                  color: selectedIndex == serviceList.indexOf(e)
                                      ? Colors.white
                                      : textPrimaryColorGlobal)),*/
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                printAmount(e.totalAmount!
                                    .toStringAsFixed(digitAfterDecimal)),
                                style: e.discountAmount != 0
                                    ? secondaryTextStyle(
                                        color: selectedIndex ==
                                                serviceList.indexOf(e)
                                            ? Colors.white
                                            : textSecondaryColorGlobal,
                                        textDecoration: e.discountAmount != 0
                                            ? TextDecoration.lineThrough
                                            : null,
                                      )
                                    : boldTextStyle(
                                        color: selectedIndex ==
                                                serviceList.indexOf(e)
                                            ? Colors.white
                                            : textPrimaryColorGlobal,
                                      ),
                              ),
                              if (e.discountAmount != 0)
                                Text(
                                  printAmount(e.subtotal!
                                      .toStringAsFixed(digitAfterDecimal)),
                                  style: boldTextStyle(
                                      color: selectedIndex ==
                                              serviceList.indexOf(e)
                                          ? Colors.white
                                          : primaryColor),
                                ),
                            ],
                          ),
                          SizedBox(width: 8),
                          inkWellWidget(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                        topRight:
                                            Radius.circular(defaultRadius),
                                        topLeft:
                                            Radius.circular(defaultRadius))),
                                builder: (_) {
                                  return CarDetailWidget(service: e);
                                },
                              );
                            },
                            child: Icon(Icons.info_outline_rounded,
                                size: 16,
                                color: selectedIndex == serviceList.indexOf(e)
                                    ? Colors.white
                                    : textPrimaryColorGlobal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
        inkWellWidget(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) {
                return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                  return Observer(builder: (context) {
                    return Stack(
                      children: [
                        AlertDialog(
                          contentPadding: EdgeInsets.all(16),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(language.paymentMethod,
                                        style: boldTextStyle()),
                                    inkWellWidget(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Icon(Icons.close,
                                            color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(language.chooseYouPaymentLate,
                                    style: secondaryTextStyle()),
                                // Text(isOther.toString(),
                                //   style: secondaryTextStyle()),
                                isOther == false
                                    ? RadioListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.trailing,
                                        activeColor: primaryColor,
                                        value: 'cash',
                                        groupValue: 'cash',
                                        title: Text(language.cash,
                                            style: boldTextStyle()),
                                        onChanged: (String? val) {},
                                      )
                                    : Column(
                                        children: cashList.map((e) {
                                          return RadioListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                            activeColor: primaryColor,
                                            value: e,
                                            groupValue: paymentMethodType ==
                                                    'cash_wallet'
                                                ? 'cash'
                                                : paymentMethodType,
                                            title: Text(paymentStatus(e),
                                                style: boldTextStyle()),
                                            onChanged: (String? val) {
                                              paymentMethodType = val!;
                                              setState(() {});
                                            },
                                          );
                                        }).toList(),
                                      ),
                                SizedBox(height: 16),
                                AppTextField(
                                  controller: promoCode,
                                  autoFocus: false,
                                  textFieldType: TextFieldType.NAME,
                                  keyboardType: TextInputType.emailAddress,
                                  errorThisFieldRequired:
                                      language.thisFieldRequired,
                                  readOnly: false,
                                  /* onTap: () async {
                                    var data = await showModalBottomSheet(
                                      context: context,
                                      builder: (_) {
                                        return CouPonWidget();
                                      },
                                    );
                                    if (data != null) {
                                      promoCode.text = data;
                                    }
                                  },**/
                                  decoration: inputDecoration(context,
                                      label: language.enterPromoCode,
                                      suffixIcon: promoCode.text.isNotEmpty
                                          ? inkWellWidget(
                                              onTap: () {
                                                getNewService(coupon: false);
                                                promoCode.clear();
                                              },
                                              child: Icon(Icons.close,
                                                  color: Colors.black,
                                                  size: 25),
                                            )
                                          : null),
                                ),
                                SizedBox(height: 16),
                                AppButtonWidget(
                                  width: MediaQuery.of(context).size.width,
                                  text: language.confirm,
                                  textStyle: boldTextStyle(color: Colors.white),
                                  color: primaryColor,
                                  onTap: () {
                                    if (promoCode.text.isNotEmpty) {
                                      getCouponNewService();
                                      // getNewService(coupon: true);
                                    } else {
                                      //  getNewService();
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Observer(builder: (context) {
                          return Visibility(
                              visible: appStore.isLoading,
                              child: loaderWidget());
                        }),
                      ],
                    );
                  });
                });
              },
            ).then((value) {
              setState(() {});
            });
          },
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
                border: Border.all(color: dividerColor),
                borderRadius: BorderRadius.circular(defaultRadius)),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.paymentVia, style: secondaryTextStyle(size: 12)),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(defaultRadius)),
                      child: Icon(Icons.wallet_outlined,
                          size: 20, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isOther == false
                                      ? language.cash
                                      : paymentMethodType == 'cash_wallet'
                                          ? language.cash
                                          : paymentStatus(paymentMethodType),
                                  style: boldTextStyle(size: 14),
                                ),
                              ),
                              if (mSelectServiceAmount != null &&
                                  paymentMethodType != 'cash_wallet' &&
                                  paymentMethodType == 'wallet' &&
                                  double.parse(mSelectServiceAmount!) >=
                                      mTotalAmount.toDouble())
                                inkWellWidget(
                                  onTap: () {
                                    launchScreen(context, WalletScreen())
                                        .then((value) {
                                      init();
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: dividerColor),
                                        color: primaryColor,
                                        borderRadius: radius()),
                                    child: Text(language.addMoney,
                                        style: primaryTextStyle(
                                            size: 14, color: Colors.white)),
                                  ),
                                )
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                              paymentMethodType != 'cash_wallet'
                                  ? language.forInstantPayment
                                  : language.lblPayWhenEnds,
                              style: secondaryTextStyle(size: 12)),
                          if (mSelectServiceAmount != null &&
                              paymentMethodType != 'cash_wallet' &&
                              paymentMethodType == 'wallet' &&
                              double.parse(mSelectServiceAmount!) >=
                                  mTotalAmount.toDouble())
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(language.lblLessWalletAmount,
                                  style: boldTextStyle(
                                      size: 12,
                                      color: Colors.red,
                                      letterSpacing: 0.5,
                                      weight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: AppButtonWidget(
            color: primaryColor,
            onTap: () async {
              if (!isOther) {
                if (nameController.text.isEmptyOrNull ||
                    phoneController.text.isEmptyOrNull) {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.all(0),
                          content: mSomeOnElse(),
                        );
                      });
                    },
                  ).then((value) {
                    setState(() {});
                  });
                } else {
                  isRideSelection = true;
                }
              } else {
                isRideSelection = true;
              }
              setState(() {});
            },
            text: language.lblNext,
            textStyle: boldTextStyle(color: Colors.white),
            width: MediaQuery.of(context).size.width,
          ),
        ),
      ],
    );
  }
}
