import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/appointment_provider.dart';

// Conditional import: usa Web Speech API en web, stub en otras plataformas
import 'consultation_web_helper_stub.dart'
    if (dart.library.js_interop) 'consultation_web_helper.dart';

class ConsultationScreen extends StatefulWidget {
  final String appointmentId;

  const ConsultationScreen({super.key, required this.appointmentId});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _transcriptionController = TextEditingController();
  final WebSpeechRecognition _speechRecognition = WebSpeechRecognition();

  bool _isRecording = false;
  bool _isGeneratingSummary = false;
  bool _isSaving = false;
  String? _aiSummary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointmentData();
    });
  }

  Future<void> _loadAppointmentData() async {
    final provider = context.read<AppointmentProvider>();
    await provider.loadAppointment(widget.appointmentId);
    final apt = provider.selectedAppointment;
    if (apt != null && mounted) {
      setState(() {
        if (apt.transcription != null) {
          _transcriptionController.text = apt.transcription!;
        }
        _aiSummary = apt.aiSummary;
      });
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _speechRecognition.stop();
      setState(() => _isRecording = false);
    } else {
      if (kIsWeb && _speechRecognition.isSupported) {
        setState(() {
          _isRecording = true;
          _errorMessage = null;
        });
        _speechRecognition.start(
          onResult: (text, isFinal) {
            setState(() {
              _transcriptionController.text = text;
              _transcriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _transcriptionController.text.length),
              );
            });
          },
          onEnd: () {
            if (mounted) setState(() => _isRecording = false);
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isRecording = false;
                _errorMessage = 'Error de reconocimiento: $error';
              });
            }
          },
        );
      } else {
        setState(() {
          _errorMessage = kIsWeb
              ? 'Tu navegador no soporta reconocimiento de voz. Usa Chrome.'
              : 'Reconocimiento de voz solo disponible en web. Escribe manualmente.';
        });
      }
    }
  }

  Future<void> _saveTranscription() async {
    final text = _transcriptionController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Escribe o graba una transcripción primero');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final provider = context.read<AppointmentProvider>();
    final success = await provider.saveTranscription(widget.appointmentId, text);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Transcripción guardada' : provider.error ?? 'Error al guardar'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _generateSummary() async {
    final text = _transcriptionController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Necesitas una transcripción para generar el resumen');
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
      _errorMessage = null;
    });

    final provider = context.read<AppointmentProvider>();
    final success = await provider.generateSummary(
      widget.appointmentId,
      transcription: text,
    );

    if (mounted) {
      setState(() {
        _isGeneratingSummary = false;
        if (success && provider.selectedAppointment?.aiSummary != null) {
          _aiSummary = provider.selectedAppointment!.aiSummary;
        } else if (!success) {
          _errorMessage = provider.error ?? 'Error al generar resumen';
        }
      });
    }
  }

  @override
  void dispose() {
    _speechRecognition.stop();
    _transcriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta'),
        actions: [
          if (_transcriptionController.text.trim().isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveTranscription,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Microphone button
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.error : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isRecording ? 'Grabando... Toca para detener' : 'Toca para grabar',
                style: TextStyle(
                  color: _isRecording ? AppColors.error : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transcription area
            const Text(
              'Transcripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transcriptionController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'La transcripción aparecerá aquí, o escribe manualmente...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveTranscription,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingSummary ? null : _generateSummary,
                    icon: _isGeneratingSummary
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGeneratingSummary ? 'Generando...' : 'Resumen IA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI Summary result
            if (_aiSummary != null) ...[
              const Text(
                'Resumen IA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                color: AppColors.success.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.success.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Generado por IA',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copiar resumen',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _aiSummary!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Resumen copiado al portapapeles'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _aiSummary!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
