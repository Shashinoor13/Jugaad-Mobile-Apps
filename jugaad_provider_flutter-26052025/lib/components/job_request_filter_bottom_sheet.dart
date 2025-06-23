import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../../utils/colors.dart';
import '../models/category_filter_response.dart';
import '../models/city_list_response.dart';
import '../networks/rest_apis.dart';
import '../provider/jobRequest/job_list_screen.dart';
import '../utils/constant.dart';
import '../utils/images.dart';

class JobRequestFilterBottomSheet extends StatefulWidget {
  const JobRequestFilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<JobRequestFilterBottomSheet> createState() => _JobRequestFilterBottomSheetState();
}

class _JobRequestFilterBottomSheetState extends State<JobRequestFilterBottomSheet> {
  Future<List<CategoryFilterData>>? future;

  List<CategoryFilterData> list = [];
  CategoryFilterData? selectedData;
  late RangeValues rangeValues;

  List<CityListResponse> cityList = [];
  @override
  void initState() {
    if (cachedCategoryDropdown.validate().isEmpty) {
      init();
    }
    if (cachedCityList.validate().isEmpty) {
      getCity();
    }

    rangeValues = RangeValues(1, 10000);
    super.initState();
  }

  void init() async {
    future = getCategoryFilter(list: list);
  }

  Future<void> getCity() async {
    appStore.setLoading(true);
    await getAdminCityList().then((value) async {
      cityList.clear();
      cityList.addAll(value);
      cachedCityList = cityList;
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
    setState(() {});
  }

  Widget itemWidget(CategoryFilterData res) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: boxDecorationDefault(
        color: appStore.isDarkMode
            ? res.isSelected
                ? lightPrimaryColor
                : context.scaffoldBackgroundColor
            : res.isSelected
                ? lightPrimaryColor
                : context.scaffoldBackgroundColor,
        borderRadius: radius(8),
        border: Border.all(color: appStore.isDarkMode ? Colors.white54 : lightPrimaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (res.isSelected)
            Container(
              padding: EdgeInsets.all(2),
              margin: EdgeInsets.only(right: 1),
              child: Icon(Icons.done, size: 16, color: context.primaryColor),
            ),
          Text(res.name.validate().toString(),
            style: primaryTextStyle(
                color: appStore.isDarkMode
                    ? res.isSelected
                        ? context.primaryColor
                        : Colors.white54
                    : res.isSelected
                        ? context.primaryColor
                        : Colors.black38,
                size: 12),
          ),
        ],
      ),
    ).onTap(() {
      res.isSelected = !res.isSelected;

      setState(() {});
    });
  }

  Widget itemCityWidget(CityListResponse res) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: boxDecorationDefault(
        color: appStore.isDarkMode
            ? res.isSelected
                ? lightPrimaryColor
                : context.scaffoldBackgroundColor
            : res.isSelected
                ? lightPrimaryColor
                : context.scaffoldBackgroundColor,
        borderRadius: radius(8),
        border: Border.all(color: appStore.isDarkMode ? Colors.white54 : lightPrimaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (res.isSelected)
            Container(
              padding: EdgeInsets.all(2),
              margin: EdgeInsets.only(right: 1),
              child: Icon(Icons.done, size: 16, color: context.primaryColor),
            ),
          Text(res.name.validate().toString(),
            style: primaryTextStyle(
                color: appStore.isDarkMode
                    ? res.isSelected
                        ? context.primaryColor
                        : Colors.white54
                    : res.isSelected
                        ? context.primaryColor
                        : Colors.black38,
                size: 12),
          ),
        ],
      ),
    ).onTap(() {
      res.isSelected = !res.isSelected;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: boxDecorationWithRoundedCorners(
            borderRadius: radiusOnly(topLeft: 0, topRight: 0), backgroundColor: context.cardColor),
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(languages.filterBy, style: boldTextStyle()),
              //     IconButton(
              //       padding: EdgeInsets.all(0),
              //       icon: Icon(Icons.close, color: appStore.isDarkMode ? lightPrimaryColor : context.primaryColor, size: 20),
              //       visualDensity: VisualDensity.compact,
              //       onPressed: () async {
              //         finish(context);
              //       },
              //     ),
              //   ],
              // ),
              // 8.height,
              // Container(width: context.width() - 16, height: 1, color: gray.withOpacity(0.3)).center(),
              // 8.height,
              Container(
                width: context.width(),
                decoration: boxDecorationDefault(color: context.cardColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Price Range', style: primaryTextStyle()).paddingAll(1),
                    RangeSlider(
                      min: 1,
                      max: 10000,
                      divisions: (10000 ~/ 10).toInt(),
                      labels: RangeLabels(
                          rangeValues.start.toInt().toString(), rangeValues.end.toInt().toString()),
                      values: rangeValues,
                      onChanged: (values) {
                        rangeValues = values;
                        setState(() {});
                      },
                    ),
                    16.height,
                    Marquee(
                      child: Row(
                        children: [
                          Text("[ ", style: primaryTextStyle()),
                          PriceWidget(
                              price: rangeValues.start.toInt(),
                              isBoldText: false,
                              color: textPrimaryColorGlobal,
                              decimalPoint: 0),
                          Text(" - ", style: primaryTextStyle()),
                          PriceWidget(
                              price: rangeValues.end.toInt(),
                              isBoldText: false,
                              color: textPrimaryColorGlobal,
                              decimalPoint: 0),
                          Text("]", style: primaryTextStyle()),
                        ],
                      ),
                    ).center(),
                  ],
                ),
              ),
              24.height,
              Container(width: context.width() - 16, height: 1, color: gray.withOpacity(0.3))
                  .center(),
              8.height,
              Text(languages.hintSelectCategory, style: primaryTextStyle()),
              24.height,
              FutureBuilder<List<CategoryFilterData>>(
                initialData: cachedCategoryDropdown,
                future: future,
                builder: (context, snap) {
                  if (snap.hasData) {
                    return Wrap(
                      runSpacing: 12,
                      spacing: 12,
                      children: List.generate(
                          snap.data!.length, (index) => itemWidget(snap.data![index])),
                    );
                  }

                  return snapWidgetHelper(snap, defaultErrorMessage: "", loadingWidget: Offstage());
                },
              ),
              24.height,
              Container(width: context.width() - 16, height: 1, color: gray.withOpacity(0.3))
                  .center(),
              8.height,
              Text(languages.selectCity, style: primaryTextStyle()),
              24.height,
              Wrap(
                runSpacing: 12,
                spacing: 12,
                children: List.generate(
                    cachedCityList!.length, (index) => itemCityWidget(cachedCityList![index])),
              ),
              96.height,
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     AppButton(
              //       text: languages.clearFilter,
              //       color: appStore.isDarkMode
              //           ? context.scaffoldBackgroundColor
              //           : white,
              //       textColor:
              //           appStore.isDarkMode ? white : context.primaryColor,
              //       width: context.width() - context.navigationBarHeight,
              //       onTap: () {
              //         int selectedCount = cachedCategoryDropdown!
              //             .where((element) => element.isSelected)
              //             .length;
              //
              //         if (selectedCount >= 1) {
              //           selectedFilters =
              //               'min_price=&max_price=&category_ids=&city_id=';
              //           finish(context, selectedFilters);
              //           init();
              //           getCity();
              //         } else {
              //           selectedFilters =
              //               'min_price=&max_price=&category_ids=&city_id=';
              //           finish(context, selectedFilters);
              //         }
              //       },
              //     ).expand(),
              //     16.width,
              //     AppButton(
              //       text: languages.apply,
              //       color: context.primaryColor,
              //       textColor: white,
              //       width: context.width() - context.navigationBarHeight,
              //       onTap: () {
              //         String filterQuery =
              //             'min_price=${rangeValues.start}&max_price=${rangeValues.end}&category_ids=';
              //
              //         int selectedCount = cachedCategoryDropdown!
              //             .where((element) => element.isSelected)
              //             .length;
              //         if (selectedCount >= 1) {
              //           String ids = cachedCategoryDropdown
              //               .validate()
              //               .where((element) => element.isSelected)
              //               .map((e) => e.id)
              //               .join(',');
              //           filterQuery = filterQuery + ids;
              //         }
              //
              //         int selectedCityCount = cachedCityList!
              //             .where((element) => element.isSelected)
              //             .length;
              //         if (selectedCityCount >= 1) {
              //           String cityIds = cachedCityList
              //               .validate()
              //               .where((element) => element.isSelected)
              //               .map((e) => e.id)
              //               .join(',');
              //           filterQuery = '${filterQuery}&city_id=${cityIds}';
              //         }
              //         finish(context, filterQuery);
              //       },
              //     ).expand(),
              //   ],
              // ).paddingOnly(left: 16, right: 16, bottom: 16),
            ],
          ),
        ),
      ),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
              decoration: boxDecorationDefault(
                  color: context.scaffoldBackgroundColor, borderRadius: radius(0)),
              padding: EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Theme(
                data: ThemeData(
                  unselectedWidgetColor:
                      appStore.isDarkMode ? context.dividerColor : context.iconColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      text: languages.clearFilter,
                      color:
                          appStore.isDarkMode ? context.scaffoldBackgroundColor : context.cardColor,
                      textColor: appStore.isDarkMode ? white : context.primaryColor,
                      width: context.width() - context.navigationBarHeight,
                      onTap: () {
                        int selectedCount =
                            cachedCategoryDropdown!.where((element) => element.isSelected).length;

                        if (selectedCount >= 1) {
                          selectedFilters = 'min_price=&max_price=&category_ids=&city_id=';
                          finish(context, selectedFilters);
                          init();
                          getCity();
                        } else {
                          selectedFilters = 'min_price=&max_price=&category_ids=&city_id=';
                          finish(context, selectedFilters);
                        }
                      },
                    ).expand(),
                    16.width,
                    AppButton(
                      text: languages.apply,
                      color: context.primaryColor,
                      textColor: white,
                      width: context.width() - context.navigationBarHeight,
                      onTap: () {
                        String filterQuery =
                            'min_price=${rangeValues.start}&max_price=${rangeValues.end}&category_ids=';

                        int selectedCount =
                            cachedCategoryDropdown!.where((element) => element.isSelected).length;
                        if (selectedCount >= 1) {
                          String ids = cachedCategoryDropdown
                              .validate()
                              .where((element) => element.isSelected)
                              .map((e) => e.id)
                              .join(',');
                          filterQuery = filterQuery + ids;
                        }

                        int selectedCityCount =
                            cachedCityList!.where((element) => element.isSelected).length;
                        if (selectedCityCount >= 1) {
                          String cityIds = cachedCityList
                              .validate()
                              .where((element) => element.isSelected)
                              .map((e) => e.id)
                              .join(',');
                          filterQuery = '${filterQuery}&city_id=${cityIds}';
                        }
                        finish(context, filterQuery);
                      },
                    ).expand(),
                  ],
                ).paddingOnly(left: 16, right: 16, bottom: 16),
              )))
    ]);
  }
}
