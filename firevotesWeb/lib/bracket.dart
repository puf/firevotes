import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

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
  Map<String, StreamSubscription<DatabaseEvent>> roundOptionsListeners = Map();
  Map<String, StreamSubscription<DatabaseEvent>> roundTotalsListeners = Map();

  BracketState(this.dbRoot) {
    dbRoot.child('current_bracket').onValue.listen((event) {
      setRounds(event);
      addRoundsListeners(event);
      removeOutdatedListeners(event);
    });
  }

  void setRounds(DatabaseEvent event) {
    if (!event.snapshot.exists) return;
    setState(() {
      roundKeys = Map<String,String>.from(event.snapshot.value as Map<dynamic, dynamic>).values.toList();
    });
  }

  void addRoundsListeners(DatabaseEvent event) {
    if (!event.snapshot.exists) return;

    roundKeys.forEach((roundKey) {
      if (!roundOptionsListeners.containsKey(roundKey)) {
        roundOptionsListeners[roundKey] = dbRoot.child('/rounds/$roundKey').onValue.listen((event) {
          roundOptions[roundKey] = List<String>.from(event.snapshot.value as List<dynamic>);
          setState(() { });
        });
        roundTotalsListeners[roundKey] = dbRoot.child('/totals/$roundKey').onValue.listen((event) {
          if (event.snapshot.exists) {
            roundTotals[roundKey] = Map<String,int>.from(event.snapshot.value);
            setState(() { });
          }
        });
      }
    });
  }

  void removeOutdatedListeners(DatabaseEvent event) {
    roundOptionsListeners.forEach((key, value) {
      if (!roundKeys.contains(key)) {
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

class BracketPainter extends CustomPainter {
  final BracketState bracket;

  const BracketPainter(Key key, this.bracket);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    // Left top
    canvas.drawLine(Offset( 50, 40), Offset(160, 40), paint);
    canvas.drawLine(Offset( 50,180), Offset(160,180), paint);
    canvas.drawLine(Offset(160, 40), Offset(160,180), paint);

    // Left bottom
    canvas.drawLine(Offset( 50,310), Offset(160,310), paint);
    canvas.drawLine(Offset( 50,450), Offset(160,450), paint);
    canvas.drawLine(Offset(160,310), Offset(160,450), paint);

    // Left center
    canvas.drawLine(Offset(160,110), Offset(280,110), paint);
    canvas.drawLine(Offset(160,380), Offset(280,380), paint);
    canvas.drawLine(Offset(280,110), Offset(280,380), paint);

    // Left finalist
    canvas.drawLine(Offset(280,210), Offset(390,210), paint);

    // Right top
    canvas.drawLine(Offset(650, 40), Offset(540, 40), paint);
    canvas.drawLine(Offset(650,180), Offset(540,180), paint);
    canvas.drawLine(Offset(540, 40), Offset(540,180), paint);

    // Right bottom
    canvas.drawLine(Offset(650,310), Offset(540,310), paint);
    canvas.drawLine(Offset(650,450), Offset(540,450), paint);
    canvas.drawLine(Offset(540,310), Offset(540,450), paint);

    // Right center
    canvas.drawLine(Offset(540,110), Offset(420,110), paint);
    canvas.drawLine(Offset(540,380), Offset(420,380), paint);
    canvas.drawLine(Offset(420,110), Offset(420,380), paint);

    // Right finalist
    canvas.drawLine(Offset(420,290), Offset(310,290), paint);

    if (bracket != null) {
      bracket.roundKeys.forEach((roundKey) {
        var options = bracket.roundOptions[roundKey] ?? [];
        var totals = bracket.roundTotals[roundKey] ?? Map();

        List<Offset> offsets;
        if (options.length == 8) {
          offsets = [
            Offset( 50,  10),
            Offset( 50, 180),
            Offset( 50, 280),
            Offset( 50, 450),
            Offset(540,  10),
            Offset(540, 180),
            Offset(540, 280),
            Offset(540, 450),
          ];
        }
        else if (options.length == 4) {
          offsets = [
            Offset(165,  80),
            Offset(165, 380),
            Offset(420,  80),
            Offset(420, 380),
          ];
        }
        else if (options.length == 2) {
          offsets = [
            Offset(285, 180),
            Offset(310, 290),
          ];
        }
        else if (options.length == 0) {
          print("Waiting for options for round $roundKey to load");
        }
        else throw Exception('Invalid number of options in round $roundKey: ${options.length}');
        var getTotalForOption = ((i) {
          var option = options[i];
          var total = totals.containsKey(option) ? totals[option] : 0;
          return total;
        });
        for (var i=0; i < options.length; i++) {
          var option = options[i];
          var total = totals.containsKey(option) ? totals[option] : 0;
          var isLeading = total > (i % 2 == 0 ? getTotalForOption(i+1) : getTotalForOption(i-1));
          var text = i<options.length/2 ? option+": "+total.toString() : total.toString()+": "+option;
          //Divide width by 5.3 (number of segments -> [rounds * 2] - 1) plus a little smaller
          paintTextAt(canvas, text, 24, isLeading ? Colors.black : Colors.black54, size.width / 5.3, offsets[i]);
        }
      });
    }
  }

  void paintTextAt(Canvas canvas, String text, double fontSize, Color color, double maxWidth, Offset offset) {
    var textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fontSize)
      ),
      textDirection: TextDirection.ltr,)
      ..layout(
        minWidth: 0,
        maxWidth: maxWidth,
      );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(BracketPainter oldDelegate) {
    var eq = MapEquality().equals;
    return eq(oldDelegate.bracket.roundTotals, this.bracket.roundTotals);
  }
}
