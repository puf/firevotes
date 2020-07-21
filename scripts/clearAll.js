const admin = require('firebase-admin');
const serviceAccount = require("./firevotes-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://firevotes.firebaseio.com"
});

(async function() {
  await admin.database().ref().update({
    current_bracket: null,
    current_round: null, 
    rounds: null,
    votes: null,
    totals: null,
  })
}());