import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:user/screens/RidePaymentDetailScreen.dart';
import 'package:user/screens/RiderStopWidget.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/ChatScreen.dart';
import '../screens/NewEstimateRideListWidget.dart';
import '../screens/ReviewScreen.dart';
import '../screens/DashBoardScreen.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../utils/Extensions/app_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/Common.dart';
import '../screens/AlertScreen.dart';
import 'CancelOrderDialog.dart';

class RideAcceptWidget extends StatefulWidget {
  final Driver? driverData;
  OnRideRequest? rideRequest;
  String? travelPrice;

  RideAcceptWidget({this.driverData, this.rideRequest, this.travelPrice});

  @override
  RideAcceptWidgetState createState() => RideAcceptWidgetState();
}

class RideAcceptWidgetState extends State<RideAcceptWidget> {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          SizedBox(height: 12),

          // PREMIERE LIGNE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // STATUT COURSE
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: radius(),
                  ),
                  child: Text(
                    statusName(status: widget.rideRequest!.status.validate()),
                    style: boldTextStyle(color: Colors.white),
                  ),
                ),
              ),
              (widget.rideRequest!.status.validate() != IN_PROGRESS)
                  ? SizedBox(width: 50)
                  : SizedBox(width: 150),

              // Add some spacing between the widgets

              // TEMPS ATTENTE
              Visibility(
                visible: (shouldShowWidget &&
                        widget.rideRequest!.status.validate() == ACCEPTED ||
                    widget.rideRequest!.status.validate() == ARRIVING),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                    borderRadius: radius(defaultRadius),
                    color: Color.fromARGB(255, 144, 96, 148),
                  ),
                  child: Text('$tempsEstimeEnMinutesEntier min',
                      style: boldTextStyle(color: Colors.white)),
                ),
              ),

              // DEFINITION ARRETS
              Visibility(
                visible: (shouldShowWidget &&
                    widget.rideRequest!.status.validate() == ARRIVING),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(width: 20),
                    inkWellWidget(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(defaultRadius),
                                  topLeft: Radius.circular(defaultRadius))),
                          builder: (_) {
                            return RiderStopWidget(
                              title: language.defineStopPoints,
                              rideRequest: widget.rideRequest!,
                              onRideRequest: (map) async {
                                await stopRequest(map);
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            border: Border.all(color: dividerColor),
                            color: appStore.isDarkMode
                                ? scaffoldColorDark
                                : scaffoldColorLight,
                            borderRadius: BorderRadius.circular(defaultRadius)),
                        child: Center(
                          child: Text(language.defineStopPoints,
                              style: boldTextStyle(color: Colors.black)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Visibility(
                visible: (shouldShowWidget &&
                    widget.rideRequest!.status.validate() == ARRIVING &&
                    widget.rideRequest!.stopLatitude != null),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(width: 20),
                    inkWellWidget(
                      onTap: () async {
                        widget.rideRequest!.stopLatitude = null;
                        widget.rideRequest!.stopLongitude = null;
                        widget.rideRequest!.stopAddress = null;
                        await stopRequest(widget.rideRequest);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            border: Border.all(color: dividerColor),
                            color: appStore.isDarkMode
                                ? scaffoldColorDark
                                : scaffoldColorLight,
                            borderRadius: BorderRadius.circular(defaultRadius)),
                        child: Center(
                          child: Text(language.noStopPoints,
                              style: boldTextStyle(color: Colors.black)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // temps attente
              // Add more widgets to the Row if needed
            ],
          ),
          SizedBox(height: 12),

          // DEUXIEME LIGNE DU BOTTOMSHEET
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(widget.driverData!.driverService!.name.validate(),
                    //     style: boldTextStyle()),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text('${widget.driverData!.userDetail!.carModel}'),
                        Text('(${widget.driverData!.userDetail!.carColor})',
                            style: secondaryTextStyle()),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                    borderRadius: radius(defaultRadius),
                    color: primaryColor),
                child: Text(
                    '${widget.driverData!.userDetail!.carPlateNumber.validate()}',
                    style: boldTextStyle(color: Colors.white)),
              ),
              Visibility(
                visible: (shouldShowWidget &&
                        widget.rideRequest!.status.validate() == ACCEPTED ||
                    widget.rideRequest!.status.validate() == ARRIVING),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                    borderRadius: radius(defaultRadius),
                    color: Color.fromARGB(255, 144, 96, 148),
                  ),
                  child: Text('$distancesentier km',
                      style: boldTextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // TROISIEME LIGNE DU BOTTOM SHEET
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: commonCachedNetworkImage(
                    widget.driverData!.profileImage.validate(),
                    fit: BoxFit.cover,
                    height: 40,
                    width: 40),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${widget.driverData!.firstName.validate()} ${widget.driverData!.lastName.validate()}',
                        style: boldTextStyle()),
                    SizedBox(height: 2),
                    Text('${widget.driverData!.contactNumber}',
                        style: secondaryTextStyle()),
                  ],
                ),
              ),
              inkWellWidget(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        contentPadding: EdgeInsets.all(0),
                        content: AlertScreen(
                            rideId: widget.rideRequest!.id,
                            regionId: widget.rideRequest!.regionId),
                      );
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border.all(color: dividerColor),
                      borderRadius: radius(defaultRadius)),
                  child: Text(language.sos, style: boldTextStyle(size: 14)),
                ),
              ),
              SizedBox(width: 8),
              /* inkWellWidget(
                onTap: () {
                  launchScreen(context, ChatScreen(userData: userData),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                },
                child: chatCallWidget(Icons.chat_bubble_outline),
              ),*/
              SizedBox(width: 8),
              inkWellWidget(
                onTap: () {
                  launchUrl(
                      Uri.parse('tel:${widget.driverData!.contactNumber}'),
                      mode: LaunchMode.externalApplication);
                },
                child: chatCallWidget(Icons.call),
              ),
            ],
          ),
          SizedBox(height: 16),

          // QUATRIEME LIGNE DU BOTTOM SHEET COMPRENANT LARRIVEE ET LE DEPART
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CONDITION POUR SIL EXISTE UN ARRET
              stopAdress == null
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.near_me, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    widget.rideRequest!.startAddress ??
                                        ''.validate(),
                                    style: primaryTextStyle(size: 14),
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
                                    widget.rideRequest!.endAddress ?? '',
                                    style: primaryTextStyle(size: 14),
                                    maxLines: 2)),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.near_me, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    widget.rideRequest!.startAddress ??
                                        ''.validate(),
                                    style: primaryTextStyle(size: 14),
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
                                    style: primaryTextStyle(size: 14),
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
                                    widget.rideRequest!.endAddress ?? '',
                                    style: primaryTextStyle(size: 14),
                                    maxLines: 2)),
                          ],
                        ),
                      ],
                    ),

              //  AFFICHAGE DU PRIX DE LA COURSE

              SizedBox(
                height: 15,
              ),

              // mSelectServiceAmount != null
              // ?
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                    border: Border.all(color: dividerColor),
                    color: appStore.isDarkMode
                        ? scaffoldColorDark
                        : scaffoldColorLight,
                    borderRadius: BorderRadius.circular(defaultSmallRadius)),
                child: Row(
                  children: [
                    Text(
                      "${language.cash} : ",
                      style: boldTextStyle(
                        color: textPrimaryColorGlobal,
                      ),
                    ),
                    Text(
                      mSelectServiceAmount != null
                          ? printAmount(mSelectServiceAmount!)
                          : printAmount(widget.travelPrice!),
                      style: boldTextStyle(
                        color: textPrimaryColorGlobal,
                      ),
                    ),
                  ],
                ),
              )
              // : Center()
              ,
              SizedBox(
                height: 24,
              )
            ],
          ),

          //  BOUTON DEN BAS
          Visibility(
            visible: widget.rideRequest!.status == COMPLETED,
            child: Column(
              children: [
                SizedBox(height: 8),
                AppButtonWidget(
                  text: language.driverReview,
                  width: MediaQuery.of(context).size.width,
                  textStyle: boldTextStyle(color: Colors.white),
                  color: primaryColor,
                  onTap: () {
                    //  userReviewData();
                    launchScreen(
                        context,
                        ReviewScreen(
                            driverData: widget.driverData,
                            rideRequest: widget.rideRequest!),
                        pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                  },
                ),
              ],
            ),
          ),
          if (widget.rideRequest!.status == ACCEPTED ||
              widget.rideRequest!.status == ARRIVING ||
              widget.rideRequest!.status == ARRIVED)
            AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              text: language.cancelRide,
              onTap: () {
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
              },
            )
        ],
      ),
    );
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
}
