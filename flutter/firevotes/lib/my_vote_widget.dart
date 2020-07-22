import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MyVoteWidget extends StatelessWidget {
  final String roundKey;
  final List<String> round;
  final void Function(String, String) callback;
  final int index;

  MyVoteWidget(this.roundKey, this.round, this.index, this.callback);

  @override
  Widget build(BuildContext context) {
    var option1 = this.index < round?.length ?? 0 ? round[this.index]   : "...";
    var option2 = this.index < round?.length ?? 0 ? round[this.index+1] : "...";
    return Column(children: <Widget>[
      Text(this.roundKey != null ? this.roundKey : "Loading..."),
      Row(children: <Widget>[
        Expanded(child: RaisedButton(onPressed: () { callback(roundKey, option1); }, child: Text(option1), color: Color(0xFFFFA000))),
        Expanded(child: RaisedButton(onPressed: () { callback(roundKey, option2); }, child: Text(option2), color: Color(0xFFFF8A65)))
      ]),
    ]);
  }
}