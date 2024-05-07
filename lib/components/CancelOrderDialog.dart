import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';

import '../../main.dart';
import '../utils/DataProvider.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';

class CancelOrderDialog extends StatefulWidget {
  static String tag = '/CancelOrderDialog';

  final Function(String)? onCancel;

  CancelOrderDialog({this.onCancel});

  @override
  CancelOrderDialogState createState() => CancelOrderDialogState();
}

class CancelOrderDialogState extends State<CancelOrderDialog> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController reasonController = TextEditingController();
  String? reason;

  List<String> cancelReasonList = getCancelReasonList();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    LiveStream().on('UpdateLanguage', (p0) {
      cancelReasonList.clear();
      cancelReasonList.addAll(getCancelReasonList());
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: formKey,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.cancelRide, style: boldTextStyle(size: 18)),
                    InkWell(
                      onTap: () {
                        widget.onCancel?.call('');
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.clear),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: reason,
                  isExpanded: true,
                  decoration:
                      inputDecoration(context, label: language.selectReason),
                  items: cancelReasonList.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    reason = val;
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null) return language.thisFieldRequired;
                    return null;
                  },
                ),
                SizedBox(height: 16),
                if (reason.validate().trim() == language.others)
                  AppTextField(
                    controller: reasonController,
                    textFieldType: TextFieldType.OTHER,
                    decoration: inputDecoration(context,
                        label: language.writeReasonHere),
                    maxLines: 3,
                    minLines: 3,
                    validator: (value) {
                      if (value!.isEmpty) return language.thisFieldRequired;
                      return null;
                    },
                  ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButtonWidget(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        widget.onCancel?.call(
                            reason!.validate().trim() != language.others
                                ? reason.validate()
                                : reasonController.text);
                      }
                    },
                    text: language.submit,
                    color: primaryColor,
                    textStyle: boldTextStyle(color: Colors.white),
                    width: MediaQuery.of(context).size.width,
                  ),
                )
              ],
            ),
            Observer(
                builder: (context) => Visibility(
                    visible: appStore.isLoading,
                    child: Positioned.fill(child: loaderWidget()))),
          ],
        ),
      ),
    );
  }
}
