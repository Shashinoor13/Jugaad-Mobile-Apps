import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

const APP_NAME = 'Jugaad Provider';
const DEFAULT_LANGUAGE = 'en';

const primaryColor = Color(0xFF2C5F2D);

const DOMAIN_URL =
    'https://admin.jugaad.com.np'; // Don't add slash at the end of the url

const BASE_URL = "$DOMAIN_URL/api/";

/// You can specify in Admin Panel, These will be used if you don't specify in Admin Panel
const IOS_LINK_FOR_PARTNER =
    "https://apps.apple.com/in/app/ehomesolutions-provider/id1596025324";

const TERMS_CONDITION_URL = 'https://jugaad.com.np/terms-of-use/';
const PRIVACY_POLICY_URL = 'https://jugaad.com.np/privacy-policy.html';
const HELP_AND_SUPPORT_URL = 'https://jugaad.com.np/privacy-policy/';
const REFUND_POLICY_URL =
    'https://jugaad.com.np/licensing-terms-more/#refund-policy';
const INQUIRY_SUPPORT_EMAIL = 'jugaadnp@gmail.com';
//Airtel Money Payments
///It Supports ["UGX", "NGN", "TZS", "KES", "RWF", "ZMW", "CFA", "XOF", "XAF", "CDF", "USD", "XAF", "SCR", "MGA", "MWK"]
const AIRTEL_CURRENCY_CODE = "MWK";
const AIRTEL_COUNTRY_CODE = "MW";
const AIRTEL_TEST_BASE_URL = 'https://openapiuat.airtel.africa/'; //Test Url
const AIRTEL_LIVE_BASE_URL = 'https://openapi.airtel.africa/'; // Live Url

/// PAYSTACK PAYMENT DETAIL
const PAYSTACK_CURRENCY_CODE = 'NGN';

/// SADAD PAYMENT DETAIL
const SADAD_API_URL = 'https://api-s.sadad.qa';
const SADAD_PAY_URL = "https://d.sadad.qa";

/// RAZORPAY PAYMENT DETAIL
const RAZORPAY_CURRENCY_CODE = 'INR';

/// PAYPAL PAYMENT DETAIL
const PAYPAL_CURRENCY_CODE = 'USD';

/// STRIPE PAYMENT DETAIL
const STRIPE_MERCHANT_COUNTRY_CODE = 'IN';
const STRIPE_CURRENCY_CODE = 'INR';

Country defaultCountry() {
  return Country(
    phoneCode: '977',
    countryCode: 'NP',
    e164Sc: 977,
    geographic: true,
    level: 977,
    name: 'Nepal',
    example: '9774567890',
    displayName: 'Nepal (NP) [+977]',
    displayNameNoCountryCode: 'Nepal (NP)',
    e164Key: '977-NP-0',
    fullExampleWithPlusSign: '+9771234567890',
  );
}

//Chat Module File Upload Configs
const chatFilesAllowedExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
  'pdf', 'txt', // Documents
  'mkv', 'mp4', // Video
  'mp3', // Audio
];
const max_acceptable_file_size = 5; //Size in Mb
