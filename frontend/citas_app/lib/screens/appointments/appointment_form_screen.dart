import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class AppointmentFormScreen extends StatefulWidget {
  final String? appointmentId;
  final String? preselectedPatientId;
  final DateTime? preselectedDate;

  const AppointmentFormScreen({
    super.key,
    this.appointmentId,
    this.preselectedPatientId,
    this.preselectedDate,
  });

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Patient? _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 30;
  bool _isLoading = false;

  bool get isEditing => widget.appointmentId != null;

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    
    // Preseleccionar fecha si viene del calendario
    if (widget.preselectedDate != null) {
      _selectedDate = widget.preselectedDate!;
    }

    // Cargar datos después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatients(refresh: true);
      
      // Si es edición, cargar la cita
      if (isEditing) {
        _loadAppointment();
      }
    });
  }

  Future<void> _loadAppointment() async {
    final provider = context.read<AppointmentProvider>();
    await provider.loadAppointment(widget.appointmentId!);
    final apt = provider.selectedAppointment;
    
    if (apt != null && mounted) {
      setState(() {
        _selectedPatient = apt.patient;
        _selectedDate = apt.dateTime;
        _selectedTime = TimeOfDay.fromDateTime(apt.dateTime);
        _duration = apt.duration;
        _notesController.text = apt.notes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime get _appointmentDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un paciente'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final appointment = Appointment(
      id: widget.appointmentId ?? '',
      patientId: _selectedPatient!.id,
      dateTime: _appointmentDateTime,
      duration: _duration,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      createdAt: DateTime.now(),
    );

    final provider = context.read<AppointmentProvider>();
    bool success;

    if (isEditing) {
      success = await provider.updateAppointment(widget.appointmentId!, appointment);
    } else {
      success = await provider.createAppointment(appointment);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing 
                ? 'Cita actualizada exitosamente' 
                : 'Cita creada exitosamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      // Mostrar diálogo con el error de conflicto
      _showErrorDialog(provider.error ?? 'Error al guardar la cita');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.event_busy,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('No se puede agendar'),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cita' : 'Nueva Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de paciente
              Consumer<PatientProvider>(
                builder: (context, provider, _) {
                  // Si hay un paciente preseleccionado por ID
                  if (widget.preselectedPatientId != null && _selectedPatient == null) {
                    final match = provider.patients.where(
                      (p) => p.id == widget.preselectedPatientId,
                    );
                    if (match.isNotEmpty) _selectedPatient = match.first;
                  }

                  // Asegurar que _selectedPatient sea una instancia de la lista del provider
                  Patient? dropdownValue;
                  if (_selectedPatient != null) {
                    final match = provider.patients.where(
                      (p) => p.id == _selectedPatient!.id,
                    );
                    dropdownValue = match.isNotEmpty ? match.first : null;
                  }

                  return DropdownButtonFormField<Patient>(
                    value: dropdownValue,
                    decoration: InputDecoration(
                      labelText: 'Paciente',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: const Text('Seleccionar paciente'),
                    items: provider.patients.map((patient) {
                      return DropdownMenuItem(
                        value: patient,
                        child: Row(
                          children: [
                            Text(patient.fullName),
                            if (patient.isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NUEVO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPatient = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un paciente';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Fecha y hora
              Row(
                children: [
                  // Fecha
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Hora
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Duración
              const Text(
                'Duración',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durationOptions.map((duration) {
                  final isSelected = _duration == duration;
                  return ChoiceChip(
                    label: Text('$duration min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _duration = duration);
                      }
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Preview de conflictos y citas del día
              Consumer<AppointmentProvider>(
                builder: (context, aptProvider, _) {
                  final dayAppointments = aptProvider.getAppointmentsForDate(_selectedDate);
                  final conflict = aptProvider.checkConflict(
                    _appointmentDateTime,
                    _duration,
                    excludeId: widget.appointmentId,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Alerta de conflicto
                      if (conflict != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Conflicto: ${conflict.patient?.fullName ?? "Paciente"} de '
                                  '${DateFormat('HH:mm').format(conflict.dateTime)} a '
                                  '${DateFormat('HH:mm').format(conflict.endTime)}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Citas del día seleccionado
                      if (dayAppointments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Citas del ${DateFormat('d MMMM', 'es').format(_selectedDate)} (${dayAppointments.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...dayAppointments.map((apt) {
                          final isConflict = conflict != null && apt.id == conflict.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isConflict
                                  ? AppColors.error.withOpacity(0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: isConflict
                                  ? Border.all(color: AppColors.error.withOpacity(0.3))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${DateFormat('HH:mm').format(apt.dateTime)} - ${DateFormat('HH:mm').format(apt.endTime)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isConflict ? AppColors.error : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    apt.patient?.fullName ?? 'Paciente',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${apt.duration} min',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Notas
              CustomTextField(
                controller: _notesController,
                label: 'Notas (opcional)',
                hint: 'Motivo de la consulta, observaciones...',
                prefixIcon: Icons.notes,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Resumen
              Card(
                color: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de la cita',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _summaryRow(
                        Icons.person,
                        'Paciente',
                        _selectedPatient?.fullName ?? 'No seleccionado',
                      ),
                      _summaryRow(
                        Icons.calendar_today,
                        'Fecha',
                        DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate),
                      ),
                      _summaryRow(
                        Icons.access_time,
                        'Hora',
                        '${_selectedTime.format(context)} - ${TimeOfDay(
                          hour: (_selectedTime.hour + _duration ~/ 60) % 24,
                          minute: (_selectedTime.minute + _duration % 60) % 60,
                        ).format(context)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _handleSubmit,
                text: isEditing ? 'Guardar Cambios' : 'Agendar Cita',
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
