class ProviderSubscriptionModel {
  int? id;
  String? title;
  String? identifier;
  int? amount;
  String? type;
  String? endAt;
  int? planId;
  String? startAt;
  String? status;
  int? trialPeriod;
  String? description;
  String? duration;
  PlanLimitation? planLimitation;
  String? planType;
  bool? isVerifiedPlan;
  PlansVerifiedProviders? plansVerifiedProviders;
  int? remainingQuotation;
  int? remainingHandyman;
  int? remainingService;

  ProviderSubscriptionModel({
    this.id,
    this.title,
    this.identifier,
    this.amount,
    this.type,
    this.endAt,
    this.planId,
    this.startAt,
    this.status,
    this.trialPeriod,
    this.description,
    this.duration,
    this.planLimitation,
    this.planType,
    this.isVerifiedPlan,
    this.plansVerifiedProviders,
    this.remainingQuotation,
    this.remainingHandyman,
    this.remainingService
  });

  factory ProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ProviderSubscriptionModel(
      amount: json['amount'],
      endAt: json['end_at'],
      planLimitation: json['plan_limitation'] != null ? PlanLimitation.fromJson(json['plan_limitation']) : null,
      plansVerifiedProviders: json['plans_verified_providers'] != null
          ? new PlansVerifiedProviders.fromJson(json['plans_verified_providers'])
          : null,
      id: json['id'],
      identifier: json['identifier'],
      planId: json['plan_id'],
      startAt: json['start_at'],
      status: json['status'],
      type: json['type'],
      title: json['title'],
      trialPeriod: json['trial_period'],
      description: json['description'],
      duration: json['duration'],
      planType: json['plan_type'],
      isVerifiedPlan: json['is_verified_plan'],
      remainingQuotation: json['remaining_quotation'],
      remainingHandyman: json['remaining_handyman'],
      remainingService: json['remaining_service'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['end_at'] = this.endAt;
    data['id'] = this.id;
    data['identifier'] = this.identifier;
    data['plan_id'] = this.planId;
    data['start_at'] = this.startAt;
    data['status'] = this.status;
    data['type'] = this.type;
    data['title'] = this.title;
    data['trial_period'] = this.trialPeriod;
    data['description'] = this.description;
    data['duration'] = this.duration;
    data['plan_limitation'] = this.planLimitation;
    data['plan_type'] = this.planType;
    data['is_verified_plan'] = this.isVerifiedPlan;
    if (this.planLimitation != null) {
      data['plan_limitation'] = this.planLimitation!.toJson();
    }
    if (this.plansVerifiedProviders != null) {
      data['plans_verified_providers'] = this.plansVerifiedProviders!.toJson();
    }
    data['remaining_quotation'] = this.remainingQuotation;
    data['remaining_handyman'] = this.remainingHandyman;
    data['remaining_service'] = this.remainingService;
    return data;
  }
}

class PlanLimitation {
  LimitData? quotationLimitation;
  LimitData? featuredService;
  LimitData? handyman;
  LimitData? service;

  PlanLimitation({this.quotationLimitation,this.featuredService, this.handyman, this.service});

  factory PlanLimitation.fromJson(Map<String, dynamic> json) {
    return PlanLimitation(
      quotationLimitation: json['quotation_limitation'] != null ? LimitData.fromJson(json['quotation_limitation']) : null,
      featuredService: json['featured_service'] != null ? LimitData.fromJson(json['featured_service']) : null,
      handyman: json['handyman'] != null ? LimitData.fromJson(json['handyman']) : null,
      service: json['service'] != null ? LimitData.fromJson(json['service']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.quotationLimitation != null) {
      data['quotation_limitation'] = this.quotationLimitation!.toJson();
    }
    if (this.featuredService != null) {
      data['featured_service'] = this.featuredService!.toJson();
    }
    if (this.handyman != null) {
      data['handyman'] = this.handyman!.toJson();
    }
    if (this.service != null) {
      data['service'] = this.service!.toJson();
    }
    return data;
  }
}

class LimitData {
  String? isChecked;
  String? limit;

  LimitData({this.isChecked, this.limit});

  factory LimitData.fromJson(Map<String, dynamic> json) {
    return LimitData(
      isChecked: json['is_checked'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_checked'] = this.isChecked;
    data['limit'] = this.limit;
    return data;
  }
}

class PlansVerifiedProviders {
  int? id;
  int? planId;
  String? verifiedProviderType;
  String? verifiedProviderDuration;
  String? verifiedProviderAmount;

  PlansVerifiedProviders(
      {this.id,
        this.planId,
        this.verifiedProviderType,
        this.verifiedProviderDuration,
        this.verifiedProviderAmount});

  PlansVerifiedProviders.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    planId = json['plan_id'];
    verifiedProviderType = json['verified_provider_type'];
    verifiedProviderDuration = json['verified_provider_duration'];
    verifiedProviderAmount = json['verified_provider_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['plan_id'] = this.planId;
    data['verified_provider_type'] = this.verifiedProviderType;
    data['verified_provider_duration'] = this.verifiedProviderDuration;
    data['verified_provider_amount'] = this.verifiedProviderAmount;
    return data;
  }
}