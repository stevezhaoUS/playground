import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'split_view_model.dart';

class SplitView extends StatelessWidget {
  final double width;
  final double height;

  const SplitView({Key key, this.width, this.height}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<SplitViewModel>(builder: (context, model, child) {
      return Container(
          width: width,
          height: height,
          child: CustomMultiChildLayout(
              children: model.views, delegate: SplitViewDelegate(model, Size(width, height))));
    });
  }
}

class SplitViewDelegate extends MultiChildLayoutDelegate {
  SplitViewModel model;
  Size viewSize;
  SplitViewDelegate(this.model, this.viewSize);
  @override
  void performLayout(Size size) {
    for (LayoutContext layout in model.layouts) {
      if (hasChild(layout.id)) {
        layoutChild(
            layout.id,
            BoxConstraints(
                maxWidth: double.infinity,
                minWidth: layout.size.width,
                minHeight: layout.size.height,
                maxHeight: layout.size.height));

        positionChild(layout.id, layout.offset);
      }
    }
  }

  @override
  bool shouldRelayout(covariant SplitViewDelegate oldDelegate) {
    // return viewSize != oldDelegate.viewSize;
    return true;
  }
}
