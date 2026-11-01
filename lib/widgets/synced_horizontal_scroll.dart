import 'package:flutter/material.dart';

/// Keeps several horizontal scroll views (a table header and each row) at
/// the same offset, so the columns scroll sideways together. Used by tables
/// whose header is pinned in a sliver while the rows are in a sliver list.
class HorizontalScrollGroup {
  final Set<ScrollController> _controllers = {};
  double _offset = 0;
  bool _syncing = false;

  ScrollController attach() {
    final controller = ScrollController(initialScrollOffset: _offset);
    controller.addListener(() => _sync(controller));
    _controllers.add(controller);
    return controller;
  }

  void detach(ScrollController controller) {
    _controllers.remove(controller);
    controller.dispose();
  }

  void _sync(ScrollController source) {
    if (_syncing || !source.hasClients) return;
    _syncing = true;
    _offset = source.offset;
    for (final controller in _controllers) {
      if (controller != source &&
          controller.hasClients &&
          controller.offset != _offset) {
        controller.jumpTo(_offset);
      }
    }
    _syncing = false;
  }
}

/// A horizontal scroll view at least [width] wide whose offset is shared
/// with every other member of [group].
class SyncedHorizontalScroll extends StatefulWidget {
  const SyncedHorizontalScroll({
    super.key,
    required this.group,
    required this.width,
    required this.child,
  });

  final HorizontalScrollGroup group;
  final double width;
  final Widget child;

  @override
  State<SyncedHorizontalScroll> createState() => _SyncedHorizontalScrollState();
}

class _SyncedHorizontalScrollState extends State<SyncedHorizontalScroll> {
  late final ScrollController _controller = widget.group.attach();

  @override
  void dispose() {
    widget.group.detach(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > widget.width
            ? constraints.maxWidth
            : widget.width;
        return SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(width: width, child: widget.child),
        );
      },
    );
  }
}
