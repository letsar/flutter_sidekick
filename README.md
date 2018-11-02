# flutter_sidekick

Widgets for creating Hero-like animations between two widgets within the same screen.

[![Pub](https://img.shields.io/pub/v/flutter_sidekick.svg)](https://pub.dartlang.org/packages/flutter_sidekick)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QTT34M25RDNL6)

![Logo](https://raw.githubusercontent.com/letsar/flutter_sidekick/master/doc/images/sidekick_logo_220x321.png)

![Overview](https://raw.githubusercontent.com/letsar/flutter_sidekick/master/doc/images/bubble_overview.gif)

## Features

* Hero-Like animations.
* Widget to manage animations between children of two multi-child widgets.

## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:
The latest version is [![Pub](https://img.shields.io/pub/v/flutter_sidekick.svg)](https://pub.dartlang.org/packages/flutter_sidekick)

```yaml
dependencies:
  ...
  flutter_sidekick: ^latest_version
```

In your library add the following import:

```dart
import 'package:flutter_sidekick/flutter_sidekick.dart';
```

For help getting started with Flutter, view the online [documentation](https://flutter.io/).

## Widgets

### Sidekick

The `Sidekick` widget is **heavily** inspired by the [Hero](https://docs.flutter.io/flutter/widgets/Hero-class.html) widget API.
To link two sidekicks, the `targetTag` property of the one denoted as the **source** must be identical to the `tag` property of the other one, denoted the **target**.
Then to animate sidekicks, you can use the `SidekickController` and one of the *move* function.

The animation below can be created with the following code:

![Simple Overview](https://raw.githubusercontent.com/letsar/flutter_sidekick/master/doc/images/simple_overview.gif)

```dart
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
```

### SidekickTeamBuilder

The `SidekickTeamBuilder` widget can be used to create complex layouts, where widgets from one container can be moved to another one, and you want the transition to be animated:

![Wrap Overview](https://raw.githubusercontent.com/letsar/flutter_sidekick/master/doc/images/wrap_overview.gif)

```dart
import 'package:example/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';

class Item {
  Item({
    this.id,
  });
  final int id;
}

class WrapExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SidekickTeamBuilder<Item>(
      initialSourceList: List.generate(20, (i) => Item(id: i)),
      builder: (context, sourceBuilderDelegates, targetBuilderDelegates) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 120.0,
                child: Wrap(
                  children: sourceBuilderDelegates
                      .map((builderDelegate) => builderDelegate.build(
                            context,
                            WrapItem(builderDelegate.message, true),
                            animationBuilder: (animation) => CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.ease,
                                ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircleButton(
                      text: '>',
                      onPressed: () => SidekickTeamBuilder.of<Item>(context)
                          .moveAll(SidekickFlightDirection.toTarget),
                    ),
                    SizedBox(width: 60.0, height: 60.0),
                    CircleButton(
                      text: '<',
                      onPressed: () => SidekickTeamBuilder.of<Item>(context)
                          .moveAll(SidekickFlightDirection.toSource),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250.0,
                child: Wrap(
                  children: targetBuilderDelegates
                      .map((builderDelegate) => builderDelegate.build(
                            context,
                            WrapItem(builderDelegate.message, false),
                            animationBuilder: (animation) => CurvedAnimation(
                                  parent: animation,
                                  curve: FlippedCurve(Curves.ease),
                                ),
                          ))
                      .toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class WrapItem extends StatelessWidget {
  const WrapItem(
    this.item,
    this.isSource,
  ) : size = isSource ? 40.0 : 50.0;
  final bool isSource;
  final double size;
  final Item item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SidekickTeamBuilder.of<Item>(context).move(item),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          height: size - 4,
          width: size - 4,
          color: _getColor(item.id),
        ),
      ),
    );
  }

  Color _getColor(int index) {
    switch (index % 4) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.red;
    }
    return Colors.indigo;
  }
}
```

## Changelog

Please see the [Changelog](https://github.com/letsar/flutter_sidekick/blob/master/CHANGELOG.md) page to know what's recently changed.

## Contributions

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an [issue](https://github.com/letsar/flutter_sidekick/issues).  
If you fixed a bug or implemented a new feature, please send a [pull request](https://github.com/letsar/flutter_sidekick/pulls).