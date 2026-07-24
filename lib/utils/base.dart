
class APIURLs{
  /// Live Portal
  static const baseURL = "http://cimtapi.cimtapps.com/";
   /// Uat portal
   // static const baseURL = "http://103.224.6.71:5006/";


  /// See Plan Portal
  static const URL = "https://cimtone.cimtapps.com/";

//  static const seePlanURL = "api/Execution/plans/pending-plan";
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
