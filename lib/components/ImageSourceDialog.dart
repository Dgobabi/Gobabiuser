import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';

class ImageSourceDialog extends StatefulWidget {
 final Function()? onGallery;
 final Function()? onCamera;

 ImageSourceDialog({this.onGallery, this.onCamera});

  @override
  State<ImageSourceDialog> createState() => _ImageSourceDialogState();
}

class _ImageSourceDialogState extends State<ImageSourceDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.selectSources, style: boldTextStyle(size: 18)),
              InkWell(onTap: (){
                Navigator.pop(context);
              },child: Icon(Icons.cancel_outlined)),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: inkWellWidget(
                  onTap: widget.onGallery ?? (){},
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.5)), borderRadius: BorderRadius.circular(defaultRadius)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(ic_gallery, height: 30, width: 30, fit: BoxFit.cover),
                        SizedBox(height: 16),
                        Text(language.gallery, style: boldTextStyle()),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: inkWellWidget(
                  onTap: widget.onCamera ?? (){},
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.5)), borderRadius: BorderRadius.circular(defaultRadius)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(ic_camera, height: 30, width: 30, fit: BoxFit.cover),
                        SizedBox(height: 16),
                        Text(language.camera, style: boldTextStyle()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
