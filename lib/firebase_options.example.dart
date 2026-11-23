// PLANTILLA: copia este archivo como lib/firebase_options.dart (está en .gitignore)
// y reemplaza los valores con los de tu proyecto en Firebase Console
// (Configuración del proyecto > Tus apps > App web > SDK setup and configuration).
import 'package:firebase_core/firebase_core.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'TU_API_KEY',
  appId: 'TU_APP_ID',
  messagingSenderId: 'TU_SENDER_ID',
  projectId: 'TU_PROJECT_ID',
);
