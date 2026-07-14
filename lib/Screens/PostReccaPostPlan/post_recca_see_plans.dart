import 'package:canimage/Repository/postRecca_balance_count_change_repository.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Hive_Database/post_recca_seePlan_db.dart';
import '../../Provider/can_image_provider.dart';
import '../../Repository/completed_upload_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../Repository/remarks_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import 'post_recca_Sub_see_maps.dart';

final currentScreenProvider = StateProvider<String>((ref) => 'suplans');
final suOfflineCountRefreshProvider = StateProvider<int>((ref) => 0);

class SUSeePlanScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const SUSeePlanScreen({super.key, required this.changeLanguage});
  @override
  _SUSeePlanScreenState createState() => _SUSeePlanScreenState();
}

class _SUSeePlanScreenState extends ConsumerState<SUSeePlanScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  final Map<String, bool> _expandedGroups = {};
  final Map<String, int> _offlineCountCache = {};
  Map<String, Map<String, dynamic>>? _processedGroupedPlans;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _offlineCountCache.clear();
    });
  }

  Future<void> _refreshPlans() async {
    try {
      final uploadRepository = PostReccaImageUploadHiveRepository();
      final pendingUploads = await uploadRepository.getAllMetadata();

      if (pendingUploads.isNotEmpty) {
        if (mounted) {
          _showPendingSyncDialog(pendingUploads.length);
        }
        return;
      }

      ref.read(isRefreshingProvider.notifier).state = true;

      await CompletedUploadRepository().clearAll();
      print('Cleared completed uploads - fresh start');
      await ref.refresh(reloadSUPlansProvider(true).future);
      await CountChangeHiveRepository().clearAllOfflineCounts();

      ref.read(suOfflineCountRefreshProvider.notifier).state++;
      _offlineCountCache.clear();
      _processedGroupedPlans = null;

      final plansAsyncValue = ref.read(plansSUProvider);

      plansAsyncValue.when(
        data: (refreshedPlans) {
          if (refreshedPlans == "null" || refreshedPlans.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text(S.of(context).noDataFound, style: TextStyle(fontFamily: "Roboto")),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(S.of(context).reccaPlan, style: TextStyle(fontFamily: "Roboto")),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        loading: () {},
        error: (error, stackTrace) {},
      );
    } catch (e) {
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
      if (mounted) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }

  void _showPendingSyncDialog(int pendingCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).pendingUploads,
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).youhave} $pendingCount ${S.of(context).pendingSynced}',
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context).pleaseSyncAllPending,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkRemarksAvailability() async {
    try {
      final remarks = await RemarksHiveRepository().loadRemarks();
      return remarks.isNotEmpty;
    } catch (e) {
      print('Error checking remarks: $e');
      return false;
    }
  }

  void _onGroupRowClick(List<SUPlanModel> group) async {
    final remarksAvailable = await _checkRemarksAvailability();

    if (!remarksAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).pleaseSyncAllPending,
                  style: TextStyle(fontFamily: "Roboto", fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: S.of(context).reload,
            textColor: Colors.white,
            onPressed: () {
              _refreshPlans();
            },
          ),
        ),
      );
      _showRemarksEmptyDialog();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SUSubMapScreen(
          groupedPlans: group,
          changeLanguage: widget.changeLanguage,
        ),
      ),
    );

    _offlineCountCache.clear();
    _processedGroupedPlans = null;
    ref.read(suOfflineCountRefreshProvider.notifier).state++;
    setState(() {});
  }

  void _showRemarksEmptyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).remarksNotAvailable,
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).remarksDataRequiredProceed,
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context).willRefreshAllPlans,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 12,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.refresh, size: 18),
              label: Text(
                S.of(context).reloadPlans,
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
    );
    return false;
  }

  Future<int> _getCachedOfflineCount(String groupKey, SUPlanModel firstPlan) async {
    if (_offlineCountCache.containsKey(groupKey)) {
      return _offlineCountCache[groupKey]!;
    }

    final count = await CountChangeHiveRepository().getOfflineCountForGroup(
      firstPlan.planCode,
      firstPlan.villageCode,
      firstPlan.villageName,
      firstPlan.tehsil,
    );

    _offlineCountCache[groupKey] = count;
    return count;
  }

  // NEW: Process plans with hierarchical structure (project-plan grouping)
  Map<String, Map<String, dynamic>> _processPlansData(List<SUPlanModel> plans) {
    final projectPlanGroups = <String, Map<String, dynamic>>{};

    for (var plan in plans) {
      // Assuming SUPlanModel has a projectName field. If not, you can use planCode as the project identifier
      // If there's no projectName, use planCode as both project and plan identifier
      final projectPlanKey = plan.planCode; // Adjust if you have separate projectName field

      if (!projectPlanGroups.containsKey(projectPlanKey)) {
        projectPlanGroups[projectPlanKey] = {
          'planCode': plan.planCode,
          'villageGroups': <String, Map<String, dynamic>>{},
          'totalBalance': 0,
          'projectName': plan.projectName ,
        };
      }

      final villageKey = '${plan.planCode}_${plan.villageCode}_${plan.villageName}_${plan.tehsil}';

      if (!projectPlanGroups[projectPlanKey]!['villageGroups'].containsKey(villageKey)) {
        projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey] = {
          'plans': <SUPlanModel>[],
          'totalBalance': 0,
        };
      }

      projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey]['plans'].add(plan);
      projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey]['totalBalance']++;
      projectPlanGroups[projectPlanKey]!['totalBalance']++;
    }

    projectPlanGroups.removeWhere((key, group) => (group['totalBalance'] as int) <= 0);
    return projectPlanGroups;
  }

  // NEW: Apply search filter on hierarchical structure
  Map<String, Map<String, dynamic>> _applySearchFilter(
      Map<String, Map<String, dynamic>> groupedPlans, String query) {
    if (query.isEmpty) return groupedPlans;

    final lowercaseQuery = query.toLowerCase();
    Map<String, Map<String, dynamic>> result = {};

    for (var entry in groupedPlans.entries) {
      final projectPlanKey = entry.key;
      final projectPlanData = entry.value;
      final planCode = (projectPlanData['planCode'] as String).toLowerCase();
      final allVillageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;

      final planMatches = planCode.contains(lowercaseQuery);

      if (planMatches) {
        result[projectPlanKey] = projectPlanData;
      } else {
        Map<String, Map<String, dynamic>> matchingVillages = {};
        int totalFilteredBalance = 0;

        for (var villageEntry in allVillageGroups.entries) {
          final villageKey = villageEntry.key;
          final villageData = villageEntry.value;
          final groupPlans = villageData['plans'] as List<SUPlanModel>;

          final villageMatches = groupPlans.any((plan) =>
          (plan.villageCode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (plan.villageName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (plan.tehsil?.toLowerCase().contains(lowercaseQuery) ?? false));

          if (villageMatches) {
            matchingVillages[villageKey] = villageData;
            totalFilteredBalance += villageData['totalBalance'] as int;
          }
        }

        if (matchingVillages.isNotEmpty) {
          result[projectPlanKey] = {
            'planCode': projectPlanData['planCode'],
            'villageGroups': matchingVillages,
            'totalBalance': totalFilteredBalance,
            'projectName': projectPlanData['projectName'],
          };
        }
      }
    }

    return result;
  }

  // NEW: Build hierarchical list with collapsible plan groups
  Widget _buildHierarchicalList(Map<String, Map<String, dynamic>> displayPlans) {
    final projectPlanKeys = displayPlans.keys.toList();
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return ListView.builder(
      controller: _scrollController,
      itemCount: projectPlanKeys.length,
      itemBuilder: (context, index) {
        final projectPlanKey = projectPlanKeys[index];
        final projectPlanData = displayPlans[projectPlanKey]!;
        final planCode = projectPlanData['planCode'] as String;
        final projectName = projectPlanData['projectName'] as String;
        final villageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;
        final totalBalance = projectPlanData['totalBalance'] as int;

        final isExpanded = _expandedGroups[projectPlanKey] ?? true;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // PLAN HEADER
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedGroups[projectPlanKey] = !isExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Font.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                      bottom: isExpanded ? Radius.zero : Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        color: Font.primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$projectName - $planCode',
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Font.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${villageGroups.length} village(s) • Balance: $totalBalance',
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // VILLAGE TABLE
              if (isExpanded)
                Column(
                  children: [
                    // Header
                    Container(
                      color: Font.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 12,
                        vertical: isTablet ? 12 : 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 15, child: Text(S.of(context).villageCodePost, style: TextstyleGlobal.tableHeaderTextStyle)),
                          Expanded(flex: 30, child: Text(S.of(context).villageNameMap, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                          Expanded(flex: 25, child: Text(S.of(context).tehsil, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                          Expanded(flex: 20, child: Text(S.of(context).balance, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // Rows
                    ...villageGroups.entries.map((villageEntry) {
                      final villageKey = villageEntry.key;
                      final villageData = villageEntry.value;
                      final groupPlans = villageData['plans'] as List<SUPlanModel>;
                      final totalBalance = villageData['totalBalance'] as int;
                      final firstPlan = groupPlans[0];
                      final villageIndex = villageGroups.keys.toList().indexOf(villageKey);

                      return InkWell(
                        onTap: () => _onGroupRowClick(groupPlans),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                            color: villageIndex % 2 == 0 ? Colors.white : Colors.grey[50],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 12,
                            vertical: isTablet ? 14 : 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 15,
                                child: Text(
                                  firstPlan.villageCode,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Expanded(
                                flex: 30,
                                child: Text(
                                  firstPlan.villageName,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Expanded(
                                flex: 25,
                                child: Text(
                                  firstPlan.tehsil,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Expanded(
                                flex: 20,
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    ref.watch(suOfflineCountRefreshProvider);
                                    final isRefreshing = ref.watch(isRefreshingProvider);

                                    return FutureBuilder<int>(
                                      key: ValueKey('${villageKey}_${ref.watch(suOfflineCountRefreshProvider)}_$isRefreshing'),
                                      future: _getCachedOfflineCount(villageKey, firstPlan),
                                      builder: (context, snapshot) {
                                        int offlineCount = snapshot.data ?? 0;
                                        int displayBalance = totalBalance - offlineCount;

                                        if (isRefreshing && displayBalance <= 0) {
                                          return SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          );
                                        }

                                        return Text(
                                          '$displayBalance',
                                          style: TextstyleGlobal.bodyTextStyleSeeplan.copyWith(
                                            color: Font.neutralDarkColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, Map<String, dynamic>>> _filterGroupsWithDisplayBalance(
      Map<String, Map<String, dynamic>> groupedPlans) async {
    Map<String, Map<String, dynamic>> filteredGroups = {};

    for (var entry in groupedPlans.entries) {
      final projectPlanKey = entry.key;
      final projectPlanData = entry.value;
      final villageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;

      int totalDisplayBalance = 0;
      Map<String, Map<String, dynamic>> filteredVillageGroups = {};

      for (var villageEntry in villageGroups.entries) {
        final villageKey = villageEntry.key;
        final villageData = villageEntry.value;
        final totalBalance = villageData['totalBalance'] as int;
        final groupPlans = villageData['plans'] as List<SUPlanModel>;
        final firstPlan = groupPlans[0];

        if (totalBalance <= 0) continue;

        int offlineCount = await _getCachedOfflineCount(villageKey, firstPlan);
        int displayBalance = totalBalance - offlineCount;

        if (displayBalance > 0) {
          filteredVillageGroups[villageKey] = villageData;
          totalDisplayBalance += displayBalance;
        }
      }

      if (totalDisplayBalance > 0) {
        filteredGroups[projectPlanKey] = {
          'planCode': projectPlanData['planCode'],
          'villageGroups': filteredVillageGroups,
          'totalBalance': totalDisplayBalance,
          'projectName': projectPlanData['projectName'],
        };
      }
    }

    return filteredGroups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansState = ref.watch(plansSUProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);
    final suOfflineCountRefresh = ref.watch(suOfflineCountRefreshProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
              S.of(context).reccaPlanTitle,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Roboto"),
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Font.pureWhiteColor, Font.pureWhiteColor, Font.pureWhiteColor],
              ),
            ),
            child: Column(
              children: [
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
                              prefixIcon: Icon(Icons.search_sharp, color: Font.primaryLightColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Font.primaryLightColor),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              hintText: S.of(context).search,
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: "Roboto"),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Font.primaryLightColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: isRefreshing ? null : _refreshPlans,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isRefreshing ? Colors.grey : Font.accentColor,
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
                                    fontFamily: "Roboto"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: plansState.when(
                    data: (plans) {
                      if (_processedGroupedPlans == null) {
                        _processedGroupedPlans = _processPlansData(plans);
                      }

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        key: ValueKey('${_processedGroupedPlans!.length}_${suOfflineCountRefresh}_${isRefreshing}_$_searchQuery'),
                        future: _filterGroupsWithDisplayBalance(_processedGroupedPlans!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.red, fontFamily: "Roboto"),
                              ),
                            );
                          }

                          final balanceFilteredPlans = snapshot.data ?? {};
                          final searchFilteredPlans = _applySearchFilter(balanceFilteredPlans, _searchQuery);

                          if (searchFilteredPlans.isEmpty && _searchQuery.isNotEmpty) {
                            return _buildNoResultsWidget();
                          }

                          if (searchFilteredPlans.isEmpty) {
                            return _buildNoPlansWidget();
                          }

                          return Column(
                            children: [
                              if (_searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${S.of(context).showing} ${searchFilteredPlans.length} ${S.of(context).results}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily: "Roboto",
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(child: _buildHierarchicalList(searchFilteredPlans)),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, stack) => _buildErrorWidget(e),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '${S.of(context).noPlanFound} "${_searchQuery}"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: "Roboto"),
          ),
          SizedBox(height: 8),
          Text(
            S.of(context).trySearching,
            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: "Roboto"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlansWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(S.of(context).noPlanFound, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: "Roboto")),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _processedGroupedPlans = null;
                _offlineCountCache.clear();
              });
              ref.invalidate(plansSUProvider);
            },
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text(S.of(context).retry, style: TextStyle(color: Colors.white, fontFamily: "Roboto")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Font.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object e) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getErrorIcon(e.toString()), size: 80, color: _getErrorColor(e.toString())),
              SizedBox(height: 24),
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
              Text(
                e.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: "Roboto"),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _processedGroupedPlans = null;
                        _offlineCountCache.clear();
                      });
                      ref.invalidate(plansSUProvider);
                    },
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      S.of(context).retry,
                      style: TextStyle(color: Colors.white, fontFamily: "Roboto", fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Font.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (e.toString().contains(S.of(context).pleaseContact))
                    ElevatedButton.icon(
                      onPressed: () => _showContactAdminDialog(context),
                      icon: Icon(Icons.support_agent, color: Colors.white),
                      label: Text(
                        S.of(context).contactAdmin,
                        style: TextStyle(color: Colors.white, fontFamily: "Roboto", fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
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
            style: TextStyle(fontFamily: "Roboto", fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${S.of(context).serverErrorOccured}:', style: TextStyle(fontFamily: "Roboto")),
              SizedBox(height: 16),
              Text(S.of(context).errorType, style: TextStyle(fontFamily: "Roboto", fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                '${S.of(context).time}: ${DateTime.now().toString()}',
                style: TextStyle(fontFamily: "Roboto", fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                S.of(context).ok,
                style: TextStyle(fontFamily: "Roboto", color: Color(0xFF0056A4), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}