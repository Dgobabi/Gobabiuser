import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as location;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:user/components/OrderDialogWidget.dart';
import 'package:user/model/lieuPrefereModel.dart';
import 'package:user/service/NotificationService.dart';
import 'package:user/service/notifi_service.dart';
import '../utils/Extensions/context_extension.dart';
import '../components/drawer_component.dart';
import '../screens/ReviewScreen.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/NearByDriverListModel.dart';
import '../model/TextModel.dart';
import '../network/RestApis.dart';
import '../screens/RidePaymentDetailScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/DataProvider.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/images.dart';
import 'LocationPermissionScreen.dart';
import 'NewEstimateRideListWidget.dart';
import 'NotificationScreen.dart';
import 'RiderWidget.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  LatLng? sourceLocation;
  double epsilon = 0.000001;
  List<TexIModel> list = getBookList();
  List<Marker> markers = [];
  Set<Polyline> _polyLines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  OnRideRequest? servicesListData;
  String _myVariable = "";

  double cameraZoom = 17.0, cameraTilt = 0;

  double cameraBearing = 30;
  int onTapIndex = 0;

  int selectIndex = 0;
  String sourceLocationTitle = '';

  late StreamSubscription<ServiceStatus> serviceStatusStream;

  location.Location _location = location.Location();

  LocationPermission? permissionData;

  late BitmapDescriptor riderIcon;
  late BitmapDescriptor driverIcon;
  List<NearByDriverListModel>? nearDriverModel;

  List<LieuPrefereModel>? lieuxPreferes;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadVariable();
    // speakText('bonjour');
    getLieuPreferes();
    getCurrentRequest();
    afterBuildCreated(() {
      init();
    });

    // Update every 5 seconds
    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      updateLogic();
      //  locationPermission();
    });
  }

  Future<void> speakText(String text) async {
    print("PARLE");
    await flutterTts.setLanguage("fr-fr");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("$text");
  }

  // Update every 5 seconds
  void updateLogic() {
    // Your logic to be updated every 5 seconds
    // For example, you can call getCurrentRequest() or any other logic you want.
    // locationPermission();
    //getCurrentRequest();
    //getCurrentUserLocation();
    // getCurrentUserLocation();
    //getCurrentRequest();
    // locationPermission();
    // Add other logic as needed
    ///getCurrentRequest();
    init();
  }

  void init() async {
    _startTimer();
    getCurrentUserLocation();
    riderIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), SourceIcon);
    driverIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), MultipleDriver);
    await getAppSetting().then((value) {
      if (value.walletSetting != null) {
        value.walletSetting!.forEach((element) {
          if (element.key == PRESENT_TOPUP_AMOUNT) {
            appStore.setWalletPresetTopUpAmount(
                element.value ?? PRESENT_TOP_UP_AMOUNT_CONST);
          }
          if (element.key == MIN_AMOUNT_TO_ADD) {
            if (element.value != null)
              appStore.setMinAmountToAdd(int.parse(element.value!));
          }
          if (element.key == MAX_AMOUNT_TO_ADD) {
            if (element.value != null)
              appStore.setMaxAmountToAdd(int.parse(element.value!));
          }
        });
      }
      if (value.rideSetting != null) {
        value.rideSetting!.forEach((element) {
          if (element.key == PRESENT_TIP_AMOUNT) {
            appStore.setWalletTipAmount(
                element.value ?? PRESENT_TOP_UP_AMOUNT_CONST);
          }
          if (element.key == RIDE_FOR_OTHER) {
            appStore.setIsRiderForAnother(element.value ?? "0");
          }
          if (element.key == MAX_TIME_FOR_RIDER_MINUTE) {
            appStore.setRiderMinutes(element.value ?? '4');
          }
        });
      }
      if (value.currencySetting != null) {
        appStore
            .setCurrencyCode(value.currencySetting!.symbol ?? currencySymbol);
        appStore
            .setCurrencyName(value.currencySetting!.code ?? currencyNameConst);
        appStore.setCurrencyPosition(value.currencySetting!.position ?? LEFT);
      }
      if (value.settingModel != null) {
        appStore.settingModel = value.settingModel!;
      }
      if (value.privacyPolicyModel!.value != null)
        appStore.privacyPolicy = value.privacyPolicyModel!.value!;
      if (value.termsCondition!.value != null)
        appStore.termsCondition = value.termsCondition!.value!;
      if (value.settingModel!.helpSupportUrl != null)
        appStore.mHelpAndSupport = value.settingModel!.helpSupportUrl!;
    }).catchError((error) {
      log('${error.toString()}');
    });
    polylinePoints = PolylinePoints();
  }

  void _loadVariable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _myVariable = prefs.getString('permissionScreen') ?? "";
    });
    if (_myVariable != "permis") {
      print(_myVariable);
      locationPermission();
    }
  }

  void _startTimer() {
    // Configurez un timer pour actualiser les données toutes les 10 secondes
    Timer.periodic(Duration(seconds: 2), (Timer timer) {
      //   getCurrentUserLocation();
    });
  }

  String _getGreetingMessage() {
    var hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Bonjour ';
    } else if (hour >= 12 && hour < 18) {
      return 'Bonne aprèm ';
    } else {
      return 'Bonsoir ';
    }
  }

  Future<void> getCurrentUserLocation() async {
    if (permissionData != LocationPermission.denied) {
      print("LA PERMISSION DENIED");
      final geoPosition = await Geolocator.getCurrentPosition(
              timeLimit: Duration(seconds: 30),
              desiredAccuracy: LocationAccuracy.high)
          .catchError((error) {
        print("LA PERMISSION DENIED ERROR");
        if (_myVariable != "permis") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => LocationPermissionScreen()));
        }
      });
      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);
      List<Placemark>? placemarks = await placemarkFromCoordinates(
          geoPosition.latitude, geoPosition.longitude);
      sharedPref.setString(COUNTRY,
          placemarks[0].isoCountryCode.validate(value: defaultCountry));

      Placemark place = placemarks[0];
      if (place != null) {
        sourceLocationTitle =
            "${place.name != null ? place.name : place.subThoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}";
        polylineSource = LatLng(geoPosition.latitude, geoPosition.longitude);
      }
      markers.add(
        Marker(
          markerId: MarkerId('Order Detail'),
          position: sourceLocation!,
          draggable: true,
          infoWindow: InfoWindow(title: sourceLocationTitle, snippet: ''),
          icon: riderIcon,
        ),
      );
      startLocationTracking();
      getNearByDriverList(latLng: sourceLocation).then((value) async {
        value.data!.forEach((element) {
          //

          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()),
                  double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(
                  title: '${element.firstName} ${element.lastName}',
                  snippet: ''),
              icon: driverIcon,
            ),
          );

          getLocationUpdates(element);
        });
        setState(() {});
      });
      setState(() {});
    } else {
      print("LA PERMISSION OKAY");
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => LocationPermissionScreen()));
    }
  }

  Future<void> getLocationUpdates(element) async {
    // MA FONCTION POUR LA DISPOSITION DU VEHICULE
    // LatLng prev = LatLng(0, 0);
    // LatLng next;
    _location.onLocationChanged.listen((location.LocationData currentLocation) {
      setState(() {
        element.latitude != currentLocation.latitude!;
        element.longitude != currentLocation.longitude!;
        print("element gps ${currentLocation.latitude} ");
        // next = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        // markers.add(
        //   Marker(
        //     markerId: MarkerId('Driver${element.id}'),
        //     position: LatLng(double.parse(element.latitude!.toString()),
        //         double.parse(element.longitude!.toString())),
        //     infoWindow: InfoWindow(
        //         title: '${element.firstName} ${element.lastName}', snippet: ''),
        //     icon: driverIcon,
        //     // rotation: _calculateRotation(prev, next)
        //   ),
        // );

        // prev = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
      // _controller!.animateCamera(CameraUpdate.newLatLng(_carPosition));
    });
  }

  // Calculer la rotation de l'image du marqueur en degrés
  double _calculateRotation(LatLng prev, LatLng next) {
    final rotation =
        atan2(next.longitude - prev.longitude, next.latitude - prev.latitude) *
            (180 / pi);
    return rotation;
  }

  Future<void> getLieuPreferes() async {
    await getLieuPrefere(
            rider_id: sharedPref.getString(FIRST_NAME).validate(),
            status: "canceled")
        .then((value) {
      print("lieu prefere ${value.end_address}");
    }).catchError((error) {
      log(error.toString());
      print("lieu prefere error ${error}");
    });
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) {
      servicesListData = value.rideRequest ?? value.onRideRequest;
      print("current req ride ${servicesListData!.status}");
      if (servicesListData != null) {
        if (servicesListData!.status != COMPLETED) {
          print("current ride req lancement widget");
          launchScreen(
            getContext,
            isNewTask: true,
            NewEstimateRideListWidget(
              sourceLatLog: LatLng(
                  double.parse(servicesListData!.startLatitude!),
                  double.parse(servicesListData!.startLongitude!)),
              destinationLatLog: LatLng(
                  double.parse(servicesListData!.endLatitude!),
                  double.parse(servicesListData!.endLongitude!)),
              sourceTitle: servicesListData!.startAddress!,
              destinationTitle: servicesListData!.endAddress!,
              isCurrentRequest: true,
              servicesId: servicesListData!.serviceId,
              id: servicesListData!.id,
            ),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
          );
        } else if (servicesListData!.status == COMPLETED &&
            servicesListData!.isRiderRated == 0) {
          launchScreen(
              context,
              ReviewScreen(
                  rideRequest: servicesListData!, driverData: value.driver),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
              isNewTask: true);
        }
      } else if (value.payment != null &&
          value.payment!.paymentStatus != COMPLETED) {
        launchScreen(context,
            RidePaymentDetailScreen(rideId: value.payment!.rideRequestId),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            isNewTask: true);
      }
    }).catchError((error) {
      log(error.toString());
    });
  }

  Future<void> locationPermission() async {
    serviceStatusStream =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
      } else if (status == ServiceStatus.enabled) {
        getCurrentUserLocation();
        if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
          Navigator.pop(navigatorKey.currentState!.overlay!.context);
        }
      }
    }, onError: (error) {
      //
    });
  }

  Future<void> startLocationTracking() async {
    Map req = {
      "status": "active",
      "latitude": sourceLocation!.latitude.toString(),
      "longitude": sourceLocation!.longitude.toString(),
    };
    await updateStatus(req).then((value) {}).catchError((error) {
      log(error);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: DrawerComponent(),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            trafficEnabled: true,
            markers: markers.map((e) => e).toSet(),
            polylines: _polyLines,
            initialCameraPosition: CameraPosition(
              target: sourceLocation ??
                  LatLng(sharedPref.getDouble(LATITUDE)!,
                      sharedPref.getDouble(LONGITUDE)!),
              zoom: cameraZoom,
              tilt: cameraTilt,
              bearing: cameraBearing,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.4, right: 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  // Appel de la fonction pour recentrer la carte
                  _centerMap();
                },
                child: Icon(Icons.my_location),
                //  backgroundColor: Colors.blue,
                tooltip: 'Recentrer la carte',
              ),
            ),
          ),
          Positioned(
            top: context.statusBarHeight + 4,
            right: 8,
            left: 8,
            child: topWidget(),
          ),
          SlidingUpPanel(
            // padding: EdgeInsets.all(16),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(defaultRadius),
                topRight: Radius.circular(defaultRadius)),
            backdropTapClosesPanel: true,
            minHeight: 270,
            maxHeight: 270,
            panel: Stack(children: [
              Container(
                  decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.contain,
                  alignment: AlignmentDirectional(0, -0.9),
                  image: Image.asset(
                    relief,
                    height: 40,
                  ).image,
                ),
              )),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(bottom: 15),
                        height: 10,
                        width: 70,
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(defaultRadius)),
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          ic_app_logo,
                          width: 30,
                          height: 30,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          _getGreetingMessage(),
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        Text(
                            "${sharedPref.getString(FIRST_NAME).validate()} ${sharedPref.getString(LAST_NAME).validate()}",
                            style: TextStyle(
                                fontSize: 20,
                                color: primaryColor,
                                fontWeight: FontWeight.w600))
                      ],
                    ),
                    Divider(color: Colors.grey[100]),
                    SizedBox(
                      height: 20,
                    ),
                    Text(language.whatWouldYouLikeToGo.capitalizeFirstLetter(),
                        style: primaryTextStyle()),
                    SizedBox(height: 20),
                    // Generated code for this Row Widget...

                    AppTextField(
                      autoFocus: false,
                      readOnly: true,
                      onTap: () async {
                        if (await checkPermission()) {
                          showModalBottomSheet(
                            // enableDrag: true,
                            // showDragHandle: true,
                            // isDismissible: true,
                            isScrollControlled: true,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(defaultRadius),
                                  topRight: Radius.circular(defaultRadius)),
                            ),
                            context: context,
                            builder: (_) {
                              return RiderWidget(title: sourceLocationTitle);
                            },
                          );
                        }
                      },
                      textFieldType: TextFieldType.EMAIL,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Feather.search),
                        filled: true,
                        fillColor: Colors.purple[50],
                        isDense: true,
                        focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                            borderSide: BorderSide(color: Colors.white)),
                        disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                            borderSide: BorderSide(
                                color:
                                    const Color.fromARGB(255, 255, 255, 255)!)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                            borderSide: BorderSide(
                                color:
                                    const Color.fromARGB(255, 255, 255, 255)!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                            borderSide: BorderSide(color: Colors.white)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                            borderSide: BorderSide(color: Colors.red)),
                        alignLabelWithHint: true,
                        hintText: language.enterYourDestination,
                      ),
                    ),
                    SizedBox(height: 20),
                    // lieuxPreferes != null && lieuxPreferes != []
                    //     ? Row(
                    //         mainAxisSize: MainAxisSize.max,
                    //         mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //         children: lieuxPreferes != null
                    //             ? <Widget>[
                    //                 Expanded(
                    //                   child: ListView(
                    //                     scrollDirection: Axis.horizontal,
                    //                     children: lieuxPreferes!.map((item) {
                    //                       return Container(
                    //                         margin: EdgeInsets.all(8),
                    //                         padding: EdgeInsets.all(12),
                    //                         color: Colors.blue,
                    //                         child: dernierDeplacement(item),
                    //                       );
                    //                     }).toList(),
                    //                   ),
                    //                 ),
                    //               ]
                    //             : [],
                    //       )
                    //     : Center(
                    //         child: // Generated code for this Image Widget...
                    //             Container(
                    //           width: 90,
                    //           height: 90,
                    //           decoration: BoxDecoration(
                    //             borderRadius: BorderRadius.circular(3),
                    //             // color: Colors.red,
                    //             image: DecorationImage(
                    //               fit: BoxFit.contain,
                    //               image: Image.asset(
                    //                 city_driver,
                    //               ).image,
                    //             ),
                    //           ),
                    //         ),
                    //       )
                  ],
                ),
              ),
            ]),
          ),
          Visibility(
            visible: appStore.isLoading,
            child: loaderWidget(),
          ),
        ],
      ),
      /*    floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Appel de la fonction pour recentrer la carte
          _centerMap();
        },
        child: Icon(Icons.my_location), // Utilisez une icône appropriée
        backgroundColor: Colors.blue, // Couleur de fond du bouton
        tooltip: 'Recentrer la carte', // Utilisez une icône appropriée
      ),*/
    );
  }

  Widget dernierDeplacement(LieuPrefereModel lieu) {
    return InkWell(
      onTap: () {
        launchScreen(
            context,
            NewEstimateRideListWidget(
                sourceLatLog: polylineSource,
                destinationLatLog: LatLng(double.parse(lieu.end_latitude),
                    double.parse(lieu.end_longitude)),
                sourceTitle: sourceLocationTitle,
                destinationTitle: lieu.end_address),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
      },
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          color: Colors.orange[100],
          // boxShadow: [
          //   BoxShadow(
          //     blurRadius: 4,
          //     color: Color(0x33000000),
          //     offset: Offset(
          //       0,
          //       2,
          //     ),
          //   )
          // ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional(1, 1),
              child: Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  // color: Colors.white,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: Image.asset(
                      pointMap,
                    ).image,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                lieu.end_address.split(',').first,
                textAlign: TextAlign.start,
                style: TextStyle(
                    // fontFamily: 'Readex Pro',
                    color: Colors.grey[700],
                    letterSpacing: 0,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget topWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        inkWellWidget(
          onTap: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Color(0x33000000),
                  offset: Offset(
                    0,
                    2,
                  ),
                  spreadRadius: 1,
                )
                // BoxShadow(
                //     color: Colors.black.withOpacity(0.2), spreadRadius: 1),
              ],
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            child: Icon(
              Icons.drag_handle,
              color: primaryColor,
            ),
          ),
        ),
        inkWellWidget(
          onTap: () {
            NotificationService2()
                .showNotification(title: 'Sample title', body: 'It works!');
            launchScreen(context, NotificationScreen(),
                pageRouteAnimation: PageRouteAnimation.Slide);
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Color(0x33000000),
                  offset: Offset(
                    0,
                    2,
                  ),
                  spreadRadius: 1,
                )
                // BoxShadow(
                //     color: Colors.black.withOpacity(0.2), spreadRadius: 1),
              ],
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            child: Icon(Ionicons.notifications_outline, color: primaryColor),
          ),
        ),
      ],
    );
  }

  // Fonction pour recentrer la carte à la position initiale
  Future<void> _centerMap() async {
    if (_mapController != null) {
      var position = await GeolocatorPlatform.instance.getCurrentPosition();
      CameraPosition initialPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 18.0,
      );
      _mapController!
          .animateCamera(CameraUpdate.newCameraPosition(initialPosition));
    }
  }
}
