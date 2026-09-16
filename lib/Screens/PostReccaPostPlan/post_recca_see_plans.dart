import 'package:canimage/Repository/postRecca_balance_count_change_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Hive_Database/post_recca_seePlan_db.dart';
import '../../Provider/can_image_provider.dart';
import '../../Repository/completed_upload_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../Repository/remarks_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';
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
  final Set<String> _showAllVillagesInPlan = {};
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
      final _ = await ref.refresh(reloadSUPlansProvider(true).future);
      await CountChangeHiveRepository().clearAllOfflineCounts();

      ref.read(suOfflineCountRefreshProvider.notifier).state++;
      _offlineCountCache.clear();
      _processedGroupedPlans = null;

      final plansAsyncValue = ref.read(plansSUProvider);

      plansAsyncValue.when(
        data: (refreshedPlans) {
          if (refreshedPlans.isEmpty) {
            if (mounted) {
              AppSnackBar.showError(
                context,
                S.of(context).noDataFound,
              );
            }
          } else {
            if (mounted) {
              AppSnackBar.showSuccess(
                context,
                S.of(context).reccaPlan,
              );
            }
          }
        },
        loading: () {},
        error: (error, stackTrace) {},
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          '${S.of(context).failedRecca}: $e',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_rounded, color: Colors.orange[800], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).pendingUploads,
                  style: const TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
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
                style: const TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        S.of(context).pleaseSyncAllPending,
                        style: const TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 12.5,
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w700,
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
      return false;
    }
  }

  void _onGroupRowClick(List<SUPlanModel> group) async {
    final remarksAvailable = await _checkRemarksAvailability();

    if (!remarksAvailable) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          S.of(context).pleaseSyncAllPending,
        );
        _showRemarksEmptyDialog();
      }
      return;
    }

    if (!mounted) return;
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
    if (mounted) {
      setState(() {});
    }
  }

  void _showRemarksEmptyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).remarksNotAvailable,
                  style: const TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
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
                style: const TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        S.of(context).willRefreshAllPlans,
                        style: const TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 12.5,
                          color: Color(0xFF9A3412),
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
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                S.of(context).reloadPlans,
                style: const TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
      return false;
    }
  }

  // Fast single-pass grouping for 5000+ items
  Map<String, Map<String, dynamic>> _processPlansData(List<SUPlanModel> plans) {
    final projectPlanGroups = <String, Map<String, dynamic>>{};

    for (var plan in plans) {
      final projectPlanKey = plan.planCode;

      if (!projectPlanGroups.containsKey(projectPlanKey)) {
        projectPlanGroups[projectPlanKey] = {
          'planCode': plan.planCode,
          'villageGroups': <String, Map<String, dynamic>>{},
          'totalBalance': 0,
          'projectName': plan.projectName,
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

  // High performance batch balance calculation
  Future<Map<String, Map<String, dynamic>>> _filterGroupsWithDisplayBalance(
      Map<String, Map<String, dynamic>> groupedPlans) async {
    Map<String, Map<String, dynamic>> filteredGroups = {};

    // Single fast query for all offline counts from Hive
    final offlineCountsMap = await CountChangeHiveRepository().getAllOfflineCountsMap();
    _offlineCountCache.addAll(offlineCountsMap);

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

        if (totalBalance <= 0) continue;

        final int offlineCount = offlineCountsMap[villageKey] ?? 0;
        int displayBalance = totalBalance - offlineCount;

        if (displayBalance > 0) {
          filteredVillageGroups[villageKey] = {
            ...villageData,
            'displayBalance': displayBalance,
          };
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

  // Instant search filter
  Map<String, Map<String, dynamic>> _applySearchFilter(
      Map<String, Map<String, dynamic>> groupedPlans, String query) {
    if (query.isEmpty) return groupedPlans;

    final lowercaseQuery = query.toLowerCase().trim();
    Map<String, Map<String, dynamic>> result = {};

    for (var entry in groupedPlans.entries) {
      final projectPlanKey = entry.key;
      final projectPlanData = entry.value;
      final planCode = (projectPlanData['planCode'] as String).toLowerCase();
      final projectName = (projectPlanData['projectName'] as String).toLowerCase();
      final allVillageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;

      final planMatches = planCode.contains(lowercaseQuery) || projectName.contains(lowercaseQuery);

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
              (plan.villageCode.toLowerCase().contains(lowercaseQuery)) ||
              (plan.villageName.toLowerCase().contains(lowercaseQuery)) ||
              (plan.tehsil.toLowerCase().contains(lowercaseQuery)));

          if (villageMatches) {
            matchingVillages[villageKey] = villageData;
            totalFilteredBalance += (villageData['displayBalance'] as int? ?? villageData['totalBalance'] as int);
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

  bool _areAllExpanded(Iterable<String> keys) {
    if (keys.isEmpty) return false;
    return keys.every((k) => _expandedGroups[k] ?? false);
  }

  void _toggleExpandAll(Iterable<String> keys) {
    final willExpand = !_areAllExpanded(keys);
    setState(() {
      for (var key in keys) {
        _expandedGroups[key] = willExpand;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(plansSUProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);
    final suOfflineCountRefresh = ref.watch(suOfflineCountRefreshProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Modern clean slate-50 background
        appBar: CommonAppBar(
          title: S.of(context).reccaPlanTitle,
          onBackPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          actions: const [CommonHomeButton()],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Search & Reload Header Bar
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Roboto",
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 18,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            hintText: S.of(context).search,
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                              fontFamily: "Roboto",
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Reload Button
                    InkWell(
                      onTap: isRefreshing ? null : _refreshPlans,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isRefreshing ? const Color(0xFF94A3B8) : Font.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isRefreshing)
                              BoxShadow(
                                color: Font.primaryColor.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRefreshing) ...[
                              const CanImageSpinner(
                                size: 14,
                                primaryColor: Colors.white70,
                                accentColor: Colors.white,
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              isRefreshing ? S.of(context).loading : S.of(context).reload,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                fontFamily: "Roboto",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main List Content
              Expanded(
                child: plansState.when(
                  data: (plans) {
                    if (_processedGroupedPlans == null) {
                      _processedGroupedPlans = _processPlansData(plans);
                    }

                    return FutureBuilder<Map<String, Map<String, dynamic>>>(
                      key: ValueKey(
                        '${_processedGroupedPlans!.length}_${suOfflineCountRefresh}_${isRefreshing}_$_searchQuery',
                      ),
                      future: _filterGroupsWithDisplayBalance(_processedGroupedPlans!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CanImageLoader(
                              spinnerSize: 48,
                              showBrand: true,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red, fontFamily: "Roboto"),
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

                        return _buildHierarchicalList(searchFilteredPlans);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CanImageLoader(
                      spinnerSize: 48,
                      showBrand: true,
                    ),
                  ),
                  error: (e, stack) => _buildErrorWidget(e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern minimal summary overview bar
  Widget _buildSummaryMetricsBar(Map<String, Map<String, dynamic>> displayPlans) {
    int totalPlans = displayPlans.length;
    int totalVillages = 0;
    int totalBalance = 0;

    for (var p in displayPlans.values) {
      final vGroups = p['villageGroups'] as Map<String, dynamic>? ?? {};
      totalVillages += vGroups.length;
      totalBalance += (p['totalBalance'] as int? ?? 0);
    }

    final allExpanded = _areAllExpanded(displayPlans.keys);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stat pills wrapped in horizontal scroll to prevent overflow on any screen
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stat 1: Plans Count
                  _buildStatPill(
                    icon: Icons.layers_outlined,
                    label: '$totalPlans Plans',
                    bgColor: const Color(0xFFEFF6FF),
                    textColor: const Color(0xFF1D4ED8),
                    iconColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),

                  // Stat 2: Villages Count
                  _buildStatPill(
                    icon: Icons.holiday_village_outlined,
                    label: '$totalVillages Villages',
                    bgColor: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF334155),
                    iconColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),

                  // Stat 3: Total Balance
                  _buildStatPill(
                    icon: Icons.inventory_2_outlined,
                    label: '$totalBalance Bal',
                    bgColor: const Color(0xFFFFF7ED),
                    textColor: const Color(0xFFC2410C),
                    iconColor: const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Quick Toggle: Expand / Collapse All
          InkWell(
            onTap: () => _toggleExpandAll(displayPlans.keys),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 15,
                    color: Font.primaryColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    allExpanded ? 'Collapse' : 'Expand',
                    style: TextStyle(
                      fontFamily: "Roboto",
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Font.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Modern hierarchical list with high performance virtualization
  Widget _buildHierarchicalList(Map<String, Map<String, dynamic>> displayPlans) {
    final projectPlanKeys = displayPlans.keys.toList();

    return Column(
      children: [
        // Summary bar
        _buildSummaryMetricsBar(displayPlans),

        // Result count when searching
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${S.of(context).showing} ${displayPlans.length} matching plans',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Plans ListView with virtualization
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: projectPlanKeys.length,
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            itemBuilder: (context, index) {
              final projectPlanKey = projectPlanKeys[index];
              final projectPlanData = displayPlans[projectPlanKey]!;
              final planCode = projectPlanData['planCode'] as String;
              final projectName = projectPlanData['projectName'] as String;
              final villageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;
              final totalBalance = projectPlanData['totalBalance'] as int;

              // Collapsed by default when massive data; first item open
              final isExpanded = _expandedGroups[projectPlanKey] ?? (index == 0 && _searchQuery.isEmpty);

              return _buildPlanCard(
                projectPlanKey: projectPlanKey,
                planCode: planCode,
                projectName: projectName,
                villageGroups: villageGroups,
                totalBalance: totalBalance,
                isExpanded: isExpanded,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String projectPlanKey,
    required String planCode,
    required String projectName,
    required Map<String, Map<String, dynamic>> villageGroups,
    required int totalBalance,
    required bool isExpanded,
  }) {
    final villageEntries = villageGroups.entries.toList();
    final bool hasLargeList = villageEntries.length > 30;
    final bool isShowingAll = _showAllVillagesInPlan.contains(projectPlanKey);
    final int renderedCount = (hasLargeList && !isShowingAll) ? 30 : villageEntries.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? Font.primaryColor.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PLAN HEADER (Tap to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _expandedGroups[projectPlanKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: isExpanded ? Radius.zero : const Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isExpanded ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  // Animated Chevron Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? Font.primaryColor.withOpacity(0.12)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isExpanded ? Font.primaryColor : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Plan Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project & Plan Code
                        Text(
                          '$projectName - $planCode',
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Badges Row
                        Row(
                          children: [
                            // Village Count Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_city_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${villageGroups.length} village(s)',
                                    style: const TextStyle(
                                      fontFamily: "Roboto",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Balance Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFED7AA), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.pending_actions_rounded,
                                    size: 13,
                                    color: Color(0xFFEA580C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Balance: $totalBalance',
                                    style: const TextStyle(
                                      fontFamily: "Roboto",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // VILLAGE DATA GRID / TABLE
          if (isExpanded)
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Table Header
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 22,
                        child: Text(
                          S.of(context).villageCodePost,
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 36,
                        child: Text(
                          S.of(context).villageNameMap,
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 26,
                        child: Text(
                          S.of(context).tehsil,
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 16,
                        child: Text(
                          S.of(context).balance,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Table Rows (chunked up to 30 for super-fast scrolling)
                ...List.generate(renderedCount, (idx) {
                  final villageEntry = villageEntries[idx];
                  final villageData = villageEntry.value;
                  final groupPlans = villageData['plans'] as List<SUPlanModel>;
                  final firstPlan = groupPlans[0];
                  final int displayBalance = villageData['displayBalance'] as int? ?? villageData['totalBalance'] as int;

                  final bool isEven = idx % 2 == 0;

                  return Material(
                    color: isEven ? Colors.white : const Color(0xFFFBFDFF),
                    child: InkWell(
                      onTap: () => _onGroupRowClick(groupPlans),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Village Code
                            Expanded(
                              flex: 22,
                              child: Text(
                                firstPlan.villageCode,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Village Name
                            Expanded(
                              flex: 36,
                              child: Text(
                                firstPlan.villageName,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Tehsil
                            Expanded(
                              flex: 26,
                              child: Text(
                                firstPlan.tehsil,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Balance Pill & Indicator
                            Expanded(
                              flex: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$displayBalance',
                                      style: TextStyle(
                                        fontFamily: "Roboto",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Font.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 15,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Pagination / Show More for Plans with 30+ Villages
                if (hasLargeList)
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isShowingAll) {
                          _showAllVillagesInPlan.remove(projectPlanKey);
                        } else {
                          _showAllVillagesInPlan.add(projectPlanKey);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isShowingAll
                                ? 'Show Less (First 30 Villages)'
                                : 'Show All ${villageEntries.length} Villages (+${villageEntries.length - 30} more)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Font.primaryColor,
                              fontFamily: "Roboto",
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isShowingAll
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Font.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              '${S.of(context).noPlanFound} "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                fontFamily: "Roboto",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              S.of(context).trySearching,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontFamily: "Roboto",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(
                'Clear Search',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Font.primaryColor,
                backgroundColor: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlansWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noPlanFound,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                fontFamily: "Roboto",
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _processedGroupedPlans = null;
                  _offlineCountCache.clear();
                });
                ref.invalidate(plansSUProvider);
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: Text(
                S.of(context).retry,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getErrorIcon(e.toString()), size: 64, color: _getErrorColor(e.toString())),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(e.toString()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _getErrorColor(e.toString()),
                fontFamily: "Roboto",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontFamily: "Roboto",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  label: Text(
                    S.of(context).retry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Font.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (e.toString().contains(S.of(context).pleaseContact))
                  ElevatedButton.icon(
                    onPressed: () => _showContactAdminDialog(context),
                    icon: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
                    label: Text(
                      S.of(context).contactAdmin,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Roboto",
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon(String error) {
    if (error.contains('Network error') || error.contains('internet connection')) {
      return Icons.wifi_off_rounded;
    } else if (error.contains('Authentication failed') || error.contains('Unauthorized')) {
      return Icons.lock_outline_rounded;
    } else if (error.contains('Please contact admin') || error.contains('Internal Server Error')) {
      return Icons.error_outline_rounded;
    } else if (error.contains('No data found')) {
      return Icons.inbox_outlined;
    } else {
      return Icons.warning_amber_rounded;
    }
  }

  Color _getErrorColor(String error) {
    if (error.contains('Network error') || error.contains('internet connection')) {
      return Colors.orange[700]!;
    } else if (error.contains('Authentication failed') || error.contains('Unauthorized')) {
      return Colors.blue[700]!;
    } else if (error.contains('Please contact admin') || error.contains('Internal Server Error')) {
      return Colors.red[700]!;
    } else if (error.contains('No data found')) {
      return Colors.grey[700]!;
    } else {
      return Colors.amber[800]!;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            S.of(context).contactAdministrator,
            style: const TextStyle(
              fontFamily: "Roboto",
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).serverErrorOccured}:',
                style: const TextStyle(fontFamily: "Roboto", fontSize: 13.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).errorType,
                style: const TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${S.of(context).time}: ${DateTime.now().toString()}',
                style: const TextStyle(fontFamily: "Roboto", fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}