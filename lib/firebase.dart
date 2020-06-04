import 'package:firebase/firebase.dart' as firebase;
import 'package:dashboard/firebase_constants.dart' as fb_constants;
import 'package:dashboard/logger.dart';

Logger logger = Logger('firebase.dart');

firebase.Auth get firebaseAuth => firebase.auth();
List<String> get allowedEmailDomains => fb_constants.allowedEmailDomains;

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
  logger.debug('Firebase initialised');
}

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
