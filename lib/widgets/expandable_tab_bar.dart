import 'package:flutter/material.dart';
import 'dart:ui';

/// Tab item data class
class ExpandableTabItem {
  final String label;
  final IconData icon;

  const ExpandableTabItem({
    required this.label,
    required this.icon,
  });
}

/// Expandable Tab Bar - Jetpack Compose style
/// Selected tab expands with gradient background and shows icon + label
/// Unselected tabs show only icon with no background
class ExpandableTabBar extends StatefulWidget {
  final List<ExpandableTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Duration animationDuration;
  final Curve animationCurve;

  const ExpandableTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<ExpandableTabBar> createState() => _ExpandableTabBarState();
}

class _ExpandableTabBarState extends State<ExpandableTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ExpandableTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332), // Dark navy background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.tabs.length,
            (index) => Expanded(
              child: _buildTab(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final tab = widget.tabs[index];
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Center(
          child: AnimatedContainer(
            duration: widget.animationDuration,
            curve: widget.animationCurve,
            padding: EdgeInsets.only(
              left: isSelected ? 8 : 6,
              right: isSelected ? 8 : 6,
              top: 12,
              bottom: 12,
            ),
            constraints: const BoxConstraints(
              minWidth: 0,
              maxWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon with fixed size
                      Icon(
                        tab.icon,
                        color: isSelected ? Colors.white : Colors.white54,
                        size: 16,
                      ),
                      // Label with smooth fade and size animation - allows wrapping
                      AnimatedSize(
                        duration: widget.animationDuration,
                        curve: widget.animationCurve,
                        alignment: Alignment.centerLeft,
                        child: isSelected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 4, right: 2),
                                child: AnimatedOpacity(
                                  duration: widget.animationDuration,
                                  opacity: isSelected ? 1.0 : 0.0,
                                  child: _buildLabelText(tab.label),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    // Split label by spaces to handle multi-word labels
    final words = label.split(' ');
    
    // If single word, display normally
    if (words.length == 1) {
      return Flexible(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          softWrap: true,
        ),
      );
    }
    
    // If multiple words, stack them vertically
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: words.map((word) {
          return Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          );
        }).toList(),
      ),
    );
  }
}
