import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playground/split_view/split_view_model.dart' as SplitModel;

void main() {
  SplitModel.SplitViewModel model;
  setUp(() {
    model = SplitModel.SplitViewModel(
        viewportSize: Size(1000, 1000), orientation: SplitModel.Orientation.HORIZONTAL);
  });
  group('SplitView addView method', () {
    test('addView without resizing', () {
      model.size = 1000;
      model.viewItems = [];
      model.addView(Container(), size: 100, skipLayout: true);
      expect(model.viewItems.length, 1);
      expect(model.viewItems.first.size, 100);
      model.addView(Container(), size: 50, skipLayout: true);
      expect(model.viewItems[1].size, 50);
    });

    test('addView only the last one resizing', () {
      model.size = 1000;
      model.viewItems = [];
      model.addView(Container(), size: 100, minSize: 100, maxSize: 120);
      model.addView(Container(), size: 100, minSize: 100, maxSize: 120);
      model.addView(Container(), size: 100, minSize: 100, maxSize: 120);
      model.addView(Container(), size: 100);

      expect(model.viewItems[0].size, 115);
      expect(model.viewItems[1].size, 115);
      expect(model.viewItems[2].size, 115);
      expect(model.viewItems[3].size, 655);
    });
  });
}
