# firevotes

This repo contains all the code for the audience polling app that is build in this 50m talk 
[Zero to app: Livecoding a cross platform app with Firebase and Flutter](https://youtu.be/rwrUezKCc34). 
It also contains the code for the companion (web) app that allowed the audience to participate.

## Folder structure

The repo contains the following top-level folders:

* `flutter` - This contains the final version of the app that was built in the talk, and is designed to run on iOS and Android. 
* `build/web`
* `firevotesWeb` - This is the companion web app that the audience used during the talk, and which is hosted on https://firevotes.web.app.
* `functions` - These are the Cloud Functions that were either shown in during the talk, or used during the later demos.
* `scripts` - Some Node.js script that are handy for running locally.
