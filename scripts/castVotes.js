const admin = require('firebase-admin');
const serviceAccount = require("./firevotes-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://firevotes.firebaseio.com"
});

let key, round;
admin.database().ref("current_round").on("value", function(snapshot) {
  key = snapshot.val();
  console.log(`Got current round key ${key}`);
  round = undefined;
  if (key) {
    console.log(`Loading values for round ${key}...`);
    admin.database().ref("rounds").child(key).once("value").then(function(snapshot) {
      console.log(`Got values for round ${key}`);
      round = snapshot.val();
    });
  }
});

setInterval(function() {
  if (key && round) {
    let uid = 'admin-'+Math.round(Math.random() * 10000);
    let value = round[Math.floor(Math.random() * round.length)];
    console.log(`votes/${key}/${uid} = ${value}`);
    admin.database().ref(`votes/${key}/${uid}`).set(value);
  }
  else {
    console.log(`Key=${key} round=${JSON.stringify(round)}`);
  }
}, 500);