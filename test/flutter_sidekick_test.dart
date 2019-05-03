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
    this.keepShowingSource = false,
  ]);
  final String sourceTag;
  final String targetTag;
  final bool keepShowingSource;

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
                keepShowingWidget: widget.keepShowingSource,
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
  SidekickTeamBuilderExample(
    this.teamKey, [
    List<Item> sourceList,
    List<Item> targetList,
  ])  : sourceList = sourceList ?? List.generate(4, (i) => Item(i)),
        targetList = targetList ?? List.generate(4, (i) => Item(i + 4));
  final List<Item> sourceList;
  final List<Item> targetList;
  final Key teamKey;

  @override
  Widget build(BuildContext context) {
    return SidekickTeamBuilder<Item>(
      key: teamKey,
      animationDuration: Duration(milliseconds: 1000),
      initialSourceList: sourceList,
      initialTargetList: targetList,
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
            SizedBox(
              height: 50.0,
              child: Row(
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
            message,
          ),
        );
      },
    );
  }
}

void main() {
  group('Sidekick', () {
    testWidgets('Animate to target', (WidgetTester tester) async {
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
      expect(find.byKey(simpleTarget), isInCard);
    });

    testWidgets('Animate to target with keepShowing source',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(home: SimpleExample('source', 'target', true)));

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

    testWidgets('Animate to source', (WidgetTester tester) async {
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
      expect(find.byKey(simpleSource), isInCard);
    });

    testWidgets('Same key, throws', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SimpleExample('tag', 'tag')));
      await tester.tap(find.byKey(simpleSource));
      await tester.pump(); // the animation will start at the next frame.
      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('Target grows mid-flight', (WidgetTester tester) async {
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

    testWidgets('Source shrinks mid-flight', (WidgetTester tester) async {
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

    testWidgets('Target scrolls mid-flight', (WidgetTester tester) async {
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

    testWidgets('Source scrolls mid-flight', (WidgetTester tester) async {
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
  });

  group('SidekickTeamBuilder ', () {
    testWidgets('lists are changed after moveAllToSource',
        (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      await tester
          .pumpWidget(MaterialApp(home: SidekickTeamBuilderExample(key)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      state.moveAllToSource().then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1001));

      expect(logs, <String>['complete']);

      expect(
        state.sourceList,
        containsAllItemsInOrder([0, 1, 2, 3, 4, 5, 6, 7]),
      );
      expect(state.targetList.length, 0);
    });

    testWidgets('lists are changed after moveAllToTarget',
        (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      await tester
          .pumpWidget(MaterialApp(home: SidekickTeamBuilderExample(key)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      state.moveAllToTarget().then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1001));

      expect(logs, <String>['complete']);

      expect(
        state.targetList,
        containsAllItemsInOrder([4, 5, 6, 7, 0, 1, 2, 3]),
      );
      expect(state.sourceList.length, 0);
    });

    testWidgets('correct item is moved', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      state.move(sourceList[2]).then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1001));

      expect(logs, <String>['complete']);

      expect(
        state.sourceList,
        containsAllItemsInOrder([0, 1, 3]),
      );
      expect(
        state.targetList,
        containsAllItemsInOrder([4, 5, 6, 7, 2]),
      );

      state.move(sourceList[2]).then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1001));

      expect(logs, <String>['complete', 'complete']);

      expect(
        state.sourceList,
        containsAllItemsInOrder([0, 1, 3, 2]),
      );
      expect(
        state.targetList,
        containsAllItemsInOrder([4, 5, 6, 7]),
      );
    });

    testWidgets('item is animated', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));
      final item = sourceList[2];

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));
      expect(find.text(item.message), findsOneWidget);

      final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
      final double initialHeight =
          tester.getSize(find.text(item.message)).height;
      expect(initialTop, 200.0);
      expect(initialHeight, 50.0);

      state.move(sourceList[2]).then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final double midTop = tester.getTopLeft(find.text(item.message)).dy;
      final double midHeight = tester.getSize(find.text(item.message)).height;
      expect(midTop, closeTo(100.0, 0.1));
      expect(midHeight, closeTo(40.0, 0.1));

      await tester.pump(const Duration(milliseconds: 500));

      final double finalTop = tester.getTopLeft(find.text(item.message)).dy;
      final double finalHeight = tester.getSize(find.text(item.message)).height;
      expect(finalTop, 0.0);
      expect(finalHeight, 30.0);

      await tester.pump(const Duration(milliseconds: 1));

      final double finalFrameTop =
          tester.getTopLeft(find.text(item.message)).dy;
      final double finalFrameHeight =
          tester.getSize(find.text(item.message)).height;
      expect(finalFrameTop, 0.0);
      expect(finalFrameHeight, 30.0);

      expect(logs, <String>['complete']);
    });

    testWidgets('items are animated to target', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      for (var item in sourceList) {
        expect(find.text(item.message), findsOneWidget);

        final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
        final double initialHeight =
            tester.getSize(find.text(item.message)).height;
        expect(initialTop, 200.0);
        expect(initialHeight, 50.0);
      }

      state.moveAllToTarget().then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in sourceList) {
        final double midTop = tester.getTopLeft(find.text(item.message)).dy;
        final double midHeight = tester.getSize(find.text(item.message)).height;
        expect(midTop, closeTo(100.0, 0.1));
        expect(midHeight, closeTo(40.0, 0.1));
      }
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in sourceList) {
        final double finalTop = tester.getTopLeft(find.text(item.message)).dy;
        final double finalHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalTop, 0.0);
        expect(finalHeight, 30.0);
      }

      await tester.pump(const Duration(milliseconds: 1));

      for (var item in sourceList) {
        final double finalFrameTop =
            tester.getTopLeft(find.text(item.message)).dy;
        final double finalFrameHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalFrameTop, 0.0);
        expect(finalFrameHeight, 30.0);
      }

      expect(logs, <String>['complete']);
    });

    testWidgets('items are animated to source', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      for (var item in targetList) {
        expect(find.text(item.message), findsOneWidget);

        final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
        final double initialHeight =
            tester.getSize(find.text(item.message)).height;
        expect(initialTop, 0.0);
        expect(initialHeight, 30.0);
      }

      state.moveAllToSource().then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in targetList) {
        final double midTop = tester.getTopLeft(find.text(item.message)).dy;
        final double midHeight = tester.getSize(find.text(item.message)).height;
        expect(midTop, closeTo(100.0, 0.1));
        expect(midHeight, closeTo(40.0, 0.1));
      }
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in targetList) {
        final double finalTop = tester.getTopLeft(find.text(item.message)).dy;
        final double finalHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalTop, 200.0);
        expect(finalHeight, 50.0);
      }

      await tester.pump(const Duration(milliseconds: 1));

      for (var item in targetList) {
        final double finalFrameTop =
            tester.getTopLeft(find.text(item.message)).dy;
        final double finalFrameHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalFrameTop, 200.0);
        expect(finalFrameHeight, 50.0);
      }

      expect(logs, <String>['complete']);
    });

    testWidgets('items not moved do not animate', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final List<String> logs = <String>[];
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      for (var item in sourceList) {
        expect(find.text(item.message), findsOneWidget);

        final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
        final double initialHeight =
            tester.getSize(find.text(item.message)).height;
        expect(initialTop, 200.0);
        expect(initialHeight, 50.0);
      }

      state.moveAllToSource().then((_) => logs.add('complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in sourceList) {
        final double midTop = tester.getTopLeft(find.text(item.message)).dy;
        final double midHeight = tester.getSize(find.text(item.message)).height;
        expect(midTop, 200.0);
        expect(midHeight, 50.0);
      }
      await tester.pump(const Duration(milliseconds: 500));

      for (var item in sourceList) {
        final double finalTop = tester.getTopLeft(find.text(item.message)).dy;
        final double finalHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalTop, 200.0);
        expect(finalHeight, 50.0);
      }

      await tester.pump(const Duration(milliseconds: 1));

      for (var item in sourceList) {
        final double finalFrameTop =
            tester.getTopLeft(find.text(item.message)).dy;
        final double finalFrameHeight =
            tester.getSize(find.text(item.message)).height;
        expect(finalFrameTop, 200.0);
        expect(finalFrameHeight, 50.0);
      }

      expect(logs, <String>['complete']);
    });

    testWidgets('new lists rebuild', (WidgetTester tester) async {
      final key = GlobalKey<SidekickTeamBuilderState<Item>>();
      final sourceList = List.generate(4, (i) => Item(i));
      final targetList = List.generate(4, (i) => Item(i + 4));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, sourceList, targetList)));

      final SidekickTeamBuilderState<Item> state = key.currentState;

      expect(state.sourceList, containsAllItemsInOrder([0, 1, 2, 3]));
      expect(state.targetList, containsAllItemsInOrder([4, 5, 6, 7]));

      for (var item in sourceList) {
        expect(find.text(item.message), findsOneWidget);

        final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
        final double initialHeight =
            tester.getSize(find.text(item.message)).height;
        expect(initialTop, 200.0);
        expect(initialHeight, 50.0);
      }

      final newSourceList = List.generate(2, (i) => Item(i));
      final newTargetList = List.generate(2, (i) => Item(i + 2));

      await tester.pumpWidget(MaterialApp(
          home: SidekickTeamBuilderExample(key, newSourceList, newTargetList)));

      expect(state.sourceList, containsAllItemsInOrder([0, 1]));
      expect(state.targetList, containsAllItemsInOrder([2, 3]));

      for (var item in newSourceList) {
        expect(find.text(item.message), findsOneWidget);

        final double initialTop = tester.getTopLeft(find.text(item.message)).dy;
        final double initialHeight =
            tester.getSize(find.text(item.message)).height;
        expect(initialTop, 200.0);
        expect(initialHeight, 50.0);
      }
    });
  });
}

Matcher containsAllItemsInOrder(List<int> expected) =>
    new _ItemContainsInOrder(expected);

class _ItemContainsInOrder extends Matcher {
  _ItemContainsInOrder(this.ids);
  final List<int> ids;

  @override
  Description describe(Description description) =>
      description.add('contains in order(').addDescriptionOf(ids).add(')');

  String _test(List<Item> item, Map matchState) {
    var matcherIndex = 0;
    for (var value in item) {
      if (ids[matcherIndex] == value.index) matcherIndex++;
      if (matcherIndex == item.length) return null;
    }
    return new StringDescription()
        .add('did not find a value matching ')
        .addDescriptionOf(ids[matcherIndex])
        .add(' following expected prior values')
        .toString();
  }

  @override
  bool matches(item, Map matchState) => _test(item, matchState) == null;

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription.add(_test(item, matchState));
}
