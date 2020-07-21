const admin = require('firebase');

admin.initializeApp({
  databaseURL: 'https://stackoverflow.firebaseio.com'
});
var ref = admin.database().ref("61536203");

ref.on("value", function(snapshot) {
  console.log(snapshot.val());
});

timer = setInterval(function() {
  ref.set(admin.database.ServerValue.increment(1));
}, 50);

setTimeout(function() {
  clearInterval(timer);
  process.exit(1);
}, 60000)
