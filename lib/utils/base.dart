
class APIURLs{
  /// Live Portal Failover
  static const List<String> baseUrls = [
    "https://cimtapi.cimtapps.com/", // Primary Domain
    "http://27.107.233.154:9001/",   // Tata
    "http://182.73.169.146:9001/",   // Airtel
  ];

  /// See Plan Portal Failover
  static const List<String> seePlanUrls = [
    "https://cimtone.cimtapps.com/", // Primary Domain
    "http://27.107.233.154:9006/",   // Tata
    "http://182.73.169.146:9006/",   // Airtel
  ];

  /// Currently active URLs. Every call site below keeps reading these as
  /// plain strings, so ServerFailoverInterceptor can swap them to a backup
  /// domain (on connection failure) transparently, with no other code
  /// needing to change.
  static String baseURL = baseUrls[0];
  static String URL = seePlanUrls[0];

  static const seePlanURL = "api/Pointer/Pending-Plan";
  static const seeSUPlanURL = "api/Supervisor/plans/post-recca/executed-plan";
  static const reccaRemarks = "api/Master/post-recca-remarks";
  static const projects = "api/Master/user-projects";
  static const reccaPost = "api/Supervisor/plans/post-recca/upload-prints";
  static const executionPost = "api/Execution/plans/upload-prints";
  static const resendExecutionPost = "/api/Execution/plans/resend-upload-prints";
  static const executionDashoardSummary = "api/Dashboard/execution/summary";
  static const executionDashoardSummaryDetails = "api/Dashboard/execution/summary-details";
  static const loginURL = "api/Auth/sign-in";
  static const registerURL = "api/User/register-user";
  static const ReworkUrl = "api/Execution/plans/rework-plan";
  static const ReworkUpload = "api/Execution/plans/rework-upload-prints";
   static const artworkURL = "api/Master/artworks";
   static const postRecceRemarksURL = "api/Master/post-recca-remarks";
}
