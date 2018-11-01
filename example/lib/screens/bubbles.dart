import 'package:example/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sidekick/flutter_sidekick.dart';

class BubblesExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SidekickTeamBuilder<String>(
      animationDuration: Duration(milliseconds: 500),
      initialSourceList: <String>[
        'Log\nextension',
        'Goblet\nSquats',
        'Squats',
        'Barbell\nLunge',
        'Burpee',
        'Dumbell\nLunge',
        'Front\nSquats',
      ],
      builder: (context, sourceBuilderDelegates, targetBuilderDelegates) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 150.0),
                  child: Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: targetBuilderDelegates.map((builderDelegate) {
                      return builderDelegate.build(
                        context,
                        GestureDetector(
                          onTap: () => SidekickTeamBuilder.of<String>(context)
                              .move(builderDelegate.message),
                          child: Bubble(
                            radius: 30.0,
                            fontSize: 12.0,
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                builderDelegate.message,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        animationBuilder: (animation) => CurvedAnimation(
                              parent: animation,
                              curve: FlippedCurve(Curves.easeOut),
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
                              builderDelegate.message,
                            ),
                      );
                    }).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CircleButton(
                      text: '>',
                      onPressed: () => SidekickTeamBuilder.of<String>(context)
                          .moveAll(SidekickFlightDirection.toSource),
                    ),
                    SizedBox(width: 60.0, height: 60.0),
                    CircleButton(
                      text: '<',
                      onPressed: () => SidekickTeamBuilder.of<String>(context)
                          .moveAll(SidekickFlightDirection.toTarget),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: sourceBuilderDelegates.map((builderDelegate) {
                    return builderDelegate.build(
                      context,
                      GestureDetector(
                        onTap: () => SidekickTeamBuilder.of<String>(context)
                            .move(builderDelegate.message),
                        child: Bubble(
                          radius: 50.0,
                          fontSize: 20.0,
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(
                              builderDelegate.message,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      animationBuilder: (animation) => CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
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
                            builderDelegate.message,
                          ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
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
        return Bubble(
          radius: Tween<double>(begin: 50.0, end: 30.0).evaluate(animation),
          fontSize: Tween<double>(begin: 20.0, end: 12.0).evaluate(animation),
          backgroundColor: ColorTween(begin: Colors.green, end: Colors.blue)
              .evaluate(animation),
          foregroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

class Bubble extends StatelessWidget {
  const Bubble({
    Key key,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.radius,
    this.fontSize,
  }) : super(key: key);

  final Widget child;

  final Color backgroundColor;

  final Color foregroundColor;

  final double radius;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TextStyle textStyle =
        theme.primaryTextTheme.subhead.copyWith(color: foregroundColor);
    Color effectiveBackgroundColor = backgroundColor;
    if (effectiveBackgroundColor == null) {
      switch (ThemeData.estimateBrightnessForColor(textStyle.color)) {
        case Brightness.dark:
          effectiveBackgroundColor = theme.primaryColorLight;
          break;
        case Brightness.light:
          effectiveBackgroundColor = theme.primaryColorDark;
          break;
      }
    } else if (foregroundColor == null) {
      switch (ThemeData.estimateBrightnessForColor(backgroundColor)) {
        case Brightness.dark:
          textStyle = textStyle.copyWith(color: theme.primaryColorLight);
          break;
        case Brightness.light:
          textStyle = textStyle.copyWith(color: theme.primaryColorDark);
          break;
      }
    }

    textStyle = textStyle.copyWith(fontSize: fontSize);

    final double diameter = radius * 2;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: IconTheme(
          data: theme.iconTheme.copyWith(color: textStyle.color),
          child: DefaultTextStyle(
            style: textStyle,
            child: child,
          ),
        ),
      ),
    );
  }
}
