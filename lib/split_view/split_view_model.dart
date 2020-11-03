import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum LayoutPriority { Normal, Low, High }
enum Orientation { VERTICAL, HORIZONTAL }

List<int> range(int from, int to) {
  int step = from > to ? -1 : 1;
  return [for (int i = from; i != to; i += step) i];
}

void pushToStart(List<int> arr, int value) {
  int index = arr.indexOf(value);
  if (index != -1) {
    arr.removeAt(index);
    arr.insert(0, value);
  }
}

void pushToEnd(List<int> arr, int value) {
  int index = arr.indexOf(value);
  if (index != -1) {
    arr.removeAt(index);
    arr.add(value);
  }
}

class SashItem {
  Object id;
  Orientation orientation;
  double size;
  Function(SashItem) getShashtPosition;
  SashItem({this.id, this.orientation, this.size, this.getShashtPosition});
}

class LayoutContext {
  Object id;
  Size size;
  Offset offset;

  LayoutContext({this.id, this.size, this.offset});
}

class ViewItem {
  Widget child;
  double maxSize;
  double minSize;
  double size;
  LayoutPriority priority;
  Object id;

  bool visible;

  ViewItem({this.maxSize, this.minSize, this.id, this.child, this.visible = true, this.size})
      : assert(maxSize != null && minSize != null),
        assert(id != null),
        assert(child != null);
}

class SplitViewModel extends ChangeNotifier {
  double size;
  double contentSize;
  Orientation orientation;
  List<ViewItem> viewItems = [];
  List<SashItem> sashItems = [];
  List<LayoutId> _cachedViews = [];
  List<LayoutContext> _cachedLayouts = [];
  List<num> proportions = [];
  bool proportionalLayout;
  int count = 0;
  Size viewportSize;
  SashItem dragingSash;

  SplitViewModel({this.orientation, this.proportionalLayout = true, @required this.viewportSize}) {
    this.size = orientation == Orientation.HORIZONTAL ? viewportSize.width : viewportSize.height;
  }

  List<LayoutId> get views => _cachedViews;
  List<LayoutContext> get layouts => _cachedLayouts;

  void addView(Widget widget,
      {double size = 0,
      double minSize = 0,
      double maxSize = double.infinity,
      bool skipLayout = false}) {
    double viewSize = size.clamp(minSize, maxSize);
    bool visibility = true;

    ViewItem view = ViewItem(
        child: widget,
        visible: visibility,
        size: viewSize,
        id: count++,
        maxSize: maxSize,
        minSize: minSize);

    viewItems.add(view);

    //Add Sash
    if (viewItems.length > 1) {
      sashItems.add(SashItem(id: count++, orientation: this.orientation, size: 4));
    }

    if (!skipLayout) {
      this._distributeViewSizes();
      this._distributeEmptySpace();
    }

    relayout([], []);
  }

  double _getShashtPosition(SashItem sash) {
    double position = 0;

    for (int i = 0; i < this.sashItems.length; i++) {
      position += this.viewItems[i].size;

      if (this.sashItems[i] == sash) {
        return position;
      }
    }

    return 0;
  }

  void _distributeViewSizes() {
    List<ViewItem> flexibleViewItems = [];
    double flexibleSize = 0;

    for (ViewItem item in this.viewItems) {
      if (item.maxSize - item.minSize > 0 && item.visible) {
        flexibleViewItems.add(item);
        flexibleSize += item.size;
      }
    }

    double size = (flexibleSize / flexibleViewItems.length).floorToDouble();

    for (ViewItem item in flexibleViewItems) {
      item.size = size.clamp(item.minSize, item.maxSize);
    }
  }

  void _distributeEmptySpace() {
    contentSize = this.viewItems.fold(0, (r, i) => r + i.size);
    double emptyDelta = this.size - contentSize;

    List<int> indexes = range(this.viewItems.length - 1, -1);

    for (int i = 0; emptyDelta != 0 && i < indexes.length; i++) {
      ViewItem item = this.viewItems[indexes[i]];
      double size = (item.size + emptyDelta).clamp(item.minSize, item.maxSize);
      double viewDelta = size - item.size;

      emptyDelta -= viewDelta;
      item.size = size;
    }
  }

  void layout(Size viewSize) {
    viewportSize = viewSize;
    this.size = orientation == Orientation.HORIZONTAL ? viewSize.width : viewSize.height;

    if (this.proportions.isNotEmpty) {
      for (int i = 0; i < this.viewItems.length; ++i) {
        ViewItem item = viewItems[i];
        item.size = (this.proportions[i] * size).clamp(item.minSize, item.maxSize);
      }
    }

    this._distributeEmptySpace();
    this.layoutViews();
  }

  void relayout(List<int> lowPriorityIndexes, List<int> highPriorityIndexes) {
    contentSize = viewItems.fold(0, (r, i) => r + i.size);

    this.resize(this.viewItems.length - 1, this.size - contentSize);
    this._distributeEmptySpace();
    this.layoutViews();
    this.saveProportions();
  }

  onSashDrag(int index, double delta) {
    this.resize(index, delta);
    this._distributeEmptySpace();
    this.layoutViews();
    notifyListeners();
  }

  void saveProportions() {
    if (this.proportionalLayout && this.contentSize > 0) {
      this.proportions = viewItems.map((ViewItem i) => i.size / this.contentSize).toList();
    }
  }

  List<LayoutContext> layoutViews() {
    double offset = 0;
    bool isHorizontal = orientation == Orientation.HORIZONTAL;

    // Generate LayoutID
    _cachedViews = viewItems
        .map((ViewItem view) => LayoutId(
              id: view.id,
              child: view.child,
            ))
        .toList();

    sashItems.asMap().forEach((int index, SashItem sash) => {
          _cachedViews.add(LayoutId(
              id: sash.id,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  onVerticalDragStart: (DragStartDetails detail) {
                    this.dragingSash = sash;
                  },
                  onVerticalDragCancel: () {
                    this.dragingSash = null;
                  },
                  onVerticalDragUpdate: (details) {
                    this.onSashDrag(index, details.delta.dy);
                  },
                  child: Container(
                    color: Colors.blueGrey,
                  ),
                ),
              )))
        });

    List<LayoutContext> _layout = [];
    for (ViewItem viewItem in this.viewItems) {
      Size _viewSize = isHorizontal
          ? Size(viewItem.size, viewportSize.height)
          : Size(viewportSize.width, viewItem.size);

      _layout.add(LayoutContext(id: viewItem.id, size: _viewSize, offset: Offset(0, offset)));
      offset += viewItem.size;
    }

    for (SashItem sash in sashItems) {
      Size _viewSize =
          isHorizontal ? Size(sash.size, viewportSize.height) : Size(viewportSize.width, sash.size);

      Offset _offset =
          isHorizontal ? Offset(_getShashtPosition(sash), 0) : Offset(0, _getShashtPosition(sash));
      _layout.add(LayoutContext(id: sash.id, size: _viewSize, offset: _offset));
    }
    _cachedLayouts = _layout;
    return _layout;
  }

  void resize(int index, double delta) {
    List<int> upIndexes = range(index, -1);
    List<int> downIndexes = range(index + 1, this.viewItems.length);
    List<double> sizes = this.viewItems.map((i) => i.size).toList();

    List<ViewItem> upItems = upIndexes.map((i) => this.viewItems[i]).toList();
    List<double> upSizes = upIndexes.map((i) => sizes[i]).toList();

    List<ViewItem> downItems = downIndexes.map((i) => this.viewItems[i]).toList();
    List<double> downSizes = downIndexes.map((i) => sizes[i]).toList();

    double minDeltaUp = upIndexes.fold(0, (r, i) => r + (this.viewItems[i].minSize - sizes[i]));
    double maxDeltaUp = upIndexes.fold(0, (r, i) => r + (this.viewItems[i].maxSize - sizes[i]));
    double maxDeltaDown = downIndexes.length == 0
        ? double.infinity
        : downIndexes.fold(0, (r, i) => r + (sizes[i] - this.viewItems[i].minSize));
    double minDeltaDown = downIndexes.length == 0
        ? double.negativeInfinity
        : downIndexes.fold(0, (r, i) => r + (sizes[i] - this.viewItems[i].maxSize));
    double minDelta = max(minDeltaUp, minDeltaDown);
    double maxDelta = min(maxDeltaDown, maxDeltaUp);

    delta = delta.clamp(minDelta, maxDelta);
    double deltaUp = delta;
    for (int i = 0; i < upItems.length; i++) {
      ViewItem item = upItems[i];
      double size = (upSizes[i] + deltaUp).clamp(item.minSize, item.maxSize);
      double viewDelta = size - upSizes[i];

      deltaUp -= viewDelta;
      item.size = size;
    }

    double deltaDown = delta;
    for (int i = 0; i < downItems.length; i++) {
      ViewItem item = downItems[i];
      double size = (downSizes[i] - deltaDown).clamp(item.minSize, item.maxSize);
      double viewDelta = size - downSizes[i];

      deltaDown += viewDelta;
      item.size = size;
    }
    notifyListeners();
  }
}
