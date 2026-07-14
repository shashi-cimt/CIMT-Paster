import 'package:canimage/Model/see_plan_model.dart';
import 'package:canimage/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../APIService/auth_service.dart';
import '../../Hive_Database/execution_seeplan_db.dart';
import '../../Model/execution_dashboard_summary_details_model.dart';
import '../../Model/project_model.dart';
import '../../Provider/can_image_provider.dart';

import '../../Repository/upload_count_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../landing/landing_screen.dart';

class PrintRecord {
  final String printName;
  final String status;
  final String remarks;
  final String canId;

  PrintRecord({
    required this.printName,
    required this.status,
    required this.remarks,
    required this.canId,
  });
}

// State management with Riverpod
final startDateProvider = StateProvider<DateTime?>((ref) => DateTime.now());
final endDateProvider = StateProvider<DateTime?>((ref) => DateTime.now());
final testNameProvider = StateProvider<String>((ref) => '');

// Sample data providers


// Dashboard stats provider




class DashboardPage extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const DashboardPage({super.key, required this.changeLanguage});


  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool loader = false;
  List<SeePlanModel>? plans;
  List<Data> dataPlans = [];
  dynamic totalPrints;
  var printsUploaded;
  var executedByVendorRaw = 0;
  var approved;
  var partial;
  var rejected;
  String? _selectedRemark;
  final TextEditingController _projectIDDisplayCtrl = TextEditingController();
  List<DataDashboard>? data = [];
  final Set<String> _selectedRemarks = {};
  List<DataProject> dataProject = [];
  String? _selectedProjectName;
  String? _selectedProjectDisplayName; // This will hold the project name for display
  @override
  void initState() {
    super.initState();
    // fetchSeePlan();
    fetchProject();
  }


  void fetchProject() async {
    setState(() {
      loader = true;
    });

    try {
      final value = await Auth().fetchProjectModel();
      // print('Fetched Remarks Model: $value');

      if (value != null && value.data != null) {
        // Assign the 'data' list directly to the 'plans' variable
        dataProject = value.data!;
        // print(dataProject.length);
        // print("plans.length::::");
      } else {
        // print('API returned null or empty list of remarks.');
      }
    } catch (e) {
      // print('Error fetching remarks: $e');
      Fluttertoast.showToast(msg: S.of(context).failedFetchRemarks);
    } finally {
      setState(() {
        loader = false;
      });
    }
  }


  void fetchDashboardSummary(String StartDate, String EndDate, String ProjectID) async {
    setState(() {
      loader = true;
    });

    try {
      final value = await Auth().fetchExecutionDashboardSummary(StartDate, EndDate, ProjectID);
      // print('Fetched Dashboard Model: $value');

      if (value != null && value.data != null && value.isSuccess == true) {
        // Safely assign values with null checks
        int localUploadCount = await UploadCountRepository().getUploadCount(
          StartDate,
          EndDate,
        );
        totalPrints = localUploadCount;
        printsUploaded = value.data!.printsUploaded ?? 0;
        executedByVendorRaw = value.data!.executedByVendorRaw ?? 0;
        approved = value.data!.approved ?? 0;
        partial = value.data!.partial ?? 0;
        rejected = value.data!.rejected ?? 0;


        data = [];
        // print("Details list has been cleared. ${data!.length}");

      } else if (value != null && value.isSuccess == false) {
        // print('API returned unsuccessful response: ${value.message}');
        Fluttertoast.showToast(
            msg: "${S.of(context).failedFetchDashboard}: ${value.message ?? S.of(context).unKnownError}"
        );
      } else {
        // print('API returned null or invalid response structure.');
        Fluttertoast.showToast(msg: S.of(context).noDashboardDataAvailable);
      }
    } catch (e) {
      // print('Error in fetchDashboardSummary: $e');
      Fluttertoast.showToast(msg: S.of(context).failedFetchDashboardTryAgain);
    } finally {
      setState(() {
        loader = false;
      });
    }
  }

  void _openRemarksDialog() async {
    if (dataProject.isEmpty) {
      Fluttertoast.showToast(msg: S.of(context).noProjectAvaiable);
      return;
    }

    String? tempSelectedProjectID = _selectedProjectName;
    String? tempSelectedProjectDisplayName = _selectedProjectDisplayName;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(S.of(context).pleaseSelect, style: TextStyle(fontFamily: "Roboto", fontSize: 14)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: dataProject.map((opt) {
                      return RadioListTile<String>(
                        title: Text(opt.projectName?.toString() ?? '', style: TextStyle(fontFamily: "Roboto", fontSize: 12)),
                        value: opt.projectId!.toString(),
                        groupValue: tempSelectedProjectID,
                        onChanged: (String? value) {
                          setLocal(() {
                            tempSelectedProjectID = value;
                            tempSelectedProjectDisplayName = opt.projectName?.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(S.of(context).cancel, style: TextStyle(fontFamily: "Roboto", color: Font.primaryColor)),
                ),
                TextButton(
                  onPressed: () {
                    if (tempSelectedProjectID != null && tempSelectedProjectDisplayName != null) {
                      setState(() {
                        _selectedProjectName = tempSelectedProjectID;
                        _selectedProjectDisplayName = tempSelectedProjectDisplayName;
                        _projectIDDisplayCtrl.text = tempSelectedProjectDisplayName!;
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(S.of(context).submit, style: TextStyle(fontFamily: "Roboto", color: Font.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // final stats = ref.watch(dashboardStatsProvider);



    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
              S.of(context).dashboard,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 1,
                fontFamily: "Roboto",
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                  );
                },
              ),
            ],
          ),
          body: loader == true ? Center(child: CircularProgressIndicator(color: Font.primaryColor,)) : SingleChildScrollView(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDashboardCard(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildDateInputs(context, ref),
            const SizedBox(height: 24),
            _buildVillageDropdown(ref),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 40),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildExecuteByVendor(),
            const SizedBox(height: 32),
            _buildStatusButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [

        Text(
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Font.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInputs(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildDateInput(
            context,
            ref,
            S.of(context).startDate,
            startDateProvider,
            Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateInput(
            context,
            ref,
            S.of(context).endDate,
            endDateProvider,
            Icons.event_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput(
      BuildContext context,
      WidgetRef ref,
      String label,
      StateProvider<DateTime?> provider,
      IconData icon,
      ) {
    final date = ref.watch(provider);

    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Font.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          ref.read(provider.notifier).state = selectedDate;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      label,
                      style: TextStyle(
                        color: Font.neutralDarkColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        fontFamily: "Roboto",
                      )
                  ),
                  const SizedBox(height: 2),
                  Text(
                      date != null
                          ? DateFormat('dd/MM/yyyy').format(date)
                          : S.of(context).selectDate,
                      style: TextstyleGlobal.bodyTextStyle
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillageDropdown(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: GestureDetector(
        onTap: _openRemarksDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: _selectedProjectName == null
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).pleaseSelect,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: "Roboto",
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: Colors.grey),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedProjectDisplayName!,
                              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2D2D2D),
                  fontFamily: "Roboto",
                              ),
                            ),
                  Icon(Icons.expand_more, size: 18, color: Colors.grey),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Font.primaryColor, Font.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {

            setState(() {
              // fetchDashboardSummary();
              _submitForm();
            });
            // Handle submit action
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              S.of(context).submit,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: "Roboto",
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    // Get the start date and end date
    final startDate = ref.read(startDateProvider);
    final endDate = ref.read(endDateProvider);

    // Check if both startDate and endDate are not null and _selectedProjectName is selected
    if (startDate != null && endDate != null && _selectedProjectName != null) {
      // Format dates in 'YYYY-MM-DD' format
      String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
      // print(formattedStartDate);
      // print(formattedEndDate);
      // print(_selectedProjectName);
      // print("_selectedProjectName");

      // Call the method with the formatted dates and selected project name
      fetchDashboardSummary(formattedStartDate, formattedEndDate, _selectedProjectName!);
    } else {
      // Show an error if dates or project name are missing
      Fluttertoast.showToast(msg: S.of(context).pleaseStartEndDates);
    }
  }


  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            S.of(context).printsCaptured,
            totalPrints ?? 0,
            Icons.camera_alt_rounded,
            Font.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            S.of(context).printsUploaded,
            printsUploaded ?? 0,
            Icons.cloud_upload_rounded,
            Font.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  color: Font.neutralDarkColor,
                  fontSize: 14,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Font.neutralDarkColor,
              fontSize: 12,
              fontFamily: "Roboto",
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteByVendor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Font.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Font.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Font.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: Font.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                S.of(context).rawHold,
                style: TextStyle(
                  color: Font.neutralDarkColor,
                  fontSize: 12,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                executedByVendorRaw.toString() ,
                style: TextStyle(
                  color: Font.neutralDarkColor,
                  fontSize: 14,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusButton(
            context,
            ref,
            S.of(context).approved,
            approved ?? 0,
            Colors.green,
            'Approved',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusButton(
            context,
            ref,
            S.of(context).partial,
            partial ?? 0,
            Colors.orange,
            'Partial',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusButton(
            context,
            ref,
            S.of(context).rejected,
            rejected ?? 0,
            Colors.red,
            'Rejected',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context, WidgetRef ref, String status, int count, Color color, String type) {
    return GestureDetector(
      onTap: () => _showStatusPopup(context, ref, status, type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: "Roboto",
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: "Roboto",
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPopup(BuildContext context, WidgetRef ref, String status, String type) async {
    // Set the default color for the status popup.
    Color statusColor;

    // Determine the color based on the status type.
    switch (type) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Partial':
        statusColor = Colors.orange;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
      // Use a default color if the type doesn't match.
        statusColor = Font.primaryColor;
        break;
    }

    // Define a variable to hold the data fetched from the API.
    List<DataDashboard> recordsToDisplay = [];

    // Show a loading dialog while the data is being fetched.
    // We use a separate variable to hold the dialog's context to avoid issues with closing it later.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Font.primaryColor),
                const SizedBox(height: 20),
                Text(
                  '${S.of(context).loadingDashboard} $status ${S.of(context).recordsDashboard}...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Read the required data from providers and local variables.
      final startDate = ref.read(startDateProvider);
      final endDate = ref.read(endDateProvider);
      // You need to ensure `_selectedProjectName` is accessible here.
      final selectedProjectName = _selectedProjectName;

      // Check for required data before making the API call.
      if (startDate != null && endDate != null && selectedProjectName != null) {
        // Format dates for the API call.
        String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
        String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

        // Await the API call. This is the crucial part that was missing a try-catch.
        final dashboardData = await Auth().fetchExecutionDashboardSummaryDetails(
          type,
          formattedStartDate,
          formattedEndDate,
          selectedProjectName,
        );
        // print("Dashboard data received: $dashboardData");
        // print("Is dashboardData null? ${dashboardData == null}");

        if (dashboardData != null) {
          // print("Dashboard data isSuccess: ${dashboardData.isSuccess}");
          // print("Dashboard data list: ${dashboardData.data}");
          // print("Dashboard data length: ${dashboardData.data?.length}");
        }
        // Update the recordsToDisplay with the fetched data if it's not null.
        recordsToDisplay = dashboardData?.data ?? [];
        // print("Final recordsToDisplay length: ${recordsToDisplay.length}");

      } else {
        // Show an error if data is missing.
        // Fluttertoast.showToast(msg: "Please select both start and end dates, and a project.");
      }
    } catch (e) {
      // Handle potential errors from the API call.
      Fluttertoast.showToast(msg: "Failed to fetch data. Please try again.");
      // print('Error fetching dashboard data: $e');
    } finally {
      // Close the loading dialog.
      // Ensure the context is still valid before popping.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    // Now show the actual status dialog with the newly fetched data.
    // This dialog will only appear after the API call is complete (or an error occurs).
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 1,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(type),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$status Records',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: "Roboto",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Custom Table Header
                Container(
                  color: Font.primaryColor,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            "Can Id",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            S.of(context).printName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            S.of(context).status,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            S.of(context).remarks,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Data
                Expanded(
                  child: (recordsToDisplay.isEmpty)
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${S.of(context).noDashboard} $status ${S.of(context).recordsFound}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: recordsToDisplay.length,
                    itemBuilder: (context, index) {
                      final item = recordsToDisplay[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item.canId?.toString() ?? '',
                                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey[200]),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item.printName?.toString() ?? '',
                                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey[200]),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    item.status?.toString() ?? '',
                                    style: TextstyleGlobal.bodyTextStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      color: statusColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey[200]),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item.remarks?.toString() ?? '',
                                  style: TextstyleGlobal.bodyTextStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${S.of(context).total} ${recordsToDisplay.length} ${S.of(context).recordsFound}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Roboto",
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }





  IconData _getStatusIcon(String type) {
    switch (type) {
      case 'Approved':
        return Icons.check_circle_outline;
      case 'Partial':
        return Icons.access_time;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}