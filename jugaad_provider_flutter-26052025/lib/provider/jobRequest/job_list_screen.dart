import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/shimmer/job_request_shimmer.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/cached_image_widget.dart';
import '../../components/empty_error_state_widget.dart';
import '../../components/job_request_filter_bottom_sheet.dart';
import '../../models/city_list_response.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../../utils/model_keys.dart';
import 'components/job_item_widget.dart';
import 'models/post_job_data.dart';

String selectedFilters = 'min_price=&max_price=&category_ids=&city_id=';

class JobListScreen extends StatefulWidget {
  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late Future<List<PostJobData>> future;
  List<PostJobData> myPostJobList = [];
  List<CityListResponse> cityList = [];
  CityListResponse? selectedCity;
  int cityId = 0;
  int page = 1;
  bool isLastPage = false;
  UniqueKey keyForList = UniqueKey();

  FocusNode myFocusNode = FocusNode();

  TextEditingController searchCont = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedFilters = 'min_price=&max_price=&category_ids=';
    cachedCategoryDropdown?.clear();
    cachedCityList?.clear();
    init();
    getCity();
  }

  Future<void> init({String filters = ''}) async {
    future = getPostJobList(
      page,
      postJobList: myPostJobList,
      searchText: searchCont.text,
      filters: filters.isEmpty ? selectedFilters : filters,
      lastPageCallback: (val) => isLastPage = val,
    );
    setState(() {});
  }

  Future<void> getCity() async {
    appStore.setLoading(true);

    await getAdminCityList().then((value) async {
      cityList.clear();
      cityList.addAll(value);
      cachedCityList =cityList;
      value.forEach((e) {
        if (e.id == getIntAsync(CITY_ID)) {
          selectedCity = e;
        }
      });
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.jobRequestList,
      body: Stack(
        children: [
          SnapHelperWidget<List<PostJobData>>(
            future: future,
            onSuccess: (data) {
              return AnimatedScrollView(
                  controller: scrollController,
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    page = 1;
                    appStore.setLoading(true);

                    init(filters: selectedFilters);
                    setState(() {});

                    return await 1.seconds.delay;
                  },
                  onNextPage: () {
                    if (!isLastPage) {
                      page++;
                      appStore.setLoading(true);

                      init();
                      setState(() {});
                    }
                  },
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: 16, right: 16, top: 24, bottom: 8),
                      child: Row(
                        children: [
                          AppTextField(
                            textFieldType: TextFieldType.OTHER,
                            focus: myFocusNode,
                            controller: searchCont,
                            suffix: CloseButton(
                              onPressed: () {
                                page = 1;
                                searchCont.clear();

                                appStore.setLoading(true);

                                init();
                                setState(() {});
                              },
                            ).visible(searchCont.text.isNotEmpty),
                            onFieldSubmitted: (s) {
                              page = 1;

                              appStore.setLoading(true);

                              init();
                              setState(() {});
                            },
                            decoration: inputDecoration(context).copyWith(
                              hintText: "Search here",
                              prefixIcon:
                                  ic_search.iconImage(size: 8).paddingAll(16),
                              hintStyle: secondaryTextStyle(),
                            ),
                          ).expand(),
                          // DropdownButtonFormField<CityListResponse>(
                          //   decoration: inputDecoration(context, hint: 'Select City'),
                          //   isExpanded: false,
                          //   hint: Text('Select City', style: secondaryTextStyle()),
                          //   value: selectedCity,
                          //   validator: (value) {
                          //     if (value == null) return errorThisFieldRequired;
                          //
                          //     return null;
                          //   },
                          //   dropdownColor: context.cardColor,
                          //   items: cityList.map((CityListResponse e) {
                          //     return DropdownMenuItem<CityListResponse>(
                          //       value: e,
                          //       child: Text(e.name!, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                          //     );
                          //   }).toList(),
                          //   onChanged: (CityListResponse? value) async {
                          //     hideKeyboard(context);
                          //     selectedCity = value;
                          //     cityId = value!.id!;
                          //     init(filters: selectedFilters);
                          //     setState(() {});
                          //   },
                          // ).expand(),
                          16.width,
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: boxDecorationDefault(
                                color: context.primaryColor),
                            child: CachedImageWidget(url: ic_filter, height: 26, width: 26, color: Colors.white,),
                          ).onTap(
                            () async {
                              hideKeyboard(context);
                              String? res = await showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                isDismissible: true,
                                enableDrag: false,
                                shape: RoundedRectangleBorder(borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
                                builder: (_) {
                                  return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      Container(
                                            decoration: boxDecorationWithRoundedCorners(borderRadius: radiusOnly(topLeft: defaultRadius, topRight: defaultRadius), backgroundColor: context.cardColor),
                                            padding: EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(languages.filterBy, style: boldTextStyle()),
                                                IconButton(
                                                  padding: EdgeInsets.all(0),
                                                  icon: Icon(Icons.close, color: appStore.isDarkMode ? lightPrimaryColor : context.primaryColor, size: 20),
                                                  visualDensity: VisualDensity.compact,
                                                  onPressed: () async {
                                                    finish(context);
                                                  },
                                                ),
                                              ],
                                            )),
                                  Flexible(
                                  child: JobRequestFilterBottomSheet())
                                      ]
                                  );
                                },
                              );

                              if (res.validate().isNotEmpty) {
                                page = 1;
                                appStore.setLoading(true);

                                selectedFilters = res.validate();
                                init(filters: res.validate());

                                if (myPostJobList.isNotEmpty) {
                                  scrollController.animateTo(0,
                                      duration: 1.seconds,
                                      curve: Curves.easeOutQuart);
                                } else {
                                  scrollController = ScrollController();
                                  keyForList = UniqueKey();
                                }
                                setState(() {});
                              }
                            },
                            borderRadius: radius(),
                          ),
                        ],
                      ),
                    ),
                    AnimatedListView(
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration:
                          FadeInConfiguration(duration: 2.seconds),
                      padding: EdgeInsets.all(16),
                      itemCount: data.validate().length,
                      shrinkWrap: true,
                      emptyWidget: NoDataWidget(
                        title: languages.noDataFound,
                        imageWidget: EmptyStateWidget(),
                      ),
                      itemBuilder: (_, i) => JobItemWidget(data: data[i]),
                      onNextPage: () {
                        if (!isLastPage) {
                          page++;
                          appStore.setLoading(true);

                          init();
                          setState(() {});
                        }
                      },
                      onSwipeRefresh: () async {
                        page = 1;

                        init(filters: selectedFilters);
                        setState(() {});

                        return await 2.seconds.delay;
                      },
                    )
                  ]);
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: languages.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);

                  init();
                  setState(() {});
                },
              );
            },
            loadingWidget: JobPostRequestShimmer(),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
