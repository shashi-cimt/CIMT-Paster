import 'package:canimage/Model/see_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../APIService/auth_service.dart';
import '../../Model/execution_dashboard_summary_details_model.dart';
import '../../Model/project_model.dart';
import '../../Repository/upload_count_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';

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
  dynamic totalPrints = 0;
  dynamic printsUploaded = 0;
  int executedByVendorRaw = 0;
  dynamic approved = 0;
  dynamic partial = 0;
  dynamic rejected = 0;
  final TextEditingController _projectIDDisplayCtrl = TextEditingController();
  List<DataDashboard>? data = [];
  List<DataProject> dataProject = [];
  String? _selectedProjectName;
  String? _selectedProjectDisplayName;

  @override
  void initState() {
    super.initState();
    fetchProject();
  }

  @override
  void dispose() {
    _projectIDDisplayCtrl.dispose();
    super.dispose();
  }

  void fetchProject() async {
    setState(() {
      loader = true;
    });

    try {
      final value = await Auth().fetchProjectModel();

      if (value != null && value.data != null) {
        dataProject = value.data!;
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).failedFetchRemarks);
      }
    } finally {
      if (mounted) {
        setState(() {
          loader = false;
        });
      }
    }
  }

  void fetchDashboardSummary(String startDate, String endDate, String projectID) async {
    setState(() {
      loader = true;
    });

    try {
      final value = await Auth().fetchExecutionDashboardSummary(startDate, endDate, projectID);

      if (value != null && value.data != null && value.isSuccess == true) {
        int localUploadCount = await UploadCountRepository().getUploadCount(
          startDate,
          endDate,
        );
        if (mounted) {
          setState(() {
            totalPrints = localUploadCount;
            printsUploaded = value.data!.printsUploaded ?? 0;
            executedByVendorRaw = value.data!.executedByVendorRaw ?? 0;
            approved = value.data!.approved ?? 0;
            partial = value.data!.partial ?? 0;
            rejected = value.data!.rejected ?? 0;
            data = [];
          });
        }
      } else if (value != null && value.isSuccess == false) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            "${S.of(context).failedFetchDashboard}: ${value.message ?? S.of(context).unKnownError}",
          );
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, S.of(context).noDashboardDataAvailable);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, S.of(context).failedFetchDashboardTryAgain);
      }
    } finally {
      if (mounted) {
        setState(() {
          loader = false;
        });
      }
    }
  }

  void _openRemarksDialog() async {
    if (dataProject.isEmpty) {
      AppSnackBar.showError(context, S.of(context).noProjectsAvailable);
      return;
    }

    String? tempSelectedProjectID = _selectedProjectName;
    String? tempSelectedProjectDisplayName = _selectedProjectDisplayName;
    String searchQuery = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final filteredList = dataProject.where((opt) {
              final name = opt.projectName?.toString().toLowerCase() ?? '';
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Font.primaryColor,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).pleaseSelect,
                              style: const TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search input if multiple projects
                    if (dataProject.length > 3)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (val) {
                              setLocal(() {
                                searchQuery = val;
                              });
                            },
                            style: const TextStyle(fontSize: 13, fontFamily: "Roboto"),
                            decoration: InputDecoration(
                              hintText: "Search project...",
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500], fontFamily: "Roboto"),
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                      ),

                    // Projects list
                    Flexible(
                      child: filteredList.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                "No projects found",
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final opt = filteredList[index];
                                final isSelected = tempSelectedProjectID == opt.projectId?.toString();
                                return InkWell(
                                  onTap: () {
                                    setLocal(() {
                                      tempSelectedProjectID = opt.projectId?.toString();
                                      tempSelectedProjectDisplayName = opt.projectName?.toString();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Font.primaryColor.withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                          color: isSelected ? Font.primaryColor : Colors.grey[400],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            opt.projectName?.toString() ?? '',
                                            style: TextStyle(
                                              fontFamily: "Roboto",
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                              color: isSelected ? Font.primaryColor : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                S.of(context).cancel,
                                style: TextStyle(fontFamily: "Roboto", color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Font.primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                S.of(context).submit,
                                style: const TextStyle(fontFamily: "Roboto", color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
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
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CommonAppBar(
          title: S.of(context).dashboard,
          actions: const [CommonHomeButton()],
        ),
        body: SafeArea(
          top: false,
          child: loader
              ? const Center(
                  child: CanImageLoader(
                    spinnerSize: 54,
                    showBrand: true,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 24.0),
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateInputs(context, ref),
            const SizedBox(height: 16),
            _buildVillageDropdown(ref),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 14),
            _buildExecuteByVendor(),
            const SizedBox(height: 18),
            _buildStatusButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInputs(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildDateInputCard(
            context: context,
            label: S.of(context).startDate,
            provider: startDateProvider,
            icon: Icons.calendar_today_rounded,
            onTap: () => _pickStartDate(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateInputCard(
            context: context,
            label: S.of(context).endDate,
            provider: endDateProvider,
            icon: Icons.event_rounded,
            onTap: () => _pickEndDate(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = ref.read(startDateProvider);
    final currentEnd = ref.read(endDateProvider);

    // Max allowed date is today (cannot exceed current date)
    // If end date is set and is before today, max date is end date
    DateTime maxDate = today;
    if (currentEnd != null) {
      final endOnly = DateTime(currentEnd.year, currentEnd.month, currentEnd.day);
      if (endOnly.isBefore(today)) {
        maxDate = endOnly;
      }
    }

    DateTime initialDate = currentStart != null
        ? DateTime(currentStart.year, currentStart.month, currentStart.day)
        : today;
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }
    if (initialDate.isBefore(DateTime(2020))) {
      initialDate = DateTime(2020);
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Font.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Font.neutralDarkColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      ref.read(startDateProvider.notifier).state = selectedDate;
      // If end date is earlier than the selected start date, sync end date to match start date
      if (currentEnd != null && currentEnd.isBefore(selectedDate)) {
        ref.read(endDateProvider.notifier).state = selectedDate;
      }
    }
  }

  Future<void> _pickEndDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = ref.read(startDateProvider);
    final currentEnd = ref.read(endDateProvider);

    // Min date for end date is start date (or 2020)
    DateTime minDate = DateTime(2020);
    if (currentStart != null) {
      minDate = DateTime(currentStart.year, currentStart.month, currentStart.day);
      if (minDate.isAfter(today)) {
        minDate = today;
      }
    }

    DateTime initialDate = currentEnd != null
        ? DateTime(currentEnd.year, currentEnd.month, currentEnd.day)
        : today;
    if (initialDate.isAfter(today)) {
      initialDate = today;
    }
    if (initialDate.isBefore(minDate)) {
      initialDate = minDate;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: today, // Cannot exceed today (current date)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Font.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Font.neutralDarkColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      ref.read(endDateProvider.notifier).state = selectedDate;
    }
  }

  Widget _buildDateInputCard({
    required BuildContext context,
    required String label,
    required StateProvider<DateTime?> provider,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final date = ref.watch(provider);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Font.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Font.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      fontFamily: "Roboto",
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : S.of(context).selectDate,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Roboto",
                    ),
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
    return InkWell(
      onTap: _openRemarksDialog,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Font.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 18,
                color: Font.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Project",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontFamily: "Roboto",
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selectedProjectDisplayName ?? S.of(context).pleaseSelect,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedProjectDisplayName != null ? FontWeight.w600 : FontWeight.w400,
                      color: _selectedProjectDisplayName != null ? const Color(0xFF1E293B) : Colors.grey[500],
                      fontFamily: "Roboto",
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Font.primaryColor, const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Font.primaryColor.withOpacity(0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitForm,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loader) ...[
                  const CanImageSpinner(
                    size: 18,
                    primaryColor: Colors.white70,
                    accentColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  loader ? S.of(context).loading : S.of(context).submit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    final startDate = ref.read(startDateProvider);
    final endDate = ref.read(endDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (startDate != null && startDate.isAfter(today)) {
      AppSnackBar.showError(context, "Start date cannot be in the future.");
      return;
    }
    if (endDate != null && endDate.isAfter(today)) {
      AppSnackBar.showError(context, "End date cannot be in the future.");
      return;
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      AppSnackBar.showError(context, "Start date cannot be after end date.");
      return;
    }

    if (startDate != null && endDate != null && _selectedProjectName != null) {
      String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
      fetchDashboardSummary(formattedStartDate, formattedEndDate, _selectedProjectName!);
    } else {
      AppSnackBar.showError(context, S.of(context).pleaseStartEndDates);
    }
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: S.of(context).printsCaptured,
            count: totalPrints ?? 0,
            icon: Icons.camera_alt_rounded,
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: S.of(context).printsUploaded,
            count: printsUploaded ?? 0,
            icon: Icons.cloud_done_rounded,
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic count,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontFamily: "Roboto",
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteByVendor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Font.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.domain_rounded,
              size: 20,
              color: Font.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).rawHold,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontFamily: "Roboto",
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Font.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$executedByVendorRaw',
              style: TextStyle(
                color: Font.primaryColor,
                fontSize: 16,
                fontFamily: "Roboto",
                fontWeight: FontWeight.w800,
              ),
            ),
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
            context: context,
            ref: ref,
            status: S.of(context).approved,
            count: approved ?? 0,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            icon: Icons.check_circle_rounded,
            type: 'Approved',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusButton(
            context: context,
            ref: ref,
            status: S.of(context).partial,
            count: partial ?? 0,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            icon: Icons.access_time_filled_rounded,
            type: 'Partial',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusButton(
            context: context,
            ref: ref,
            status: S.of(context).rejected,
            count: rejected ?? 0,
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            icon: Icons.cancel_rounded,
            type: 'Rejected',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required WidgetRef ref,
    required String status,
    required dynamic count,
    required List<Color> gradient,
    required IconData icon,
    required String type,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusPopup(context, ref, status, type),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "Roboto",
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "View",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 9,
                        fontFamily: "Roboto",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 8,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusPopup(BuildContext context, WidgetRef ref, String status, String type) async {
    Color statusColor;
    List<Color> headerGradient;

    switch (type) {
      case 'Approved':
        statusColor = const Color(0xFF10B981);
        headerGradient = const [Color(0xFF15803D), Color(0xFF16A34A)];
        break;
      case 'Partial':
        statusColor = const Color(0xFFF59E0B);
        headerGradient = const [Color(0xFFD97706), Color(0xFFF59E0B)];
        break;
      case 'Rejected':
        statusColor = const Color(0xFFEF4444);
        headerGradient = const [Color(0xFFB91C1C), Color(0xFFDC2626)];
        break;
      default:
        statusColor = Font.primaryColor;
        headerGradient = [Font.primaryColor, Font.primaryColor];
        break;
    }

    List<DataDashboard> recordsToDisplay = [];

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: CanImageLoader(
              spinnerSize: 52,
              showBrand: true,
              message: '${S.of(context).loadingDashboard} $status ${S.of(context).recordsDashboard}...',
            ),
          ),
        );
      },
    );

    try {
      final startDate = ref.read(startDateProvider);
      final endDate = ref.read(endDateProvider);
      final selectedProjectName = _selectedProjectName;

      if (startDate != null && endDate != null && selectedProjectName != null) {
        String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
        String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

        final dashboardData = await Auth().fetchExecutionDashboardSummaryDetails(
          type,
          formattedStartDate,
          formattedEndDate,
          selectedProjectName,
        );

        recordsToDisplay = dashboardData?.data ?? [];
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch data. Please try again.");
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return;

    // Status records dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header with status gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: headerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(type),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$status Records',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${recordsToDisplay.length} total records',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Font.primaryColor,
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell("Can Id", flex: 2),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildHeaderCell(S.of(context).printName, flex: 3),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildHeaderCell(S.of(context).status, flex: 2),
                      Container(width: 1, height: 20, color: Colors.white24),
                      _buildHeaderCell(S.of(context).remarks, flex: 2),
                    ],
                  ),
                ),

                // Table Data / Empty State
                Expanded(
                  child: recordsToDisplay.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${S.of(context).noDashboard} $status ${S.of(context).recordsFound}',
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontFamily: "Roboto",
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No records available for the selected dates and project.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontFamily: "Roboto",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: recordsToDisplay.length,
                          itemBuilder: (context, index) {
                            final item = recordsToDisplay[index];
                            final isEven = index % 2 == 0;
                            return Container(
                              color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Can Id
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        child: Text(
                                          item.canId?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontFamily: "Roboto",
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: Color(0xFF1E293B),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),

                                    // Print Name
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        child: Text(
                                          item.printName?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontFamily: "Roboto",
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                            color: Color(0xFF334155),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),

                                    // Status Pill
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item.status?.toString() ?? '-',
                                            style: TextStyle(
                                              fontFamily: "Roboto",
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                              color: statusColor,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),

                                    // Remarks
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        child: Text(
                                          item.remarks?.toString().isNotEmpty == true
                                              ? item.remarks.toString()
                                              : '-',
                                          style: TextStyle(
                                            fontFamily: "Roboto",
                                            fontWeight: FontWeight.w400,
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${S.of(context).total} ${recordsToDisplay.length} ${S.of(context).recordsFound}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Roboto",
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
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

  Widget _buildHeaderCell(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: "Roboto",
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  IconData _getStatusIcon(String type) {
    switch (type) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Partial':
        return Icons.access_time_filled_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}