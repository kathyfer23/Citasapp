// Stub para plataformas no-web (mobile, desktop).
// La implementación real de Web Speech API está en consultation_web_helper.dart.

class WebSpeechRecognition {
  bool get isSupported => false;

  void start({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
  }) {
    onError('Reconocimiento de voz no disponible en esta plataforma');
  }

  void stop() {}
}
