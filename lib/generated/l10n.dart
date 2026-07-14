// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Landing Page`
  String get appTitle {
    return Intl.message(
      'Landing Page',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get greeting {
    return Intl.message(
      'Welcome',
      name: 'greeting',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get registerButton {
    return Intl.message(
      'Register',
      name: 'registerButton',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get loginButton {
    return Intl.message(
      'Login',
      name: 'loginButton',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot Password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `See Plans`
  String get seePlan {
    return Intl.message(
      'See Plans',
      name: 'seePlan',
      desc: '',
      args: [],
    );
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message(
      'Dashboard',
      name: 'dashboard',
      desc: '',
      args: [],
    );
  }

  /// `See Map`
  String get seeMap {
    return Intl.message(
      'See Map',
      name: 'seeMap',
      desc: '',
      args: [],
    );
  }

  /// `Help / Support`
  String get helpSupport {
    return Intl.message(
      'Help / Support',
      name: 'helpSupport',
      desc: '',
      args: [],
    );
  }

  /// `Print Sync`
  String get printSync {
    return Intl.message(
      'Print Sync',
      name: 'printSync',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `@All rights reserved Can Image Media Tech`
  String get copyRights {
    return Intl.message(
      '@All rights reserved Can Image Media Tech',
      name: 'copyRights',
      desc: '',
      args: [],
    );
  }

  /// `Version 2.0.0`
  String get version {
    return Intl.message(
      'Version 2.0.0',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Your \nPassword?`
  String get forgotPass {
    return Intl.message(
      'Forgot Your \nPassword?',
      name: 'forgotPass',
      desc: '',
      args: [],
    );
  }

  /// `Enter your registered phone number or User ID to reset your password.`
  String get forgotText {
    return Intl.message(
      'Enter your registered phone number or User ID to reset your password.',
      name: 'forgotText',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number / User ID`
  String get phoneNo {
    return Intl.message(
      'Phone Number / User ID',
      name: 'phoneNo',
      desc: '',
      args: [],
    );
  }

  /// `Enter Phone Number / User ID here`
  String get enterPhoneNo {
    return Intl.message(
      'Enter Phone Number / User ID here',
      name: 'enterPhoneNo',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get resetPass {
    return Intl.message(
      'Reset Password',
      name: 'resetPass',
      desc: '',
      args: [],
    );
  }

  /// `Remember your password?`
  String get rememberPass {
    return Intl.message(
      'Remember your password?',
      name: 'rememberPass',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid 10-digit phone number.`
  String get loginPhVal {
    return Intl.message(
      'Please enter a valid 10-digit phone number.',
      name: 'loginPhVal',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters.`
  String get loginPassVal {
    return Intl.message(
      'Password must be at least 6 characters.',
      name: 'loginPassVal',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get success {
    return Intl.message(
      'Success',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `Logged In successfully!`
  String get loggedIn {
    return Intl.message(
      'Logged In successfully!',
      name: 'loggedIn',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message(
      'Ok',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Login failed`
  String get loginFailed {
    return Intl.message(
      'Login failed',
      name: 'loginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get letsSignIn {
    return Intl.message(
      'Sign In',
      name: 'letsSignIn',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error`
  String get unKnownError {
    return Intl.message(
      'Unknown error',
      name: 'unKnownError',
      desc: '',
      args: [],
    );
  }

  /// `Welcome back! Please login to your Account.`
  String get welcomeBack {
    return Intl.message(
      'Welcome back! Please login to your Account.',
      name: 'welcomeBack',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Enter Password here`
  String get enterPass {
    return Intl.message(
      'Enter Password here',
      name: 'enterPass',
      desc: '',
      args: [],
    );
  }

  /// `Remember Me`
  String get rememberMe {
    return Intl.message(
      'Remember Me',
      name: 'rememberMe',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password?`
  String get forgotPassLogin {
    return Intl.message(
      'Forgot Password?',
      name: 'forgotPassLogin',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get signIn {
    return Intl.message(
      'Sign In',
      name: 'signIn',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get dontHaveAcc {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAcc',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get registerBut {
    return Intl.message(
      'Register',
      name: 'registerBut',
      desc: '',
      args: [],
    );
  }

  /// `Please fill the firstname.`
  String get firstNameVal {
    return Intl.message(
      'Please fill the firstname.',
      name: 'firstNameVal',
      desc: '',
      args: [],
    );
  }

  /// `Please fill the last name.`
  String get lastNameVal {
    return Intl.message(
      'Please fill the last name.',
      name: 'lastNameVal',
      desc: '',
      args: [],
    );
  }

  /// `Registration successful! User ID`
  String get registerSuccess {
    return Intl.message(
      'Registration successful! User ID',
      name: 'registerSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Role`
  String get role {
    return Intl.message(
      'Role',
      name: 'role',
      desc: '',
      args: [],
    );
  }

  /// `Registration failed`
  String get registrationFailed {
    return Intl.message(
      'Registration failed',
      name: 'registrationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Failure`
  String get failure {
    return Intl.message(
      'Failure',
      name: 'failure',
      desc: '',
      args: [],
    );
  }

  /// `An unexpected error occurred. Please try again.`
  String get unExpectedError {
    return Intl.message(
      'An unexpected error occurred. Please try again.',
      name: 'unExpectedError',
      desc: '',
      args: [],
    );
  }

  /// `Let's Register Account`
  String get registrationTitle {
    return Intl.message(
      'Let\'s Register Account',
      name: 'registrationTitle',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get firstName {
    return Intl.message(
      'First Name',
      name: 'firstName',
      desc: '',
      args: [],
    );
  }

  /// `Enter First Name here`
  String get firstNameTxt {
    return Intl.message(
      'Enter First Name here',
      name: 'firstNameTxt',
      desc: '',
      args: [],
    );
  }

  /// `Last Name`
  String get lastName {
    return Intl.message(
      'Last Name',
      name: 'lastName',
      desc: '',
      args: [],
    );
  }

  /// `Enter Last Name here`
  String get lastNameTxt {
    return Intl.message(
      'Enter Last Name here',
      name: 'lastNameTxt',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNoOnly {
    return Intl.message(
      'Phone Number',
      name: 'phoneNoOnly',
      desc: '',
      args: [],
    );
  }

  /// `Enter Phone Number here`
  String get phoneNoOnlyTxt {
    return Intl.message(
      'Enter Phone Number here',
      name: 'phoneNoOnlyTxt',
      desc: '',
      args: [],
    );
  }

  /// `Please select a role (Pastor or CanImage User).`
  String get selectRole {
    return Intl.message(
      'Please select a role (Pastor or CanImage User).',
      name: 'selectRole',
      desc: '',
      args: [],
    );
  }

  /// `Pastor`
  String get pastor {
    return Intl.message(
      'Pastor',
      name: 'pastor',
      desc: '',
      args: [],
    );
  }

  /// `CanImage User`
  String get supervisor {
    return Intl.message(
      'CanImage User',
      name: 'supervisor',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get registerBtn {
    return Intl.message(
      'Register',
      name: 'registerBtn',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get alreadyAcct {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyAcct',
      desc: '',
      args: [],
    );
  }

  /// `You have logged out successfully.`
  String get logoutTxt {
    return Intl.message(
      'You have logged out successfully.',
      name: 'logoutTxt',
      desc: '',
      args: [],
    );
  }

  /// `Plans reloaded successfully!`
  String get planSuccess {
    return Intl.message(
      'Plans reloaded successfully!',
      name: 'planSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Village Artworks reloaded successfully!`
  String get villageSuccess {
    return Intl.message(
      'Village Artworks reloaded successfully!',
      name: 'villageSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Failed to reload plans`
  String get failedPlan {
    return Intl.message(
      'Failed to reload plans',
      name: 'failedPlan',
      desc: '',
      args: [],
    );
  }

  /// `Plan`
  String get plan {
    return Intl.message(
      'Plan',
      name: 'plan',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Reload`
  String get reload {
    return Intl.message(
      'Reload',
      name: 'reload',
      desc: '',
      args: [],
    );
  }

  /// `Plan`
  String get planTab {
    return Intl.message(
      'Plan',
      name: 'planTab',
      desc: '',
      args: [],
    );
  }

  /// `Village\nCode`
  String get villageCode {
    return Intl.message(
      'Village\nCode',
      name: 'villageCode',
      desc: '',
      args: [],
    );
  }

  /// `Village\nName`
  String get villageName {
    return Intl.message(
      'Village\nName',
      name: 'villageName',
      desc: '',
      args: [],
    );
  }

  /// `CD Block`
  String get cdBlock {
    return Intl.message(
      'CD Block',
      name: 'cdBlock',
      desc: '',
      args: [],
    );
  }

  /// `Balance`
  String get balance {
    return Intl.message(
      'Balance',
      name: 'balance',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message(
      'Retry',
      name: 'retry',
      desc: '',
      args: [],
    );
  }

  /// `Recca Plans reloaded successfully!`
  String get reccaPlan {
    return Intl.message(
      'Recca Plans reloaded successfully!',
      name: 'reccaPlan',
      desc: '',
      args: [],
    );
  }

  /// `Failed to reload recca plans`
  String get failedRecca {
    return Intl.message(
      'Failed to reload recca plans',
      name: 'failedRecca',
      desc: '',
      args: [],
    );
  }

  /// `Recca Plans`
  String get reccaPlanTitle {
    return Intl.message(
      'Recca Plans',
      name: 'reccaPlanTitle',
      desc: '',
      args: [],
    );
  }

  /// `Lat`
  String get lat {
    return Intl.message(
      'Lat',
      name: 'lat',
      desc: '',
      args: [],
    );
  }

  /// `Lng`
  String get lng {
    return Intl.message(
      'Lng',
      name: 'lng',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `Geo Location`
  String get geoLoc {
    return Intl.message(
      'Geo Location',
      name: 'geoLoc',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Print No`
  String get printNo {
    return Intl.message(
      'Print No',
      name: 'printNo',
      desc: '',
      args: [],
    );
  }

  /// `Search markers...`
  String get searchMarker {
    return Intl.message(
      'Search markers...',
      name: 'searchMarker',
      desc: '',
      args: [],
    );
  }

  /// `Village Name`
  String get viilageNameTab {
    return Intl.message(
      'Village Name',
      name: 'viilageNameTab',
      desc: '',
      args: [],
    );
  }

  /// `Coordinates`
  String get coordinates {
    return Intl.message(
      'Coordinates',
      name: 'coordinates',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: '',
      args: [],
    );
  }

  /// `Size`
  String get size {
    return Intl.message(
      'Size',
      name: 'size',
      desc: '',
      args: [],
    );
  }

  /// `Distance`
  String get distance {
    return Intl.message(
      'Distance',
      name: 'distance',
      desc: '',
      args: [],
    );
  }

  /// `View Details`
  String get viewDetails {
    return Intl.message(
      'View Details',
      name: 'viewDetails',
      desc: '',
      args: [],
    );
  }

  /// `Village Name`
  String get villageNameMap {
    return Intl.message(
      'Village Name',
      name: 'villageNameMap',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continueBtn {
    return Intl.message(
      'Continue',
      name: 'continueBtn',
      desc: '',
      args: [],
    );
  }

  /// `Brand`
  String get brand {
    return Intl.message(
      'Brand',
      name: 'brand',
      desc: '',
      args: [],
    );
  }

  /// `Remarks`
  String get remarks {
    return Intl.message(
      'Remarks',
      name: 'remarks',
      desc: '',
      args: [],
    );
  }

  /// `Near View`
  String get nearView {
    return Intl.message(
      'Near View',
      name: 'nearView',
      desc: '',
      args: [],
    );
  }

  /// `Road View`
  String get roadView {
    return Intl.message(
      'Road View',
      name: 'roadView',
      desc: '',
      args: [],
    );
  }

  /// `Surrounding view`
  String get surroundingview {
    return Intl.message(
      'Surrounding view',
      name: 'surroundingview',
      desc: '',
      args: [],
    );
  }

  /// `Submit Details`
  String get submitDetails {
    return Intl.message(
      'Submit Details',
      name: 'submitDetails',
      desc: '',
      args: [],
    );
  }

  /// `Sync`
  String get sync {
    return Intl.message(
      'Sync',
      name: 'sync',
      desc: '',
      args: [],
    );
  }

  /// `Sync All`
  String get syncAll {
    return Intl.message(
      'Sync All',
      name: 'syncAll',
      desc: '',
      args: [],
    );
  }

  /// `View`
  String get view {
    return Intl.message(
      'View',
      name: 'view',
      desc: '',
      args: [],
    );
  }

  /// `Village`
  String get village {
    return Intl.message(
      'Village',
      name: 'village',
      desc: '',
      args: [],
    );
  }

  /// `Print ID.`
  String get printID {
    return Intl.message(
      'Print ID.',
      name: 'printID',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get images {
    return Intl.message(
      'Images',
      name: 'images',
      desc: '',
      args: [],
    );
  }

  /// `Action`
  String get action {
    return Intl.message(
      'Action',
      name: 'action',
      desc: '',
      args: [],
    );
  }

  /// `Successfully synced plan`
  String get syncPlan {
    return Intl.message(
      'Successfully synced plan',
      name: 'syncPlan',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sync plan`
  String get failedSyncPlan {
    return Intl.message(
      'Failed to sync plan',
      name: 'failedSyncPlan',
      desc: '',
      args: [],
    );
  }

  /// `Successfully synced all plans!`
  String get syncAllPlan {
    return Intl.message(
      'Successfully synced all plans!',
      name: 'syncAllPlan',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sync all plans!`
  String get failedSyncAllPlan {
    return Intl.message(
      'Failed to sync all plans!',
      name: 'failedSyncAllPlan',
      desc: '',
      args: [],
    );
  }

  /// `Images for Print Number`
  String get imagePrintNo {
    return Intl.message(
      'Images for Print Number',
      name: 'imagePrintNo',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Print Details`
  String get printDetails {
    return Intl.message(
      'Print Details',
      name: 'printDetails',
      desc: '',
      args: [],
    );
  }

  /// `Please select...`
  String get pleaseSelect {
    return Intl.message(
      'Please select...',
      name: 'pleaseSelect',
      desc: '',
      args: [],
    );
  }

  /// `Upload Images`
  String get uploadImages {
    return Intl.message(
      'Upload Images',
      name: 'uploadImages',
      desc: '',
      args: [],
    );
  }

  /// `Add Photo`
  String get addPhoto {
    return Intl.message(
      'Add Photo',
      name: 'addPhoto',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick image!`
  String get failedImage {
    return Intl.message(
      'Failed to pick image!',
      name: 'failedImage',
      desc: '',
      args: [],
    );
  }

  /// `Please select the remarks`
  String get selectRemarks {
    return Intl.message(
      'Please select the remarks',
      name: 'selectRemarks',
      desc: '',
      args: [],
    );
  }

  /// `Submitting plan details...`
  String get submitPlan {
    return Intl.message(
      'Submitting plan details...',
      name: 'submitPlan',
      desc: '',
      args: [],
    );
  }

  /// `Please upload all 7 images`
  String get imageVal {
    return Intl.message(
      'Please upload all 7 images',
      name: 'imageVal',
      desc: '',
      args: [],
    );
  }

  /// `Enter the Valid Mobile Number / User ID`
  String get loginNewVal {
    return Intl.message(
      'Enter the Valid Mobile Number / User ID',
      name: 'loginNewVal',
      desc: '',
      args: [],
    );
  }

  /// `Plan Details`
  String get planDetails {
    return Intl.message(
      'Plan Details',
      name: 'planDetails',
      desc: '',
      args: [],
    );
  }

  /// `Width`
  String get width {
    return Intl.message(
      'Width',
      name: 'width',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message(
      'Height',
      name: 'height',
      desc: '',
      args: [],
    );
  }

  /// `District Name`
  String get districtName {
    return Intl.message(
      'District Name',
      name: 'districtName',
      desc: '',
      args: [],
    );
  }

  /// `CD Block Name`
  String get cdBlockName {
    return Intl.message(
      'CD Block Name',
      name: 'cdBlockName',
      desc: '',
      args: [],
    );
  }

  /// `Total Prints`
  String get totalPrints {
    return Intl.message(
      'Total Prints',
      name: 'totalPrints',
      desc: '',
      args: [],
    );
  }

  /// `Balance Prints`
  String get balancePrints {
    return Intl.message(
      'Balance Prints',
      name: 'balancePrints',
      desc: '',
      args: [],
    );
  }

  /// `Bad Request: No data found. Please try again later.`
  String get badRequest {
    return Intl.message(
      'Bad Request: No data found. Please try again later.',
      name: 'badRequest',
      desc: '',
      args: [],
    );
  }

  /// `Unauthorized: Authentication failed. Please login again.`
  String get unauthorized {
    return Intl.message(
      'Unauthorized: Authentication failed. Please login again.',
      name: 'unauthorized',
      desc: '',
      args: [],
    );
  }

  /// `Forbidden: Access denied. Please contact admin.`
  String get forbidden {
    return Intl.message(
      'Forbidden: Access denied. Please contact admin.',
      name: 'forbidden',
      desc: '',
      args: [],
    );
  }

  /// `Not Found: No data found. Please try again later.`
  String get notFound {
    return Intl.message(
      'Not Found: No data found. Please try again later.',
      name: 'notFound',
      desc: '',
      args: [],
    );
  }

  /// `Internal Server Error: Please contact admin for assistance.`
  String get internalServerError {
    return Intl.message(
      'Internal Server Error: Please contact admin for assistance.',
      name: 'internalServerError',
      desc: '',
      args: [],
    );
  }

  /// `Bad Gateway: Server temporarily unavailable. Please try again later.`
  String get badGateway {
    return Intl.message(
      'Bad Gateway: Server temporarily unavailable. Please try again later.',
      name: 'badGateway',
      desc: '',
      args: [],
    );
  }

  /// `Service Unavailable: Please try again later.`
  String get serviceUnavailable {
    return Intl.message(
      'Service Unavailable: Please try again later.',
      name: 'serviceUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Server Error`
  String get serverError {
    return Intl.message(
      'Server Error',
      name: 'serverError',
      desc: '',
      args: [],
    );
  }

  /// `No data found. Please try again later.`
  String get noDataFound {
    return Intl.message(
      'No data found. Please try again later.',
      name: 'noDataFound',
      desc: '',
      args: [],
    );
  }

  /// `Network error: Please check your internet connection and try again.`
  String get networkerror {
    return Intl.message(
      'Network error: Please check your internet connection and try again.',
      name: 'networkerror',
      desc: '',
      args: [],
    );
  }

  /// `An unexpected error occurred. Please try again later.`
  String get unexpectedError {
    return Intl.message(
      'An unexpected error occurred. Please try again later.',
      name: 'unexpectedError',
      desc: '',
      args: [],
    );
  }

  /// `Error during fetching artwork details: Please try again later.`
  String get errorArtworkDetails {
    return Intl.message(
      'Error during fetching artwork details: Please try again later.',
      name: 'errorArtworkDetails',
      desc: '',
      args: [],
    );
  }

  /// `Enter the Valid Mobile Number / User ID`
  String get loginNewValidVal {
    return Intl.message(
      'Enter the Valid Mobile Number / User ID',
      name: 'loginNewValidVal',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `Resend`
  String get resend {
    return Intl.message(
      'Resend',
      name: 'resend',
      desc: '',
      args: [],
    );
  }

  /// `Logs`
  String get logs {
    return Intl.message(
      'Logs',
      name: 'logs',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `No plans found for`
  String get noPlanFound {
    return Intl.message(
      'No plans found for',
      name: 'noPlanFound',
      desc: '',
      args: [],
    );
  }

  /// `Try searching with different keywords`
  String get trySearching {
    return Intl.message(
      'Try searching with different keywords',
      name: 'trySearching',
      desc: '',
      args: [],
    );
  }

  /// `Showing`
  String get showing {
    return Intl.message(
      'Showing',
      name: 'showing',
      desc: '',
      args: [],
    );
  }

  /// `of`
  String get ofText {
    return Intl.message(
      'of',
      name: 'ofText',
      desc: '',
      args: [],
    );
  }

  /// `results`
  String get results {
    return Intl.message(
      'results',
      name: 'results',
      desc: '',
      args: [],
    );
  }

  /// `Please contact admin`
  String get pleaseContact {
    return Intl.message(
      'Please contact admin',
      name: 'pleaseContact',
      desc: '',
      args: [],
    );
  }

  /// `Contact Admin`
  String get contactAdmin {
    return Intl.message(
      'Contact Admin',
      name: 'contactAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Connection Problem`
  String get connectionProblem {
    return Intl.message(
      'Connection Problem',
      name: 'connectionProblem',
      desc: '',
      args: [],
    );
  }

  /// `Authentication Required`
  String get authenticationRequired {
    return Intl.message(
      'Authentication Required',
      name: 'authenticationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Server Issue`
  String get serverIssue {
    return Intl.message(
      'Server Issue',
      name: 'serverIssue',
      desc: '',
      args: [],
    );
  }

  /// `No Data Available`
  String get noDataAvaiable {
    return Intl.message(
      'No Data Available',
      name: 'noDataAvaiable',
      desc: '',
      args: [],
    );
  }

  /// `Something Went Wrong`
  String get somethingWentWrong {
    return Intl.message(
      'Something Went Wrong',
      name: 'somethingWentWrong',
      desc: '',
      args: [],
    );
  }

  /// `Contact Administrator`
  String get contactAdministrator {
    return Intl.message(
      'Contact Administrator',
      name: 'contactAdministrator',
      desc: '',
      args: [],
    );
  }

  /// `A server error has occurred. Please contact the system administrator with the following details`
  String get serverErrorOccured {
    return Intl.message(
      'A server error has occurred. Please contact the system administrator with the following details',
      name: 'serverErrorOccured',
      desc: '',
      args: [],
    );
  }

  /// `Error Type: Server Error (500)`
  String get errorType {
    return Intl.message(
      'Error Type: Server Error (500)',
      name: 'errorType',
      desc: '',
      args: [],
    );
  }

  /// `Time`
  String get time {
    return Intl.message(
      'Time',
      name: 'time',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch remarks. Please try again.`
  String get failedFetchRemarks {
    return Intl.message(
      'Failed to fetch remarks. Please try again.',
      name: 'failedFetchRemarks',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch dashboard`
  String get failedFetchDasboard {
    return Intl.message(
      'Failed to fetch dashboard',
      name: 'failedFetchDasboard',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch Dashboard. Please try again.`
  String get failedFetchDashboardTry {
    return Intl.message(
      'Failed to fetch Dashboard. Please try again.',
      name: 'failedFetchDashboardTry',
      desc: '',
      args: [],
    );
  }

  /// `No projects available. Please try again later.`
  String get noProjectAvaiable {
    return Intl.message(
      'No projects available. Please try again later.',
      name: 'noProjectAvaiable',
      desc: '',
      args: [],
    );
  }

  /// `Start Date`
  String get startDate {
    return Intl.message(
      'Start Date',
      name: 'startDate',
      desc: '',
      args: [],
    );
  }

  /// `End Date`
  String get endDate {
    return Intl.message(
      'End Date',
      name: 'endDate',
      desc: '',
      args: [],
    );
  }

  /// `Select date`
  String get selectDate {
    return Intl.message(
      'Select date',
      name: 'selectDate',
      desc: '',
      args: [],
    );
  }

  /// `Please select both start and end dates, and a project.`
  String get pleaseSelectBothDates {
    return Intl.message(
      'Please select both start and end dates, and a project.',
      name: 'pleaseSelectBothDates',
      desc: '',
      args: [],
    );
  }

  /// `Prints Captured`
  String get printsCaptured {
    return Intl.message(
      'Prints Captured',
      name: 'printsCaptured',
      desc: '',
      args: [],
    );
  }

  /// `Prints Uploaded`
  String get printsUploaded {
    return Intl.message(
      'Prints Uploaded',
      name: 'printsUploaded',
      desc: '',
      args: [],
    );
  }

  /// `Execute by Raw Vendor`
  String get executeVendor {
    return Intl.message(
      'Execute by Raw Vendor',
      name: 'executeVendor',
      desc: '',
      args: [],
    );
  }

  /// `Approved`
  String get approved {
    return Intl.message(
      'Approved',
      name: 'approved',
      desc: '',
      args: [],
    );
  }

  /// `Partial`
  String get partial {
    return Intl.message(
      'Partial',
      name: 'partial',
      desc: '',
      args: [],
    );
  }

  /// `Rejected`
  String get rejected {
    return Intl.message(
      'Rejected',
      name: 'rejected',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loadingDashboard {
    return Intl.message(
      'Loading',
      name: 'loadingDashboard',
      desc: '',
      args: [],
    );
  }

  /// `records`
  String get recordsDashboard {
    return Intl.message(
      'records',
      name: 'recordsDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch data. Please try again.`
  String get failedFetchData {
    return Intl.message(
      'Failed to fetch data. Please try again.',
      name: 'failedFetchData',
      desc: '',
      args: [],
    );
  }

  /// `Print\nName`
  String get printName {
    return Intl.message(
      'Print\nName',
      name: 'printName',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: '',
      args: [],
    );
  }

  /// `Unable to retrieve UID for your role. Please restart the app and try again.`
  String get unableUID {
    return Intl.message(
      'Unable to retrieve UID for your role. Please restart the app and try again.',
      name: 'unableUID',
      desc: '',
      args: [],
    );
  }

  /// `UID`
  String get uid {
    return Intl.message(
      'UID',
      name: 'uid',
      desc: '',
      args: [],
    );
  }

  /// `This account is registered as`
  String get accountRegistered {
    return Intl.message(
      'This account is registered as',
      name: 'accountRegistered',
      desc: '',
      args: [],
    );
  }

  /// `Please select the correct role and try again.`
  String get pleaseCorrectRole {
    return Intl.message(
      'Please select the correct role and try again.',
      name: 'pleaseCorrectRole',
      desc: '',
      args: [],
    );
  }

  /// `Role information not found. Please contact support.`
  String get roleInformation {
    return Intl.message(
      'Role information not found. Please contact support.',
      name: 'roleInformation',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number or Password is Incorrect`
  String get phoneNumberIncorrect {
    return Intl.message(
      'Phone Number or Password is Incorrect',
      name: 'phoneNumberIncorrect',
      desc: '',
      args: [],
    );
  }

  /// `Unable to connect to server. Please try again.`
  String get unableServer {
    return Intl.message(
      'Unable to connect to server. Please try again.',
      name: 'unableServer',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred during login. Please try again.`
  String get errorOccurredLogin {
    return Intl.message(
      'An error occurred during login. Please try again.',
      name: 'errorOccurredLogin',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred during registration. Please try again.`
  String get errorOccurredRegstration {
    return Intl.message(
      'An error occurred during registration. Please try again.',
      name: 'errorOccurredRegstration',
      desc: '',
      args: [],
    );
  }

  /// `Current Location`
  String get currentLocation {
    return Intl.message(
      'Current Location',
      name: 'currentLocation',
      desc: '',
      args: [],
    );
  }

  /// `Tap for address`
  String get tapAddress {
    return Intl.message(
      'Tap for address',
      name: 'tapAddress',
      desc: '',
      args: [],
    );
  }

  /// `Location permission denied`
  String get locationPermissionDenied {
    return Intl.message(
      'Location permission denied',
      name: 'locationPermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Location Services Disabled`
  String get locationServicesDisabled {
    return Intl.message(
      'Location Services Disabled',
      name: 'locationServicesDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Please enable location services for accurate positioning.`
  String get pleaseAccurate {
    return Intl.message(
      'Please enable location services for accurate positioning.',
      name: 'pleaseAccurate',
      desc: '',
      args: [],
    );
  }

  /// `Open Settings`
  String get openSettings {
    return Intl.message(
      'Open Settings',
      name: 'openSettings',
      desc: '',
      args: [],
    );
  }

  /// `Location Permission Required`
  String get locationRequired {
    return Intl.message(
      'Location Permission Required',
      name: 'locationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Please enable location permission in app settings.`
  String get pleaseAppSettings {
    return Intl.message(
      'Please enable location permission in app settings.',
      name: 'pleaseAppSettings',
      desc: '',
      args: [],
    );
  }

  /// `Location Detection Failed`
  String get locationDetectionFailed {
    return Intl.message(
      'Location Detection Failed',
      name: 'locationDetectionFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to get location. Try:`
  String get unableLocation {
    return Intl.message(
      'Unable to get location. Try:',
      name: 'unableLocation',
      desc: '',
      args: [],
    );
  }

  /// `Move closer to windows`
  String get moveWindows {
    return Intl.message(
      'Move closer to windows',
      name: 'moveWindows',
      desc: '',
      args: [],
    );
  }

  /// `Enable Wi-Fi`
  String get enableWiFi {
    return Intl.message(
      'Enable Wi-Fi',
      name: 'enableWiFi',
      desc: '',
      args: [],
    );
  }

  /// `Use manual selection`
  String get useManualSelection {
    return Intl.message(
      'Use manual selection',
      name: 'useManualSelection',
      desc: '',
      args: [],
    );
  }

  /// `Manual Selection`
  String get manualSelection {
    return Intl.message(
      'Manual Selection',
      name: 'manualSelection',
      desc: '',
      args: [],
    );
  }

  /// `Tap on map to set location`
  String get tapLocation {
    return Intl.message(
      'Tap on map to set location',
      name: 'tapLocation',
      desc: '',
      args: [],
    );
  }

  /// `Location set\nTap location button to resume GPS`
  String get locationResumeGPS {
    return Intl.message(
      'Location set\nTap location button to resume GPS',
      name: 'locationResumeGPS',
      desc: '',
      args: [],
    );
  }

  /// `Address unavailable (offline mode)`
  String get addressUnavailable {
    return Intl.message(
      'Address unavailable (offline mode)',
      name: 'addressUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `GPS tracking resumed\nAuto-refresh enabled`
  String get gpsTrackingResumed {
    return Intl.message(
      'GPS tracking resumed\nAuto-refresh enabled',
      name: 'gpsTrackingResumed',
      desc: '',
      args: [],
    );
  }

  /// `Accuracy`
  String get accuracy {
    return Intl.message(
      'Accuracy',
      name: 'accuracy',
      desc: '',
      args: [],
    );
  }

  /// `Low Accuracy Warning`
  String get lowAccuracy {
    return Intl.message(
      'Low Accuracy Warning',
      name: 'lowAccuracy',
      desc: '',
      args: [],
    );
  }

  /// `Location accuracy is low`
  String get locationAccuracy {
    return Intl.message(
      'Location accuracy is low',
      name: 'locationAccuracy',
      desc: '',
      args: [],
    );
  }

  /// `Continue anyway or improve location?`
  String get continueAnyway {
    return Intl.message(
      'Continue anyway or improve location?',
      name: 'continueAnyway',
      desc: '',
      args: [],
    );
  }

  /// `Improve`
  String get improve {
    return Intl.message(
      'Improve',
      name: 'improve',
      desc: '',
      args: [],
    );
  }

  /// `Please wait for location detection`
  String get pleaseDetection {
    return Intl.message(
      'Please wait for location detection',
      name: 'pleaseDetection',
      desc: '',
      args: [],
    );
  }

  /// `Pending Uploads`
  String get pendingUploads {
    return Intl.message(
      'Pending Uploads',
      name: 'pendingUploads',
      desc: '',
      args: [],
    );
  }

  /// `You have`
  String get youhave {
    return Intl.message(
      'You have',
      name: 'youhave',
      desc: '',
      args: [],
    );
  }

  /// `pending plan(s) that need to be synced.`
  String get pendingSynced {
    return Intl.message(
      'pending plan(s) that need to be synced.',
      name: 'pendingSynced',
      desc: '',
      args: [],
    );
  }

  /// `Please sync all pending plans before reloading.`
  String get pleaseSyncAllPending {
    return Intl.message(
      'Please sync all pending plans before reloading.',
      name: 'pleaseSyncAllPending',
      desc: '',
      args: [],
    );
  }

  /// `village(s)`
  String get villages {
    return Intl.message(
      'village(s)',
      name: 'villages',
      desc: '',
      args: [],
    );
  }

  /// `No plans Found`
  String get noPlansFoundPlan {
    return Intl.message(
      'No plans Found',
      name: 'noPlansFoundPlan',
      desc: '',
      args: [],
    );
  }

  /// `Searching for location`
  String get searchingForLocation {
    return Intl.message(
      'Searching for location',
      name: 'searchingForLocation',
      desc: '',
      args: [],
    );
  }

  /// `No plans with balance available for this location`
  String get noPlansWithBalance {
    return Intl.message(
      'No plans with balance available for this location',
      name: 'noPlansWithBalance',
      desc: '',
      args: [],
    );
  }

  /// `Located`
  String get located {
    return Intl.message(
      'Located',
      name: 'located',
      desc: '',
      args: [],
    );
  }

  /// `Location not found. Try manual selection.`
  String get locationNotFoundSelection {
    return Intl.message(
      'Location not found. Try manual selection.',
      name: 'locationNotFoundSelection',
      desc: '',
      args: [],
    );
  }

  /// `Unable to find location. Try manual selection.`
  String get unableToFindSelection {
    return Intl.message(
      'Unable to find location. Try manual selection.',
      name: 'unableToFindSelection',
      desc: '',
      args: [],
    );
  }

  /// `Project Name`
  String get projectName {
    return Intl.message(
      'Project Name',
      name: 'projectName',
      desc: '',
      args: [],
    );
  }

  /// `Search with Village Code`
  String get searchVillageCode {
    return Intl.message(
      'Search with Village Code',
      name: 'searchVillageCode',
      desc: '',
      args: [],
    );
  }

  /// `No villages with balance found`
  String get noBalanceFound {
    return Intl.message(
      'No villages with balance found',
      name: 'noBalanceFound',
      desc: '',
      args: [],
    );
  }

  /// `Try different search terms`
  String get tryDifferentSearch {
    return Intl.message(
      'Try different search terms',
      name: 'tryDifferentSearch',
      desc: '',
      args: [],
    );
  }

  /// `Getting your location...`
  String get getingLocation {
    return Intl.message(
      'Getting your location...',
      name: 'getingLocation',
      desc: '',
      args: [],
    );
  }

  /// `Unable to get current location. Please enable GPS`
  String get unablePleaseEnableGPS {
    return Intl.message(
      'Unable to get current location. Please enable GPS',
      name: 'unablePleaseEnableGPS',
      desc: '',
      args: [],
    );
  }

  /// `away from the selected location.\nPlease move closer (within 50m) to capture the first image.`
  String get awayFromSelected {
    return Intl.message(
      'away from the selected location.\nPlease move closer (within 50m) to capture the first image.',
      name: 'awayFromSelected',
      desc: '',
      args: [],
    );
  }

  /// `Location Too Far`
  String get locationTooFar {
    return Intl.message(
      'Location Too Far',
      name: 'locationTooFar',
      desc: '',
      args: [],
    );
  }

  /// `meters away from the selected location`
  String get metersAwaySelectedLocation {
    return Intl.message(
      'meters away from the selected location',
      name: 'metersAwaySelectedLocation',
      desc: '',
      args: [],
    );
  }

  /// `The first image must be captured within 50 meters of the selected location.`
  String get firstImageCaptured {
    return Intl.message(
      'The first image must be captured within 50 meters of the selected location.',
      name: 'firstImageCaptured',
      desc: '',
      args: [],
    );
  }

  /// `Options`
  String get options {
    return Intl.message(
      'Options',
      name: 'options',
      desc: '',
      args: [],
    );
  }

  /// `Move closer to the location`
  String get moveCloser {
    return Intl.message(
      'Move closer to the location',
      name: 'moveCloser',
      desc: '',
      args: [],
    );
  }

  /// `Refresh your location on map`
  String get refreshLocationMap {
    return Intl.message(
      'Refresh your location on map',
      name: 'refreshLocationMap',
      desc: '',
      args: [],
    );
  }

  /// `Stay Here`
  String get stayHere {
    return Intl.message(
      'Stay Here',
      name: 'stayHere',
      desc: '',
      args: [],
    );
  }

  /// `Refresh Location`
  String get refreshLocation {
    return Intl.message(
      'Refresh Location',
      name: 'refreshLocation',
      desc: '',
      args: [],
    );
  }

  /// `Image captured successfully!`
  String get imageCaptured {
    return Intl.message(
      'Image captured successfully!',
      name: 'imageCaptured',
      desc: '',
      args: [],
    );
  }

  /// `Image selected successfully!`
  String get imageSelected {
    return Intl.message(
      'Image selected successfully!',
      name: 'imageSelected',
      desc: '',
      args: [],
    );
  }

  /// `Camera permission is required`
  String get cameraPermission {
    return Intl.message(
      'Camera permission is required',
      name: 'cameraPermission',
      desc: '',
      args: [],
    );
  }

  /// `Unable to access external storage directory`
  String get unableExternalstorage {
    return Intl.message(
      'Unable to access external storage directory',
      name: 'unableExternalstorage',
      desc: '',
      args: [],
    );
  }

  /// `Opening Camera...`
  String get openingCamera {
    return Intl.message(
      'Opening Camera...',
      name: 'openingCamera',
      desc: '',
      args: [],
    );
  }

  /// `Please enter both parts of the print number`
  String get pleaseEnterPrintNumber {
    return Intl.message(
      'Please enter both parts of the print number',
      name: 'pleaseEnterPrintNumber',
      desc: '',
      args: [],
    );
  }

  /// `Unable to get current location for submission. Please enable GPS.`
  String get unableCurrentLocationSubmission {
    return Intl.message(
      'Unable to get current location for submission. Please enable GPS.',
      name: 'unableCurrentLocationSubmission',
      desc: '',
      args: [],
    );
  }

  /// `Cannot Submit`
  String get cannotSubmit {
    return Intl.message(
      'Cannot Submit',
      name: 'cannotSubmit',
      desc: '',
      args: [],
    );
  }

  /// `meters away from where you captured the first image.`
  String get metersAwayFirstImage {
    return Intl.message(
      'meters away from where you captured the first image.',
      name: 'metersAwayFirstImage',
      desc: '',
      args: [],
    );
  }

  /// `Submission Requirements:`
  String get submissionRequirements {
    return Intl.message(
      'Submission Requirements:',
      name: 'submissionRequirements',
      desc: '',
      args: [],
    );
  }

  /// `You must be within 100 meters of the image capture location to submit.`
  String get youMetersImageCapturesubmit {
    return Intl.message(
      'You must be within 100 meters of the image capture location to submit.',
      name: 'youMetersImageCapturesubmit',
      desc: '',
      args: [],
    );
  }

  /// `Please return to the location where you captured the images.`
  String get pleaseReturnLocationImages {
    return Intl.message(
      'Please return to the location where you captured the images.',
      name: 'pleaseReturnLocationImages',
      desc: '',
      args: [],
    );
  }

  /// `Understood`
  String get understood {
    return Intl.message(
      'Understood',
      name: 'understood',
      desc: '',
      args: [],
    );
  }

  /// `Please go back to the image capture location (within 100m) to submit the plan.`
  String get pleaseBackImageLocationPlan {
    return Intl.message(
      'Please go back to the image capture location (within 100m) to submit the plan.',
      name: 'pleaseBackImageLocationPlan',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while submitting. Please try again`
  String get errorOccurredSubmitting {
    return Intl.message(
      'An error occurred while submitting. Please try again',
      name: 'errorOccurredSubmitting',
      desc: '',
      args: [],
    );
  }

  /// `Auto-Rotate enable`
  String get autoRotateEnable {
    return Intl.message(
      'Auto-Rotate enable',
      name: 'autoRotateEnable',
      desc: '',
      args: [],
    );
  }

  /// `Auto-rotate is currently disabled on your device. For the best camera experience, please enable auto-rotate in your device settings.`
  String get autoRotateDevice {
    return Intl.message(
      'Auto-rotate is currently disabled on your device. For the best camera experience, please enable auto-rotate in your device settings.',
      name: 'autoRotateDevice',
      desc: '',
      args: [],
    );
  }

  /// `How to enable auto-rotate:`
  String get enableAutoRotate {
    return Intl.message(
      'How to enable auto-rotate:',
      name: 'enableAutoRotate',
      desc: '',
      args: [],
    );
  }

  /// `Swipe down from the top of your screen`
  String get swipeDownScreen {
    return Intl.message(
      'Swipe down from the top of your screen',
      name: 'swipeDownScreen',
      desc: '',
      args: [],
    );
  }

  /// `Look for the Auto-rotate or rotation lock icon or lock orientation`
  String get lookAutoRotateOrientation {
    return Intl.message(
      'Look for the Auto-rotate or rotation lock icon or lock orientation',
      name: 'lookAutoRotateOrientation',
      desc: '',
      args: [],
    );
  }

  /// `Tap to enable auto-rotate`
  String get tapEnableAutoRotate {
    return Intl.message(
      'Tap to enable auto-rotate',
      name: 'tapEnableAutoRotate',
      desc: '',
      args: [],
    );
  }

  /// `Error taking picture. Please try again`
  String get errorTakingPicture {
    return Intl.message(
      'Error taking picture. Please try again',
      name: 'errorTakingPicture',
      desc: '',
      args: [],
    );
  }

  /// `Initializing Camera...`
  String get initializingCamera {
    return Intl.message(
      'Initializing Camera...',
      name: 'initializingCamera',
      desc: '',
      args: [],
    );
  }

  /// `Setting up Camera...`
  String get settingUpCamera {
    return Intl.message(
      'Setting up Camera...',
      name: 'settingUpCamera',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch dashboard:`
  String get failedFetchDashboard {
    return Intl.message(
      'Failed to fetch dashboard:',
      name: 'failedFetchDashboard',
      desc: '',
      args: [],
    );
  }

  /// `No dashboard data available.`
  String get noDashboardDataAvailable {
    return Intl.message(
      'No dashboard data available.',
      name: 'noDashboardDataAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Failed to fetch Dashboard. Please try again.`
  String get failedFetchDashboardTryAgain {
    return Intl.message(
      'Failed to fetch Dashboard. Please try again.',
      name: 'failedFetchDashboardTryAgain',
      desc: '',
      args: [],
    );
  }

  /// `No projects available. Please try again later.`
  String get noProjectsAvailable {
    return Intl.message(
      'No projects available. Please try again later.',
      name: 'noProjectsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Please select both start and end dates, and a project.`
  String get pleaseStartEndDates {
    return Intl.message(
      'Please select both start and end dates, and a project.',
      name: 'pleaseStartEndDates',
      desc: '',
      args: [],
    );
  }

  /// `Raw / Hold`
  String get rawHold {
    return Intl.message(
      'Raw / Hold',
      name: 'rawHold',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get noDashboard {
    return Intl.message(
      'No',
      name: 'noDashboard',
      desc: '',
      args: [],
    );
  }

  /// `records found`
  String get recordsFound {
    return Intl.message(
      'records found',
      name: 'recordsFound',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get total {
    return Intl.message(
      'Total',
      name: 'total',
      desc: '',
      args: [],
    );
  }

  /// `Select Language`
  String get selectLanguage {
    return Intl.message(
      'Select Language',
      name: 'selectLanguage',
      desc: '',
      args: [],
    );
  }

  /// `App Version:`
  String get appVersion {
    return Intl.message(
      'App Version:',
      name: 'appVersion',
      desc: '',
      args: [],
    );
  }

  /// `User Id:`
  String get userId {
    return Intl.message(
      'User Id:',
      name: 'userId',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to logout?`
  String get wantToLogout {
    return Intl.message(
      'Do you want to logout?',
      name: 'wantToLogout',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yesDashboard {
    return Intl.message(
      'Yes',
      name: 'yesDashboard',
      desc: '',
      args: [],
    );
  }

  /// `No log files found in the specified folders`
  String get noLogFilesFoundFolders {
    return Intl.message(
      'No log files found in the specified folders',
      name: 'noLogFilesFoundFolders',
      desc: '',
      args: [],
    );
  }

  /// `Application Logs`
  String get applicationLogs {
    return Intl.message(
      'Application Logs',
      name: 'applicationLogs',
      desc: '',
      args: [],
    );
  }

  /// `Logs exported on`
  String get logsExportedOn {
    return Intl.message(
      'Logs exported on',
      name: 'logsExportedOn',
      desc: '',
      args: [],
    );
  }

  /// `Logs shared successfully`
  String get logsSharedSuccessfully {
    return Intl.message(
      'Logs shared successfully',
      name: 'logsSharedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Failed to create logs zip file`
  String get failedLogsZipFile {
    return Intl.message(
      'Failed to create logs zip file',
      name: 'failedLogsZipFile',
      desc: '',
      args: [],
    );
  }

  /// `Error sharing logs:`
  String get errorSharingLogs {
    return Intl.message(
      'Error sharing logs:',
      name: 'errorSharingLogs',
      desc: '',
      args: [],
    );
  }

  /// `Share Logs`
  String get shareLogs {
    return Intl.message(
      'Share Logs',
      name: 'shareLogs',
      desc: '',
      args: [],
    );
  }

  /// `Tap the share icon to export and share all logs as a zip file.`
  String get tapExportShareZipFile {
    return Intl.message(
      'Tap the share icon to export and share all logs as a zip file.',
      name: 'tapExportShareZipFile',
      desc: '',
      args: [],
    );
  }

  /// `No log files found`
  String get noLogFilesFound {
    return Intl.message(
      'No log files found',
      name: 'noLogFilesFound',
      desc: '',
      args: [],
    );
  }

  /// `Pending Sync Count:`
  String get pendingSyncCount {
    return Intl.message(
      'Pending Sync Count:',
      name: 'pendingSyncCount',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load remarks. Please try again.`
  String get failedLoadRemarks {
    return Intl.message(
      'Failed to load remarks. Please try again.',
      name: 'failedLoadRemarks',
      desc: '',
      args: [],
    );
  }

  /// `Please upload all 2 images`
  String get pleaseUploadAllImages {
    return Intl.message(
      'Please upload all 2 images',
      name: 'pleaseUploadAllImages',
      desc: '',
      args: [],
    );
  }

  /// `No matching marker found`
  String get noMatchingMarkerFound {
    return Intl.message(
      'No matching marker found',
      name: 'noMatchingMarkerFound',
      desc: '',
      args: [],
    );
  }

  /// `plan Id`
  String get planId {
    return Intl.message(
      'plan Id',
      name: 'planId',
      desc: '',
      args: [],
    );
  }

  /// `Location Error`
  String get locationError {
    return Intl.message(
      'Location Error',
      name: 'locationError',
      desc: '',
      args: [],
    );
  }

  /// `Marker location is not available. Please try again.`
  String get markerLocationNotAvailable {
    return Intl.message(
      'Marker location is not available. Please try again.',
      name: 'markerLocationNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Unable to get your current location. Please enable location services and try again.`
  String get unableYourCurrentLocation {
    return Intl.message(
      'Unable to get your current location. Please enable location services and try again.',
      name: 'unableYourCurrentLocation',
      desc: '',
      args: [],
    );
  }

  /// `Distance Error`
  String get distanceError {
    return Intl.message(
      'Distance Error',
      name: 'distanceError',
      desc: '',
      args: [],
    );
  }

  /// `meters away from the marker location. You must be within 50 meters to continue.`
  String get metersAwayMarkerLocationContinue {
    return Intl.message(
      'meters away from the marker location. You must be within 50 meters to continue.',
      name: 'metersAwayMarkerLocationContinue',
      desc: '',
      args: [],
    );
  }

  /// `Validation Error`
  String get validationError {
    return Intl.message(
      'Validation Error',
      name: 'validationError',
      desc: '',
      args: [],
    );
  }

  /// `Unable to validate your location. Please try again.`
  String get unableValidateLocation {
    return Intl.message(
      'Unable to validate your location. Please try again.',
      name: 'unableValidateLocation',
      desc: '',
      args: [],
    );
  }

  /// `Remarks data not found. Please reload the plan to fetch remarks.`
  String get remarksDataNotFound {
    return Intl.message(
      'Remarks data not found. Please reload the plan to fetch remarks.',
      name: 'remarksDataNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Remarks Not Available`
  String get remarksNotAvailable {
    return Intl.message(
      'Remarks Not Available',
      name: 'remarksNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Remarks data is required to proceed. Please reload the plan to fetch the latest remarks.`
  String get remarksDataRequiredProceed {
    return Intl.message(
      'Remarks data is required to proceed. Please reload the plan to fetch the latest remarks.',
      name: 'remarksDataRequiredProceed',
      desc: '',
      args: [],
    );
  }

  /// `This will refresh all plans and fetch remarks data.`
  String get willRefreshAllPlans {
    return Intl.message(
      'This will refresh all plans and fetch remarks data.',
      name: 'willRefreshAllPlans',
      desc: '',
      args: [],
    );
  }

  /// `Reload Plans`
  String get reloadPlans {
    return Intl.message(
      'Reload Plans',
      name: 'reloadPlans',
      desc: '',
      args: [],
    );
  }

  /// `Village Code`
  String get villageCodePost {
    return Intl.message(
      'Village Code',
      name: 'villageCodePost',
      desc: '',
      args: [],
    );
  }

  /// `Tehsil`
  String get tehsil {
    return Intl.message(
      'Tehsil',
      name: 'tehsil',
      desc: '',
      args: [],
    );
  }

  /// `Please check the village code`
  String get pleaseCheckVillageCode {
    return Intl.message(
      'Please check the village code',
      name: 'pleaseCheckVillageCode',
      desc: '',
      args: [],
    );
  }

  /// `Successfully synced`
  String get successfullySynced {
    return Intl.message(
      'Successfully synced',
      name: 'successfullySynced',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sync - Unknown error`
  String get failedToSync {
    return Intl.message(
      'Failed to sync - Unknown error',
      name: 'failedToSync',
      desc: '',
      args: [],
    );
  }

  /// `No details provided`
  String get noDetailsProvided {
    return Intl.message(
      'No details provided',
      name: 'noDetailsProvided',
      desc: '',
      args: [],
    );
  }

  /// `Unexpected response format`
  String get unexpectedResponseFormat {
    return Intl.message(
      'Unexpected response format',
      name: 'unexpectedResponseFormat',
      desc: '',
      args: [],
    );
  }

  /// `Already uploaded to server (duplicate detected)`
  String get alreadyUploadedServer {
    return Intl.message(
      'Already uploaded to server (duplicate detected)',
      name: 'alreadyUploadedServer',
      desc: '',
      args: [],
    );
  }

  /// `already on server. Removed from the sync.`
  String get alreadyOnServer {
    return Intl.message(
      'already on server. Removed from the sync.',
      name: 'alreadyOnServer',
      desc: '',
      args: [],
    );
  }

  /// `Print`
  String get print {
    return Intl.message(
      'Print',
      name: 'print',
      desc: '',
      args: [],
    );
  }

  /// `All plans synced successfully`
  String get allPlansSyncedSuccessfully {
    return Intl.message(
      'All plans synced successfully',
      name: 'allPlansSyncedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sync all plans - Unknown error`
  String get failedSyncallPlans {
    return Intl.message(
      'Failed to sync all plans - Unknown error',
      name: 'failedSyncallPlans',
      desc: '',
      args: [],
    );
  }

  /// `No details`
  String get noDetails {
    return Intl.message(
      'No details',
      name: 'noDetails',
      desc: '',
      args: [],
    );
  }

  /// `print(s) already on server. Removed from the sync`
  String get printsAlreadyOnServer {
    return Intl.message(
      'print(s) already on server. Removed from the sync',
      name: 'printsAlreadyOnServer',
      desc: '',
      args: [],
    );
  }

  /// `duplicate(s) removed`
  String get duplicatesRemoved {
    return Intl.message(
      'duplicate(s) removed',
      name: 'duplicatesRemoved',
      desc: '',
      args: [],
    );
  }

  /// `error(s) occurred`
  String get errorsOccurred {
    return Intl.message(
      'error(s) occurred',
      name: 'errorsOccurred',
      desc: '',
      args: [],
    );
  }

  /// `Uploading...`
  String get uploading {
    return Intl.message(
      'Uploading...',
      name: 'uploading',
      desc: '',
      args: [],
    );
  }

  /// `Successfully resent data`
  String get successfullyResentData {
    return Intl.message(
      'Successfully resent data',
      name: 'successfullyResentData',
      desc: '',
      args: [],
    );
  }

  /// `Resend failed - Server returned false`
  String get resendFailed {
    return Intl.message(
      'Resend failed - Server returned false',
      name: 'resendFailed',
      desc: '',
      args: [],
    );
  }

  /// `Successfully resent plan`
  String get successfullyResentPlan {
    return Intl.message(
      'Successfully resent plan',
      name: 'successfullyResentPlan',
      desc: '',
      args: [],
    );
  }

  /// `Resend failed for plan`
  String get resendFailedPlan {
    return Intl.message(
      'Resend failed for plan',
      name: 'resendFailedPlan',
      desc: '',
      args: [],
    );
  }

  /// `Error during resend`
  String get errorDuringResend {
    return Intl.message(
      'Error during resend',
      name: 'errorDuringResend',
      desc: '',
      args: [],
    );
  }

  /// `Response Details - Plan`
  String get responseDetails {
    return Intl.message(
      'Response Details - Plan',
      name: 'responseDetails',
      desc: '',
      args: [],
    );
  }

  /// `Last Response Time`
  String get lastResponseTime {
    return Intl.message(
      'Last Response Time',
      name: 'lastResponseTime',
      desc: '',
      args: [],
    );
  }

  /// `Status Code`
  String get statusCode {
    return Intl.message(
      'Status Code',
      name: 'statusCode',
      desc: '',
      args: [],
    );
  }

  /// `Total Retry Count`
  String get totalRetryCount {
    return Intl.message(
      'Total Retry Count',
      name: 'totalRetryCount',
      desc: '',
      args: [],
    );
  }

  /// `You have`
  String get latestMessage {
    return Intl.message(
      'You have',
      name: 'latestMessage',
      desc: '',
      args: [],
    );
  }

  /// `You have`
  String get viewAttemptsHistory {
    return Intl.message(
      'You have',
      name: 'viewAttemptsHistory',
      desc: '',
      args: [],
    );
  }

  /// `Complete History - Plan`
  String get completeHistory {
    return Intl.message(
      'Complete History - Plan',
      name: 'completeHistory',
      desc: '',
      args: [],
    );
  }

  /// `Total Attempts`
  String get totalAttempts {
    return Intl.message(
      'Total Attempts',
      name: 'totalAttempts',
      desc: '',
      args: [],
    );
  }

  /// `Attempt`
  String get attempt {
    return Intl.message(
      'Attempt',
      name: 'attempt',
      desc: '',
      args: [],
    );
  }

  /// `Latest`
  String get latest {
    return Intl.message(
      'Latest',
      name: 'latest',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get code {
    return Intl.message(
      'Code',
      name: 'code',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get message {
    return Intl.message(
      'Message',
      name: 'message',
      desc: '',
      args: [],
    );
  }

  /// `Creating ZIP file`
  String get creatingZIPFile {
    return Intl.message(
      'Creating ZIP file',
      name: 'creatingZIPFile',
      desc: '',
      args: [],
    );
  }

  /// `Failed to create ZIP file`
  String get failedCreateZIPFile {
    return Intl.message(
      'Failed to create ZIP file',
      name: 'failedCreateZIPFile',
      desc: '',
      args: [],
    );
  }

  /// `Search by Village, Plan, Print No, Status...`
  String get searchPrintNoStatus {
    return Intl.message(
      'Search by Village, Plan, Print No, Status...',
      name: 'searchPrintNoStatus',
      desc: '',
      args: [],
    );
  }

  /// `Print\nNo`
  String get printNoResend {
    return Intl.message(
      'Print\nNo',
      name: 'printNoResend',
      desc: '',
      args: [],
    );
  }

  /// `ZIP`
  String get zip {
    return Intl.message(
      'ZIP',
      name: 'zip',
      desc: '',
      args: [],
    );
  }

  /// `Sending...`
  String get sending {
    return Intl.message(
      'Sending...',
      name: 'sending',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get failed {
    return Intl.message(
      'Failed',
      name: 'failed',
      desc: '',
      args: [],
    );
  }

  /// `Security Warning`
  String get securityWarning {
    return Intl.message(
      'Security Warning',
      name: 'securityWarning',
      desc: '',
      args: [],
    );
  }

  /// `The following security issues were detected:`
  String get securityIssuesDetected {
    return Intl.message(
      'The following security issues were detected:',
      name: 'securityIssuesDetected',
      desc: '',
      args: [],
    );
  }

  /// `How to fix:`
  String get howToFix {
    return Intl.message(
      'How to fix:',
      name: 'howToFix',
      desc: '',
      args: [],
    );
  }

  /// `Tap Open Settings below`
  String get tapOpenSettings {
    return Intl.message(
      'Tap Open Settings below',
      name: 'tapOpenSettings',
      desc: '',
      args: [],
    );
  }

  /// `Search for Developer Options`
  String get searchDeveloperOptions {
    return Intl.message(
      'Search for Developer Options',
      name: 'searchDeveloperOptions',
      desc: '',
      args: [],
    );
  }

  /// `Turn OFF Developer Options`
  String get turnOFFDeveloperOptions {
    return Intl.message(
      'Turn OFF Developer Options',
      name: 'turnOFFDeveloperOptions',
      desc: '',
      args: [],
    );
  }

  /// `Turn OFF Mock Location`
  String get turnOFFMockLocation {
    return Intl.message(
      'Turn OFF Mock Location',
      name: 'turnOFFMockLocation',
      desc: '',
      args: [],
    );
  }

  /// `Return to this app`
  String get returnApp {
    return Intl.message(
      'Return to this app',
      name: 'returnApp',
      desc: '',
      args: [],
    );
  }

  /// `Turn ON Location Services`
  String get turnONLocationServices {
    return Intl.message(
      'Turn ON Location Services',
      name: 'turnONLocationServices',
      desc: '',
      args: [],
    );
  }

  /// `The app will automatically recheck when you return.`
  String get appAutomaticallyRecheckReturn {
    return Intl.message(
      'The app will automatically recheck when you return.',
      name: 'appAutomaticallyRecheckReturn',
      desc: '',
      args: [],
    );
  }

  /// `Exit App`
  String get exitApp {
    return Intl.message(
      'Exit App',
      name: 'exitApp',
      desc: '',
      args: [],
    );
  }

  /// `Fix the issues and return to app`
  String get fixIssuesReturnApp {
    return Intl.message(
      'Fix the issues and return to app',
      name: 'fixIssuesReturnApp',
      desc: '',
      args: [],
    );
  }

  String get withinAllowedRange {
    return Intl.message(
      'You are within allowed range',
      name: 'withinAllowedRange',
      desc: '',
      args: [],
    );
  }



  /// `Rework`
  String get rework {
    return Intl.message(
      'Rework',
      name: 'rework',
      desc: '',
      args: [],
    );
  }


  String get tapToViewLocationDetails {
    return Intl.message(
      'Tap to view location details',
      name: 'tapToViewLocationDetails',
      desc: '',
      args: [],
    );
  }

  String get pointerCoordinates {
    return Intl.message(
      'Pointer Coordinates',
      name: 'pointerCoordinates',
      desc: '',
      args: [],
    );
  }

  String get yourCoordinates {
    return Intl.message(
      'Your Coordinates',
      name: 'yourCoordinates',
      desc: '',
      args: [],
    );
  }

  String get latitude {
    return Intl.message(
      'Latitude',
      name: 'latitude',
      desc: '',
      args: [],
    );
  }

  String get longitude {
    return Intl.message(
      'Longitude',
      name: 'longitude',
      desc: '',
      args: [],
    );
  }


  String get moveWithin100mToUnlockNext {
    return Intl.message(
      'Move within 100m to unlock Next',
      name: 'moveWithin100mToUnlockNext',
      desc: '',
      args: [],
    );
  }

  /// `Can ID`
  String get canId {
    return Intl.message(
      'Can ID',
      name: 'canId',
      desc: '',
      args: [],
    );
  }

  /// `360 View`
  String get view360 {
    return Intl.message(
      '360 View',
      name: 'view360',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'bn'),
      Locale.fromSubtags(languageCode: 'gu'),
      Locale.fromSubtags(languageCode: 'hi'),
      Locale.fromSubtags(languageCode: 'mr'),
      Locale.fromSubtags(languageCode: 'ta'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
