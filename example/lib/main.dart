import 'package:flutter/material.dart';
import 'screens/bubbles.dart';
import 'screens/simple.dart';
import 'screens/wrap.dart';
import 'screens/wrap_change.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sidekick Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      routes: <String, WidgetBuilder>{
        'simple': (context) =>
            SimpleScaffold(title: 'Simple', child: SimpleExample()),
        'wrap': (context) =>
            SimpleScaffold(title: 'Wrap', child: WrapExample()),
        'bubbles': (context) =>
            SimpleScaffold(title: 'Bubbles', child: BubblesExample()),
        'wrap_change': (context) =>
            SimpleScaffold(title: 'Wrap change', child: WrapChangeExample()),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sidekick Demo')),
      body: ListView(
        children: <Widget>[
          HomeTile('Simple', Colors.red, 'simple'),
          HomeTile('Wrap', Colors.indigo, 'wrap'),
          HomeTile('Bubbles', Colors.green, 'bubbles'),
          HomeTile('Wrap change', Colors.pink, 'wrap_change'),
        ],
      ),
    );
  }
}

class HomeTile extends StatelessWidget {
  HomeTile(
    this.title,
    this.color,
    this.route,
  );

  final String title;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.title.copyWith(
                  color: ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleScaffold extends StatelessWidget {
  const SimpleScaffold({
    Key key,
    this.title,
    this.child,
  }) : super(key: key);

  final String title;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: child,
    );
  }
}
