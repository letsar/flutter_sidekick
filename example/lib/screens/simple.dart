import 'package:flutter/material.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';

class SimpleExample extends StatefulWidget {
  @override
  _SimpleExampleState createState() => _SimpleExampleState();
}

class _SimpleExampleState extends State<SimpleExample>
    with TickerProviderStateMixin {
  SidekickController controller;

  @override
  void initState() {
    super.initState();
    controller =
        SidekickController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: 20.0,
          left: 20.0,
          width: 100.0,
          height: 100.0,
          child: GestureDetector(
            onTap: () => controller.moveToTarget(context),
            child: Sidekick(
              tag: 'source',
              targetTag: 'target',
              child: Container(
                color: Colors.blue,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20.0,
          right: 20.0,
          width: 150.0,
          height: 100.0,
          child: GestureDetector(
            onTap: () => controller.moveToSource(context),
            child: Sidekick(
              tag: 'target',
              child: Container(
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
