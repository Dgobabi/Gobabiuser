import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../screens/BankInfoScreen.dart';
import '../screens/EditProfileScreen.dart';
import '../screens/EmergencyContactScreen.dart';
import '../screens/RideListScreen.dart';
import '../screens/WalletScreen.dart';
import '../screens/SettingScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';
import 'DrawerWidget.dart';

class DrawerComponent extends StatefulWidget {
  @override
  State<DrawerComponent> createState() => _DrawerComponentState();
}

class _DrawerComponentState extends State<DrawerComponent> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35),
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Observer(builder: (context) {
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: radius(),
                          child: commonCachedNetworkImage(
                              appStore.userProfile.validate().validate(),
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  sharedPref
                                          .getString(FIRST_NAME)
                                          .validate()
                                          .capitalizeFirstLetter() +
                                      " " +
                                      sharedPref
                                          .getString(LAST_NAME)
                                          .validate()
                                          .capitalizeFirstLetter(),
                                  style: boldTextStyle()),
                              SizedBox(height: 4),
                              Text(
                                  sharedPref
                                      .getString(CONTACT_NUMBER)
                                      .validate(),
                                  style: secondaryTextStyle()),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Divider(thickness: 1, height: 40),
                DrawerWidget(
                  title: language.profile,
                  iconData: ic_my_profile,
                  onTap: () {
                    Navigator.pop(context);
                    launchScreen(context, EditProfileScreen(),
                        pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ),
                DrawerWidget(
                    title: language.rides,
                    iconData: ic_my_rides,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, RideListScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),
                /*   DrawerWidget(
                    title: language.wallet,
                    iconData: ic_my_wallet,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, WalletScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),*/
                /*  DrawerWidget(
                    title: language.bankInfo,
                    iconData: ic_update_bank_info,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, BankInfoScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),*/
                DrawerWidget(
                    title: language.emergencyContacts,
                    iconData: ic_emergency_contact,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, EmergencyContactScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),
                DrawerWidget(
                    title: language.settings,
                    iconData: ic_setting,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, SettingScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    }),
                DrawerWidget(
                    title: language.logOut,
                    iconData: ic_logout,
                    onTap: () async {
                      await showConfirmDialogCustom(context,
                          primaryColor: primaryColor,
                          dialogType: DialogType.CONFIRMATION,
                          title: language.areYouSureYouWantToLogoutThisApp,
                          positiveText: language.yes,
                          negativeText: language.no, onAccept: (v) async {
                        await appStore.setLoggedIn(true);
                        await Future.delayed(Duration(milliseconds: 500));
                        await logout();
                      });
                    }),
                SizedBox(
                  height: 30,
                ),
                Center(
                  child: Text(
                    "1.8.3",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
