import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firevotes/bracket_painter.dart';
import 'package:flutter/widgets.dart';

class Bracket extends StatefulWidget {
  Bracket(Key key, this.dbRoot) : super(key: key);

  final DatabaseReference dbRoot;

  @override
  BracketState createState() => BracketState(this.dbRoot);
}

class BracketState extends State<Bracket> {

  DatabaseReference dbRoot;

  List<String> roundKeys = List();
  Map<String, List<String>> roundOptions = Map();
  Map<String, Map<String, int>> roundTotals = Map();
  Map<String, StreamSubscription<Event>> roundOptionsListeners = Map();
  Map<String, StreamSubscription<Event>> roundTotalsListeners = Map();

  BracketState(this.dbRoot) {
    dbRoot.child('current_bracket').onValue.listen((event) {
      setRounds(event);
      addRoundsListeners(event);
      removeOutdatedListeners(event);
    });
  }

  void setRounds(Event event) {
    print('Got current_bracket: ${event.snapshot.value}');
    if (event.snapshot.value == null) return;
    setState(() {
      roundKeys = Map<String,String>.from(event.snapshot.value as Map<dynamic, dynamic>).values.toList();
      print('bracket.roundKeys: ${roundKeys}');
    });
  }

  void addRoundsListeners(Event event) {
    roundKeys.forEach((roundKey) {
      if (!roundOptionsListeners.containsKey(roundKey)) {
        print('Adding listener for options and totals of round $roundKey');
        roundOptionsListeners[roundKey] = dbRoot.child('/rounds/$roundKey').onValue.listen((event) {
          print('Got options for bracket round $roundKey');
          roundOptions[roundKey] = List<String>.from(event.snapshot.value as List<dynamic>);
          //TODO check if setState with empty values is even necessary
          setState(() { });
        });
        roundTotalsListeners[roundKey] = dbRoot.child('/totals/$roundKey').onValue.listen((event) {
          if (event.snapshot.value != null) {
            print('Got totals for bracket round $roundKey');
            roundTotals[roundKey] = Map<String,int>.from(event.snapshot.value as Map<dynamic, dynamic>);
            setState(() { });
          }
        });
      }
    });
  }

  void removeOutdatedListeners(Event event) {
    roundOptionsListeners.forEach((key, value) {
      if (!roundKeys.contains(key)) {
        print('Removing options listener for bracket round $key');
        if (value != null) value.cancel();
        roundOptionsListeners[key] = null;
      }
    });

    roundTotalsListeners
        .keys
        .where((key) => !roundKeys.contains(key))
        .forEach((key) {
      if (roundTotalsListeners[key] != null) roundTotalsListeners[key].cancel();
      roundTotalsListeners[key] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
            width: 700,
            height: 500,
            child: CustomPaint(
              painter: BracketPainter(Key("painter"), this),
            )
        )
    );
  }  

}
