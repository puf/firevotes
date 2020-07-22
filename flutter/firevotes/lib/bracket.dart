import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class Bracket {
  List<String> roundKeys = List();
  Map<String, List<String>> roundOptions = Map();
  Map<String, Map<String, int>> roundTotals = Map();
  Map<String, StreamSubscription<Event>> roundOptionsListeners = Map();
  Map<String, StreamSubscription<Event>> roundTotalsListeners = Map();
}