import 'dart:async';
//import 'dart:io' show Platform;
import 'dart:math';
//import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:firebase_database/ui/firebase_list.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_database/ui/firebase_animated_list.dart';

//void main() => runApp(MyApp());
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp  app = FirebaseApp.instance;
  /*final FirebaseApp  app = await FirebaseApp.configure(
    name: "defaultAppName",
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: '1:683370992766:ios:84ac92b8f2b22ef8d6f42f',
            gcmSenderID: '683370992766',
            databaseURL: 'https://firevotes.firebaseio.com',
          )
        : const FirebaseOptions(
            googleAppID: '1:683370992766:android:619af5fbff695544d6f42f',
            apiKey: 'AIzaSyDkL7r8MePU4sU-2ipkYwZsV8digavndbg',
            databaseURL: 'https://firevotes.firebaseio.com',
          ),
  );*/
  FirebaseDatabase(app: app).setPersistenceEnabled(true); 
  FirebaseDatabase(app: app).reference().child("/rounds/r1").orderByValue().onChildAdded.forEach((event) => {
    print(event.snapshot.value)
  });

  runApp(MaterialApp(
    title: 'Flutter Database Example',
    home: MyApp(app),
  ));
}

class MyApp extends StatelessWidget {
  MyApp(this.app);

  final FirebaseApp app;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: '🔥💙 FlutterFire Votes 💙🔥', app: app),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.app}) : super(key: key);

  final FirebaseApp app;
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(this.app );
}

class Bracket {
  // String bracketKey?
  List<String> roundKeys = List();
  Map<String, List<String>> roundOptions = Map();
  Map<String, Map<String, int>> roundTotals = Map();
  Map<String, StreamSubscription<Event>> roundOptionsListeners = Map();
  Map<String, StreamSubscription<Event>> roundTotalsListeners = Map();
} 

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseApp app;
  DatabaseReference dbRoot;
  String currentRoundKey;
  List<String> currentRound;
  int currentRoundIndex;
  FirebaseUser user;
  StreamSubscription currentRoundListener;
  Bracket bracket = Bracket();

  _MyHomePageState(this.app)  {
    /*
    list = FirebaseList(query: FirebaseDatabase(app: app).reference().child("/rounds/r1"), 
      onChildAdded: (pos, snapshot) {},
      onChildRemoved: (pos, snapshot) {},
      onChildChanged: (pos, snapshot) {},
      onChildMoved: (oldpos, newpos, snapshot) {},
      onValue: (snapshot) {
        for (var i=0; i < this.list.length; i++) {
          print('$i: ${list[i].value}');
        }
      }
    );*/

    FirebaseAuth.fromApp(app).signInAnonymously().then((result) {
      setState((){
        this.user = result.user;
      });
    });
    print('Loading curent bracket...');
    dbRoot = FirebaseDatabase(app: this.app).reference();
    dbRoot.child('current_bracket').onValue.listen((event) {
      print('Got current_bracket: ${event.snapshot.value}');
      if (event.snapshot.value == null) return;
      setState(() {
        bracket.roundKeys = Map<String,String>.from(event.snapshot.value as Map<dynamic, dynamic>).values.toList();
        print('bracket.roundKeys: ${bracket.roundKeys}');
      });
      // Add new round listeners
      bracket.roundKeys.forEach((roundKey) { 
        if (!bracket.roundOptionsListeners.containsKey(roundKey)) {
          print('Adding listener for options and totals of round $roundKey');
          bracket.roundOptionsListeners[roundKey] = dbRoot.child('/rounds/$roundKey').onValue.listen((event) {
            print('Got options for bracket round $roundKey');
            bracket.roundOptions[roundKey] = List<String>.from(event.snapshot.value as List<dynamic>);
            setState(() { });
          });
          bracket.roundTotalsListeners[roundKey] = dbRoot.child('/totals/$roundKey').onValue.listen((event) {
            if (event.snapshot.value != null) {
              print('Got totals for bracket round $roundKey');
              bracket.roundTotals[roundKey] = Map<String,int>.from(event.snapshot.value as Map<dynamic, dynamic>);
              setState(() { });
            }
          });
        }
      });
      // remove outdated listeners
      bracket.roundOptionsListeners.forEach((key, value) {
        if (!bracket.roundKeys.contains(key)) {
          print('Removing options listener for bracket round $key');
          value.cancel();
          bracket.roundOptionsListeners[key] = null;
        }
      });
      bracket.roundTotalsListeners
        .keys
        .where((key) => !bracket.roundKeys.contains(key))
        .forEach((key) { 
          print('Removing totals listener for bracket round $key');
          bracket.roundTotalsListeners[key].cancel();
          bracket.roundTotalsListeners[key] = null;
        });
    });
    print('Loading current_round...');
    dbRoot.child("current_round").onValue.listen((event) {
      if (currentRoundListener != null) {
        currentRoundListener.cancel();
        currentRoundListener = null;
      }
      setState(() { 
        currentRoundKey = event.snapshot.value;
        currentRound = [];
        currentRoundIndex = 0;
      });
      if (currentRoundKey != null) {
        print('Loading round $currentRoundKey');
        currentRoundListener = dbRoot.child('rounds/$currentRoundKey').onValue.listen((event) {
          print('Got data for round $currentRoundKey: ${event.snapshot.value}');
          setState(() { 
            currentRound = List<String>.from(event.snapshot.value as List<dynamic>);
            currentRoundIndex = 2 * Random().nextInt(currentRound.length ~/ 2);
            print('On a round of ${currentRound.length}, index=$currentRoundIndex');
          });
        });
      }
    });
  }
  void vote(String roundKey, String option) {
    print('votes/$currentRoundKey/${user.uid} = $option');

    dbRoot.child('votes/$currentRoundKey/${user.uid}').set(option);
    print("You voted for $option in round $roundKey");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            currentRoundKey != null /*&& currentRound != null && currentRound.length > 0*/ ? 
              MyVoteWidget(currentRoundKey, currentRound, currentRoundIndex, vote) : 
              Text("Waiting for round to start..."),
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 700,
                height: 500,
                child: CustomPaint(
                  painter: BracketPainter2(Key("painter"), bracket),
                )
              )
            )
          ],
        ),
      ),
    );
  }
}

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
        Expanded(child: RaisedButton(onPressed: () { callback(roundKey, option1); }, child: Text(option1))),
        Expanded(child: RaisedButton(onPressed: () { callback(roundKey, option2); }, child: Text(option2)))
      ]),
      //Text(round != null ? round.toString() : "Loading..."),
    ]);    
  }
}

/*
1. Read /current_bracket
2. For each round in this bracket
   1. Read /rounds/$round
   2. Listen for /totals/$round
      1. Show the totals in the order of the options in /rounds/$round
*/
class BracketPainter2 extends CustomPainter {
  final Bracket bracket;

  const BracketPainter2(Key key, this.bracket);

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
        var options = bracket.roundOptions[roundKey];
        var totals = bracket.roundTotals[roundKey] ?? Map();

        List<Offset> offsets;
        if (options.length == 8) {
          offsets = [
            Offset( 50,  20),
            Offset( 50, 180),
            Offset( 50, 290),
            Offset( 50, 450),
            Offset(540,  20),
            Offset(540, 180),
            Offset(540, 290),
            Offset(540, 450),
          ];
        }
        else if (options.length == 4) {
          offsets = [
            Offset(165,  90),
            Offset(165, 380),
            Offset(420,  90),
            Offset(420, 380),
          ];
        }
        else if (options.length == 2) {
          offsets = [
            Offset(285, 190),
            Offset(310, 290),
          ];
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
          paintTextAt(canvas, text, 20, isLeading ? Colors.black : Colors.black54, size.width, offsets[i]);
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
  bool shouldRepaint(BracketPainter2 oldDelegate) {
    var eq = MapEquality().equals;
    return eq(oldDelegate.bracket.roundTotals, this.bracket.roundTotals);
  }
}
