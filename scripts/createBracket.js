const admin = require('firebase-admin');
const serviceAccount = require("./firevotes-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://firevotes.firebaseio.com"
});

let options = [
  ["C or C++", "JavaScript", "Swift", "Kotlin", "Java", "Dart", "Go", "C#"],
  ["Firebase", "Google Maps", "App Engine", "Android", "Assistant", "TensorFlow", "BigQuery", "Flutter"],
  ["Pink", "Yellow", "Red", "Orange", "Purple", "Blue", "Green", "Fuchsia"],
  ["3D printing", "Cloud computing", "iPad", "Uber and Lyft", "Alexa, Siri, and Assistant", "iPhone", "Machine translation", "GPS"],
  ["Bert", "Elmo", "Cookie monster", "Grover", "Count von Count", "Kermit", "Oscar the grouch", "Ernie"],
];

(async function() {
  let roundRef = admin.database().ref("rounds").push();
  let picked = options[Math.floor(Math.random()*options.length)];
  await roundRef.set(picked)
  await admin.database().ref("current_round").set(roundRef.key);
  let bracket = {};
  bracket["round_of_"+picked.length] = (await roundRef).key;
  await admin.database().ref("current_bracket").set(bracket);
}());