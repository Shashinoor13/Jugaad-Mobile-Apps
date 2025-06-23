import 'dart:convert';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/createService/create_service_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/post_voice_recorder.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/chat_gpt_loder.dart';
import '../../component/empty_error_state_widget.dart';
import '../../model/city_list_model.dart';
import '../../network/network_utils.dart';

class CreatePostRequestScreen extends StatefulWidget {
  @override
  _CreatePostRequestScreenState createState() =>
      _CreatePostRequestScreenState();
}

class _CreatePostRequestScreenState extends State<CreatePostRequestScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController postTitleCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();
  TextEditingController priceCont = TextEditingController();

  FocusNode descriptionFocus = FocusNode();
  FocusNode priceFocus = FocusNode();

  List<ServiceData> myServiceList = [];
  List<ServiceData> selectedServiceList = [];

  List<CityListResponse> cityList = [];
  CityListResponse? selectedCity;
  int cityId = 0;
  String audioPath = "";

  @override
  void initState() {
    super.initState();
    init();
    getCity();
  }

  Future<void> init() async {
    appStore.setLoading(true);

    await getMyServiceList().then((value) {
      appStore.setLoading(false);

      if (value.userServices != null) {
        myServiceList = value.userServices.validate();
      }
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });

    setState(() {});
  }

  Future<void> getCity() async {
    appStore.setLoading(true);

    await getAdminCityList().then((value) async {
      cityList.clear();
      cityList.addAll(value);
      value.forEach((e) {
        if (e.id == getIntAsync(CITY_ID)) {
          selectedCity = e;
        }
      });
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  // Future<void> getAdminCityList() async {
  //   await getAdminCityList().then((value) async {
  //     cityList.clear();
  //     cityList.addAll(value);
  //     setState(() {});
  //     value.forEach((e) {
  //       if (e.id == getIntAsync(COUNTRY_ID)) {
  //         selectedCity = e;
  //       }
  //     });
  //   }).catchError((e) {
  //     toast('$e', print: true);
  //   });
  //   appStore.setLoading(false);
  // }

  Future<void> createJobRequest() async {
    appStore.setLoading(true);
    List<int> serviceList = [];
    String serviceIDs = "";

    if (selectedServiceList.isNotEmpty) {
      selectedServiceList.forEach((element) {
        serviceList.add(element.id.validate());
        serviceIDs = serviceIDs + element.id.validate().toString() + ",";
      });
    }

    MultipartRequest multiPartRequest =
        await getMultiPartRequest('create-post-job');
    multiPartRequest.fields[PostJob.postTitle] = postTitleCont.text.validate();
    multiPartRequest.fields[PostJob.description] = selectedCity!.name.validate();
    multiPartRequest.fields[PostJob.cityId] = '$cityId';
    multiPartRequest.fields[PostJob.serviceId] = serviceIDs;
    multiPartRequest.fields[PostJob.price] = priceCont.text.validate();
    multiPartRequest.fields[PostJob.status] = JOB_REQUEST_STATUS_REQUESTED;
    multiPartRequest.fields[PostJob.latitude] = appStore.latitude.toString();
    multiPartRequest.fields[PostJob.longitude] = appStore.longitude.toString();

    log("multiPart Request: ${multiPartRequest.fields}");

    if (audioPath.isNotEmpty)
      multiPartRequest.files
          .add(await MultipartFile.fromPath(PostJob.voiceNote, audioPath));

    multiPartRequest.headers.addAll(buildHeaderTokens());

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        toast(jsonDecode(data)['message'], print: true);

        finish(context, true);
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void createPostJobClick() {
    appStore.setLoading(true);
    List<int> serviceList = [];

    if (selectedServiceList.isNotEmpty) {
      selectedServiceList.forEach((element) {
        serviceList.add(element.id.validate());
      });
    }

    Map request = {
      PostJob.postTitle: postTitleCont.text.validate(),
      PostJob.description: selectedCity!.name.validate(),
      PostJob.cityId: cityId,
      PostJob.serviceId: serviceList,
      PostJob.price: priceCont.text.validate(),
      PostJob.status: JOB_REQUEST_STATUS_REQUESTED,
      PostJob.latitude: appStore.latitude,
      PostJob.longitude: appStore.longitude,
    };

    savePostJob(request).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());

      finish(context, true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void deleteService(ServiceData data) {
    appStore.setLoading(true);

    deleteServiceRequest(data.id.validate()).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());
      init();
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.newPostJobRequest,
      child: Stack(
        children: [
          AnimatedScrollView(
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            padding: EdgeInsets.only(bottom: 60),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        16.height,
                        AppTextField(
                          controller: postTitleCont,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.requiredText,
                          nextFocus: descriptionFocus,
                          decoration: inputDecoration(context,
                              labelText: language.postJobTitle),
                        ),
                        16.height,
                        if (cityList.isNotEmpty)
                          DropdownButtonFormField<CityListResponse>(
                            decoration: inputDecoration(context, labelText: language.selectCity),
                            isExpanded: false,
                            hint: Text(language.selectCity,
                                style: secondaryTextStyle()),
                            value: selectedCity,
                            validator: (value) {
                              if (value == null) return errorThisFieldRequired;

                              return null;
                            },
                            dropdownColor: context.cardColor,
                            items: cityList.map((CityListResponse e) {
                              return DropdownMenuItem<CityListResponse>(
                                value: e,
                                child: Text(e.name!, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (CityListResponse? value) async {
                              hideKeyboard(context);
                              selectedCity = value;
                              cityId = value!.id!;
                              setState(() {});
                            },
                          ),
                        AppTextField(
                          controller: descriptionCont,
                          textFieldType: TextFieldType.ADDRESS,
                          errorThisFieldRequired: language.requiredText,
                          maxLines: 1,
                          focus: descriptionFocus,
                          nextFocus: priceFocus,
                          // enableChatGPT: appConfigurationStore.chatGPTStatus,
                          // promptFieldInputDecorationChatGPT:
                          //     inputDecoration(context).copyWith(
                          //   hintText: language.writeHere,
                          //   fillColor: context.scaffoldBackgroundColor,
                          //   filled: true,
                          // ),
                          testWithoutKeyChatGPT:
                              appConfigurationStore.testWithoutKey,
                          loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                          decoration: inputDecoration(context,
                              labelText: "Address"),
                        ).visible(false),
                        16.height,
                        AppTextField(
                          textFieldType: TextFieldType.PHONE,
                          controller: priceCont,
                          focus: priceFocus,
                          errorThisFieldRequired: language.requiredText,
                          decoration: inputDecoration(context,
                              labelText: "Estimated " + language.price),
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: (s) {
                            if (s!.isEmpty) return errorThisFieldRequired;

                            if (s.toDouble() <= 0)
                              return language.priceAmountValidationMessage;
                            return null;
                          },
                        )
                      ],
                    ).paddingAll(16),
                  ),
                  Text(language.addVoiceNote,
                          style: boldTextStyle(size: LABEL_TEXT_SIZE))
                      .paddingSymmetric(horizontal: 16, vertical: 4),
                  PostVoiceRecorder(
                    callback: (v) {
                      setState(() {
                        audioPath = v;
                        print("audioPath: " + audioPath);
                      });
                    },
                  ).paddingSymmetric(horizontal: 16, vertical: 0),
                  // Column(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  // AppButton(
                  //   child: Text(language.addVoiceNote, style: boldTextStyle(color: context.primaryColor)),
                  //   onTap: () async {
                  //     hideKeyboard(context);
                  //
                  //     bool? res = await VoiceRecordingScreen().launch(context);
                  //     if (res ?? false) init();
                  //   },
                  // ),
                  // ],
                  // ).paddingOnly(right: 8, left: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(language.services,
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                    ],
                  ).paddingOnly(right: 8, left: 16, top: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton(
                        width: context.width() - 48,
                        color: context.primaryColor,
                        child: Text(language.addNewService,
                            style: boldTextStyle(color: Colors.white)),
                        onTap: () async {
                          hideKeyboard(context);
                          bool? res =
                          await CreateServiceScreen().launch(context);
                          if (res ?? false) init();
                        },
                      ),
                    ],
                  ).paddingOnly(right: 8, left: 8, top: 8),
                  if (myServiceList.isNotEmpty)
                    AnimatedListView(
                      itemCount: myServiceList.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(8),
                      listAnimationType: ListAnimationType.FadeIn,
                      itemBuilder: (_, i) {
                        ServiceData data = myServiceList[i];

                        return Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.all(8),
                          width: context.width(),
                          decoration: boxDecorationWithRoundedCorners(
                              backgroundColor: context.cardColor),
                          child: Row(
                            children: [
                              CachedImageWidget(
                                url: data.attachments.validate().isNotEmpty
                                    ? data.attachments!.first.validate()
                                    : "",
                                fit: BoxFit.cover,
                                height: 60,
                                width: 60,
                                radius: defaultRadius,
                              ),
                              16.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data.name.validate(),
                                      style: boldTextStyle()),
                                  4.height,
                                  Text(data.categoryName.validate(),
                                      style: secondaryTextStyle()),
                                ],
                              ).expand(),
                              Column(
                                children: [
                                  IconButton(
                                    icon: ic_edit_square.iconImage(size: 14),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      bool? res =
                                          await CreateServiceScreen(data: data)
                                              .launch(context);
                                      if (res ?? false) init();
                                    },
                                  ),
                                  IconButton(
                                    icon: ic_delete.iconImage(size: 14),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      showConfirmDialogCustom(
                                        context,
                                        dialogType: DialogType.DELETE,
                                        positiveText: language.lblDelete,
                                        negativeText: language.lblCancel,
                                        onAccept: (p0) {
                                          // ifNotTester(() {
                                          deleteService(data);
                                          //});
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              selectedServiceList.any((e) => e.id == data.id)
                                  ? AppButton(
                                      child: Text(language.remove,
                                          style: boldTextStyle(
                                              color: redColor, size: 14)),
                                      onTap: () {
                                        selectedServiceList.remove(data);
                                        setState(() {});
                                      },
                                    )
                                  : AppButton(
                                      child: Text(language.add,
                                          style: boldTextStyle(
                                              size: 14,
                                              color: context.primaryColor)),
                                      onTap: () {
                                        selectedServiceList.add(data);
                                        setState(() {});
                                      },
                                    ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (myServiceList.isEmpty && !appStore.isLoading)
                    NoDataWidget(
                      imageWidget: EmptyStateWidget(),
                      title: language.noServiceAdded,
                      imageSize: Size(90, 90),
                    ).paddingOnly(top: 16),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AppButton(
              child: Text(language.save, style: boldTextStyle(color: white)),
              color: context.primaryColor,
              width: context.width(),
              onTap: () {
                hideKeyboard(context);

                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  if (selectedServiceList.isNotEmpty) {
                    createJobRequest();
                  } else {
                    toast(language.createPostJobWithoutSelectService);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
