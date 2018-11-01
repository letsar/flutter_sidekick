import 'package:example/screens/bubbles.dart';
import 'package:flutter/material.dart';
import 'package:example/screens/wrap.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Sidekick Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new HomePage(),
      routes: <String, WidgetBuilder>{
        'wrap': (context) =>
            SimpleScaffold(title: 'Wrap', child: WrapExample()),
        'bubbles': (context) =>
            SimpleScaffold(title: 'Bubbles', child: BubblesExample()),
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
          HomeTile('Wrap', Colors.indigo, 'wrap'),
          HomeTile('Bubbles', Colors.green, 'bubbles'),
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
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
      ),
      body: child,
    );
  }
}
