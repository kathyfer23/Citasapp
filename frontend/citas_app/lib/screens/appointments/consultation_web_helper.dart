import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebSpeechRecognition {
  web.SpeechRecognition? _recognition;

  bool get isSupported {
    try {
      _recognition = web.SpeechRecognition();
      return true;
    } catch (_) {
      return false;
    }
  }

  void start({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
  }) {
    try {
      _recognition = web.SpeechRecognition();
      _recognition!.lang = 'es-ES';
      _recognition!.continuous = true;
      _recognition!.interimResults = true;

      _recognition!.onresult = (web.SpeechRecognitionEvent event) {
        final results = event.results;
        final buffer = StringBuffer();
        var lastIsFinal = false;

        for (var i = 0; i < results.length; i++) {
          final result = results.item(i);
          buffer.write(result.item(0).transcript);
          if (result.isFinal) lastIsFinal = true;
        }

        onResult(buffer.toString(), lastIsFinal);
      }.toJS;

      _recognition!.onerror = (web.SpeechRecognitionErrorEvent event) {
        onError(event.error);
      }.toJS;

      _recognition!.onend = (web.Event event) {
        onEnd();
      }.toJS;

      _recognition!.start();
    } catch (e) {
      onError('Error iniciando reconocimiento de voz: $e');
    }
  }

  void stop() {
    _recognition?.stop();
  }
}
