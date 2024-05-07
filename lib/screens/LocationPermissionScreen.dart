import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'DashBoardScreen.dart';

class LocationPermissionScreen extends StatefulWidget {
  @override
  LocationPermissionScreenState createState() =>
      LocationPermissionScreenState();
}

class LocationPermissionScreenState extends State<LocationPermissionScreen> {
  String _myVariable = "";

  @override
  void initState() {
    super.initState();
    _loadVariable();
    init();
  }

  void init() async {
    // determinePosition();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _loadVariable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _myVariable = prefs.getString('permisionScreen') ?? "";
    });
  }

  void _updateVariable(String newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('permissionScreen', newValue);
    setState(() {
      _myVariable = newValue;
    });
    print('PERMISSION OK');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset('images/location-permissions.json',
                  height: 200, width: 200, fit: BoxFit.cover),
              SizedBox(height: 32),
              Text(language.mostReliableMightyRiderApp,
                  style: boldTextStyle(size: 18)),
              SizedBox(height: 16),
              Text(language.toEnjoyYourRideExperiencePleaseAllowPermissions,
                  style: secondaryTextStyle(color: primaryColor),
                  textAlign: TextAlign.center),
              SizedBox(height: 32),
              AppButtonWidget(
                width: MediaQuery.of(context).size.width,
                text: language.allow,
                textStyle: boldTextStyle(color: Colors.white),
                color: primaryColor,
                onTap: () async {
                  if (await checkPermission()) {
                    _updateVariable('permis');
                    launchScreen(context, DashBoardScreen(), isNewTask: true);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<Position?> determinePosition() async {
  LocationPermission permission;
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(language.locationNotAvailable);
    }
  } else {
    //throw Exception('Error');
  }
  return await Geolocator.getCurrentPosition();
}
