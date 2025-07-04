import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';

class PlanRequestModel {
  int? amount;
  bool? isVerifiedPlan;
  String? description;
  String? duration;
  String? identifier;
  String? otherTransactionDetail;
  String? paymentStatus;
  String? paymentType;
  int? planId;
  PlanLimitation? planLimitation;
  PlansVerifiedProviders? plansVerifiedProviders;
  String? planType;
  String? title;
  String? txnId;
  String? type;
  int? userId;

  PlanRequestModel({
    this.amount,
    this.isVerifiedPlan,
    this.description,
    this.duration,
    this.identifier,
    this.otherTransactionDetail,
    this.paymentStatus,
    this.paymentType,
    this.planId,
    this.planLimitation,
    this.plansVerifiedProviders,
    this.planType,
    this.title,
    this.txnId,
    this.type,
    this.userId,
  });

  factory PlanRequestModel.fromJson(Map<String, dynamic> json) {
    return PlanRequestModel(
      amount: json['amount'],
      isVerifiedPlan: json['is_verified_plan'],
      description: json['description'],
      duration: json['duration'],
      identifier: json['identifier'],
      otherTransactionDetail: json['other_transaction_detail'],
      paymentStatus: json['payment_status'],
      paymentType: json['payment_type'],
      planId: json['plan_id'],
      planLimitation: json['plan_limitation'] != null ? PlanLimitation.fromJson(json['plan_limitation']) : null,
      plansVerifiedProviders: json['plans_verified_providers'] != null
          ? new PlansVerifiedProviders.fromJson(json['plans_verified_providers'])
          : null,
      planType: json['plan_type'],
      title: json['title'],
      txnId: json['txn_id'],
      type: json['type'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['is_verified_plan'] = this.isVerifiedPlan;
    data['description'] = this.description;
    data['duration'] = this.duration;
    data['identifier'] = this.identifier;
    data['other_transaction_detail'] = this.otherTransactionDetail;
    data['payment_status'] = this.paymentStatus;
    data['payment_type'] = this.paymentType;
    data['plan_id'] = this.planId;
    data['plan_type'] = this.planType;
    data['title'] = this.title;
    data['txn_id'] = this.txnId;
    data['type'] = this.type;
    data['user_id'] = this.userId;
    if (this.planLimitation != null) {
      data['plan_limitation'] = this.planLimitation!.toJson();
    }
    if (this.plansVerifiedProviders != null) {
      data['plans_verified_providers'] = this.plansVerifiedProviders!.toJson();
    }
    return data;
  }
}
