import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class PatientFormScreen extends StatefulWidget {
  final String? patientId;

  const PatientFormScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _birthDate;
  bool _isLoading = false;

  bool get isEditing => widget.patientId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadPatient();
    }
  }

  void _loadPatient() async {
    final provider = context.read<PatientProvider>();
    await provider.loadPatient(widget.patientId!);
    final patient = provider.selectedPatient;
    
    if (patient != null && mounted) {
      setState(() {
        _firstNameController.text = patient.firstName;
        _lastNameController.text = patient.lastName;
        _emailController.text = patient.email;
        _phoneController.text = patient.phone ?? '';
        _notesController.text = patient.notes ?? '';
        _birthDate = patient.birthDate;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final patient = Patient(
      id: widget.patientId ?? '',
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null,
      birthDate: _birthDate,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      createdAt: DateTime.now(),
    );

    final provider = context.read<PatientProvider>();
    bool success;

    if (isEditing) {
      success = await provider.updatePatient(widget.patientId!, patient);
    } else {
      success = await provider.createPatient(patient);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing 
                ? 'Paciente actualizado exitosamente' 
                : 'Paciente creado exitosamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al guardar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Paciente' : 'Nuevo Paciente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              CustomTextField(
                controller: _firstNameController,
                label: 'Nombre',
                hint: 'Juan',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Apellido
              CustomTextField(
                controller: _lastNameController,
                label: 'Apellido',
                hint: 'Pérez',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              CustomTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'paciente@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono
              CustomTextField(
                controller: _phoneController,
                label: 'Teléfono (opcional)',
                hint: '+1 234 567 8900',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento (opcional)',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: _birthDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _birthDate = null);
                            },
                          )
                        : null,
                  ),
                  child: Text(
                    _birthDate != null
                        ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _birthDate != null 
                          ? null 
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notas
              CustomTextField(
                controller: _notesController,
                label: 'Notas (opcional)',
                hint: 'Información adicional del paciente...',
                prefixIcon: Icons.notes,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Botón guardar
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _handleSubmit,
                text: isEditing ? 'Guardar Cambios' : 'Crear Paciente',
                icon: isEditing ? Icons.save : Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
