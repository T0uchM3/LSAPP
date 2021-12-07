import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Answer extends StatefulWidget {
  final String? answerText;
  final Color? answerColor;
  final Function()? answerTap;
  final bool? valid;
  Answer({this.answerText, this.answerColor, this.answerTap, this.valid});
  @override
  _answer createState() => _answer();
}

class _answer extends State<Answer> {
  int x = 1;
  bool click = false;
  // final String? answerText;
  // final Color? answerColor;
  // final Function()? answerTap;

  // _answer({this.answerText, this.answerColor, this.answerTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.answerTap,
      // onTap: () => setState(() {
      //   click = !click;
      // }),
      onTapDown: (TapDownDetails details) {
        setState(() {
          click = !click;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
        width: double.infinity,
        decoration: BoxDecoration(
          // color: widget.answerColor,
          // color: _flag ? Colors.red : Colors.teal,
          color: (click == false)
              ? Colors.white70
              : ((widget.valid == true))
                  ? Colors.green
                  : Colors.red,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          widget.answerText!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25.0,
          ),
        ),
      ),
    );
  }
}