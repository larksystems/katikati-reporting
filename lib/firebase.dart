import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as fb_constants;
import 'logger.dart';
import 'model.dart' as model;
import 'dart:html' as html;
import 'dart:convert' as convert;

Logger logger = Logger('firebase.dart');

firestore.CollectionReference _summaryMetricsRef;
firestore.DocumentReference _topMetricRef;
firestore.CollectionReference _eventsRef;
firestore.CollectionReference _messagesRef;

firestore.CollectionReference _misinfoRef;
firestore.CollectionReference _interactionsRef;

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
  _summaryMetricsRef = _store.collection('daily_tag_metrics');
  _topMetricRef =
      _store.collection('total_counts_metrics').doc('total_counts_metrics');
  _eventsRef = _store.collection('events');
  _messagesRef = _store.collection('messages-test');
  _misinfoRef =
      _store.collection('datasets').doc('misinfo').collection('messages');
  _interactionsRef = _store
      .collection('datasets')
      .doc('covid19-som')
      .collection('interactions');
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

Future<List<model.InteractionFilter>> readThemeFilters() async {
  const filters = [
    {
      'value': 'gender',
      'label': 'Gender',
      'options': [
        {'value': 'all', 'label': 'All genders'},
        {'value': 'MALE', 'label': 'Male'},
        {'value': 'FEMALE', 'label': 'Female'},
        {'value': 'UNKNOWN', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'age',
      'label': 'Age',
      'options': [
        {'value': 'all', 'label': 'All age buckets'},
        {'value': '15_to_17', 'label': '15 - 17 yrs'},
        {'value': '18_to_35', 'label': '18 - 35 yrs'},
        {'value': '36_to_54', 'label': '36 - 54 yrs'},
        {'value': '55_to_99', 'label': '> 55 yrs'},
        {'value': 'UNKNOWN', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'idp_status',
      'label': 'IDP Status',
      'options': [
        {'value': 'all', 'label': 'All status'},
        {'value': 'DISPLACED', 'label': 'Displaced'},
        {'value': 'NOT_DISPLACED', 'label': 'Not displaced'},
        {'value': 'UNKNOWN', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'household_language',
      'label': 'Household language',
      'options': [
        {'value': 'all', 'label': 'All languages'},
        {'value': 'arabic', 'label': 'Arabic'},
        {'value': 'barawe', 'label': 'Barawe'},
        {'value': 'english', 'label': 'English'},
        {'value': 'kiswahili', 'label': 'Kiswahili'},
        {'value': 'maimai', 'label': 'Maimai'},
        {'value': 'mother-tongue', 'label': 'Mother tongue'},
        {'value': 'multiple_languages', 'label': 'Multiple languages'},
        {'value': 'somali', 'label': 'Somali'},
        {'value': 'other', 'label': 'Others'},
        {'value': 'UNKNOWN', 'label': 'Unknown'}
      ]
    },
    {
      'value': 'location_region',
      'label': 'Region',
      'options': [
        {'value': 'all', 'label': 'All regions'},
        {'value': 'galgaduud', 'label': 'Galgaduud'},
        {'value': 'middle shabelle', 'label': 'Middle Shabelle'},
        {'value': 'lower shabelle', 'label': 'Lower Shabelle'},
        {'value': 'banadir', 'label': 'Banadir'},
        {'value': 'bari', 'label': 'Bari'},
        {'value': 'nugaal', 'label': 'Nugaal'},
        {'value': 'lower juba', 'label': 'Lower Juba'},
        {'value': 'hiraan', 'label': 'Hiraan'},
        {'value': 'mudug', 'label': 'Mudug'},
        {'value': 'bay', 'label': 'Bay'},
        {'value': 'gedo', 'label': 'Gedo'},
        {'value': 'bakool', 'label': 'Bakool'},
        {'value': 'sanaag', 'label': 'Sanaag'},
        {'value': 'woqooyi galbeed', 'label': 'Woqooyi Galbeed'},
        {'value': 'togdheer', 'label': 'Togdheer'},
        {'value': 'middle juba', 'label': 'Middle Juba'},
        {'value': 'awdal', 'label': 'Awdal'},
        {'value': 'sool', 'label': 'Sool'},
        {'value': 'UNKNOWN', 'label': 'Unknown'}
      ]
    }
  ];

  var filtersList = List<model.InteractionFilter>();
  filters.forEach((f) {
    var filter = model.InteractionFilter.fromFirebaseMap(f);
    filtersList.add(filter);
  });

  return Future.delayed(Duration(seconds: 0), () => filtersList);
}

Future<List<model.Option>> readAllThemes() async {
  const themes = [
    {'value': 'all', 'label': 'All themes'},
    {'value': 'about_coronavirus', 'label': 'About coronavirus'},
    {'value': 'anxiety_panic', 'label': 'Anxiety or panic'},
    {'value': 'attitude', 'label': 'Attitude'},
    // {'value': 'chasing_reply', 'label': 'Chasing reply'},
    {'value': 'call_for_right_practice', 'label': 'Call for right practice'},
    {'value': 'religious_hope_practice', 'label': 'Religious hope or practice'},
    {'value': 'statement', 'label': 'Statement'},
    {'value': 'knowledge', 'label': 'Knowledge'},
    {'value': 'rumour_stigma_misinfo', 'label': 'Rumour stigma misinfo'},
    {'value': 'government_responce', 'label': 'Government response'},
    {'value': 'behaviour', 'label': 'Behaviour'},
    {'value': 'about_conversation', 'label': 'About conversation'},
    // {'value': 'gratitude', 'label': 'Gratitude'},
    {'value': 'call_for_awareness_creation', 'label': 'Call for awareness'},
    {'value': 'how_to_treat', 'label': 'How to treat'},
    {'value': 'how_to_prevent', 'label': 'How to prevent'},
    {'value': 'collective_hope', 'label': 'Collective hope'},
    {
      'value': 'how_spread_transmitted',
      'label': 'How virus spreads or transmitted'
    },
    {'value': 'symptoms', 'label': 'Symptoms'},
    {'value': 'humanitarian_aid', 'label': 'Humanitarian aid'},
    {'value': 'denial', 'label': 'Denial'},
    {'value': 'somalia_update', 'label': 'Somalia update'},
    {'value': 'other', 'label': 'Others'},
    {'value': 'other_theme', 'label': 'Other themes'},

    {
      'value': 'right_practice_general_follow_advice',
      'label': 'Right practice: general follow advice'
    },
    {
      'value': 'right_practice_distancing_isolation_quarantine',
      'label': 'Right practice: Distancing / isolation / quarantine'
    },
    {'value': 'right_practice_hygiene', 'label': 'Right practice: Hygiene'},
    {'value': 'right_practice_multiple', 'label': 'Right practice: Multiple'},
    {'value': 'religion_practice', 'label': 'Religious practice'},
    {'value': 'religion_guidance', 'label': 'Religious guidance'},
    {'value': 'religion_hope_and_fate', 'label': 'Religious hope and fate'},
    {
      'value': 'rumour_misinfo_therapies_cures',
      'label': 'Rumour / misinfo: Therapies & cures'
    },
    {
      'value': 'rumour_misinfo_cause_misunderstood',
      'label': 'Rumour /misinfo: Cause misunderstood'
    },
    {
      'value': 'stigma_hostility_rejection_anger',
      'label': 'Stigma: hostility / rejection / anger'
    },
  ];

  var themesList = List<model.Option>();
  themes.forEach((t) {
    var option = model.Option(t['value'], t['label']);
    themesList.add(option);
  });

  return Future.delayed(Duration(seconds: 0), () => themesList);
}

Future<List<model.Interaction>> readAllInteractionsFromLocal() async {
  var str = await html.HttpRequest.getString('firebase/data.json');
  var json = convert.jsonDecode(str);

  var interactionsList = List<model.Interaction>();

  json['data'].forEach((obj) {
    var interaction = model.Interaction.fromFirebaseMap(obj);
    interactionsList.add(interaction);
  });

  return interactionsList;
}

Future<List<model.Interaction>> readAllInteractions(
    {bool readFromLocal = false}) async {
  if (readFromLocal) {
    return readAllInteractionsFromLocal();
  }

  var interactionsSnap = await _interactionsRef.get();
  var interactionsList = List<model.Interaction>();

  interactionsSnap.forEach((doc) {
    var obj = doc.data();
    var interaction = model.Interaction.fromFirebaseMap(obj);
    interactionsList.add(interaction);
  });

  // todo: check if the set of the interactions and filters match

  return interactionsList;
}
