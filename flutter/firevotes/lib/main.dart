import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    title: '🔥💙 FlutterFire Votes 💙🔥',
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: '🔥💙 FlutterFire Votes 💙🔥'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference dbRoot;
  String currentRoundKey;
  String option1;
  String option2;
  User user;
  
  _MyHomePageState() {}

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.signInAnonymously().then((result) {
      setState(() {
        this.user = result.user;
      });
    });

    dbRoot = FirebaseDatabase.instance.reference();

    dbRoot.child('rounds').orderByKey().limitToLast(1).onChildAdded.listen((event) {
      var options = List<String>.from(event.snapshot.value as List<dynamic>);
      print('Got options $options');
      setState(() {
        currentRoundKey = event.snapshot.key;
        var index = 2 * Random().nextInt(options.length ~/ 2); 
        option1 = options[index];
        option2 = options[index+1];
      });
    });
  }

  void vote(String value) {
    dbRoot.child('votes/$currentRoundKey/${user.uid}').set(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(padding: const EdgeInsets.all(8),
        child: Center(
          child: Row(children: <Widget>[
            Expanded(child: RaisedButton(
              child: Text(option1 ?? "..."),
              color: Colors.orange,
              onPressed: () { vote(option1); }
            )),
            Expanded(child: RaisedButton(
              child: Text(option2 ?? "..."),
              color: Colors.blue,
              onPressed: () { vote(option2); }
            ))
          ])
        )
      )
    );
  }
}