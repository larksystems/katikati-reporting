import 'dart:convert';
import 'dart:html' as html;

import 'package:firebase/firebase.dart' as firebase;
import 'package:dashboard/firebase_constants.dart' as fb_constants;
import 'package:dashboard/view.dart' as view;
import 'package:dashboard/logger.dart';

Logger logger = Logger('firebase.dart');

firebase.Auth get firebaseAuth => firebase.auth();

void init(String constantsFilePath, Function loginCallback,
    Function logoutCallback) async {
  await fb_constants.init(constantsFilePath);
  view.setLoginDomains(fb_constants.allowedEmailDomains);

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
  logger.debug('Firebase initialised');
  firebaseAuth.onAuthStateChanged
      .listen((user) => _fbAuthChanged(user, loginCallback, logoutCallback));
}

// Auth methods
Future<firebase.UserCredential> signInWithGoogle() async {
  var provider = firebase.GoogleAuthProvider();
  return firebaseAuth.signInWithPopup(provider);
}

void signOut() {
  firebaseAuth.signOut();
}

void deleteUser() async {
  await firebaseAuth.currentUser.delete();
  logger.debug('User deleted from the database');
}

void _fbAuthChanged(
    firebase.User user, Function loginCallback, Function logoutCallback) async {
  view.enableLoginButton();
  if (user == null) {
    logger.debug('User not signed in');
    view.showLoginModal();
    logoutCallback();
    return;
  }

  if (!fb_constants.allowedEmailDomains
      .any((domain) => user.email.endsWith(domain))) {
    logger.error('Email domain not allowed');
    await deleteUser();
    view.showLoginError('Email domain not allowed');
    return;
  }

  if (!user.emailVerified) {
    logger.error('Email not verified');
    await deleteUser();
    view.showLoginError('Email is not verified');
    return;
  }

  logger.debug('Loggedin as ${user.email}');
  view.hideLoginError();
  view.hideLoginModal();

  loginCallback();
}

// Read data
Future<Map<String, dynamic>> fetchConfig() async {
  logger.debug('Fetching config from firebase ..');

  var chartsConfigRef = firebase.firestore().doc(fb_constants.metadataPath);
  var configSnapshot = await chartsConfigRef.get();
  return configSnapshot.data();
}

Future<Null> updateConfig(Map<String, dynamic> data) async {
  var chartsConfigRef = firebase.firestore().doc(fb_constants.metadataPath);
  var configSnap = await chartsConfigRef.update(data: data);
  return configSnap;
}

Future<Map<String, Map<String, dynamic>>> fetchInteractions(String path) async {
  if (path == null || path == '') {
    throw ArgumentError(
        'Path for fetching interactions cannot be empty or null');
  }

  var _interactionsRef = firebase.firestore().collection(path);

  var interactionsSnapshot = await _interactionsRef.get();
  logger.debug('Fetched ${interactionsSnapshot.size} interactions');

  var interactionsMap = Map<String, Map<String, dynamic>>();
  interactionsSnapshot.forEach((doc) {
    interactionsMap[doc.id] = doc.data();
  });

  return interactionsMap;
}

Future<Map<String, Map<String, dynamic>>> fetchMessageStats(String path) async {
  if (path == null || path == '') {
    throw ArgumentError(
        'Path for fetching message stats cannot be empty or null');
  }

  var messageStatsRef = firebase.firestore().collection(path);

  var messageStatsSnapshot = await messageStatsRef.get();
  logger.debug('Fetched ${messageStatsSnapshot.size} message stats');

  var messageStatsMap = Map<String, Map<String, dynamic>>();
  messageStatsSnapshot.forEach((doc) {
    messageStatsMap[doc.id] = doc.data();
  });

  return messageStatsMap;
}

Future<Map<String, Map<String, dynamic>>> fetchSurveyStats(String path) async {
  if (path == null || path == '') {
    throw ArgumentError(
        'Path for fetching survey stats cannot be empty or null');
  }

  var surveyStatusRef = firebase.firestore().collection(path);

  var surveyStatusSnapshot = await surveyStatusRef.get();
  logger.debug('Fetched ${surveyStatusSnapshot.size} survey stats');

  var surveyStatusMap = Map<String, Map<String, dynamic>>();
  surveyStatusSnapshot.forEach((doc) {
    surveyStatusMap[doc.id] = doc.data();
  });

  return surveyStatusMap;
}
