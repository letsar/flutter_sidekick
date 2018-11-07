import 'package:flutter/material.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';

// We create a StatefulWidget because the SidekickController
// needs a TickerProvider.
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

    // We create the controller by passing a TickerProvider
    // (which is the State) and an optional duration (defaults to 300ms).
    controller = SidekickController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    // Don't forget to dispose the controller ;-).
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
            // We trigger the animation to the target by tapping
            // on this widget.
            onTap: () => controller.moveToTarget(context),
            // First Sidekick widget, called the 'source'.
            child: Sidekick(
              tag: 'source',
              // The targetTag is identical to the target's tag.
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
            // We trigger the animation to the source by tapping
            // on this widget.
            onTap: () => controller.moveToSource(context),
            // The second sidekick widget, called the target.
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
