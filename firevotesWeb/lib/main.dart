import 'package:flutter/material.dart';
import 'package:firebase/firebase.dart' as dartfire;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
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
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:  new MyHomePage(title: 'Flutter Hello World'),
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
  var screens = [Text("Hello world"), Demo1(), Demo2(), Demo3(), Demo4(), Demo5(), Demo6()];
  int index = -1;

  _MyHomePageState() {

  }

  @override void initState() {
    super.initState();
    dartfire.Database db = dartfire.database();
    dartfire.DatabaseReference ref = db.ref('settings/web/screen');
    ref.onValue.listen((e) {
      dartfire.DataSnapshot snapshot = e.snapshot;
      setState((){ 
        print("Setting screen index to ${snapshot.val()}");
        index = snapshot.val() as int; 
      });
    });        
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
        child: RaisedButton( onPressed: () { print("Yes"); }, 
          child: Text("Yes"),
          color:Color(0xFFFFA000)
        )
      ),
      Expanded(
        child: RaisedButton( onPressed: () { print("No"); }, 
          child: Text("No"),
          color:Color(0xFFFFA000)
        )
      ),
    ]);
  }
}
// Demo2: write gets rejected
class Demo2 extends StatelessWidget {
  final dartfire.DatabaseReference dbRoot = dartfire.database().ref('/votes');

  Demo2() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        child: RaisedButton( onPressed: () { dbRoot.set("Yes"); }, 
          child: Text("Yes"),
          color:Color(0xFFFFA000)
        )
      ),
      Expanded(
        child: RaisedButton( onPressed: () { dbRoot.set("No"); }, 
          child: Text("No"),
          color:Color(0xFFFFA000)
        )
      ),
    ]);
  }
}
// Demo3: we can now write to the database.
class Demo3 extends Demo2 {}
// Demo4: now our write gets rejected, because we're not signed in.
class Demo4 extends Demo3 {}


class Demo5 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Demo5State();
}
class _Demo5State extends State<Demo5> {
  final dartfire.DatabaseReference dbRoot = dartfire.database().ref('/votes');
  User user;

  _Demo5State() {
    print("Signing in");
    FirebaseAuth.instance.signInAnonymously().then((result) {
      setState((){
        this.user = result.user;
      });
    });
  }
  void vote(value) {
    dbRoot.set(value);
  }
  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
        child: RaisedButton( onPressed: () { vote("Yes"); }, 
                  child: Text("Yes"),
                  color:Color(0xFFFFA000)
                )
              ),
              Expanded(
                child: RaisedButton( onPressed: () { vote("No"); }, 
                  child: Text("No"),
                  color:Color(0xFFFFA000)
                )
              ),
            ]);  }
        
}

class Demo6 extends Demo5 {
  @override
  State<StatefulWidget> createState() => _Demo6State();
}
class _Demo6State extends _Demo5State {
  @override void vote(value) {
    dbRoot.child(user.uid).set(value);
  }
}
