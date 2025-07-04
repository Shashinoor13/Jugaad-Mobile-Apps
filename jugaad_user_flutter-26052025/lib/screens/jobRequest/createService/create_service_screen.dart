import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/chat_gpt_loder.dart';

class CreateServiceScreen extends StatefulWidget {
  final ServiceData? data;

  CreateServiceScreen({this.data});

  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  ImagePicker picker = ImagePicker();

  TextEditingController serviceNameCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  FocusNode serviceNameFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();

  List<XFile> imageFiles = [];
  List<Attachments> attachmentsArray = [];
  List<String> typeList = [SERVICE_TYPE_FIXED, SERVICE_TYPE_HOURLY];
  List<CategoryData> categoryList = [];

  CategoryData? selectedCategory;
  String serviceType = '';

  bool isUpdate = false;
  bool isServiceUpdated = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    isUpdate = widget.data != null;

    if (isUpdate) {
      serviceNameCont.text = widget.data!.name.validate();
      descriptionCont.text = widget.data!.description.validate();
      imageFiles.addAll(
          widget.data!.attachments!.map((e) => XFile(e.validate().toString())));
      attachmentsArray.addAll(widget.data!.attachmentsArray.validate());
    }
    await getCategoryData();
  }

  Future<void> getCategoryData() async {
    appStore.setLoading(true);
    await getCategoryList(CATEGORY_LIST_ALL).then((value) {
      if (value.categoryList!.isNotEmpty) {
        categoryList.addAll(value.categoryList.validate());
      }

      if (isUpdate) {
        selectedCategory = value.categoryList!.firstWhere(
            (element) => element.id == widget.data!.categoryId.validate());
      }

      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> getMultipleFile() async {
    await picker.pickMultiImage().then((value) {
      // if(imageFiles.isNotEmpty) imageFiles.removeLast();
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  Future<void> getMultipleVideoFile() async {
    await picker.pickMultipleMedia().then((value) {
      // if(imageFiles.isNotEmpty) imageFiles.removeLast();
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  Future<void> createServiceRequest() async {
    appStore.setLoading(true);

    MultipartRequest multiPartRequest = await getMultiPartRequest('service-save');
    multiPartRequest.fields[CreateService.name] = serviceNameCont.text.validate();
    multiPartRequest.fields[CreateService.description] = descriptionCont.text.validate();
    multiPartRequest.fields[CreateService.type] = SERVICE_TYPE_FIXED;
    multiPartRequest.fields[CreateService.price] = '0';
    multiPartRequest.fields[CreateService.addedBy] = appStore.userId.toString().validate();
    multiPartRequest.fields[CreateService.providerId] = appStore.userId.toString();
    multiPartRequest.fields[CreateService.categoryId] = selectedCategory!.id.toString();
    multiPartRequest.fields[CreateService.status] = '1';
    multiPartRequest.fields[CreateService.duration] = "0";

    log("multiPart Request: ${multiPartRequest.fields}");

    if (isUpdate) {
      multiPartRequest.fields[CreateService.id] =
          widget.data!.id.validate().toString();
    }

    if (imageFiles.isNotEmpty) {
      List<XFile> tempImages = imageFiles
          .where((element) => !element.path.contains("http"))
          .toList();

      multiPartRequest.files.clear();
      await Future.forEach<XFile>(tempImages, (element) async {
        int i = tempImages.indexOf(element);
        multiPartRequest.files.add(await MultipartFile.fromPath(
            '${CreateService.serviceAttachment + i.toString()}', element.path));
      });

      if (tempImages.isNotEmpty)
        multiPartRequest.fields[CreateService.attachmentCount] =
            tempImages.length.toString();
    }

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

  Future<void> removeAttachment({required int id}) async {
    appStore.setLoading(true);

    Map req = {
      CommonKeys.type: SERVICE_ATTACHMENT,
      CommonKeys.id: id,
    };

    await deleteImage(req).then((value) {
      attachmentsArray.validate().removeWhere((element) => element.id == id);
      isServiceUpdated = true;
      setState(() {});

      // uniqueKey = UniqueKey();

      appStore.setLoading(false);
      toast(value.message.validate(), print: true);
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
    return WillPopScope(
      onWillPop: () {
        finish(context, isServiceUpdated);
        return Future.value(false);
      },
      child: AppScaffold(
        appBarTitle: language.createServiceRequest,
        child: AnimatedScrollView(
          padding: EdgeInsets.all(16),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          children: [
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: context.width(),
                    height: 120,
                    child: Row(
                      children: [
                        Flexible(
                          flex: 5,
                          child: DottedBorderWidget(
                            color: primaryColor.withOpacity(0.6),
                            strokeWidth: 1,
                            gap: 6,
                            radius: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(selectVideo,
                                    height: 25,
                                    width: 25,
                                    color: appStore.isDarkMode ? white : gray),
                                8.height,
                                Text(language.chooseVideos,
                                    style: boldTextStyle()),
                              ],
                            ).center().onTap(borderRadius: radius(), () async {
                              getMultipleVideoFile();
                            }),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Flexible(
                          flex: 5,
                          child: DottedBorderWidget(
                            color: primaryColor.withOpacity(0.6),
                            strokeWidth: 1,
                            gap: 6,
                            radius: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(selectImage,
                                    height: 25,
                                    width: 25,
                                    color: appStore.isDarkMode ? white : gray),
                                8.height,
                                Text(language.chooseImages,
                                    style: boldTextStyle()),
                              ],
                            ).center().onTap(borderRadius: radius(), () async {
                              getMultipleFile();
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HorizontalList(
                    itemCount: imageFiles.length,
                    itemBuilder: (context, i) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          if (imageFiles[i].path.contains("http"))
                            CachedImageWidget(
                                    url: imageFiles[i].path,
                                    placeHolderImage: videoThumb,
                                    height: 90,
                                    fit: BoxFit.cover)
                                .cornerRadiusWithClipRRect(16)
                          else
                            Image.file(File(imageFiles[i].path), errorBuilder:
                                    (BuildContext context, Object error,
                                        StackTrace? stackTrace) { return Center(
                                  child: Image.asset(videoThumb,
                                      height: 80,
                                      width: 80,
                                      color:
                                          appStore.isDarkMode ? white : gray));
                            }, width: 90, height: 90, fit: BoxFit.cover)
                                .cornerRadiusWithClipRRect(16),
                          Container(
                            decoration: boxDecorationWithRoundedCorners(
                                boxShape: BoxShape.circle,
                                backgroundColor: primaryColor),
                            margin: EdgeInsets.only(right: 8, top: 4),
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 16, color: white),
                          ).onTap(() {
                            if (imageFiles[i].path.startsWith("http")) {
                              showConfirmDialogCustom(
                                context,
                                dialogType: DialogType.DELETE,
                                positiveText: language.lblDelete,
                                negativeText: language.lblCancel,
                                primaryColor: context.primaryColor,
                                onAccept: (p0) {
                                  if (attachmentsArray.any((element) =>
                                      element.url == imageFiles[i].path)) {
                                    int id = attachmentsArray
                                        .firstWhere((element) =>
                                            element.url == imageFiles[i].path)
                                        .id
                                        .validate();

                                    imageFiles.removeAt(i);
                                    attachmentsArray.removeAt(i);

                                    removeAttachment(id: id);
                                  }
                                  setState(() {});
                                },
                              );
                            } else {
                              showConfirmDialogCustom(
                                context,
                                dialogType: DialogType.DELETE,
                                positiveText: language.lblDelete,
                                negativeText: language.lblCancel,
                                primaryColor: context.primaryColor,
                                onAccept: (p0) {
                                  imageFiles.removeWhere((element) =>
                                      element.path == imageFiles[i].path);
                                  attachmentsArray.removeWhere((element) =>
                                      element.url == imageFiles[i].path);
                                  //imageFiles.removeAt(i);
                                  setState(() {});
                                },
                              );
                            }
                          }),
                        ],
                      );
                    },
                  ).paddingBottom(16).visible(imageFiles.isNotEmpty),
                  20.height,
                  DropdownButtonFormField<CategoryData>(
                    decoration: inputDecoration(context,
                        labelText: language.lblCategory),
                    hint: Text(language.selectCategory,
                        style: secondaryTextStyle()),
                    value: selectedCategory,
                    validator: (value) {
                      if (value == null) return errorThisFieldRequired;

                      return null;
                    },
                    dropdownColor: context.scaffoldBackgroundColor,
                    items: categoryList.map((data) {
                      return DropdownMenuItem<CategoryData>(
                        value: data,
                        child: Text(data.name.validate(),
                            style: primaryTextStyle()),
                      );
                    }).toList(),
                    onChanged: isUpdate
                        ? null
                        : (CategoryData? value) async {
                            selectedCategory = value!;
                            setState(() {});
                          },
                  ),
                  16.height,
                  AppTextField(
                    controller: serviceNameCont,
                    textFieldType: TextFieldType.NAME,
                    nextFocus: descriptionFocus,
                    errorThisFieldRequired: language.requiredText,
                    decoration: inputDecoration(context,
                        labelText: language.serviceName),
                  ),
                  16.height,
                  AppTextField(
                    controller: descriptionCont,
                    textFieldType: TextFieldType.MULTILINE,
                    // errorThisFieldRequired: language.requiredText,
                    maxLines: 2,
                    focus: descriptionFocus,
                    // enableChatGPT: appConfigurationStore.chatGPTStatus,
                    // promptFieldInputDecorationChatGPT:
                    //     inputDecoration(context).copyWith(
                    //   hintText: language.writeHere,
                    //   fillColor: context.scaffoldBackgroundColor,
                    //   filled: true,
                    // ),
                    // testWithoutKeyChatGPT: appConfigurationStore.testWithoutKey,
                    // loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                    decoration: inputDecoration(context,
                        labelText: language.serviceDescription),
                    validator: (value) {
                    //   if (value!.isEmpty) return language.requiredText;
                      return null;
                    },
                  ),
                  16.height,
                  AppButton(
                    text: isUpdate ? language.lblUpdate : language.save,
                    color: context.primaryColor,
                    width: context.width(),
                    onTap: () {
                      hideKeyboard(context);

                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();

                        ///Image file field is required
                        if (imageFiles.isEmpty) {
                          return toast(language.pleaseAddImage);
                        }

                        showConfirmDialogCustom(
                          context,
                          title:
                              "${language.lblAreYouSureWant} ${isUpdate ? language.lblUpdate : language.lblAdd} ${language.lblThisService}?",
                          positiveText: language.lblYes,
                          negativeText: language.lblNo,
                          primaryColor: primaryColor,
                          onAccept: (p0) {
                            createServiceRequest();
                          },
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
