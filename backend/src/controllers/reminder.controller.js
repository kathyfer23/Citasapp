const { successResponse, errorResponse } = require('../utils/response');
const { sendAppointmentReminder } = require('../services/email.service');

const sendReminder = async (req, res) => {
  try {
    const { appointmentId } = req.params;

    // Obtener la cita con paciente y usuario
    const appointment = await req.prisma.appointment.findFirst({
      where: {
        id: appointmentId,
        userId: req.user.id
      },
      include: {
        patient: true,
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    });

    if (!appointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    if (appointment.status !== 'scheduled') {
      return errorResponse(res, 'Solo se pueden enviar recordatorios de citas programadas', 400);
    }

    // Verificar que la cita está en el futuro
    if (new Date(appointment.dateTime) <= new Date()) {
      return errorResponse(res, 'No se pueden enviar recordatorios de citas pasadas', 400);
    }

    // Enviar recordatorio
    const result = await sendAppointmentReminder(
      appointment,
      appointment.patient,
      appointment.user
    );

    if (!result.success) {
      return errorResponse(res, 'Error al enviar el recordatorio', 500);
    }

    // Marcar como enviado
    await req.prisma.appointment.update({
      where: { id: appointmentId },
      data: { reminderSent: true }
    });

    return successResponse(res, { sent: true }, 'Recordatorio enviado exitosamente');
  } catch (error) {
    console.error('Error enviando recordatorio:', error);
    return errorResponse(res, 'Error al enviar recordatorio', 500);
  }
};

module.exports = {
  sendReminder
};
