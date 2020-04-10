import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as fb_constants;
import 'logger.dart';
import 'model.dart' as model;

Logger logger = Logger('firebase.dart');

firestore.CollectionReference _summaryMetricsRef;
firestore.DocumentReference _topMetricRef;
firestore.CollectionReference _eventsRef;
firestore.CollectionReference _messagesRef;

firestore.CollectionReference _misinfoRef;

firebase.Auth get firebaseAuth => firebase.auth();

void init(String constantsFilePath) async {
  await fb_constants.init(constantsFilePath);

  firebase.initializeApp(
      apiKey: fb_constants.apiKey,
      authDomain: fb_constants.authDomain,
      databaseURL: fb_constants.databaseURL,
      projectId: fb_constants.projectId,
      storageBucket: fb_constants.storageBucket,
      messagingSenderId: fb_constants.messagingSenderId,
      appId: fb_constants.appId,
      measurementId: fb_constants.measurementId);
  firebase.analytics();
  logger.log('Firebase initialised');

  var _store = firebase.firestore();
  _summaryMetricsRef = _store.collection(fb_constants.summaryMetrics);
  _topMetricRef =
      _store.collection('total_counts_metrics').doc('total_counts_metrics');
  _eventsRef = _store.collection('events');
  _messagesRef = _store.collection('messages-test');
  _misinfoRef =
      _store.collection('datasets').doc('misinfo').collection('messages');
}

// Auth login and logout
Future<firebase.UserCredential> signInWithGoogle() async {
  var provider = firebase.GoogleAuthProvider();
  return firebaseAuth.signInWithPopup(provider);
}

void signOut() {
  firebaseAuth.signOut();
}

void deleteUser() async {
  await firebaseAuth.currentUser.delete();
  logger.log('User deleted and signed out');
}

// Read data
Future<List<model.DaySummary>> readSummaryMetrics() async {
  var eventSnap = await _eventsRef.get();
  var summarySnap = await _summaryMetricsRef.get();

  var eventsList = [];
  var daySummaryMetricsList = [];

  eventSnap.forEach((doc) {
    Map<String, dynamic> obj = doc.data();
    obj['date'] = doc.id;
    eventsList.add(obj);
  });

  summarySnap.forEach((doc) {
    Map<String, dynamic> obj = doc.data();
    obj['date'] = doc.id;

    var eventForDay = eventsList.firstWhere((event) {
      return event['date'] == doc.id;
    }, orElse: () => null);

    if (eventForDay != null) {
      obj['radio_show'] = eventForDay['radio_show'];
    } else {
      obj['radio_show'] = false;
    }

    daySummaryMetricsList.add(obj);
  });

  return daySummaryMetricsList
      .map((s) => model.DaySummary.fromFirebaseMap(s))
      .toList();
}

Future<model.TopMetric> readTopMetrics() async {
  var snapshot = await _topMetricRef.get();

  return model.TopMetric.fromFirebaseMap(snapshot.data());
}

Future<List<model.Message>> readMessages() async {
  var messagesSnap = await _messagesRef.get();
  var messagesList = List<model.Message>();

  messagesSnap.forEach((doc) {
    var obj = doc.data();
    var message = model.Message.fromFirebaseMap(obj);
    messagesList.add(message);
  });

  return messagesList;
}

Future<List<model.Message>> readMisinfoMessages() async {
  var messagesSnap = await _misinfoRef.get();
  var messagesList = List<model.Message>();

  messagesSnap.forEach((doc) {
    var obj = doc.data();
    var message = model.Message.fromFirebaseMap(obj);
    messagesList.add(message);
  });

  return messagesList;
}

Future<List<model.InteractionThemeFilter>> readThemeFilters() async {
  const filters = [
    {
      'value': 'gender',
      'label': 'Gender',
      'options': [
        {'value': 'all', 'label': 'All genders'},
        {'value': 'male', 'label': 'Male'},
        {'value': 'female', 'label': 'Female'},
        {'value': 'unknown', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'age',
      'label': 'Age',
      'options': [
        {'value': 'all', 'label': 'All age buckets'},
        {'value': '0_18', 'label': '< 18 yrs'},
        {'value': '18_35', 'label': '18 to 35 yrs'},
        {'value': '35_50', 'label': '35 to 50 yrs'},
        {'value': '50_', 'label': '> 50 yrs'}
      ]
    },
    {
      'value': 'idp_status',
      'label': 'IDP Status',
      'options': [
        {'value': 'all', 'label': 'All status'},
        {'value': 'displaced', 'label': 'Displaced'},
        {'value': 'not_displaced', 'label': 'Not displaced'},
        {'value': 'unknown', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'language',
      'label': 'Language',
      'options': [
        {'value': 'all', 'label': 'All languages'},
        {'value': 'english', 'label': 'English'},
        {'value': 'swahili', 'label': 'Swahili'}
      ]
    },
    {
      'value': 'location',
      'label': 'County',
      'options': [
        {'value': 'all', 'label': 'All counties'},
        {'value': 'county_1', 'label': 'County 1'},
        {'value': 'county_1', 'label': 'County 2'}
      ]
    }
  ];

  var filtersList = List<model.InteractionThemeFilter>();
  filters.forEach((f) {
    var filter = model.InteractionThemeFilter.fromFirebaseMap(f);
    filtersList.add(filter);
  });

  return Future.delayed(Duration(seconds: 1), () => filtersList);
}
