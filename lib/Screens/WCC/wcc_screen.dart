import 'package:canimage/Repository/postRecca_balance_count_change_repository.dart';
import 'package:canimage/Screens/WCC/wcc_upload_scren.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Hive_Database/post_recca_seePlan_db.dart';
import '../../Provider/can_image_provider.dart';
import '../../generated/l10n.dart';
import '../PostReccaPostPlan/post_recca_Sub_see_maps.dart';


// Color Palette
final Color primaryColor = Color(0xFF0056A4);
final Color primaryLightColor = Color(0xFF00AEEF);
final Color accentColor = Color(0xFF5BBAD5);
final Color neutralDarkColor = Color(0xFF2D2D2D);
final Color neutralLightColor = Color(0xFFF4F4F4);
final Color pureWhiteColor = Color(0xFFFFFFFF);
final currentScreenProvider = StateProvider<String>((ref) => 'plans');

// Font Styles
final TextStyle headerTextStyle = TextStyle(
  color: primaryColor,
  fontSize: 25,
  fontWeight: FontWeight.w600,
  fontFamily: "Roboto",
);

final TextStyle bodyTextStyle = TextStyle(
  color: neutralDarkColor,
  fontSize: 10,
  fontWeight: FontWeight.w500,
  fontFamily: "Roboto",
);

final TextStyle labelTextStyle = TextStyle(
  color: primaryLightColor,
  fontWeight: FontWeight.w500,
  fontFamily: "Roboto",
);

final TextStyle buttonTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  fontFamily: 'Roboto',
);

final TextStyle tableHeaderTextStyle = TextStyle(
  color: pureWhiteColor,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  fontFamily: "Roboto",
);

class WCCSeePlanScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const WCCSeePlanScreen({super.key, required this.changeLanguage});
  @override
  _WCCSeePlanScreenState createState() => _WCCSeePlanScreenState();
}

class _WCCSeePlanScreenState extends ConsumerState<WCCSeePlanScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method to filter grouped plans based on search query
  Map<String, List<SUPlanModel>> _filterGroupedPlans(Map<String, List<SUPlanModel>> groupedPlans, String query) {
    if (query.isEmpty) {
      return groupedPlans;
    }

    final lowercaseQuery = query.toLowerCase();
    Map<String, List<SUPlanModel>> filteredGroups = {};

    groupedPlans.forEach((key, group) {
      // Check if any plan in the group matches the search query
      bool groupMatches = group.any((plan) {
        final planCode = plan.planCode?.toLowerCase() ?? '';
        final villageCode = plan.villageCode?.toLowerCase() ?? '';
        final villageName = plan.villageName?.toLowerCase() ?? '';
        final tehsil = plan.tehsil?.toLowerCase() ?? '';

        return planCode.contains(lowercaseQuery) ||
            villageCode.contains(lowercaseQuery) ||
            villageName.contains(lowercaseQuery) ||
            tehsil.contains(lowercaseQuery);
      });

      if (groupMatches) {
        filteredGroups[key] = group;
      }
    });

    return filteredGroups;
  }

  // Method to clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  // Updated refresh method
  Future<void> _refreshPlans() async {
    try {
      // Set refreshing state
      ref.read(isRefreshingProvider.notifier).state = true;

      // Call the reload provider with force reload parameter
      await ref.refresh(reloadSUPlansProvider(true).future);


      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(S.of(context).reccaPlan, style: TextStyle(fontFamily: "Roboto")),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).failedRecca}: $e', style: TextStyle(fontFamily: "Roboto")),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset refreshing state
      if (mounted) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }

  // Handle click on grouped row
  void _onGroupRowClick(List<SUPlanModel> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WCCUploadSeePlanScreen(projectID: '', villageName: '', brand: '', width: '', height: '', printNo: '', printId: '', villageCode: '', planCode: '', tensil: '', changeLanguage: widget.changeLanguage,

        ),
      ),
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
    final theme = Theme.of(context);
    final plansState = ref.watch(plansSUProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);
    final currentScreen = ref.watch(currentScreenProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            title: Text(
              S.of(context).reccaPlanTitle,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Roboto"
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  // Info action
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pureWhiteColor, pureWhiteColor, pureWhiteColor],
              ),
            ),
            child: Column(
              children: [
                // Search field and reload button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_sharp, color: primaryLightColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: primaryLightColor),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              hintText: S.of(context).search,
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: "Roboto",
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: primaryLightColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Roboto",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: isRefreshing ? null : _refreshPlans,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isRefreshing ? Colors.grey : primaryLightColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isRefreshing) ...[
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                              Text(
                                isRefreshing ? S.of(context).loading : S.of(context).reload,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: "Roboto"
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Table with proper scrolling
                Expanded(
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                            ),
                            child: plansState.when(
                              data: (plans) {
                                var groupedPlans = <String, List<SUPlanModel>>{};

                                for (var plan in plans) {
                                  print(plan.planCode);
                                  print("plan.planCode");
                                  // Create a unique key for grouping
                                  String key = '${plan.planCode}_${plan.villageCode}_${plan.villageName}_${plan.tehsil}';

                                  // Add to the group
                                  if (!groupedPlans.containsKey(key)) {
                                    groupedPlans[key] = [];
                                  }
                                  groupedPlans[key]!.add(plan);
                                }

                                // Filter grouped plans based on search query
                                final filteredGroupedPlans = _filterGroupedPlans(groupedPlans, _searchQuery);

                                // Show message when no results found
                                if (filteredGroupedPlans.isEmpty && _searchQuery.isNotEmpty) {
                                  return Container(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 60,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            '${S.of(context).noPlanFound} "${_searchQuery}"',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontFamily: "Roboto",
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            S.of(context).trySearching,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontFamily: "Roboto",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Create rows with summed balances
                                List<DataRow> rows = [];

                                filteredGroupedPlans.forEach((key, group) {
                                  // Sum the noOfBalance for this group
                                  int groupCount = group.length;

                                  // Add a row with the total balance
                                  rows.add(DataRow(
                                      cells: [
                                        DataCell(InkWell(
                                          onTap: (){
                                            _onGroupRowClick(group);
                                          },
                                          child: Container(
                                            width: 60,
                                            child: Text(group[0].planCode,
                                              maxLines: 10,
                                              softWrap: true,
                                              style: bodyTextStyle,
                                              // textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )),
                                        DataCell(InkWell(
                                          onTap: (){
                                            _onGroupRowClick(group);
                                          },
                                          child: Container(
                                            width: 60,
                                            child: Text(group[0].villageCode,
                                              maxLines: 10,
                                              softWrap: true,
                                              style: bodyTextStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )),
                                        DataCell(InkWell(
                                          onTap: (){
                                            _onGroupRowClick(group);
                                          },
                                          child: Container(
                                            width: 60,
                                            child: Text(group[0].villageName,
                                              maxLines: 10,
                                              softWrap: true,
                                              style: bodyTextStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )),
                                        DataCell(InkWell(
                                          onTap: (){
                                            _onGroupRowClick(group);
                                          },
                                          child: Container(
                                            width: 60,
                                            child: Text(group[0].tehsil,
                                              maxLines: 10,
                                              softWrap: true,
                                              style: bodyTextStyle,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )),
                                        // Sum of noOfBalance
                                        DataCell(InkWell(
                                          onTap: () => _onGroupRowClick(group),
                                          child: Container(
                                            width: 60,
                                            child: FutureBuilder<int>(
                                              future: CountChangeHiveRepository().getOfflineCountForGroup(
                                                group[0].planCode,
                                                group[0].villageCode,
                                                group[0].villageName,
                                                group[0].tehsil,
                                              ),
                                              builder: (context, snapshot) {
                                                int offlineCount = snapshot.data ?? 0;
                                                int adjustedCount = isRefreshing ? groupCount : groupCount - offlineCount;

                                                return Text(
                                                  '$adjustedCount',
                                                  maxLines: 10,
                                                  softWrap: true,
                                                  style: bodyTextStyle.copyWith(
                                                    color: neutralDarkColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                );
                                              },
                                            ),
                                          ),
                                        )),
                                      ]
                                  ));
                                });

                                return Column(
                                  children: [
                                    // Show search results count
                                    if (_searchQuery.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${S.of(context).showing} ${filteredGroupedPlans.length} ${S.of(context).ofText} ${groupedPlans.length} plan groups',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: "Roboto",
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    DataTable(
                                        dataRowMaxHeight: double.infinity,
                                        headingRowColor: MaterialStateProperty.all(primaryColor),
                                        headingTextStyle: tableHeaderTextStyle,
                                        headingRowHeight: 40,
                                        dataTextStyle: bodyTextStyle,
                                        showCheckboxColumn: true,
                                        showBottomBorder: true,
                                        columnSpacing: 10,
                                        columns: [
                                          DataColumn(
                                            label: Container(
                                              width: 60,
                                              child: Text(S.of(context).planTab,
                                                style: tableHeaderTextStyle,
                                                // textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Container(
                                              width: 60,
                                              child: Text(S.of(context).villageCode,
                                                style: tableHeaderTextStyle,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Container(
                                              width: 60,
                                              child: Text(S.of(context).villageName,
                                                style: tableHeaderTextStyle,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Container(
                                              width: 60,
                                              child: Text(S.of(context).cdBlock,
                                                style: tableHeaderTextStyle,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Container(
                                              width: 60,
                                              child: Text(S.of(context).balance,
                                                style: tableHeaderTextStyle,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: rows
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, stack) => Container(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Error icon based on error type
                                        Icon(
                                          _getErrorIcon(e.toString()),
                                          size: 80,
                                          color: _getErrorColor(e.toString()),
                                        ),
                                        SizedBox(height: 24),

                                        // Error title
                                        Text(
                                          _getErrorTitle(e.toString()),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: _getErrorColor(e.toString()),
                                            fontFamily: "Roboto",
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 12),

                                        // Error message
                                        Text(
                                          e.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontFamily: "Roboto",
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 24),

                                        // Action buttons
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Retry button (always available)
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                ref.invalidate(plansSUProvider);
                                              },
                                              icon: Icon(Icons.refresh, color: Colors.white),
                                              label: Text(
                                                S.of(context).retry,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "Roboto",
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),

                                            // Contact admin button (only for 500 errors)
                                            if (e.toString().contains(S.of(context).pleaseContact))
                                              SizedBox(width: 12),
                                            if (e.toString().contains(S.of(context).pleaseContact))
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  // You can implement your contact admin functionality here
                                                  _showContactAdminDialog(context);
                                                },
                                                icon: Icon(Icons.support_agent, color: Colors.white),
                                                label: Text(
                                                  S.of(context).contactAdmin,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: "Roboto",
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red[600],
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  IconData _getErrorIcon(String error) {
    if (error.contains('Network error') || error.contains('internet connection')) {
      return Icons.wifi_off;
    } else if (error.contains('Authentication failed') || error.contains('Unauthorized')) {
      return Icons.lock_outline;
    } else if (error.contains('Please contact admin') || error.contains('Internal Server Error')) {
      return Icons.error_outline;
    } else if (error.contains('No data found')) {
      return Icons.inbox_outlined;
    } else {
      return Icons.warning_amber_outlined;
    }
  }
  Color _getErrorColor(String error) {
    if (error.contains('Network error') || error.contains('internet connection')) {
      return Colors.orange[600]!;
    } else if (error.contains('Authentication failed') || error.contains('Unauthorized')) {
      return Colors.blue[600]!;
    } else if (error.contains('Please contact admin') || error.contains('Internal Server Error')) {
      return Colors.red[600]!;
    } else if (error.contains('No data found')) {
      return Colors.grey[600]!;
    } else {
      return Colors.amber[600]!;
    }
  }

  String _getErrorTitle(String error) {
    if (error.contains('Network error') || error.contains('internet connection')) {
      return S.of(context).connectionProblem;
    } else if (error.contains('Authentication failed') || error.contains('Unauthorized')) {
      return S.of(context).authenticationRequired;
    } else if (error.contains('Please contact admin') || error.contains('Internal Server Error')) {
      return S.of(context).serverIssue;
    } else if (error.contains('No data found')) {
      return S.of(context).noDataAvaiable;
    } else {
      return S.of(context).somethingWentWrong;
    }
  }

  void _showContactAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            S.of(context).contactAdministrator,
            style: TextStyle(
              fontFamily: "Roboto",
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).serverErrorOccured}:',
                style: TextStyle(fontFamily: "Roboto"),
              ),
              SizedBox(height: 16),
              Text(
                S.of(context).errorType,
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${S.of(context).time}: ${DateTime.now().toString()}',
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Color(0xFF0056A4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}