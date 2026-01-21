import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/app_theme.dart';
import 'clinical_summary_detail_screen.dart';
import '../utils/animation_selector.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  bool _sortByDate = true;
  DateTime _selectedDate = DateTime.now(); // Default: today
  DateTime _currentMonth = DateTime.now(); // Current month

  // Track if we've loaded data at least once
  bool _hasLoadedData = false;
  late AnimationController _pageController;
  late AnimationController _toggleController;
  late AnimationController _calendarController;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late AnimationController _historyListController;

  // State for API data
  List<HistoryRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCalendarExpanded = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    // Page load animation
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );

    // Toggle animation
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Calendar animation
    _calendarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // History list animation
    _historyListController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pageController.forward();
    _calendarController.forward();

    // Load data from API
    _loadSummaries();

    // Set up auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadSummaries();
      }
    });
  }

  /// Load summaries from API
  Future<void> _loadSummaries({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // First, try to fetch all summaries (more efficient)
      List<SummaryListItem> allSummaries = [];
      try {
        print('🟢 HistoryScreen: Starting to fetch summaries from /all endpoint...');
        allSummaries = await ApiService.getAllSummaries(limit: 500);
        print('🟢 HistoryScreen: Successfully fetched ${allSummaries.length} summaries using /all endpoint');
        debugPrint('Fetched ${allSummaries.length} summaries using /all endpoint');
      } catch (e, stackTrace) {
        print('🔴 HistoryScreen: /all endpoint FAILED with error: $e');
        print('🔴 HistoryScreen: Error type: ${e.runtimeType}');
        print('🔴 HistoryScreen: Stack trace: $stackTrace');
        print('🟡 HistoryScreen: Falling back to date-by-date method...');
        // Fallback to date-by-date fetching if /all endpoint fails
        debugPrint('Fallback to date-by-date fetching: $e');

        // Try to fetch from a wider date range (last 6 months)
        final now = DateTime.now();
        allSummaries = [];

        // Fetch for current month and 5 previous months (6 months total)
        for (int monthOffset = 5; monthOffset >= 0; monthOffset--) {
          final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
          final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
          final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

          print('🟡 HistoryScreen: Fetching for month ${targetMonth.year}-${targetMonth.month}');

          // Fetch summaries for each day in the month
          for (int day = firstDay.day; day <= lastDay.day; day++) {
            try {
              final date = DateTime(targetMonth.year, targetMonth.month, day);
              final summaries = await ApiService.getSummariesByDate(date);
              if (summaries.isNotEmpty) {
                print('🟡 HistoryScreen: Found ${summaries.length} summaries for ${date.year}-${date.month}-${date.day}');
              }
              allSummaries.addAll(summaries);
            } catch (e) {
              // Continue if a day has no summaries or error
              continue;
            }
          }
        }
        print('🟡 HistoryScreen: Fetched ${allSummaries.length} summaries using date-by-date method');
      }

      print('🟢 HistoryScreen: Total summaries fetched: ${allSummaries.length}');

      print('🟢 HistoryScreen: Converting ${allSummaries.length} summaries to HistoryRecord...');

      // Convert API responses to HistoryRecord objects
      final records = await Future.wait(allSummaries.map((summary) async {
        // Try to get full summary to extract diagnoses
        List<String> diagnosisList = [];
        try {
          final fullSummary = await ApiService.getSummaryById(summary.summaryId);
          diagnosisList = fullSummary.diagnoses;
        } catch (e) {
          // If we can't get full summary, try to extract from summary text
          diagnosisList = _extractDiagnosesFromText(summary.summaryText);
        }

        final diagnosis = diagnosisList.isNotEmpty
            ? diagnosisList.first
            : 'General Consultation';
        final animationAsset = summary.animationAsset ??
            AnimationSelector.selectAnimationAsset(
              summary.summaryText,
              diagnosisList,
            );
        final icon = AnimationSelector.getIconForAnimation(animationAsset);
        
        return HistoryRecord(
          patientName: summary.patientName,
          date: summary.createdAt,
          diagnosis: diagnosis,
          affectedOrgan: icon,
          summaryText: summary.summaryText,
          diagnosisList: diagnosisList,
          animationAsset: animationAsset, // Store the animation asset
        );
      }));

      print('🟢 HistoryScreen: Converted to ${records.length} HistoryRecord objects');

      // Debug: Print summary of loaded data
      print('🟢 HistoryScreen: Setting state with ${records.length} records');
      debugPrint('Loaded ${records.length} summaries from API');
      if (records.isNotEmpty) {
        final dateRange = records.map((r) => r.date).toList()
          ..sort();
        print('🟢 HistoryScreen: Date range: ${dateRange.first} to ${dateRange.last}');
        print('🟢 HistoryScreen: Selected date: $_selectedDate');
        print('🟢 HistoryScreen: First record: ${records.first.patientName} - ${records.first.date}');
        debugPrint('Date range: ${dateRange.first} to ${dateRange.last}');
        debugPrint('Selected date: $_selectedDate');
      } else {
        print('🟡 HistoryScreen: No records found!');
      }

      setState(() {
        _records = records;
        _isLoading = false;
        _hasLoadedData = true;

        // If we have records but none showing, update selected date to match data
        if (_sortByDate && records.isNotEmpty) {
          // Check if selected date has records
          final hasSelectedDateRecords = records.any((r) {
            final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
            final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
            return recordDate == selectedDateOnly;
          });

          if (!hasSelectedDateRecords) {
            // If selected date has no records, select the most recent date with records
            final mostRecent = records.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);
            _selectedDate = DateTime(mostRecent.year, mostRecent.month, mostRecent.day);
            _currentMonth = DateTime(mostRecent.year, mostRecent.month);
            print('🟢 HistoryScreen: Updated selected date to: $_selectedDate (most recent with records)');
            print('🟢 HistoryScreen: Updated current month to: $_currentMonth');
            debugPrint('Updated selected date to: $_selectedDate');
          }
        } else if (records.isEmpty && !_hasLoadedData) {
          // If no records and this is first load, check if we need to adjust the date
          print('🟡 HistoryScreen: No records found on first load');
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load summaries: ${e.toString()}';
        _isLoading = false;
      });
      // Print error for debugging
      debugPrint('Error loading summaries: $e');
    }
  }

  /// Load summaries for a specific date
  Future<void> _loadSummariesForDate(DateTime date) async {
    try {
      final summaries = await ApiService.getSummariesByDate(date);

      // Convert to HistoryRecord objects
      final records = await Future.wait(summaries.map((summary) async {
        // Try to get full summary to extract diagnoses
        List<String> diagnosisList = [];
        try {
          final fullSummary = await ApiService.getSummaryById(summary.summaryId);
          diagnosisList = fullSummary.diagnoses;
        } catch (e) {
          // If we can't get full summary, try to extract from summary text
          diagnosisList = _extractDiagnosesFromText(summary.summaryText);
        }

        final diagnosis = diagnosisList.isNotEmpty
            ? diagnosisList.first
            : 'General Consultation';
        final animationAsset = summary.animationAsset ??
            AnimationSelector.selectAnimationAsset(
              summary.summaryText,
              diagnosisList,
            );
        final icon = AnimationSelector.getIconForAnimation(animationAsset);
        
        return HistoryRecord(
          patientName: summary.patientName,
          date: summary.createdAt,
          diagnosis: diagnosis,
          affectedOrgan: icon,
          summaryText: summary.summaryText,
          diagnosisList: diagnosisList,
          animationAsset: animationAsset, // Store the animation asset
        );
      }));

      setState(() {
        _records = records;
      });
    } catch (e) {
      // Silently fail for date-specific loads
      setState(() {
        _records = [];
      });
    }
  }

  /// Extract diagnoses from summary text (fallback method)
  List<String> _extractDiagnosesFromText(String text) {
    // Common medical conditions to look for
    final commonDiagnoses = [
      'Type 2 Diabetes Mellitus',
      'Hypertension',
      'Ischemic Stroke',
      'Chronic Obstructive Pulmonary Disease',
      'Chronic Kidney Disease',
      'Gastritis',
      'Irritable Bowel Syndrome',
      'Peripheral Vascular Disease',
    ];

    final found = <String>[];
    for (final diagnosis in commonDiagnoses) {
      if (text.toLowerCase().contains(diagnosis.toLowerCase())) {
        found.add(diagnosis);
      }
    }
    return found;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _pageController.dispose();
    _toggleController.dispose();
    _calendarController.dispose();
    _historyListController.dispose();
    super.dispose();
  }

  List<HistoryRecord> get _filteredRecords {
    print('🔵 _filteredRecords: Total records: ${_records.length}, Sort by date: $_sortByDate, Selected: $_selectedDate');
    if (_sortByDate) {
      final filtered = _records.where((r) {
        final matches = r.date.year == _selectedDate.year &&
            r.date.month == _selectedDate.month &&
            r.date.day == _selectedDate.day;
        return matches;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      print('🔵 _filteredRecords: Filtered to ${filtered.length} records for selected date');
      return filtered;
    } else {
      final sorted = List<HistoryRecord>.from(_records)
        ..sort((a, b) => a.patientName.compareTo(b.patientName));
      print('🔵 _filteredRecords: Sorted ${sorted.length} records by patient name');
      return sorted;
    }
  }

  Map<String, List<HistoryRecord>> get _groupedByPatient {
    final grouped = <String, List<HistoryRecord>>{};
    for (final record in _filteredRecords) {
      final firstLetter = record.patientName[0].toUpperCase();
      grouped.putIfAbsent(firstLetter, () => []).add(record);
    }
    return grouped;
  }

  Set<DateTime> get _datesWithRecords {
    return _records.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();
  }

  void _toggleSortMode(bool byDate) {
    if (_sortByDate != byDate) {
      setState(() {
        _sortByDate = byDate;
      });
      _toggleController.forward(from: 0.0).then((_) {
        _toggleController.reverse();
      });
      if (byDate) {
        _calendarController.forward();
      } else {
        _calendarController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightLavender,
              AppTheme.softBlue,
              AppTheme.lightPink,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _pageFade,
            child: SlideTransition(
              position: _pageSlide,
              child: Column(
                children: [
                  // Top App Bar
                  _buildAppBar(),
                  // Sorting Toggle
                  _buildSortToggle(),
                  // Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _sortByDate
                          ? _buildDateSortView()
                          : _buildPatientSortView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Previously analyzed cases',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkGray),
                    ),
                  )
                : const Icon(Icons.refresh, color: AppTheme.darkGray),
            onPressed: _isLoading ? null : () => _loadSummaries(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSortToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton('By Date', true),
            ),
            Expanded(
              child: _buildToggleButton('By Patient', false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isDateMode) {
    final isActive = _sortByDate == isDateMode;
    return GestureDetector(
      onTap: () => _toggleSortMode(isDateMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppTheme.blueViolet.withOpacity(0.8),
                    AppTheme.violet.withOpacity(0.8),
                  ],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.blueViolet.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSortView() {
    return Column(
      key: const ValueKey('date'),
      children: [
        // Animated Calendar Container
        _buildAnimatedCalendarContainer(),
        // History List (animated slide up when calendar collapsed)
        Expanded(
          child: _buildAnimatedHistoryList(),
        ),
      ],
    );
  }

  Widget _buildAnimatedCalendarContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _isCalendarExpanded ? 0 : 8,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        child: _isCalendarExpanded
            ? _buildExpandedCalendar()
            : _buildCollapsedCalendarHeader(),
      ),
    );
  }

  Widget _buildExpandedCalendar() {
    return FadeTransition(
      opacity: _calendarController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _calendarController,
            curve: Curves.easeOut,
          ),
        ),
        child: _buildCalendar(),
      ),
    );
  }

  Widget _buildCollapsedCalendarHeader() {
    final recordsForDate = _filteredRecords;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCalendarExpanded = true;
        });
        _historyListController.reverse();
        _calendarController.forward();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recordsForDate.length} ${recordsForDate.length == 1 ? 'record' : 'records'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHistoryList() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _historyListController,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: _historyListController,
        child: _buildHistoryList(),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              // Calendar Header
              _buildCalendarHeader(),
              const SizedBox(height: 20),
              // Weekday headers
              _buildWeekdayHeaders(),
              const SizedBox(height: 12),
              // Full month grid
              _buildMonthGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous month arrow
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.darkGray),
          onPressed: () async {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
            // Reload summaries to include the new month
            await _loadSummaries(showLoading: false);
          },
        ),
        // Month name and year
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getMonthName(_currentMonth.month),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              // Clickable year
              GestureDetector(
                onTap: () => _showYearSelector(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentMonth.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.mediumGray,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Next month arrow
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppTheme.darkGray),
          onPressed: () async {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
            // Reload summaries to include the new month
            await _loadSummaries(showLoading: false);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdayNames = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdayNames.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.mediumGray,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Calculate the first Saturday of the month
    // weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    // To get to Saturday:
    // - Sat (6): subtract 0
    // - Sun (7): subtract 1
    // - Mon (1): subtract 2
    // - Tue (2): subtract 3
    // - Wed (3): subtract 4
    // - Thu (4): subtract 5
    // - Fri (5): subtract 6
    final firstWeekday = firstDay.weekday;
    final daysToSubtract = firstWeekday == 6
        ? 0
        : (firstWeekday == 7 ? 1 : firstWeekday + 1);
    final calendarStart = firstDay.subtract(Duration(days: daysToSubtract));

    // Generate 6 weeks (42 days) to cover the month
    final totalDays = 42;
    final days = List.generate(totalDays, (index) {
      return calendarStart.add(Duration(days: index));
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        final date = days[index];
        final isCurrentMonth = date.month == _currentMonth.month;
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final hasRecord = isCurrentMonth && _datesWithRecords.contains(
          DateTime(date.year, date.month, date.day),
        );

        // Show dates from current month, gray out dates from other months
        return GestureDetector(
          onTap: isCurrentMonth
              ? () async {
                  setState(() {
                    _selectedDate = date;
                    _isCalendarExpanded = false;
                  });
                  _calendarController.reverse();
                  _historyListController.forward();
                  // Reload all summaries to ensure we have data for the selected date
                  await _loadSummaries(showLoading: false);
                }
              : null,
          child: Opacity(
            opacity: isCurrentMonth ? 1.0 : 0.3,
            child: _buildDayPill(date, isSelected && isCurrentMonth, hasRecord),
          ),
        );
      },
    );
  }

  Widget _buildDayPill(DateTime date, bool isSelected, bool hasRecord) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        vertical: hasRecord && !isSelected ? 4 : 6,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFFFF6B9D), // Pink
                  Color(0xFF9C88FF), // Purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasRecord && !isSelected
            ? Border.all(
                color: const Color(0xFFFF6B9D).withOpacity(0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFFF6B9D).withOpacity(0.3)
                : (hasRecord
                    ? const Color(0xFFFF6B9D).withOpacity(0.15)
                    : Colors.black.withOpacity(0.05)),
            blurRadius: isSelected ? 12 : (hasRecord ? 8 : 6),
            offset: Offset(0, isSelected ? 4 : (hasRecord ? 3 : 2)),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (hasRecord
                        ? const Color(0xFFFF6B9D)
                        : AppTheme.darkGray),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasRecord && !isSelected)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B9D),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  void _showYearSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _YearSelectorModal(
        currentYear: _currentMonth.year,
        onYearSelected: (year) {
          setState(() {
            _currentMonth = DateTime(year, _currentMonth.month);
            // Keep the same day if possible, otherwise use last day of month
            final lastDay = DateTime(year, _currentMonth.month + 1, 0).day;
            final day = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
            _selectedDate = DateTime(year, _currentMonth.month, day);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildPatientSortView() {
    final grouped = _groupedByPatient;
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      key: const ValueKey('patient'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final records = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blueViolet,
                ),
              ),
            ),
            // Records for this letter
            ...records.asMap().entries.map((entry) {
              return _buildHistoryCard(entry.value, entry.key);
            }),
          ],
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading && _records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSummaries(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final records = _filteredRecords;
    print('🔵 _buildHistoryList: Showing ${records.length} filtered records');
    print('🔵 _buildHistoryList: Total _records: ${_records.length}');

    if (records.isEmpty) {
      print('🟡 _buildHistoryList: No records to display');
      return RefreshIndicator(
        onRefresh: () => _loadSummaries(showLoading: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _sortByDate
                        ? 'No records for this date\nTotal records: ${_records.length}'
                        : 'No records found\nTotal records: ${_records.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGray.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSummaries(showLoading: false),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(records[index], index);
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryRecord record, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
        child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicalSummaryDetailScreen(
                patientName: record.patientName,
                date: record.date,
                diagnosis: record.diagnosis,
                affectedOrgan: record.affectedOrgan,
                summaryText: record.summaryText,
                diagnosisList: record.diagnosisList,
                animationAsset: record.animationAsset, // Pass the animation asset
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  // Organ icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getOrganColor(record.affectedOrgan)
                          .withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      record.affectedOrgan,
                      color: _getOrganColor(record.affectedOrgan),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(record.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.diagnosis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getOrganColor(IconData icon) {
    if (icon == Icons.favorite) return Colors.red;
    if (icon == Icons.psychology) return AppTheme.blueViolet;
    if (icon == Icons.air) return Colors.blue;
    return AppTheme.blueViolet;
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${_formatDate(date)}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class _YearSelectorModal extends StatefulWidget {
  final int currentYear;
  final Function(int) onYearSelected;

  const _YearSelectorModal({
    required this.currentYear,
    required this.onYearSelected,
  });

  @override
  State<_YearSelectorModal> createState() => _YearSelectorModalState();
}

class _YearSelectorModalState extends State<_YearSelectorModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(21, (index) => 2010 + index); // 2010-2030

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Select Year',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 20),
              // Year list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final isSelected = year == widget.currentYear;

                    return GestureDetector(
                      onTap: () => widget.onYearSelected(year),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B9D),
                                    Color(0xFF9C88FF),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.mediumGray,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryRecord {
  final String patientName;
  final DateTime date;
  final String diagnosis;
  final IconData affectedOrgan;
  final String summaryText;
  final List<String> diagnosisList;
  final String animationAsset; // Store the animation asset path

  HistoryRecord({
    required this.patientName,
    required this.date,
    required this.diagnosis,
    required this.affectedOrgan,
    required this.summaryText,
    required this.diagnosisList,
    required this.animationAsset,
  });
}
