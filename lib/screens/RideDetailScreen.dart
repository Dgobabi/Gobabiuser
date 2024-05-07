import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../components/CouponInfo.dart';
import '../model/UserDetailModel.dart';
import '../network/RestApis.dart';
import '../screens/ComplaintScreen.dart';
import '../utils/Extensions/StringExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/AboutWidget.dart';
import '../components/GenerateInvoice.dart';
import '../main.dart';
import '../model/ComplaintModel.dart';
import '../model/CurrentRequestModel.dart';
import '../model/DriverRatting.dart';
import '../model/OrderHistory.dart';
import '../model/RiderModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'RideHistoryScreen.dart';

class RideDetailScreen extends StatefulWidget {
  final int orderId;

  RideDetailScreen({required this.orderId});

  @override
  RideDetailScreenState createState() => RideDetailScreenState();
}

class RideDetailScreenState extends State<RideDetailScreen> {
  RiderModel? riderModel;
  List<RideHistory> rideHistory = [];
  DriverRatting? driverRatting;
  ComplaintModel? complaintData;
  Payment? payment;
  UserData? userData;
  int facteurArrondi = 100;
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await rideDetail(orderId: widget.orderId).then((value) {
      riderModel = value.data!;
      rideHistory.addAll(value.rideHistory!);
      driverRatting = value.driverRatting!;
      complaintData = value.complaintModel;
      payment = value.payment;
      getDriverDetail(userId: riderModel!.driverId).then((value) {
        userData = value.data!;
        setState(() {});

        appStore.setLoading(false);
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log(error.toString());
    });
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            riderModel != null ? "${language.lblRide} #${riderModel!.id}" : "",
            style: boldTextStyle(color: Colors.white)),
        actions: [
          if (riderModel != null)
            IconButton(
                onPressed: () {
                  launchScreen(
                    context,
                    ComplaintScreen(
                      driverRatting: driverRatting ?? DriverRatting(),
                      complaintModel: complaintData,
                      riderModel: riderModel,
                    ),
                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                  );
                },
                icon: Icon(MaterialCommunityIcons.head_question))
        ],
      ),
      body: Stack(
        children: [
          if (riderModel != null)
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  driverInformationComponent(),
                  SizedBox(height: 12),
                  if (riderModel!.otherRiderData != null)
                    otherRiderInfoComponent(),
                  if (riderModel!.otherRiderData != null) SizedBox(height: 12),
                  addressComponent(),
                  SizedBox(height: 12),
                  priceDetailComponent(),
                  SizedBox(height: 12),
                  paymentDetail(),
                ],
              ),
            ),
          if (!appStore.isLoading && riderModel == null) emptyWidget(),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }

  Widget addressComponent() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: dividerColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Ionicons.calendar,
                      color: textSecondaryColorGlobal, size: 16),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                        '${printDate(riderModel!.createdAt.validate())}',
                        style: primaryTextStyle(size: 14)),
                  ),
                ],
              ),
              inkWellWidget(
                onTap: () {
                  generateInvoiceCall(riderModel, payment: payment);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(language.invoice,
                        style: primaryTextStyle(color: primaryColor)),
                    SizedBox(width: 4),
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(MaterialIcons.file_download,
                          size: 18, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
              '${language.lblDistance} ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}',
              style: boldTextStyle(size: 14)),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.near_me, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.startTime != null)
                          Text(
                              riderModel!.startTime != null
                                  ? printDate(riderModel!.startTime!)
                                  : '',
                              style: secondaryTextStyle(size: 12)),
                        if (riderModel!.startTime != null) SizedBox(height: 4),
                        Text(riderModel!.startAddress.validate(),
                            style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 10),
                  SizedBox(
                    height: 30,
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
                  Icon(Icons.location_on, color: Colors.red, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.endTime != null)
                          Text(
                              riderModel!.endTime != null
                                  ? printDate(riderModel!.endTime!)
                                  : '',
                              style: secondaryTextStyle(size: 12)),
                        if (riderModel!.endTime != null) SizedBox(height: 4),
                        Text(riderModel!.endAddress.validate(),
                            style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          inkWellWidget(
            onTap: () {
              launchScreen(context, RideHistoryScreen(rideHistory: rideHistory),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.viewHistory, style: secondaryTextStyle()),
                Icon(Entypo.chevron_right, color: dividerColor, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentDetail() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: dividerColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentType.validate()),
                  style: boldTextStyle()),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentStatus.validate()),
                  style: boldTextStyle(
                      color: paymentStatusColor(
                          riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget otherRiderInfoComponent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: dividerColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.riderInformation, style: boldTextStyle()),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Ionicons.person_outline, size: 18),
                  SizedBox(width: 8),
                  Text(riderModel!.otherRiderData!.name.validate(),
                      style: primaryTextStyle()),
                ],
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  launchUrl(
                      Uri.parse(
                          'tel:${riderModel!.otherRiderData!.conatctNumber.validate()}'),
                      mode: LaunchMode.externalApplication);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.call_sharp, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text(riderModel!.otherRiderData!.conatctNumber.validate(),
                        style: primaryTextStyle())
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget driverInformationComponent() {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: AboutWidget(userData: userData),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.aboutDriver, style: boldTextStyle(size: 16)),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        contentPadding: EdgeInsets.zero,
                        content: AboutWidget(userData: userData),
                      ),
                    );
                  },
                  child: Icon(Icons.info_outline),
                )
              ],
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(defaultRadius),
                  child: commonCachedNetworkImage(
                      riderModel!.driverProfileImage.validate(),
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(riderModel!.driverName.validate(),
                          style: boldTextStyle()),
                      SizedBox(height: 2),
                      if (driverRatting != null)
                        RatingBar.builder(
                          direction: Axis.horizontal,
                          glow: false,
                          allowHalfRating: false,
                          ignoreGestures: true,
                          wrapAlignment: WrapAlignment.spaceBetween,
                          itemCount: 5,
                          itemSize: 16,
                          initialRating:
                              double.parse(driverRatting!.rating.toString()),
                          itemPadding: EdgeInsets.symmetric(horizontal: 0),
                          itemBuilder: (context, _) =>
                              Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            //
                          },
                        ),
                      if (driverRatting != null) SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(
                                  riderModel!.riderContactNumber.validate(),
                                  style: primaryTextStyle(size: 14))),
                          InkWell(
                            onTap: () {
                              launchUrl(
                                  Uri.parse(
                                      'tel:${riderModel!.riderContactNumber}'),
                                  mode: LaunchMode.externalApplication);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: dividerColor),
                                  borderRadius: radius(10)),
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.call_sharp,
                                  size: 18, color: Colors.green),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget priceDetailComponent() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.priceDetail, style: boldTextStyle(size: 16)),
          SizedBox(height: 12),
          riderModel!.subtotal! <= riderModel!.minimumFare!
              ? totalCount(
                  title: language.minimumFare, amount: riderModel!.minimumFare)
              : Column(
                  children: [
                    totalCount(
                        title: language.basePrice,
                        amount: riderModel!.baseFare),
                    SizedBox(height: 8),
                    totalCount(
                        title: language.distancePrice,
                        amount: riderModel!.perDistanceCharge),
                    SizedBox(height: 8),
                    totalCount(
                        title: language.minutePrice,
                        amount: riderModel!.perMinuteDriveCharge),
                    SizedBox(height: 8),
                    totalCount(
                        title: language.waitingTimePrice,
                        amount: riderModel!.perMinuteWaitingCharge),
                  ],
                ),
          SizedBox(height: 8),
          if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.couponDiscount, style: secondaryTextStyle()),
                Text(
                  "- " +
                      printAmount(riderModel!.couponDiscount!
                          .toStringAsFixed(digitAfterDecimal)),
                  style: boldTextStyle(color: Colors.green, size: 14),
                ),
              ],
            ),
          if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
            SizedBox(height: 8),
          if (riderModel!.tips != null)
            totalCount(title: language.tip, amount: riderModel!.tips),
          if (riderModel!.tips != null) SizedBox(height: 8),
          if (riderModel!.extraCharges!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.additionalFees, style: boldTextStyle()),
                ...riderModel!.extraCharges!.map((e) {
                  return Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.validate().capitalizeFirstLetter(),
                            style: secondaryTextStyle()),
                        Text(
                            printAmount(
                                e.value!.toStringAsFixed(digitAfterDecimal)),
                            style: boldTextStyle(size: 14)),
                      ],
                    ),
                  );
                }).toList()
              ],
            ),
          Divider(thickness: 1),
          payment != null && payment!.driverTips != 0
              ? totalCount(
                  title: language.total,
                  amount: riderModel!.subtotal! + payment!.driverTips!,
                  isTotal: true)
              : totalCount(
                  title: language.total,
                  amount: riderModel!.subtotal,
                  isTotal: true),
        ],
      ),
    );
  }
}
