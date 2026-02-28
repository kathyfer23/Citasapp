import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/appointment_card.dart';

/// Pestaña Agenda: calendario table_calendar + lista de citas del día en Cards.
class AgendaTabContent extends StatefulWidget {
  const AgendaTabContent({super.key});

  @override
  State<AgendaTabContent> createState() => _AgendaTabContentState();
}

class _AgendaTabContentState extends State<AgendaTabContent> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

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
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: TableCalendar<Appointment>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: provider.selectedDate,
                  selectedDayPredicate: (day) =>
                      isSameDay(provider.selectedDate, day),
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    provider.setSelectedDate(selectedDay);
                  },
                  eventLoader: (day) {
                    final normalizedDay =
                        DateTime(day.year, day.month, day.day);
                    return provider.appointmentsByDate[normalizedDay] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Citas del ${DateFormat('d MMMM', 'es').format(provider.selectedDate)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.appointmentsForSelectedDate.length} citas',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.appointmentsForSelectedDate.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: AppColors.darkTextSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay citas programadas',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final appointment =
                          provider.appointmentsForSelectedDate[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppointmentCard(
                          appointment: appointment,
                          onTap: () => _showAppointmentDetails(
                              context, appointment, provider),
                          onSendReminder: () =>
                              _sendReminder(context, appointment.id, provider),
                          onUpdateStatus: (status) =>
                              provider.updateStatus(appointment.id, status),
                        ),
                      );
                    },
                    childCount: provider.appointmentsForSelectedDate.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAppointmentDetails(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  appointment.patient?.fullName ?? 'Paciente',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (appointment.patient?.isNew == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Paciente nuevo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _detailRow(
                    Icons.access_time, 'Hora',
                    DateFormat('HH:mm').format(appointment.dateTime)),
                _detailRow(
                    Icons.timer_outlined, 'Duración',
                    '${appointment.duration} minutos'),
                _detailRow(Icons.email_outlined, 'Email',
                    appointment.patient?.email ?? 'N/A'),
                _detailRow(Icons.phone_outlined, 'Teléfono',
                    appointment.patient?.phone ?? 'N/A'),
                if (appointment.notes != null &&
                    appointment.notes!.isNotEmpty)
                  _detailRow(Icons.notes, 'Notas', appointment.notes!),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(ctx, AppRoutes.appointmentForm,
                              arguments: {'appointmentId': appointment.id});
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appointment.reminderSent
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _sendReminder(context, appointment.id, provider);
                              },
                        icon: const Icon(Icons.mail_outline),
                        label: Text(
                          appointment.reminderSent
                              ? 'Enviado'
                              : 'Recordatorio',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.darkTextSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(
    BuildContext context,
    String appointmentId,
    AppointmentProvider provider,
  ) async {
    final success = await provider.sendReminder(appointmentId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Recordatorio enviado'
                : 'Error al enviar recordatorio',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
