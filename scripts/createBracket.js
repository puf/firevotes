const admin = require('firebase-admin');
const serviceAccount = require("./firevotes-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://firevotes.firebaseio.com"
});

let options = [
  ["C or C++", "JavaScript", "Swift", "Kotlin", "Java", "Dart", "Go", "C＃"],
  ["Firebase", "Google Maps", "App Engine", "Android", "Assistant", "TensorFlow", "BigQuery", "Flutter"],
  ["Pink", "Yellow", "Red", "Orange", "Purple", "Blue", "Green", "Fuchsia"],
  ["3D printing", "Cloud computing", "iPad", "Uber and Lyft", "Alexa, Siri, and Assistant", "iPhone", "Machine translation", "GPS"],
  ["Bert", "Elmo", "Cookie monster", "Grover", "Count von Count", "Kermit", "Oscar the grouch", "Ernie"],
];

(async function() {
  let roundRef = admin.database().ref("rounds").push();
  let roundIndex = Math.floor(Math.random()*options.length);
  if (process.argv.length > 2) {
    roundIndex = parseInt(process.argv[2]);
  }
  let picked = options[roundIndex];
  let updates = {};
  updates[`rounds/${roundRef.key}`] = picked;
  updates[`current_round`] = roundRef.key;
  updates[`current_bracket`] =  { [`round_of_${picked.length}`]: roundRef.key };
  picked.forEach((option) => {
    updates[`totals/${roundRef.key}/${option}`] = 0;
  });
  console.log(`Created ${JSON.stringify(updates)}`);

  await admin.database().ref().update(updates);

  process.exit();
}());