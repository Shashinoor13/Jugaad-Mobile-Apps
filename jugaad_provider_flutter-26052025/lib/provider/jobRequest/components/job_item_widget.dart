import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/extensions/color_extension.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../components/price_widget.dart';
import '../../../main.dart';
import '../job_post_detail_screen.dart';
import '../models/post_job_data.dart';

class JobItemWidget extends StatelessWidget {
  final PostJobData? data;

  const JobItemWidget({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null) return Offstage();

    return Container(
      width: context.width(),
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: boxDecorationDefault(color: context.cardColor, borderRadius: radius()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedImageWidget(
            url: data!.service.validate().isNotEmpty && data!.service.validate().first.imageAttachments.validate().isNotEmpty ? data!.service.validate().first.imageAttachments!.first.validate() : "",
            fit: BoxFit.cover,
            height: 70,
            width: 70,
            radius: defaultRadius,
          ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(data!.title.validate(), style: primaryTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis).expand(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: data!.status.validate().getJobStatusColor.withOpacity(0.1), borderRadius: radius(8)),
                    child: Text(data!.status.validate().toPostJobStatus(), style: boldTextStyle(color: data!.status.validate().getJobStatusColor, size: 12)),
                  ),
                ]
              ),
              2.height,
              PriceWidget(price: data!.price.validate(), isHourlyService: false, color: textPrimaryColorGlobal, isFreeService: false, size: 14),
              4.height,
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data!.description.validate(), style: secondaryTextStyle()),
                  Text(formatDate(data!.createdAt.validate()), style: secondaryTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ).expand(),
        ],
      ).onTap(() {
        if (appStore.userStatus == 1) { //ACME
          JobPostDetailScreen(postJobData: data!).launch(context);
        } else {
          toast(languages.pleaseContactYourAdmin);
          // push(SignInScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        }
      }, borderRadius: radius()),
    );
  }
}
