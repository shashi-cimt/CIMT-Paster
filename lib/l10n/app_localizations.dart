import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Landing Page'**
  String get appTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get greeting;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @seePlan.
  ///
  /// In en, this message translates to:
  /// **'See Plans'**
  String get seePlan;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @seeMap.
  ///
  /// In en, this message translates to:
  /// **'See Map'**
  String get seeMap;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help / Support'**
  String get helpSupport;

  /// No description provided for @printSync.
  ///
  /// In en, this message translates to:
  /// **'Print Sync'**
  String get printSync;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @copyRights.
  ///
  /// In en, this message translates to:
  /// **'@All rights reserved Can Image Media Tech'**
  String get copyRights;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 2.0.0'**
  String get version;

  /// No description provided for @forgotPass.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your \nPassword?'**
  String get forgotPass;

  /// No description provided for @forgotText.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number or User ID to reset your password.'**
  String get forgotText;

  /// No description provided for @phoneNo.
  ///
  /// In en, this message translates to:
  /// **'Phone Number / User ID'**
  String get phoneNo;

  /// No description provided for @enterPhoneNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number / User ID here'**
  String get enterPhoneNo;

  /// No description provided for @resetPass.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPass;

  /// No description provided for @rememberPass.
  ///
  /// In en, this message translates to:
  /// **'Remember your password?'**
  String get rememberPass;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginPhVal.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number.'**
  String get loginPhVal;

  /// No description provided for @loginPassVal.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginPassVal;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged In successfully!'**
  String get loggedIn;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @letsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get letsSignIn;

  /// No description provided for @unKnownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unKnownError;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please login to your Account.'**
  String get welcomeBack;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPass.
  ///
  /// In en, this message translates to:
  /// **'Enter Password here'**
  String get enterPass;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassLogin.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassLogin;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dontHaveAcc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAcc;

  /// No description provided for @registerBut.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerBut;

  /// No description provided for @firstNameVal.
  ///
  /// In en, this message translates to:
  /// **'Please fill the firstname.'**
  String get firstNameVal;

  /// No description provided for @lastNameVal.
  ///
  /// In en, this message translates to:
  /// **'Please fill the last name.'**
  String get lastNameVal;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! User ID'**
  String get registerSuccess;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @unExpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unExpectedError;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Register Account'**
  String get registrationTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @firstNameTxt.
  ///
  /// In en, this message translates to:
  /// **'Enter First Name here'**
  String get firstNameTxt;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @lastNameTxt.
  ///
  /// In en, this message translates to:
  /// **'Enter Last Name here'**
  String get lastNameTxt;

  /// No description provided for @phoneNoOnly.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNoOnly;

  /// No description provided for @phoneNoOnlyTxt.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number here'**
  String get phoneNoOnlyTxt;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select a role (Pastor or CanImage User).'**
  String get selectRole;

  /// No description provided for @pastor.
  ///
  /// In en, this message translates to:
  /// **'Pastor'**
  String get pastor;

  /// No description provided for @supervisor.
  ///
  /// In en, this message translates to:
  /// **'CanImage User'**
  String get supervisor;

  /// No description provided for @registerBtn.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerBtn;

  /// No description provided for @alreadyAcct.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyAcct;

  /// No description provided for @logoutTxt.
  ///
  /// In en, this message translates to:
  /// **'You have logged out successfully.'**
  String get logoutTxt;

  /// No description provided for @planSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plans reloaded successfully!'**
  String get planSuccess;

  /// No description provided for @villageSuccess.
  ///
  /// In en, this message translates to:
  /// **'Village Artworks reloaded successfully!'**
  String get villageSuccess;

  /// No description provided for @failedPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to reload plans'**
  String get failedPlan;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @planTab.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTab;

  /// No description provided for @villageCode.
  ///
  /// In en, this message translates to:
  /// **'Village\nCode'**
  String get villageCode;

  /// No description provided for @villageName.
  ///
  /// In en, this message translates to:
  /// **'Village\nName'**
  String get villageName;

  /// No description provided for @cdBlock.
  ///
  /// In en, this message translates to:
  /// **'CD Block'**
  String get cdBlock;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reccaPlan.
  ///
  /// In en, this message translates to:
  /// **'Recca Plans reloaded successfully!'**
  String get reccaPlan;

  /// No description provided for @failedRecca.
  ///
  /// In en, this message translates to:
  /// **'Failed to reload recca plans'**
  String get failedRecca;

  /// No description provided for @reccaPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Recca Plans'**
  String get reccaPlanTitle;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get lat;

  /// No description provided for @lng.
  ///
  /// In en, this message translates to:
  /// **'Lng'**
  String get lng;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @geoLoc.
  ///
  /// In en, this message translates to:
  /// **'Geo Location'**
  String get geoLoc;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @printNo.
  ///
  /// In en, this message translates to:
  /// **'Print No'**
  String get printNo;

  /// No description provided for @searchMarker.
  ///
  /// In en, this message translates to:
  /// **'Search markers...'**
  String get searchMarker;

  /// No description provided for @viilageNameTab.
  ///
  /// In en, this message translates to:
  /// **'Village Name'**
  String get viilageNameTab;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @villageNameMap.
  ///
  /// In en, this message translates to:
  /// **'Village Name'**
  String get villageNameMap;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @nearView.
  ///
  /// In en, this message translates to:
  /// **'Near View'**
  String get nearView;

  /// No description provided for @roadView.
  ///
  /// In en, this message translates to:
  /// **'Road View'**
  String get roadView;

  /// No description provided for @surroundingview.
  ///
  /// In en, this message translates to:
  /// **'Surrounding view'**
  String get surroundingview;

  /// No description provided for @submitDetails.
  ///
  /// In en, this message translates to:
  /// **'Submit Details'**
  String get submitDetails;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync All'**
  String get syncAll;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @printID.
  ///
  /// In en, this message translates to:
  /// **'Print ID.'**
  String get printID;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @syncPlan.
  ///
  /// In en, this message translates to:
  /// **'Successfully synced plan'**
  String get syncPlan;

  /// No description provided for @failedSyncPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync plan'**
  String get failedSyncPlan;

  /// No description provided for @syncAllPlan.
  ///
  /// In en, this message translates to:
  /// **'Successfully synced all plans!'**
  String get syncAllPlan;

  /// No description provided for @failedSyncAllPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync all plans!'**
  String get failedSyncAllPlan;

  /// No description provided for @imagePrintNo.
  ///
  /// In en, this message translates to:
  /// **'Images for Print Number'**
  String get imagePrintNo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @printDetails.
  ///
  /// In en, this message translates to:
  /// **'Print Details'**
  String get printDetails;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'Please select...'**
  String get pleaseSelect;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImages;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @failedImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image!'**
  String get failedImage;

  /// No description provided for @selectRemarks.
  ///
  /// In en, this message translates to:
  /// **'Please select the remarks'**
  String get selectRemarks;

  /// No description provided for @submitPlan.
  ///
  /// In en, this message translates to:
  /// **'Submitting plan details...'**
  String get submitPlan;

  /// No description provided for @imageVal.
  ///
  /// In en, this message translates to:
  /// **'Please upload all 7 images'**
  String get imageVal;

  /// No description provided for @loginNewVal.
  ///
  /// In en, this message translates to:
  /// **'Enter the Valid Mobile Number / User ID'**
  String get loginNewVal;

  /// No description provided for @planDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get planDetails;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @districtName.
  ///
  /// In en, this message translates to:
  /// **'District Name'**
  String get districtName;

  /// No description provided for @cdBlockName.
  ///
  /// In en, this message translates to:
  /// **'CD Block Name'**
  String get cdBlockName;

  /// No description provided for @totalPrints.
  ///
  /// In en, this message translates to:
  /// **'Total Prints'**
  String get totalPrints;

  /// No description provided for @balancePrints.
  ///
  /// In en, this message translates to:
  /// **'Balance Prints'**
  String get balancePrints;

  /// No description provided for @badRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad Request: No data found. Please try again later.'**
  String get badRequest;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized: Authentication failed. Please login again.'**
  String get unauthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden: Access denied. Please contact admin.'**
  String get forbidden;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found: No data found. Please try again later.'**
  String get notFound;

  /// No description provided for @internalServerError.
  ///
  /// In en, this message translates to:
  /// **'Internal Server Error: Please contact admin for assistance.'**
  String get internalServerError;

  /// No description provided for @badGateway.
  ///
  /// In en, this message translates to:
  /// **'Bad Gateway: Server temporarily unavailable. Please try again later.'**
  String get badGateway;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service Unavailable: Please try again later.'**
  String get serviceUnavailable;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found. Please try again later.'**
  String get noDataFound;

  /// No description provided for @networkerror.
  ///
  /// In en, this message translates to:
  /// **'Network error: Please check your internet connection and try again.'**
  String get networkerror;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again later.'**
  String get unexpectedError;

  /// No description provided for @errorArtworkDetails.
  ///
  /// In en, this message translates to:
  /// **'Error during fetching artwork details: Please try again later.'**
  String get errorArtworkDetails;

  /// No description provided for @loginNewValidVal.
  ///
  /// In en, this message translates to:
  /// **'Enter the Valid Mobile Number / User ID'**
  String get loginNewValidVal;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noPlanFound.
  ///
  /// In en, this message translates to:
  /// **'No plans found for'**
  String get noPlanFound;

  /// No description provided for @trySearching.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get trySearching;

  /// No description provided for @showing.
  ///
  /// In en, this message translates to:
  /// **'Showing'**
  String get showing;

  /// No description provided for @ofText.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofText;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get results;

  /// No description provided for @pleaseContact.
  ///
  /// In en, this message translates to:
  /// **'Please contact admin'**
  String get pleaseContact;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin'**
  String get contactAdmin;

  /// No description provided for @connectionProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection Problem'**
  String get connectionProblem;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationRequired;

  /// No description provided for @serverIssue.
  ///
  /// In en, this message translates to:
  /// **'Server Issue'**
  String get serverIssue;

  /// No description provided for @noDataAvaiable.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvaiable;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get somethingWentWrong;

  /// No description provided for @contactAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Contact Administrator'**
  String get contactAdministrator;

  /// No description provided for @serverErrorOccured.
  ///
  /// In en, this message translates to:
  /// **'A server error has occurred. Please contact the system administrator with the following details'**
  String get serverErrorOccured;

  /// No description provided for @errorType.
  ///
  /// In en, this message translates to:
  /// **'Error Type: Server Error (500)'**
  String get errorType;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @failedFetchRemarks.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch remarks. Please try again.'**
  String get failedFetchRemarks;

  /// No description provided for @failedFetchDasboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch dashboard'**
  String get failedFetchDasboard;

  /// No description provided for @failedFetchDashboardTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch Dashboard. Please try again.'**
  String get failedFetchDashboardTry;

  /// No description provided for @noProjectAvaiable.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Please try again later.'**
  String get noProjectAvaiable;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @pleaseSelectBothDates.
  ///
  /// In en, this message translates to:
  /// **'Please select both start and end dates, and a project.'**
  String get pleaseSelectBothDates;

  /// No description provided for @printsCaptured.
  ///
  /// In en, this message translates to:
  /// **'Prints Captured'**
  String get printsCaptured;

  /// No description provided for @printsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Prints Uploaded'**
  String get printsUploaded;

  /// No description provided for @executeVendor.
  ///
  /// In en, this message translates to:
  /// **'Execute by Raw Vendor'**
  String get executeVendor;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingDashboard;

  /// No description provided for @recordsDashboard.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get recordsDashboard;

  /// No description provided for @failedFetchData.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch data. Please try again.'**
  String get failedFetchData;

  /// No description provided for @printName.
  ///
  /// In en, this message translates to:
  /// **'Print\nName'**
  String get printName;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @unableUID.
  ///
  /// In en, this message translates to:
  /// **'Unable to retrieve UID for your role. Please restart the app and try again.'**
  String get unableUID;

  /// No description provided for @uid.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get uid;

  /// No description provided for @accountRegistered.
  ///
  /// In en, this message translates to:
  /// **'This account is registered as'**
  String get accountRegistered;

  /// No description provided for @pleaseCorrectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select the correct role and try again.'**
  String get pleaseCorrectRole;

  /// No description provided for @roleInformation.
  ///
  /// In en, this message translates to:
  /// **'Role information not found. Please contact support.'**
  String get roleInformation;

  /// No description provided for @phoneNumberIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Phone Number or Password is Incorrect'**
  String get phoneNumberIncorrect;

  /// No description provided for @unableServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server. Please try again.'**
  String get unableServer;

  /// No description provided for @errorOccurredLogin.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login. Please try again.'**
  String get errorOccurredLogin;

  /// No description provided for @errorOccurredRegstration.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during registration. Please try again.'**
  String get errorOccurredRegstration;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @tapAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap for address'**
  String get tapAddress;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get locationServicesDisabled;

  /// No description provided for @pleaseAccurate.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services for accurate positioning.'**
  String get pleaseAccurate;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationRequired;

  /// No description provided for @pleaseAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Please enable location permission in app settings.'**
  String get pleaseAppSettings;

  /// No description provided for @locationDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Location Detection Failed'**
  String get locationDetectionFailed;

  /// No description provided for @unableLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get location. Try:'**
  String get unableLocation;

  /// No description provided for @moveWindows.
  ///
  /// In en, this message translates to:
  /// **'Move closer to windows'**
  String get moveWindows;

  /// No description provided for @enableWiFi.
  ///
  /// In en, this message translates to:
  /// **'Enable Wi-Fi'**
  String get enableWiFi;

  /// No description provided for @useManualSelection.
  ///
  /// In en, this message translates to:
  /// **'Use manual selection'**
  String get useManualSelection;

  /// No description provided for @manualSelection.
  ///
  /// In en, this message translates to:
  /// **'Manual Selection'**
  String get manualSelection;

  /// No description provided for @tapLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on map to set location'**
  String get tapLocation;

  /// No description provided for @locationResumeGPS.
  ///
  /// In en, this message translates to:
  /// **'Location set\nTap location button to resume GPS'**
  String get locationResumeGPS;

  /// No description provided for @addressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Address unavailable (offline mode)'**
  String get addressUnavailable;

  /// No description provided for @gpsTrackingResumed.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking resumed\nAuto-refresh enabled'**
  String get gpsTrackingResumed;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @lowAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Low Accuracy Warning'**
  String get lowAccuracy;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy is low'**
  String get locationAccuracy;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway or improve location?'**
  String get continueAnyway;

  /// No description provided for @improve.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get improve;

  /// No description provided for @pleaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Please wait for location detection'**
  String get pleaseDetection;

  /// No description provided for @pendingUploads.
  ///
  /// In en, this message translates to:
  /// **'Pending Uploads'**
  String get pendingUploads;

  /// No description provided for @youhave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get youhave;

  /// No description provided for @pendingSynced.
  ///
  /// In en, this message translates to:
  /// **'pending plan(s) that need to be synced.'**
  String get pendingSynced;

  /// No description provided for @pleaseSyncAllPending.
  ///
  /// In en, this message translates to:
  /// **'Please sync all pending plans before reloading.'**
  String get pleaseSyncAllPending;

  /// No description provided for @villages.
  ///
  /// In en, this message translates to:
  /// **'village(s)'**
  String get villages;

  /// No description provided for @noPlansFoundPlan.
  ///
  /// In en, this message translates to:
  /// **'No plans Found'**
  String get noPlansFoundPlan;

  /// No description provided for @searchingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Searching for location'**
  String get searchingForLocation;

  /// No description provided for @noPlansWithBalance.
  ///
  /// In en, this message translates to:
  /// **'No plans with balance available for this location'**
  String get noPlansWithBalance;

  /// No description provided for @located.
  ///
  /// In en, this message translates to:
  /// **'Located'**
  String get located;

  /// No description provided for @locationNotFoundSelection.
  ///
  /// In en, this message translates to:
  /// **'Location not found. Try manual selection.'**
  String get locationNotFoundSelection;

  /// No description provided for @unableToFindSelection.
  ///
  /// In en, this message translates to:
  /// **'Unable to find location. Try manual selection.'**
  String get unableToFindSelection;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @searchVillageCode.
  ///
  /// In en, this message translates to:
  /// **'Search with Village Code'**
  String get searchVillageCode;

  /// No description provided for @noBalanceFound.
  ///
  /// In en, this message translates to:
  /// **'No villages with balance found'**
  String get noBalanceFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try different search terms'**
  String get tryDifferentSearch;

  /// No description provided for @getingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get getingLocation;

  /// No description provided for @unablePleaseEnableGPS.
  ///
  /// In en, this message translates to:
  /// **'Unable to get current location. Please enable GPS'**
  String get unablePleaseEnableGPS;

  /// No description provided for @awayFromSelected.
  ///
  /// In en, this message translates to:
  /// **'away from the selected location.\nPlease move closer (within 50m) to capture the first image.'**
  String get awayFromSelected;

  /// No description provided for @locationTooFar.
  ///
  /// In en, this message translates to:
  /// **'Location Too Far'**
  String get locationTooFar;

  /// No description provided for @metersAwaySelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'meters away from the selected location'**
  String get metersAwaySelectedLocation;

  /// No description provided for @firstImageCaptured.
  ///
  /// In en, this message translates to:
  /// **'The first image must be captured within 50 meters of the selected location.'**
  String get firstImageCaptured;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @moveCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the location'**
  String get moveCloser;

  /// No description provided for @refreshLocationMap.
  ///
  /// In en, this message translates to:
  /// **'Refresh your location on map'**
  String get refreshLocationMap;

  /// No description provided for @stayHere.
  ///
  /// In en, this message translates to:
  /// **'Stay Here'**
  String get stayHere;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh Location'**
  String get refreshLocation;

  /// No description provided for @imageCaptured.
  ///
  /// In en, this message translates to:
  /// **'Image captured successfully!'**
  String get imageCaptured;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected successfully!'**
  String get imageSelected;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermission;

  /// No description provided for @unableExternalstorage.
  ///
  /// In en, this message translates to:
  /// **'Unable to access external storage directory'**
  String get unableExternalstorage;

  /// No description provided for @openingCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening Camera...'**
  String get openingCamera;

  /// No description provided for @pleaseEnterPrintNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter both parts of the print number'**
  String get pleaseEnterPrintNumber;

  /// No description provided for @unableCurrentLocationSubmission.
  ///
  /// In en, this message translates to:
  /// **'Unable to get current location for submission. Please enable GPS.'**
  String get unableCurrentLocationSubmission;

  /// No description provided for @cannotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Cannot Submit'**
  String get cannotSubmit;

  /// No description provided for @metersAwayFirstImage.
  ///
  /// In en, this message translates to:
  /// **'meters away from where you captured the first image.'**
  String get metersAwayFirstImage;

  /// No description provided for @submissionRequirements.
  ///
  /// In en, this message translates to:
  /// **'Submission Requirements:'**
  String get submissionRequirements;

  /// No description provided for @youMetersImageCapturesubmit.
  ///
  /// In en, this message translates to:
  /// **'You must be within 100 meters of the image capture location to submit.'**
  String get youMetersImageCapturesubmit;

  /// No description provided for @pleaseReturnLocationImages.
  ///
  /// In en, this message translates to:
  /// **'Please return to the location where you captured the images.'**
  String get pleaseReturnLocationImages;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @pleaseBackImageLocationPlan.
  ///
  /// In en, this message translates to:
  /// **'Please go back to the image capture location (within 100m) to submit the plan.'**
  String get pleaseBackImageLocationPlan;

  /// No description provided for @errorOccurredSubmitting.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while submitting. Please try again'**
  String get errorOccurredSubmitting;

  /// No description provided for @autoRotateEnable.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rotate enable'**
  String get autoRotateEnable;

  /// No description provided for @autoRotateDevice.
  ///
  /// In en, this message translates to:
  /// **'Auto-rotate is currently disabled on your device. For the best camera experience, please enable auto-rotate in your device settings.'**
  String get autoRotateDevice;

  /// No description provided for @enableAutoRotate.
  ///
  /// In en, this message translates to:
  /// **'How to enable auto-rotate:'**
  String get enableAutoRotate;

  /// No description provided for @swipeDownScreen.
  ///
  /// In en, this message translates to:
  /// **'Swipe down from the top of your screen'**
  String get swipeDownScreen;

  /// No description provided for @lookAutoRotateOrientation.
  ///
  /// In en, this message translates to:
  /// **'Look for the Auto-rotate or rotation lock icon or lock orientation'**
  String get lookAutoRotateOrientation;

  /// No description provided for @tapEnableAutoRotate.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable auto-rotate'**
  String get tapEnableAutoRotate;

  /// No description provided for @errorTakingPicture.
  ///
  /// In en, this message translates to:
  /// **'Error taking picture. Please try again'**
  String get errorTakingPicture;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing Camera...'**
  String get initializingCamera;

  /// No description provided for @settingUpCamera.
  ///
  /// In en, this message translates to:
  /// **'Setting up Camera...'**
  String get settingUpCamera;

  /// No description provided for @failedFetchDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch dashboard:'**
  String get failedFetchDashboard;

  /// No description provided for @noDashboardDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No dashboard data available.'**
  String get noDashboardDataAvailable;

  /// No description provided for @failedFetchDashboardTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch Dashboard. Please try again.'**
  String get failedFetchDashboardTryAgain;

  /// No description provided for @noProjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Please try again later.'**
  String get noProjectsAvailable;

  /// No description provided for @pleaseStartEndDates.
  ///
  /// In en, this message translates to:
  /// **'Please select both start and end dates, and a project.'**
  String get pleaseStartEndDates;

  /// No description provided for @rawHold.
  ///
  /// In en, this message translates to:
  /// **'Raw / Hold'**
  String get rawHold;

  /// No description provided for @noDashboard.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noDashboard;

  /// No description provided for @recordsFound.
  ///
  /// In en, this message translates to:
  /// **'records found'**
  String get recordsFound;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version:'**
  String get appVersion;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User Id:'**
  String get userId;

  /// No description provided for @wantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Do you want to logout?'**
  String get wantToLogout;

  /// No description provided for @yesDashboard.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesDashboard;

  /// No description provided for @noLogFilesFoundFolders.
  ///
  /// In en, this message translates to:
  /// **'No log files found in the specified folders'**
  String get noLogFilesFoundFolders;

  /// No description provided for @applicationLogs.
  ///
  /// In en, this message translates to:
  /// **'Application Logs'**
  String get applicationLogs;

  /// No description provided for @logsExportedOn.
  ///
  /// In en, this message translates to:
  /// **'Logs exported on'**
  String get logsExportedOn;

  /// No description provided for @logsSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logs shared successfully'**
  String get logsSharedSuccessfully;

  /// No description provided for @failedLogsZipFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create logs zip file'**
  String get failedLogsZipFile;

  /// No description provided for @errorSharingLogs.
  ///
  /// In en, this message translates to:
  /// **'Error sharing logs:'**
  String get errorSharingLogs;

  /// No description provided for @shareLogs.
  ///
  /// In en, this message translates to:
  /// **'Share Logs'**
  String get shareLogs;

  /// No description provided for @tapExportShareZipFile.
  ///
  /// In en, this message translates to:
  /// **'Tap the share icon to export and share all logs as a zip file.'**
  String get tapExportShareZipFile;

  /// No description provided for @noLogFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No log files found'**
  String get noLogFilesFound;

  /// No description provided for @pendingSyncCount.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync Count:'**
  String get pendingSyncCount;

  /// No description provided for @failedLoadRemarks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load remarks. Please try again.'**
  String get failedLoadRemarks;

  /// No description provided for @pleaseUploadAllImages.
  ///
  /// In en, this message translates to:
  /// **'Please upload all 2 images'**
  String get pleaseUploadAllImages;

  /// No description provided for @noMatchingMarkerFound.
  ///
  /// In en, this message translates to:
  /// **'No matching marker found'**
  String get noMatchingMarkerFound;

  /// No description provided for @planId.
  ///
  /// In en, this message translates to:
  /// **'plan Id'**
  String get planId;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationError;

  /// No description provided for @markerLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Marker location is not available. Please try again.'**
  String get markerLocationNotAvailable;

  /// No description provided for @unableYourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get your current location. Please enable location services and try again.'**
  String get unableYourCurrentLocation;

  /// No description provided for @distanceError.
  ///
  /// In en, this message translates to:
  /// **'Distance Error'**
  String get distanceError;

  /// No description provided for @metersAwayMarkerLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'meters away from the marker location. You must be within 50 meters to continue.'**
  String get metersAwayMarkerLocationContinue;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get validationError;

  /// No description provided for @unableValidateLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to validate your location. Please try again.'**
  String get unableValidateLocation;

  /// No description provided for @remarksDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Remarks data not found. Please reload the plan to fetch remarks.'**
  String get remarksDataNotFound;

  /// No description provided for @remarksNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Remarks Not Available'**
  String get remarksNotAvailable;

  /// No description provided for @remarksDataRequiredProceed.
  ///
  /// In en, this message translates to:
  /// **'Remarks data is required to proceed. Please reload the plan to fetch the latest remarks.'**
  String get remarksDataRequiredProceed;

  /// No description provided for @willRefreshAllPlans.
  ///
  /// In en, this message translates to:
  /// **'This will refresh all plans and fetch remarks data.'**
  String get willRefreshAllPlans;

  /// No description provided for @reloadPlans.
  ///
  /// In en, this message translates to:
  /// **'Reload Plans'**
  String get reloadPlans;

  /// No description provided for @villageCodePost.
  ///
  /// In en, this message translates to:
  /// **'Village Code'**
  String get villageCodePost;

  /// No description provided for @tehsil.
  ///
  /// In en, this message translates to:
  /// **'Tehsil'**
  String get tehsil;

  /// No description provided for @pleaseCheckVillageCode.
  ///
  /// In en, this message translates to:
  /// **'Please check the village code'**
  String get pleaseCheckVillageCode;

  /// No description provided for @successfullySynced.
  ///
  /// In en, this message translates to:
  /// **'Successfully synced'**
  String get successfullySynced;

  /// No description provided for @failedToSync.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync - Unknown error'**
  String get failedToSync;

  /// No description provided for @noDetailsProvided.
  ///
  /// In en, this message translates to:
  /// **'No details provided'**
  String get noDetailsProvided;

  /// No description provided for @unexpectedResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response format'**
  String get unexpectedResponseFormat;

  /// No description provided for @alreadyUploadedServer.
  ///
  /// In en, this message translates to:
  /// **'Already uploaded to server (duplicate detected)'**
  String get alreadyUploadedServer;

  /// No description provided for @alreadyOnServer.
  ///
  /// In en, this message translates to:
  /// **'already on server. Removed from the sync.'**
  String get alreadyOnServer;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @allPlansSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All plans synced successfully'**
  String get allPlansSyncedSuccessfully;

  /// No description provided for @failedSyncallPlans.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync all plans - Unknown error'**
  String get failedSyncallPlans;

  /// No description provided for @noDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// No description provided for @printsAlreadyOnServer.
  ///
  /// In en, this message translates to:
  /// **'print(s) already on server. Removed from the sync'**
  String get printsAlreadyOnServer;

  /// No description provided for @duplicatesRemoved.
  ///
  /// In en, this message translates to:
  /// **'duplicate(s) removed'**
  String get duplicatesRemoved;

  /// No description provided for @errorsOccurred.
  ///
  /// In en, this message translates to:
  /// **'error(s) occurred'**
  String get errorsOccurred;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @successfullyResentData.
  ///
  /// In en, this message translates to:
  /// **'Successfully resent data'**
  String get successfullyResentData;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Resend failed - Server returned false'**
  String get resendFailed;

  /// No description provided for @successfullyResentPlan.
  ///
  /// In en, this message translates to:
  /// **'Successfully resent plan'**
  String get successfullyResentPlan;

  /// No description provided for @resendFailedPlan.
  ///
  /// In en, this message translates to:
  /// **'Resend failed for plan'**
  String get resendFailedPlan;

  /// No description provided for @errorDuringResend.
  ///
  /// In en, this message translates to:
  /// **'Error during resend'**
  String get errorDuringResend;

  /// No description provided for @responseDetails.
  ///
  /// In en, this message translates to:
  /// **'Response Details - Plan'**
  String get responseDetails;

  /// No description provided for @lastResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Last Response Time'**
  String get lastResponseTime;

  /// No description provided for @statusCode.
  ///
  /// In en, this message translates to:
  /// **'Status Code'**
  String get statusCode;

  /// No description provided for @totalRetryCount.
  ///
  /// In en, this message translates to:
  /// **'Total Retry Count'**
  String get totalRetryCount;

  /// No description provided for @latestMessage.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get latestMessage;

  /// No description provided for @viewAttemptsHistory.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get viewAttemptsHistory;

  /// No description provided for @completeHistory.
  ///
  /// In en, this message translates to:
  /// **'Complete History - Plan'**
  String get completeHistory;

  /// No description provided for @totalAttempts.
  ///
  /// In en, this message translates to:
  /// **'Total Attempts'**
  String get totalAttempts;

  /// No description provided for @attempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt'**
  String get attempt;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @creatingZIPFile.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP file'**
  String get creatingZIPFile;

  /// No description provided for @failedCreateZIPFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ZIP file'**
  String get failedCreateZIPFile;

  /// No description provided for @searchPrintNoStatus.
  ///
  /// In en, this message translates to:
  /// **'Search by Village, Plan, Print No, Status...'**
  String get searchPrintNoStatus;

  /// No description provided for @printNoResend.
  ///
  /// In en, this message translates to:
  /// **'Print\nNo'**
  String get printNoResend;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get zip;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @securityWarning.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get securityWarning;

  /// No description provided for @securityIssuesDetected.
  ///
  /// In en, this message translates to:
  /// **'The following security issues were detected:'**
  String get securityIssuesDetected;

  /// No description provided for @howToFix.
  ///
  /// In en, this message translates to:
  /// **'How to fix:'**
  String get howToFix;

  /// No description provided for @tapOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Tap Open Settings below'**
  String get tapOpenSettings;

  /// No description provided for @searchDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Search for Developer Options'**
  String get searchDeveloperOptions;

  /// No description provided for @turnOFFDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Turn OFF Developer Options'**
  String get turnOFFDeveloperOptions;

  /// No description provided for @turnOFFMockLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn OFF Mock Location'**
  String get turnOFFMockLocation;

  /// No description provided for @returnApp.
  ///
  /// In en, this message translates to:
  /// **'Return to this app'**
  String get returnApp;

  /// No description provided for @turnONLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn ON Location Services'**
  String get turnONLocationServices;

  /// No description provided for @appAutomaticallyRecheckReturn.
  ///
  /// In en, this message translates to:
  /// **'The app will automatically recheck when you return.'**
  String get appAutomaticallyRecheckReturn;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @fixIssuesReturnApp.
  ///
  /// In en, this message translates to:
  /// **'Fix the issues and return to app'**
  String get fixIssuesReturnApp;

  /// No description provided for @rework.
  ///
  /// In en, this message translates to:
  /// **'Rework'**
  String get rework;

  /// No description provided for @withinAllowedRange.
  ///
  /// In en, this message translates to:
  /// **'You are within allowed range'**
  String get withinAllowedRange;

  /// No description provided for @moveWithin100mToUnlockNext.
  ///
  /// In en, this message translates to:
  /// **'Move within 100m to unlock Next'**
  String get moveWithin100mToUnlockNext;

  /// No description provided for @canId.
  ///
  /// In en, this message translates to:
  /// **'Can ID'**
  String get canId;

  /// No description provided for @view360.
  ///
  /// In en, this message translates to:
  /// **'360 View'**
  String get view360;

  /// No description provided for @tapToViewLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to view location details'**
  String get tapToViewLocationDetails;

  /// No description provided for @pointerCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Pointer Coordinates'**
  String get pointerCoordinates;

  /// No description provided for @yourCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Your Coordinates'**
  String get yourCoordinates;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'mr',
    'ta',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
