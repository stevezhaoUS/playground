import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:playground/split_view/split_view.dart';
import 'package:playground/split_view/split_view_model.dart' as Base;
import 'package:provider/provider.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Demo(),
      ),
    ),
  ));
}

class Demo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints constraints) {
      return ChangeNotifierProvider(
          create: (BuildContext context) {
            Base.SplitViewModel model = Base.SplitViewModel(
              orientation: Base.Orientation.VERTICAL,
              viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
            );
            model.addView(BoxView(color: Colors.red), minSize: 100);
            model.addView(BoxView(color: Colors.blue), minSize: 50);
            model.addView(BoxView(color: Colors.green), minSize: 200, maxSize: 200);
            return model;
          },
          child: SplitView(width: constraints.maxWidth, height: constraints.maxHeight));
    });
  }
}

enum SplitViewMethod {
  ByPercentage,
  Distrubute,
  Numeric,
}

class BoxView extends StatelessWidget {
  final Color color;

  BoxView({@required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Text('Box'),
    );
  }
}
