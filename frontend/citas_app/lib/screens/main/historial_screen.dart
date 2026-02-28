import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/appointment_card.dart';

/// Pestaña Historial: citas pasadas o completadas.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.appointments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedOrPast = provider.appointments
            .where((a) =>
                a.status.name == 'completed' ||
                a.dateTime.isBefore(DateTime.now()))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        if (completedOrPast.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: AppColors.darkTextSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin historial de citas',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedOrPast.length,
          itemBuilder: (context, index) {
            final appointment = completedOrPast[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                appointment: appointment,
                onTap: () {},
                onSendReminder: null,
                onUpdateStatus: (status) =>
                    provider.updateStatus(appointment.id, status),
              ),
            );
          },
        );
      },
    );
  }
}
