# firevotesWeb

This directory contains the web app that we ran on `firevotes.web.app` during our talk, where attendees could cast their vote and interact with the same database we showed in the video. Since this was all done live, we had to do some extra work to make sure everything ran smoothly, and nobody could show any unintended content in our livestream. We'll cover the highlights below...

### Separate codebase

This web app uses a codebase separate from the app we were coding in the [video](https://www.youtube.com/watch?v=rwrUezKCc34). The main reasons for doing this were:

1. The FlutterFire library we used for the iOS/Android app did not support Realtime Database for web clients yet at the time we were building this code. So we had to have separate code paths for the web client, which we didn’t want to include in our talk (as we were already covering quite some ground).

2. While we could show database errors in the debug output of the iOS app we were building, that wouldn’t work for remote viewers. So we actually needed to show the errors in a different way (we chose a snackbar), and as before this was not the sort of code we wanted to cover in our talk.

3. While hot reload/hot restart work really well on a local development system, they can’t be used to push updates to remote users. So we had to come up with an alternative way to perform this reload. Since this is a pretty big topic, we’ll dive in a bit deeper below.

### Hot reload

We decided create a single web app that had all the demo moments in there from the get go, and we would then switch it over from demo to demo as we were completing the code in our talk. We also settled on what exact demo moments we were going to have: 9 in all. 

Each demo/screen is a separate widget. For example, [here](https://github.com/puf/firevotes/blob/main/firevotesWeb/lib/main.dart#L49) is the screen that was showing when we started:
```
Text("Hello world"),
```

OK, that is not very impressive. So [here](https://github.com/puf/firevotes/blob/main/firevotesWeb/lib/main.dart#L131-L150)'s the firt demo screen, which was when we just showed two (disabled) buttons:
```
// Demo1: just two buttons, nothing happens yet
class Demo1 extends StatelessWidget {
  Demo1() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: RaisedButton(
              child: Text("Yes"),
              color: Colors.orange)),
      Expanded(
          child: RaisedButton(
              child: Text("No"),
              color: Colors.blue)),
    ]);
  }
}
```
And [here](https://github.com/puf/firevotes/blob/main/firevotesWeb/lib/main.dart#L152-L189) is the next screen that wrote to the database unsuccessfully and showed a snackbar with the error message:
```
// Demo2: write gets rejected
class Demo2 extends StatelessWidget {
  final dartfire.DatabaseReference dbRoot = dartfire.database().ref("/");

  Demo2() {
    FirebaseAuth.instance.signOut();
  }

  void vote(BuildContext context, String option) {
    dbRoot.child("votes").set(option).then((value) {
      print("then: $value");
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('$option written'),
      ));
    }).catchError((e) {
      print("catchError: $e");
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('$e'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: RaisedButton(
              onPressed: () { vote(context, "Yes"); },
              child: Text("Yes"),
              color: Colors.orange)),
      Expanded(
          child: RaisedButton(
              onPressed: () { vote(context, "No"); },
              child: Text("No"),
              color: Colors.blue)),
    ]);
  }
}
```
You'll see that it's a bit more code than we showed in our talk, mostly because of the snackbar.

We continued adding screens for all 9 demos, sometimes with the next demo building on top of the previous one.

Now with all the screens in place, when you load `firevotes.web.app` you have all demos preloaded in your browser. All we needed to do was show you the right demo for where we were in the talk.

In the database we have a value under `/settings/web/screen` that determines the current screen to show:
```
"settings": {
  "web": {
    "screen": 2
  }
}
```
You can even see it live in the database by going to this URL: https://firevotes.firebaseio.com/settings/web/screen.json This is a cool feature of the Firebase Realtime Database: every node has its own unique address and (if the security rules allow it) you can quickly load that node in the browser by adding `.json` at the end of its address.

The `screen` nbode has value between 0 and 9, with `0` corresponding to the initial state and then the 9 demo moments in the talk. While one of us was explaining the next step of the app, the other one was writing the code, *and* updating the `/settings/web/screen` value in the database through the Firebase console.

In the web app code we then listen for this value in our `_MyHomePageState` widget and set the value to the state:
```
DatabaseReference ref = db.ref('settings/web/screen');
screenListener = ref.onValue.listen((e) {
  var newIndex = e.snapshot.val() as int;
  if (newIndex != index) {
    print("Setting screen index from $index to $newIndex");
    setState(() {
      index = newIndex;
    });
  }
});
```
We then use this value in our `build` method to render the correct demo/screen:
```
children: <Widget>[
  (index >= 0 && index < screens.length)
      ? screens[index]
      : Text("Loading screen...")
],
```

So: as we were explaining a new piece of code, we also set the `/settings/web/screen` value to the next demo, and the web app would then re-render with that new screen. Nice, right?

### Security rules

You may have noticed in our talk that the security rules we used were all showing in slides, we never actually entered them into the Firebase console. While we could have love-coded the rules, we decided that the risk of doing so was too big. With thousands of remote attendees, we needed to make sure we never showed any TODO: bad content, and the risk of making a mistake in our security rules was a bit too much.

So instead: we had predeployed our security rules before the talk. But… since we had 9 demo moments in the talk, our rules also had to covers all those moments at the same time. So we had the rules for demo 1:

{
  "rules": {
    ".read": false,
    ".write": false,
  }
}

But also the rules for the final demo 9:
```
"votes": {
  "$round": {
    "$uid": {
      ".write": "auth.uid === $uid",
      ".validate": "root.child('rounds').child($round).exists() 
                 && root.child('totals').child($round).child(newData.val()).exists()"
    }
  }
}
```
And we had to combine these, and then also merge in the working rules for all demos in between. We ended up writing this into a sort-of state machine in our rules, with constructs like [this](https://github.com/puf/firevotes/blob/main/firevotesWeb/rules.json#L29-L32):
```
"votes": {
  ".write": "
    (root.child('settings/web/screen').val() == 3 && (newData.val() === 'Yes' || newData.val() === 'No'))
  ||(root.child('settings/web/screen').val() >= 4 && root.child('settings/web/screen').val() <= 5 && (newData.val() === 'Yes' || newData.val() === 'No') && auth.uid != null)
  "
```
These rules allow users to write their vote directly under the `/votes` node, which we allowed for a part of our talk as we were building out the database.

So the `newData.val() === 'Yes' || newData.val() === 'No'` of these rules we showed in our talk, but the `root.child('settings/web/screen').val() == 3` was only in the deployed version and ensures that these rules only apply when we’re in demo 3. And same for the second line: we showed and explained the `newData.val() === 'Yes' || newData.val() === 'No') && auth.uid != null` in our talk, but the `root.child('settings/web/screen').val() >= 4 && root.child('settings/web/screen').val() <= 5` ensured that this rule only applies during demos 4 and 5.

You can probably imagine that it was important for us to have a pretty final list of the demos early on, as changing these rules afterwards was not always fun,

### Wrap-up

Hopefully this explanation gives you some more ideas of how you can use Firebase in your apps. If you have any questions drop them in the issues or discussions!
