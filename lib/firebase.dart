import 'package:covid/logger.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'firebase_constants.dart' as fb_constants;

Logger logger = Logger('firebase.dart');

void init() async {
  await fb_constants.init();

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
}
