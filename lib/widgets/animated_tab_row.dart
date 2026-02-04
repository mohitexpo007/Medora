import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import '../theme/app_theme.dart';

/// Tab item data class
class TabItem {
  final String title;
  final IconData icon;

  const TabItem({
    required this.title,
    required this.icon,
  });
}

/// Custom animated tab row widget inspired by Kotlin Compose TabRow
/// Features:
/// - Animated indicator that smoothly moves between tabs
/// - Circular/rounded shape
/// - Smooth animations with customizable duration
/// - Customizable colors and shapes
/// - Support for icons on tabs
class AnimatedTabRow extends StatefulWidget {
  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color containerColor;
  final Color indicatorColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final BorderRadius containerBorderRadius;
  final BorderRadius indicatorBorderRadius;
  final EdgeInsets padding;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool fixedSize;

  const AnimatedTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.containerColor = Colors.white,
    this.indicatorColor = AppTheme.blueViolet,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = AppTheme.darkGray,
    this.containerBorderRadius = const BorderRadius.all(Radius.circular(20)),
    this.indicatorBorderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(4),
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.fastOutSlowIn,
    this.fixedSize = true,
  });

  @override
  State<AnimatedTabRow> createState() => _AnimatedTabRowState();
}

class _AnimatedTabRowState extends State<AnimatedTabRow> {
  final Map<int, GlobalKey> _tabKeys = {};
  final Map<int, double> _tabPositions = {};
  final Map<int, double> _tabWidths = {};
  double _maxTabHeight = 0;
  double? _availableWidth;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.tabs.length; i++) {
      _tabKeys[i] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTabs();
    });
  }

  @override
  void didUpdateWidget(AnimatedTabRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length ||
        oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureTabs();
      });
    }
  }

  void _measureTabs() {
    if (!mounted) return;
    
    setState(() {
      _tabPositions.clear();
      _tabWidths.clear();
      _maxTabHeight = 0;

      double currentX = 0;
      for (int i = 0; i < widget.tabs.length; i++) {
        final key = _tabKeys[i];
        if (key?.currentContext != null) {
          final RenderBox? box =
              key!.currentContext!.findRenderObject() as RenderBox?;
          if (box != null) {
            final size = box.size;
            _tabPositions[i] = currentX;
            _tabWidths[i] = widget.fixedSize ? 0 : size.width;
            _maxTabHeight = _maxTabHeight > size.height
                ? _maxTabHeight
                : size.height;
            if (!widget.fixedSize) {
              currentX += size.width;
            }
          }
        }
      }

      // If fixed size, calculate equal widths based on available width
      if (widget.fixedSize && _availableWidth != null) {
        final equalWidth = _availableWidth! / widget.tabs.length;
        for (int i = 0; i < widget.tabs.length; i++) {
          _tabPositions[i] = i * equalWidth;
          _tabWidths[i] = equalWidth;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // #region agent log
        final logData = {
          'location': 'animated_tab_row.dart:128',
          'message': 'Row build - constraints',
          'data': {
            'availableWidth': constraints.maxWidth,
            'containerPadding': widget.padding.horizontal,
            'tabCount': widget.tabs.length,
            'selectedIndex': widget.selectedIndex,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'overflow-debug',
          'hypothesisId': 'A',
        };
        try {
          final file = File(r'c:\Medora\.cursor\debug.log');
          file.writeAsStringSync('${jsonEncode(logData)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
        
        _availableWidth = constraints.maxWidth - widget.padding.horizontal;
        
        // Calculate per-tab width
        final tabSpacing = 2.0 * 2; // 2px padding on each side
        final totalTabSpacing = tabSpacing * widget.tabs.length;
        final perTabWidth = (_availableWidth! - totalTabSpacing) / widget.tabs.length;
        
        // #region agent log
        final logData3 = {
          'location': 'animated_tab_row.dart:154',
          'message': 'Calculated tab widths',
          'data': {
            'availableWidth': _availableWidth,
            'totalTabSpacing': totalTabSpacing,
            'perTabWidth': perTabWidth,
            'tabCount': widget.tabs.length,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'overflow-debug',
          'hypothesisId': 'C',
        };
        try {
          final file3 = File(r'c:\Medora\.cursor\debug.log');
          file3.writeAsStringSync('${jsonEncode(logData3)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
        
        return ClipRect(
          clipBehavior: Clip.hardEdge,
          child: Container(
            decoration: BoxDecoration(
              color: widget.containerColor,
              borderRadius: widget.containerBorderRadius,
            ),
            padding: widget.padding,
            child: Row(
              children: widget.tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: _TabTitle(
                        key: _tabKeys[index],
                        title: tab.title,
                        icon: tab.icon,
                        position: index,
                        isSelected: index == widget.selectedIndex,
                        selectedTextColor: widget.selectedTextColor,
                        unselectedTextColor: widget.unselectedTextColor,
                        onTap: () => widget.onTabSelected(index),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedIndicator extends StatelessWidget {
  final double left;
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;
  final Duration duration;
  final Curve curve;

  const _AnimatedIndicator({
    required this.left,
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: left,
      width: width,
      height: height,
      duration: duration,
      curve: curve,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _TabTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final int position;
  final bool isSelected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _TabTitle({
    super.key,
    required this.title,
    required this.icon,
    required this.position,
    required this.isSelected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      // Selected tab with gradient, glow, and inner highlight
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: OverflowBox(
            maxWidth: double.infinity,
            minWidth: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 10),
              decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B82F6), // blue
                Color(0xFF22D3EE), // cyan
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              // Soft glow shadow (blue side)
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 1.5,
                offset: const Offset(0, 2),
              ),
              // Lighter shadow (cyan side)
              BoxShadow(
                color: const Color(0xFF22D3EE).withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
              // Mild drop shadow for raised effect
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner highlight (top-left white gradient)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              LayoutBuilder(
                builder: (context, constraints) {
                  // #region agent log
                  final logData4 = {
                    'location': 'animated_tab_row.dart:343',
                    'message': 'Tab content constraints',
                    'data': {
                      'title': title,
                      'maxWidth': constraints.maxWidth,
                      'isSelected': isSelected,
                    },
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'sessionId': 'debug-session',
                    'runId': 'overflow-debug',
                    'hypothesisId': 'D',
                  };
                  try {
                    final file4 = File(r'c:\Medora\.cursor\debug.log');
                    file4.writeAsStringSync('${jsonEncode(logData4)}\n', mode: FileMode.append);
                  } catch (_) {}
                  // #endregion
                  
                  // Calculate available width for text (icon + spacing + padding)
                  final iconWidth = 12.0;
                  final spacing = 2.0;
                  final horizontalPadding = 2.0; // Container padding
                  final availableTextWidth = (constraints.maxWidth - iconWidth - spacing - horizontalPadding * 2).clamp(0, double.infinity);
                  
                  return ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          SizedBox(
                            width: availableTextWidth > 0 ? availableTextWidth.toDouble() : 0.0,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
            ),
          ),
        ),
      );
    } else {
      // Unselected tab with glass style (icon only)
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF475569), // slate
              ),
            ),
          ),
        ),
      );
    }
  }
}
