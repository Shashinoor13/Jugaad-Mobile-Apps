import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:booking_system_flutter/screens/verified_provider_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/verified_provider_component.dart';
import '../../../utils/constant.dart';
import '../../service/view_all_service_screen.dart';

class ProviderListComponent extends StatelessWidget {
  final List<UserData> providerList;

  ProviderListComponent({required this.providerList});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        ViewAllLabel(
          label: 'Jugaad Providers',
          list: providerList,
          onTap: () {
            VerifiedProviderScreen().launch(context);
          },
        ).paddingSymmetric(horizontal: 16),
        8.height,
        providerList.isNotEmpty
            ? Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(providerList.length, (index) {
            return VerifiedProviderComponent(data: providerList[index], width: context.width() / 2 - 26);
          }),
        ).paddingSymmetric(horizontal: 16, vertical: 8)
            : Container().center(),
      ],
    );
  }
}
