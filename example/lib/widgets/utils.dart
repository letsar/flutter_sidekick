import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  CircleButton({
    @required this.text,
    @required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60.0,
      width: 60.0,
      child: RaisedButton(
        child: RotatedBox(quarterTurns: 1, child: Text(text)),
        color: Colors.blue,
        colorBrightness: Brightness.dark,
        shape: CircleBorder(),
        onPressed: onPressed,
      ),
    );
  }
}
