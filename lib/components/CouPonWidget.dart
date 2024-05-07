import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Extensions/StringExtensions.dart';
import '../model/CouponData.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class CouPonWidget extends StatefulWidget {
  @override
  CouPonWidgetState createState() => CouPonWidgetState();
}

class CouPonWidgetState extends State<CouPonWidget> {
  ScrollController scrollController = ScrollController();

  List<CouponData> couponData = [];
  int currentPage = 1;
  int totalPage = 1;

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (currentPage < totalPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    await getCouponList().then((value) {
      appStore.setLoading(false);

      currentPage = value.pagination!.currentPage!;
      totalPage = value.pagination!.totalPages!;
      if (currentPage == 1) {
        couponData.clear();
      }
      couponData.addAll(value.data!);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Stack(
          children: [
            SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.only(topLeft: radiusCircular(defaultRadius), topRight: radiusCircular(defaultRadius))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(language.availableOffers, style: boldTextStyle()),
                          inkWellWidget(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.close, size: 20),
                          )
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: couponData.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (_, index) {
                        CouponData data = couponData[index];
                        return Padding(
                          padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DottedBorder(
                                    padding: EdgeInsets.all(4),
                                    child: Text(data.code.validate(), style: boldTextStyle()),
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(data.title.validate(), style: boldTextStyle())),
                                  inkWellWidget(
                                    onTap: () {
                                      String codeData = data.code!;
                                      Navigator.pop(context, codeData);
                                      toast(language.copied);
                                    },
                                    child: Icon(Icons.content_copy, size: 18, color: dividerColor),
                                  )
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(data.discountType == CHARGE_TYPE_FIXED ? '${language.get} ${data.discount}' : '${language.get} ${data.discount} % ${language.off}', style: primaryTextStyle()),
                              if (data.description != null) SizedBox(height: 8),
                              if (data.description != null) Text(data.description.validate(), style: secondaryTextStyle(), maxLines: 2, overflow: TextOverflow.visible),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, index) {
                        return Divider(color: Colors.grey);
                      },
                    )
                  ],
                ),
              ),
            ),
            Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            ),
            if (!appStore.isLoading && couponData.isEmpty) emptyWidget()
          ],
        );
      },
    );
  }
}
