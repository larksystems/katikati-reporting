import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
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

// Listen to data changes
void listenToCollections(
    String path,
    void Function(firestore.QuerySnapshot) onData,
    Function(Object error) onError) {
  var ref = firebase.firestore().collection(path);
  ref.onSnapshot.listen(onData, onError: onError);
}

// Read config
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
