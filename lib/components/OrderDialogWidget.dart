import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:user/components/CancelOrderDialog.dart';

import 'package:user/main.dart';
import 'package:user/model/CurrentRequestModel.dart';
import 'package:user/model/LoginResponse.dart';
import 'package:user/network/RestApis.dart';
import 'package:user/screens/DashBoardScreen.dart';
import 'package:user/screens/NewEstimateRideListWidget.dart';
import 'package:user/screens/ReviewScreen.dart';
import 'package:user/screens/RidePaymentDetailScreen.dart';
import 'package:user/utils/Colors.dart';
import 'package:user/utils/Common.dart';
import 'package:user/utils/Constants.dart';
import 'package:user/utils/Extensions/AppButtonWidget.dart';
import 'package:user/utils/Extensions/StringExtensions.dart';
import 'package:user/utils/Extensions/app_common.dart';
import 'package:user/utils/images.dart';
import 'package:url_launcher/src/url_launcher_uri.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OrderDialogWidget extends StatefulWidget {
  final Driver? driverData;
  OnRideRequest? rideRequest;
  String? travelPrice;
  OrderDialogWidget({this.driverData, this.rideRequest, this.travelPrice});

  @override
  State<OrderDialogWidget> createState() => _OrderDialogWidgetState();
}

class _OrderDialogWidgetState extends State<OrderDialogWidget> {
  UserModel? userData;
  var tempsEstime;
  late Timer _timer;
  double distances = 0;
  int distancesentier = 0;
  double durationInminuite = 0;
  int tempsEstimeEnMinutesEntier = 0;
  OnRideRequest? servicesListData;
  bool shouldShowWidget = false;
  String? mSelectServiceAmount;
  String? stopAdress;
  double? lat1 = 5.3995;
  double? lon1 = -3.9458;
  double? lat2 = 5.3282;
  double? lon2 = -4.0039;
  static const String apiKey =
      'sk.eyJ1IjoieXZlc3BhY28iLCJhIjoiY2xyOXRxcmNlMDgzczJxcGptZ2QxeGttYSJ9.6PZpWGkzDX2DCTeoHu-uNQ';

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Delay for 4 seconds and then set shouldShowWidget to true
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          shouldShowWidget = true;
        });
      }
    });
    _updateData();
    _startTimer();

    print(
        "LE PRIX ${widget.travelPrice}  ${widget.driverData}  ${widget.rideRequest}");

    init();
  }

  void init() async {
    await getUserDetail(userId: widget.rideRequest!.driverId).then((value) {
      sharedPref.remove(IS_TIME);
      appStore.setLoading(false);
      userData = value.data;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("fr-fr");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("$text");
  }

  Future<void> cancelRequest(String reason) async {
    Map req = {
      "id": widget.rideRequest!.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id)
        .then((value) async {
      launchScreen(getContext, DashBoardScreen(), isNewTask: true);

      toast(value.message);
    }).catchError((error) {
      log(error.toString());
    });
  }

  double haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Rayon moyen de la Terre en kilomètres
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);

    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    var distance = R * c;
    return distance;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  ////
  double estimerTemps(double distance, double vitesseMoyenne) {
    // Vitesse moyenne en kilomètres par heure
    return distance / vitesseMoyenne;
  }

////
  ///

  ///
  @override
  void dispose() {
    // Arrêtez le timer lorsqu'il n'est plus nécessaire
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Configurez un timer pour actualiser les données toutes les 10 secondes
    _timer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      _updateData();
    });
  }

  Future<void> _updateData() async {
    // 5.402988587747909, -3.9854060962984805
    //5.3526341036545375, -3.883422224357344

    // Mise à jour des coordonnées des deux points (exemple)
    lat1 = double.tryParse(widget.driverData?.latitude ?? "");
    lon1 = double.tryParse(widget.driverData?.longitude ?? "");
    lat2 = double.tryParse(widget.rideRequest?.startLatitude ?? "");
    lon2 = double.tryParse(widget.rideRequest?.startLongitude ?? "");

    // Calcul de la distance en kilomètres
    String apiUrl =
        'https://api.mapbox.com/directions/v5/mapbox/driving/$lon1,$lat1;$lon2,$lat2?access_token=$apiKey';
    print(apiUrl);
    print("78888");

    try {
      http.Response response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Process the data as needed
        print(data);
        print('po');
        double duration = data['routes'][0]['duration'];
        distances = data['routes'][0]['distance'];
        distances = distances / 1000;
        print('po');
        print(duration);
        print(distances);
        durationInminuite = duration / 60;

        print('Durée de l\'itinéraire : $durationInminuite min');
        tempsEstimeEnMinutesEntier = durationInminuite.toInt();
        if (tempsEstimeEnMinutesEntier == 0) {
          tempsEstimeEnMinutesEntier = int.parse('1');
        }
        print(distances);
        print("pol");
        distances = max(distances, 0);
        // distances = distances.toInt() as double;
        print(distances);
        distancesentier = distances.round();
        print("pol2");

        if (distancesentier < 1) {
          print("pol1");
          distancesentier = -1;
        }
      } else {
        print('Error fetching directions: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching directions: $error');
    }

    // Mettez à jour l'interface utilisateur avec le nouveau temps
    setState(() {
      // Mettez à jour vos variables d'état ici si nécessaire
      // ...
      // lat1 = double.tryParse(widget.driverData?.latitude ?? "");
      // lon1 = double.tryParse(widget.driverData?.longitude ?? "");
      //   lat2 = double.tryParse(widget.rideRequest?.startLatitude ?? "");
      lon2 = double.tryParse(widget.rideRequest?.startLongitude ?? "");
    });

    // Vous pouvez également imprimer le temps mis à jour si nécessaire
    print('Temps estimé en minutes : $tempsEstimeEnMinutesEntier minutes');

    /// nomb= nomb+1;
  }

  ///
  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) {
      servicesListData = value.onRideRequest;

      if (value.onRideRequest == null) {
        launchScreen(context, DashBoardScreen(),
            isNewTask: true,
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
      } else {
        launchScreen(context, RidePaymentDetailScreen(),
            isNewTask: true,
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
      }
    }).catchError((error) {
      log(error.toString());
    });
  }

  Future<void> userReviewData() async {
    //   if (formKey.currentState!.validate()) {
    hideKeyboard(context);
    //    if (rattingData == 0) return toast(language.pleaseSelectRating);
    //    formKey.currentState!.save();
    appStore.setLoading(true);
    Map req = {
      "ride_request_id": widget.rideRequest?.id,
      "rating": 0,
      "comment": "ok",
      //     if (tipController.text.isNotEmpty) "tips": tipController.text,
    };
    await ratingReview(request: req).then((value) {
      appStore.setLoading(false);
      getCurrentRequest();
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
    //   }
  }

  Widget chatCallWidget(IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight,
          borderRadius: BorderRadius.circular(defaultRadius)),
      child: Icon(icon, size: 18, color: primaryColor),
    );
  }

  Future<void> stopRequest(req) async {
    appStore.setLoading(true);
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id)
        .then((value) async {
      appStore.setLoading(false);
      getCurrentRideRequest().then((value) {
        setState(() {
          stopAdress = value.onRideRequest!.stopAddress;
          widget.rideRequest = value.onRideRequest;
        });
        getCouponNewService(value.onRideRequest!);
      });
      toast(value.message);
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> getCouponNewService(OnRideRequest onRideRequest) async {
    appStore.setLoading(true);
    Map req = {
      "pick_lat": onRideRequest.startLatitude,
      "pick_lng": onRideRequest.startLongitude,
      "drop_lat": onRideRequest.endLatitude,
      "drop_lng": onRideRequest.endLongitude,
      "stop_lat": onRideRequest.stopLatitude,
      "stop_lng": onRideRequest.stopLongitude,
      if (onRideRequest.couponCode != null)
        "coupon_code": onRideRequest.couponCode,
    };
    await estimatePriceList(req).then((value) {
      appStore.setLoading(false);
      if (value.data!.isNotEmpty) {
        if (value.data![0].discountAmount != 0) {
          mSelectServiceAmount =
              value.data![0].subtotal!.toStringAsFixed(fixedDecimal);
        } else {
          mSelectServiceAmount =
              value.data![0].totalAmount!.toStringAsFixed(fixedDecimal);
        }
      }
      // Navigator.pop(context);
      launchScreen(
          context,
          NewEstimateRideListWidget(
              sourceLatLog: polylineSource,
              destinationLatLog: polylineDestination,
              sourceTitle: value.data![0].startAddress!,
              destinationTitle: value.data![0].endAddress!),
          pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
    }).catchError((error) {
      appStore.setLoading(false);
      Navigator.pop(context);
      toast(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return // Generated code for this Container Widget...
        SingleChildScrollView(
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Color(0x33000000),
              offset: Offset(
                0,
                -2,
              ),
            )
          ],
          color: Color(0xFF754CE3),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // INFOS SUR LE CHAUFFEUR
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 90,
                decoration: BoxDecoration(),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: commonCachedNetworkImage(
                                widget.driverData!.profileImage.validate(),
                                fit: BoxFit.cover,
                                height: 50,
                                width: 50),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
                                child: Text(
                                  'Votre chauffeur',
                                  style: TextStyle(
                                    // fontFamily: 'Readex Pro',
                                    color: Colors.white,
                                    fontSize: 16,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '${widget.driverData!.firstName.validate()} ${widget.driverData!.lastName.validate()}',
                                style: TextStyle(
                                  // fontFamily: 'Readex Pro',
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              SizedBox(width: 10),
                              // Text(
                              //   'Arrive dans 10 min',
                              //   style: TextStyle(
                              //     // fontFamily: 'Readex Pro',
                              //     color: Colors.white,
                              //     fontSize: 10,
                              //     letterSpacing: 0,
                              //     fontWeight: FontWeight.w300,
                              //   ),
                              // ),
                              Visibility(
                                visible: (shouldShowWidget &&
                                        widget.rideRequest!.status.validate() ==
                                            ACCEPTED ||
                                    widget.rideRequest!.status.validate() ==
                                        ARRIVING),
                                child:
                                    // Container(
                                    //   padding: EdgeInsets.all(8),
                                    //   decoration: BoxDecoration(
                                    //     border: Border.all(color: dividerColor),
                                    //     borderRadius: radius(defaultRadius),
                                    //     color: Color.fromARGB(255, 144, 96, 148),
                                    //   ),
                                    //   child:
                                    Text(
                                        'Arrive dans $tempsEstimeEnMinutesEntier min',
                                        style: boldTextStyle(
                                            size: 10,
                                            //     letterSpacing: 0,
                                            weight: FontWeight.w300,
                                            color: Colors.white)),
                                // ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(mainAxisSize: MainAxisSize.max, children: [
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              print("appel");
                              print(
                                  '${widget.driverData!.contactNumber.validate()}');
                              launchUrl(
                                  Uri.parse(
                                      'tel:${widget.driverData!.contactNumber.validate()}'),
                                  mode: LaunchMode.externalApplication);
                              // Ajoutez ici le code pour effectuer d'autres actions en réponse au clic sur l'icône
                            },
                            child: Icon(
                              Icons.call_outlined,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            if (widget.rideRequest!.status == COMPLETED) {
                              launchScreen(
                                  context,
                                  ReviewScreen(
                                      driverData: widget.driverData,
                                      rideRequest: widget.rideRequest!),
                                  pageRouteAnimation:
                                      PageRouteAnimation.SlideBottomTop);
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return CancelOrderDialog(
                                    onCancel: (reason) {
                                      cancelRequest(reason);
                                    },
                                  );
                                },
                              );
                            }
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              widget.rideRequest!.status == COMPLETED
                                  ? Icons.star
                                  : Icons.cancel_outlined,
                              color: widget.rideRequest!.status == COMPLETED
                                  ? Colors.yellow
                                  : Colors.orange[500],
                              size: 24,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              Container(
                width: MediaQuery.sizeOf(context).width,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // INFO SUR LE STATUT DE LA COURSE
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 5, 0),
                                    child: Icon(
                                      Icons.album_outlined,
                                      color: Color(0XFF939FAB),
                                      size: 18,
                                    ),
                                  ),
                                  Text(
                                    servicesName[
                                        widget.rideRequest?.serviceId as int],
                                    style: TextStyle(
                                      // fontFamily: 'Readex Pro',
                                      fontSize: 16,
                                      color: Color(0xFF754CE3),
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Row(
                              //   mainAxisSize: MainAxisSize.max,
                              //   children: [
                              //     Text(
                              //       '10 min restant',
                              //       style: TextStyle(
                              //         // fontFamily: 'Readex Pro',
                              //         color: Colors.grey,
                              //         fontSize: 10,
                              //         letterSpacing: 0,
                              //         fontWeight: FontWeight.w300,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  statusName(
                                      status: widget.rideRequest!.status
                                          .validate()),
                                  style: boldTextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      // INFO SUR LA VOITURE
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width,
                          decoration: BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    widget.driverData!.userDetail!.carColor
                                                ?.startsWith("0X") !=
                                            false
                                        ? ColorFiltered(
                                            colorFilter: ColorFilter.mode(
                                                Color(int.parse(widget
                                                        .driverData!
                                                        .userDetail!
                                                        .carColor ??
                                                    '0')),
                                                BlendMode.modulate),
                                            child: Container(
                                              // color: Color.fromARGB(255, 255, 255, 255),
                                              child: Image.asset(imgCar,
                                                  height: 90, width: 160),
                                            ),
                                          )
                                        : Column(children: [
                                            // Text(
                                            //     '${widget.driverData!.userDetail!.carColor}'),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.asset(
                                                imgCar,
                                                width: 140,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ])
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Generated code for this Container Widget...
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            117, 117, 117, 1),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            8, 5, 8, 5),
                                        child: Text(
                                          '-  ${widget.driverData!.userDetail!.carPlateNumber.validate().toUpperCase()} -',
                                          style: TextStyle(
                                            // fontFamily: 'Readex Pro',
                                            color: Colors.white,
                                            fontSize: 16,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Text(
                                      '${widget.driverData!.userDetail!.carModel}',
                                      style: TextStyle(
                                        // fontFamily: 'Readex Pro',
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // AFFICHAGE DU PRIX
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                decoration: BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 7, 10, 7),
                                  child: Text(
                                    'Prix',
                                    style: TextStyle(
                                      // fontFamily: 'Readex Pro',
                                      fontSize: 20,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Color(0xFFA5B5C1),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              // Text(
                              //   'BUSINESS',
                              //   style: TextStyle(
                              //     // fontFamily: 'Readex Pro',
                              //     color: Color(0xFF754CE3),
                              //     fontSize: 13,
                              //     letterSpacing: 0,
                              //     fontWeight: FontWeight.w600,
                              //   ),
                              // ),
                            ],
                          ),
                          Text(
                            printAmount(widget.travelPrice ?? ""),
                            style: TextStyle(
                              // fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                              fontSize: 20,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(
                        thickness: 1,
                        color: Color(0xFFE7E7E7),
                      ),
                      SizedBox(height: 10),

                      // CINQUIEME LIGNE DU BOTTOM SHEET COMPRENANT LARRIVEE ET LE DEPART
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CONDITION POUR SIL EXISTE UN ARRET
                            stopAdress == null
                                ? Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.near_me,
                                              color: Colors.green, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  widget.rideRequest!
                                                          .startAddress ??
                                                      ''.validate(),
                                                  style: primaryTextStyle(
                                                      size: 18),
                                                  maxLines: 2)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 8),
                                          SizedBox(
                                            height: 24,
                                            child: DottedLine(
                                              direction: Axis.vertical,
                                              lineLength: double.infinity,
                                              lineThickness: 1,
                                              dashLength: 2,
                                              dashColor: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  widget.rideRequest!
                                                          .endAddress ??
                                                      '',
                                                  style: primaryTextStyle(
                                                      size: 18),
                                                  maxLines: 2)),
                                        ],
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.near_me,
                                              color: Colors.green, size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  widget.rideRequest!
                                                          .startAddress ??
                                                      ''.validate(),
                                                  style: primaryTextStyle(
                                                      size: 14),
                                                  maxLines: 2)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 8),
                                          SizedBox(
                                            height: 24,
                                            child: DottedLine(
                                              direction: Axis.vertical,
                                              lineLength: double.infinity,
                                              lineThickness: 1,
                                              dashLength: 2,
                                              dashColor: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(stopAdress ?? '',
                                                  style: primaryTextStyle(
                                                      size: 14),
                                                  maxLines: 2)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 8),
                                          SizedBox(
                                            height: 24,
                                            child: DottedLine(
                                              direction: Axis.vertical,
                                              lineLength: double.infinity,
                                              lineThickness: 1,
                                              dashLength: 2,
                                              dashColor: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  widget.rideRequest!
                                                          .endAddress ??
                                                      '',
                                                  style: primaryTextStyle(
                                                      size: 14),
                                                  maxLines: 2)),
                                        ],
                                      ),
                                    ],
                                  ),

                            SizedBox(
                              height: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
