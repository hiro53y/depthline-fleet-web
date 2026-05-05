import 'audio_backend.dart';
import 'audio_backend_mobile.dart'
    if (dart.library.html) 'audio_backend_web.dart' as platform;

AudioBackend createPlatformAudioBackend() => platform.createAudioBackend();
