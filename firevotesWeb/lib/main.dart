import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
//import 'package:firebase/firebase.dart';
import 'package:firebase/firebase.dart' as dartfire;
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  if (dartfire.apps.isEmpty) {
    dartfire.initializeApp(
      apiKey: "AIzaSyAt_is4HeYaWlrotAMHmfMcrrQo9TCISwE",
      authDomain: "firevotes.firebaseapp.com",
      databaseURL: "https://firevotes.firebaseio.com",
      projectId: "firevotes",
      storageBucket: "firevotes.appspot.com",
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🔥💙 FlutterFire Votes 💙🔥',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: new MyHomePage(title: '🔥💙 FlutterFire Votes 💙🔥'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title}) : super(key: Key("MyHomePage"));

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var screens = [
    Text("Hello world"),
    Demo1(),
    Demo2(),
    Demo3(),
    Demo4(),
    Demo5(),
    Demo6(),
    Demo7(),
    Demo8(),
    Demo9(),
  ];
  var titles =[ 
    "Look at Paul and puf - they're doing awesome stuff.",
    "Demo1: just two buttons, nothing happens yet.",
    "Demo2: write gets rejected.",
    "Demo3: we can now write to the database.",
    "Demo4: now our write gets rejected, because we're not signed in.",
    "Demo5: Now we can write again, but we're still all overwriting each other's data.",
    "Demo6: now anyone can write their own vote. Only one vote per user.",
    "Demo7: show options from the database in log output.",
    "Demo8: we can now change the values on your buttons.",
    "Demo9: we can now change rounds on your screen by editing the database."
  ];

  int index = -1;
  StreamSubscription? screenListener;

  @override
  void initState() {
    super.initState();

    dartfire.Database db = dartfire.database();
    dartfire.DatabaseReference ref = db.ref('settings/web/screen');
    print("Attaching screen listener");
    screenListener = ref.onValue.listen((e) {
      var newIndex = e.snapshot.val() as int;
      if (newIndex != index) {
        print("Setting screen index from $index to $newIndex");
        setState(() {
          index = newIndex;
        });
      }
    });
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    print("didUpdateWidget from ${oldWidget.runtimeType} to ${this.runtimeType}"); 
    super.didUpdateWidget(oldWidget);
  }
  
  @override 
  void dispose() {
    print("Canceling screen listener");
    screenListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "N/A"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Text(index >= 0 && index < titles.length ? titles[index] : "...")
        )
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (index >= 0 && index < screens.length)
                ? screens[index]
                : Text("Loading screen...")
          ],
        ),
      ),
    );
  }
}

// Demo1: just two buttons, nothing happens yet
class Demo1 extends StatelessWidget {
  Demo1() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: ElevatedButton(
              child: Text("Yes"),
              onPressed: () {},            
              //color: Colors.orange
          )
      ),
      Expanded(
          child: ElevatedButton(
              child: Text("No"),
              onPressed: () {},            
              //color: Colors.blue
          )
      ),
    ]);
  }
}

// Demo2: write gets rejected
class Demo2 extends StatelessWidget {
  final dartfire.DatabaseReference dbRoot = dartfire.database().ref("/");

  Demo2() {
    FirebaseAuth.instance.signOut();
  }

  void vote(BuildContext context, String option) {
    dbRoot.child("votes").set(option).then((value) {
      print("then: $value");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$option written'),
      ));
    }).catchError((e) {
      print("catchError: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: ElevatedButton(
              onPressed: () { vote(context, "Yes"); },
              child: Text("Yes"),
              //color: Colors.orange
          )),
      Expanded(
          child: ElevatedButton(
              onPressed: () { vote(context, "No"); },
              child: Text("No"),
              //color: Colors.blue
         )),
    ]);
  }
}

// Demo3: we can now write to the database.
class Demo3 extends Demo2 {}

// Demo4: now our write gets rejected, because we're not signed in.
class Demo4 extends Demo3 {}

// Demo5: Now we can write again, but we're still all overwriting each other's data.
class Demo5 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Demo5State();
}

class _Demo5State extends State<Demo5> {
  final dartfire.DatabaseReference dbRoot = dartfire.database().ref('/');
  late User user;

  @override
  void initState() {
    super.initState();
    // Delay since the previous screen signs out, and we need to sign in after that
    Future.delayed(const Duration(milliseconds: 1500), () {
      print("${this.runtimeType}: Signing in");
      FirebaseAuth.instance.signInAnonymously().then((result) {
        setState(() {
          this.user = result.user!;
        });
      });
    });
  }
  @override void dispose() {
    print("${this.runtimeType}: Signing out");
    FirebaseAuth.instance.signOut();
    super.dispose();
  }

  dartfire.DatabaseReference? getVotePath() {
    return dbRoot.child("votes");
  }

  void vote(BuildContext context, String option) {
    dartfire.DatabaseReference? ref = getVotePath();
    if (ref != null) {
      print("Writing $option to $ref");
      ref.set(option).then((value) {
        print("then: $value");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$option written'),
        ));
      }).catchError((e) {
        print("catchError: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
        ));
      });
    }
    else {
      print('Clicked on $option');
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('Clicked on $option'),
      // ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: ElevatedButton(
              onPressed: () {
                vote(context, "Yes");
              },
              child: Text("Yes"),
              //color: Colors.orange
          )),
      Expanded(
          child: ElevatedButton(
              onPressed: () {
                vote(context, "No");
              },
              child: Text("No"),
              //color: Colors.blue
          )),
    ]);
  }
}

// Demo6: now anyone can write their own vote. Only one vote per user.
class Demo6 extends Demo5 {
  @override
  State<StatefulWidget> createState() => _Demo6State();
}

class _Demo6State extends _Demo5State {
  @override
  dartfire.DatabaseReference? getVotePath() {
    return dbRoot.child("votes").child(user.uid);
  }
}

// Demo7: show options from the database in log output. Change value, and it prints again.
class Demo7 extends Demo6 {
  @override
  State<StatefulWidget> createState() => _Demo7State();
}

class _Demo7State extends _Demo6State {
  late StreamSubscription optionsListener;

  @override
  void initState() {
    super.initState();
    optionsListener = dbRoot.child('options').onValue.listen((event) {
      var options = List<String>.from(event.snapshot.val() as List<dynamic>);
      print('Got options $options');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Got options $options'),
      ));
    });
  }
  @override
  void dispose() {
    optionsListener.cancel();
    super.dispose();
  }
  @override
  dartfire.DatabaseReference? getVotePath() {
    return null;
  }
}

class Demo8 extends Demo7 {
  @override
  State<StatefulWidget> createState() => _Demo8State();
}

// Demo8: we can now change the values on your buttons.
class _Demo8State extends _Demo7State {
  String? option1, option2;
  late StreamSubscription optionsListener;

  @override
  void initState() {
    optionsListener = dbRoot.child('options').onValue.listen((event) {
      var options = List<String>.from(event.snapshot.val() as List<dynamic>);
      print('Got options $options');
      setState(() {
        option1 = options[0];
        option2 = options[1];
      });
    });
    super.initState();
  }
  @override
  void dispose() {
    optionsListener.cancel();
    super.dispose();
  }

  dartfire.DatabaseReference? getVotePath() {
    return dbRoot.child("votes").child(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return (option1 == null || option2 == null) ? Text("Loading...") :
    Row(children: <Widget>[
      Expanded(
          child: ElevatedButton(
              onPressed: () {
                vote(context, option1!);
              },
              child: Text(option1!),
              //color: Colors.orange
          )),
      Expanded(
          child: ElevatedButton(
              onPressed: () {
                vote(context, option2!);
              },
              child: Text(option2!),
              //color: Colors.blue
          )),
    ]);
  }
}

// Demo9: we can now change rounds on your screen by editing the database.
class Demo9 extends Demo8 {
  @override
  State<StatefulWidget> createState() => _Demo9State();
}

class _Demo9State extends _Demo8State {
  StreamSubscription? currentRoundListener;
  String? currentRoundKey;
  bool showBracket = false;
  //Bracket bracket;

  @override
  void initState() {
    super.initState();

    //bracket = Bracket(Key("bracket"), dbRoot);

    dbRoot.child("rounds").orderByKey().limitToLast(1).onChildAdded.listen((event) {
      var options = List<String>.from(event.snapshot.val() as List<dynamic>);
      print('Got options $options');
      setState(() {
        currentRoundKey = event.snapshot.key;
        var index = 2 * Random().nextInt(options.length ~/ 2); 
        option1 = options[index];
        option2 = options[index+1];
      });
    });
  }
  @override
  void dispose() {
    currentRoundListener?.cancel();
    super.dispose();
  }

  dartfire.DatabaseReference getVotePath() {
    return dbRoot.child("votes/$currentRoundKey/${user.uid}");
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ElevatedButton(
        child: Text("Show ${showBracket ? 'buttons' : 'bracket'}"),
        onPressed: () { 
          setState(() { 
            showBracket = !showBracket; 
          }) ;
        },
      ),
      //showBracket ? bracket : super.build(context)
    ]);
  }

}
