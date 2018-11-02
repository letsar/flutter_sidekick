import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';

Duration frameDuration = const Duration(milliseconds: 16);
Key simpleSource = const Key('simple-source');
Key simpleTarget = const Key('simple-target');

class SimpleExample extends StatefulWidget {
  SimpleExample([
    this.sourceTag = 'source',
    this.targetTag = 'target',
  ]);
  final String sourceTag;
  final String targetTag;

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
            child: Card(
              margin: const EdgeInsets.all(0.0),
              child: Sidekick(
                tag: widget.sourceTag,
                targetTag: widget.targetTag,
                child: Container(
                  key: simpleSource,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20.0,
          right: 20.0,
          width: 150.0,
          height: 150.0,
          child: GestureDetector(
            onTap: () => controller.moveToSource(context),
            child: Card(
              margin: const EdgeInsets.all(0.0),
              child: Sidekick(
                tag: widget.targetTag,
                child: Container(
                  key: simpleTarget,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Item {
  Item(this.index);
  final int index;
  String get message => 'Item$index';
}

class SidekickTeamBuilderExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SidekickTeamBuilder<Item>(
      animationDuration: Duration(milliseconds: 1000),
      initialSourceList: List.generate(8, (i) => Item(i)),
      builder: (context, sourceBuilderDelegates, targetBuilderDelegates) {
        return ListView(
          children: <Widget>[
            SizedBox(
              height: 150.0,
              child: Wrap(
                children: targetBuilderDelegates.map((builderDelegate) {
                  return builderDelegate.build(
                    context,
                    GestureDetector(
                      onTap: () =>
                          builderDelegate.state.move(builderDelegate.message),
                      child: Container(
                        height: 30.0,
                        width: 30.0,
                        color: Colors.blue,
                        child: Text(
                          builderDelegate.message.message,
                        ),
                      ),
                    ),
                    flightShuttleBuilder: (
                      context,
                      animation,
                      type,
                      from,
                      to,
                    ) =>
                        buildShuttle(
                          animation,
                          builderDelegate.message.message,
                        ),
                  );
                }).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  child: const Text('alltosource'),
                  onPressed: () => SidekickTeamBuilder.of<String>(context)
                      .moveAll(SidekickFlightDirection.toSource),
                ),
                RaisedButton(
                  child: const Text('alltotarget'),
                  onPressed: () => SidekickTeamBuilder.of<String>(context)
                      .moveAll(SidekickFlightDirection.toTarget),
                ),
              ],
            ),
            Wrap(
              children: sourceBuilderDelegates.map((builderDelegate) {
                return builderDelegate.build(
                  context,
                  GestureDetector(
                    onTap: () =>
                        builderDelegate.state.move(builderDelegate.message),
                    child: Container(
                      height: 50.0,
                      width: 50.0,
                      color: Colors.green,
                      child: Text(
                        builderDelegate.message.message,
                      ),
                    ),
                  ),
                  flightShuttleBuilder: (
                    context,
                    animation,
                    type,
                    from,
                    to,
                  ) =>
                      buildShuttle(
                        animation,
                        builderDelegate.message.message,
                      ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget buildShuttle(
    Animation<double> animation,
    String message,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Container(
          width: Tween<double>(begin: 50.0, end: 30.0).evaluate(animation),
          height: Tween<double>(begin: 50.0, end: 30.0).evaluate(animation),
          child: Text(
            message + animation.value.toStringAsFixed(2),
          ),
        );
      },
    );
  }
}

void main() {
  testWidgets('Sidekick animate to target', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));

    // the initial setup.
    expect(find.byKey(simpleSource), isInCard);
    expect(find.byKey(simpleTarget), isInCard);

    await tester.tap(find.byKey(simpleSource));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);

    // at this stage, the sidekick just gone on its journey, we are
    // seeing them at t=16ms.

    expect(find.byKey(simpleSource), findsNothing);
    expect(find.byKey(simpleTarget), isNotInCard);

    await tester.pump(frameDuration);

    // t=32ms for the journey. Surely they are still at it.
    expect(find.byKey(simpleSource), findsNothing);
    expect(find.byKey(simpleTarget), isNotInCard);

    await tester.pump(const Duration(seconds: 1));

    // t=1.033s for the journey. The journey has ended (it ends this frame, in
    // fact). The sidekicks should be back now.
    expect(find.byKey(simpleSource), isInCard);
    expect(find.byKey(simpleTarget), isInCard);
  });

  testWidgets('Sidekick animate to source', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));

    // the initial setup.
    expect(find.byKey(simpleSource), isInCard);
    expect(find.byKey(simpleTarget), isInCard);

    await tester.tap(find.byKey(simpleTarget));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);

    // at this stage, the sidekick just gone on its journey, we are
    // seeing them at t=16ms.

    expect(find.byKey(simpleTarget), findsNothing);
    expect(find.byKey(simpleSource), isNotInCard);

    await tester.pump(frameDuration);

    // t=32ms for the journey. Surely they are still at it.
    expect(find.byKey(simpleTarget), findsNothing);
    expect(find.byKey(simpleSource), isNotInCard);

    await tester.pump(const Duration(seconds: 1));

    // t=1.033s for the journey. The journey has ended (it ends this frame, in
    // fact). The sidekicks should be back now.
    expect(find.byKey(simpleTarget), isInCard);
    expect(find.byKey(simpleSource), isInCard);
  });

  testWidgets('Sidekicks with same key crash', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample('tag', 'tag')));
    await tester.tap(find.byKey(simpleSource));
    await tester.pump(); // the animation will start at the next frame.
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('Target Sidekick grows mid-flight', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));
    final double initialHeight =
        tester.getSize(find.byKey(simpleSource)).height;

    await tester.tap(find.byKey(simpleSource));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);
    await tester.pump(const Duration(milliseconds: 500));

    double midflightHeight = tester.getSize(find.byKey(simpleTarget)).height;
    expect(midflightHeight, greaterThan(initialHeight));
    expect(midflightHeight, lessThan(150.0));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    double finalHeight = tester.getSize(find.byKey(simpleTarget)).height;
    expect(finalHeight, 150.0);
  });

  testWidgets('Source Sidekick shrinks mid-flight',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));
    final double initialHeight =
        tester.getSize(find.byKey(simpleTarget)).height;

    await tester.tap(find.byKey(simpleTarget));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);
    await tester.pump(const Duration(milliseconds: 500));

    double midflightHeight = tester.getSize(find.byKey(simpleSource)).height;
    expect(midflightHeight, lessThan(initialHeight));
    expect(midflightHeight, greaterThan(100.0));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    double finalHeight = tester.getSize(find.byKey(simpleSource)).height;
    expect(finalHeight, 100.0);
  });

  testWidgets('Target Sidekick scrolls mid-flight',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));
    final double initialTop = tester.getTopLeft(find.byKey(simpleSource)).dy;
    expect(initialTop, 20.0);

    await tester.tap(find.byKey(simpleSource));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);
    await tester.pump(const Duration(milliseconds: 500));

    double midflightTop = tester.getTopLeft(find.byKey(simpleTarget)).dy;
    expect(midflightTop, greaterThan(initialTop));
    expect(midflightTop, lessThan(430.0));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    double finalTop = tester.getTopLeft(find.byKey(simpleTarget)).dy;
    expect(finalTop, 430.0);
  });

  testWidgets('Source Sidekick scrolls mid-flight',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SimpleExample()));
    final double initialTop = tester.getTopLeft(find.byKey(simpleTarget)).dy;
    expect(initialTop, 430.0);

    await tester.tap(find.byKey(simpleTarget));
    await tester.pump(); // the animation will start at the next frame.
    await tester.pump(frameDuration);
    await tester.pump(const Duration(milliseconds: 500));

    double midflightTop = tester.getTopLeft(find.byKey(simpleSource)).dy;
    expect(midflightTop, lessThan(initialTop));
    expect(midflightTop, greaterThan(20.0));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    double finalTop = tester.getTopLeft(find.byKey(simpleSource)).dy;
    expect(finalTop, 20.0);
  });
}
