const functions = require('firebase-functions');

exports.countVote = functions.database.ref('/votes/{roundId}/{uid}').onCreate((snapshot, context) => {
  let value = snapshot.val();
  let countRef = snapshot.ref.parent.parent.parent.child(`totals/${context.params.roundId}/${value}`);
  return countRef.transaction(function(current) {
    return (current || 0) + 1;
  })
});

exports.handleRound = functions.database.ref('/current_round').onWrite(async (change, context) => {
  if (!change.after.exists()) return null; // nothing to do if there's no current round

  let roundKey = change.after.val();
  let rootRef = change.after.ref.root;

  let settingsSnapshot = await rootRef.child("settings/autobracket").once("value");
  let settings = settingsSnapshot.val();

  if (!settings.enabled) return;

  return new Promise((resolve, reject) => {
    // a round lasts a relatively short time, so we'll just... wait
    setTimeout(async() => {
      // clear the current_round while we tally results
      // TODO: await change.after.ref.remove(); // this will trigger this function again, but the first if will catch it

      let optionsSnapshot = await rootRef.child(`/rounds/${roundKey}`).once("value");
      let totalsSnapshot = await rootRef.child(`/totals/${roundKey}`).once("value");
      let options = optionsSnapshot.val();
      let totals = totalsSnapshot.val();
      
      // determine the winner of each pair, who will go to the next round
      let nextRound = [];
      for (let i=0; i < options.length-1; i += 2) {
        let a = totals[options[i]] || 0;
        let b = totals[options[i + 1]] || 0;
        let winner =  a > b ? options[i] : options[i+1];
        console.log(`Round ${roundKey}: ${winner} won with ${a} to ${b}`);
        nextRound.push(winner);
      }

      if (nextRound.length > 1) {
        let roundKey = rootRef.child("rounds").push().key;
        await rootRef.update({
          ['current_round']: roundKey,
          [`rounds/${roundKey}`]: nextRound,
          [`current_bracket/round_of_${nextRound.length}`]: roundKey,
        });
      }
      else {
        console.log(`Bracket is over, winner is ${JSON.stringify(nextRound)}`);
      }
      resolve();
    }, settings.interval);
    console.log(`Waiting for ${settings.interval}ms before finishing round ${roundKey}`);
  })
});

exports.handleAutovoting = functions.database.ref('/current_round').onWrite(async (change, context) => {
  if (!change.after.exists()) return null; // nothing to do if there's no current round

  let roundKey = change.after.val();
  let rootRef = change.after.ref.root;

  let settingsSnapshot = await rootRef.child("settings").once("value");
  let settings = settingsSnapshot.val();

  if (!settings.autovote.enabled) return;
  //let start = Date.now();

  return new Promise((resolve, reject) => {
    // a round lasts a relatively short time, so we'll just cast votes in an interval

    // TODO: listen for current_round, so we stop voting when that changes

    let interval;
    rootRef.child("rounds").child(roundKey).once("value").then(function(snapshot) {
      console.log(`Got values for round ${roundKey}`);
      let round = snapshot.val();

      interval = setInterval(function() {
        if (roundKey && round) {
          let uid = 'admin-'+Math.round(Math.random() * 10000);
          let value = round[Math.floor(Math.random() * round.length)];
          rootRef.child(`votes/${roundKey}/${uid}`).set(value);
        }
      }, settings.autovote.interval);
    });

    setTimeout(async() => {
      clearInterval(interval);
      resolve();
    }, settings.autobracket.interval);
    console.log(`Casting votes for ${settings.interval}ms for round ${roundKey}`);
  })
});
