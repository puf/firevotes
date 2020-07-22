import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'bracket.dart';
import 'bracket_painter.dart';
import 'my_vote_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = FirebaseApp.instance;

  FirebaseDatabase(app: app).setPersistenceEnabled(true);

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
    //TODO: This signs in asynchonously. Do we have the user's session id for security rules before we start accessing the database?
    FirebaseAuth.fromApp(app).signInAnonymously().then((result) {
      setState((){
        this.user = result.user;
      });
    });

    dbRoot = FirebaseDatabase(app: this.app).reference();

    //TODO Move each of these blocks into a bite-sized method
    //Load current bracket
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
          bracket.roundTotalsListeners[key].cancel();
          bracket.roundTotalsListeners[key] = null;
        });
    });

    //Loads current round
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
        currentRoundListener = dbRoot.child('rounds/$currentRoundKey').onValue.listen((event) {
          setState(() { 
            currentRound = List<String>.from(event.snapshot.value as List<dynamic>);
            currentRoundIndex = 2 * Random().nextInt(currentRound.length ~/ 2);
          });
        });
      }
    });
  }
  void vote(String roundKey, String option) {
    dbRoot.child('votes/$currentRoundKey/${user.uid}').set(option);
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
            currentRoundKey != null ?
              MyVoteWidget(currentRoundKey, currentRound, currentRoundIndex, vote) : 
              Text("Waiting for round to start..."),
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 700,
                height: 500,
                child: CustomPaint(
                  painter: BracketPainter(Key("painter"), bracket),
                )
              )
            )
          ],
        ),
      ),
    );
  }
}