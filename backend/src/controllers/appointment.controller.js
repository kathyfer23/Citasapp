const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const { sendAppointmentConfirmation } = require('../services/email.service');
const { generateConsultationSummary } = require('../services/ai.service');

/**
 * Busca una cita que conflicte con el horario dado.
 * @param {object} prisma - Prisma client
 * @param {string} userId - ID del profesional
 * @param {Date} dateTime - Inicio de la nueva cita
 * @param {number} duration - Duración en minutos
 * @param {string|null} excludeId - ID de cita a excluir (para edición)
 * @returns {object|null} Objeto con mensaje de conflicto, o null si no hay conflicto
 */
const findConflict = async (prisma, userId, dateTime, duration, excludeId = null) => {
  const appointmentDateTime = new Date(dateTime);
  const endTime = new Date(appointmentDateTime.getTime() + duration * 60000);

  const where = {
    userId,
    status: 'scheduled',
    ...(excludeId && { id: { not: excludeId } }),
    AND: [
      { dateTime: { lt: endTime } },
      { dateTime: { gte: new Date(appointmentDateTime.getTime() - 480 * 60000) } }
    ]
  };

  const conflictingAppointment = await prisma.appointment.findFirst({
    where,
    include: {
      patient: {
        select: { firstName: true, lastName: true }
      }
    },
    orderBy: { dateTime: 'asc' }
  });

  if (conflictingAppointment) {
    const conflictStart = new Date(conflictingAppointment.dateTime);
    const conflictEnd = new Date(conflictStart.getTime() + conflictingAppointment.duration * 60000);

    if (appointmentDateTime < conflictEnd && endTime > conflictStart) {
      const conflictTimeStart = conflictStart.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
      const conflictTimeEnd = conflictEnd.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
      const patientName = `${conflictingAppointment.patient.firstName} ${conflictingAppointment.patient.lastName}`;

      return `No se puede agendar: ya tienes una cita con ${patientName} de ${conflictTimeStart} a ${conflictTimeEnd}`;
    }
  }

  return null;
};

const getAll = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      status, 
      patientId,
      page = 1, 
      limit = 50 
    } = req.query;
    
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      userId: req.user.id,
      ...(status && { status }),
      ...(patientId && { patientId }),
      ...(startDate && endDate && {
        dateTime: {
          gte: new Date(startDate),
          lte: new Date(endDate)
        }
      })
    };

    const [appointments, total] = await Promise.all([
      req.prisma.appointment.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { dateTime: 'asc' },
        include: {
          patient: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              phone: true,
              isNew: true
            }
          }
        }
      }),
      req.prisma.appointment.count({ where })
    ]);

    return paginatedResponse(res, appointments, {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    });
  } catch (error) {
    console.error('Error obteniendo citas:', error);
    return errorResponse(res, 'Error al obtener citas', 500);
  }
};

const getById = async (req, res) => {
  try {
    const { id } = req.params;

    const appointment = await req.prisma.appointment.findFirst({
      where: {
        id,
        userId: req.user.id
      },
      include: {
        patient: true
      }
    });

    if (!appointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    return successResponse(res, appointment);
  } catch (error) {
    console.error('Error obteniendo cita:', error);
    return errorResponse(res, 'Error al obtener cita', 500);
  }
};

const create = async (req, res) => {
  try {
    const { patientId, dateTime, duration = 30, notes } = req.body;

    // Verificar que el paciente pertenece al usuario
    const patient = await req.prisma.patient.findFirst({
      where: {
        id: patientId,
        userId: req.user.id
      }
    });

    if (!patient) {
      return errorResponse(res, 'Paciente no encontrado', 404);
    }

    // Verificar disponibilidad (no hay otra cita en ese horario)
    const conflictMessage = await findConflict(req.prisma, req.user.id, dateTime, duration);
    if (conflictMessage) {
      return errorResponse(res, conflictMessage, 400);
    }

    const appointmentDateTime = new Date(dateTime);

    const appointment = await req.prisma.appointment.create({
      data: {
        patientId,
        userId: req.user.id,
        dateTime: appointmentDateTime,
        duration,
        notes: notes || null,
        status: 'scheduled',
        reminderSent: false
      },
      include: {
        patient: true
      }
    });

    // Si el paciente era nuevo, marcarlo como existente
    if (patient.isNew) {
      await req.prisma.patient.update({
        where: { id: patientId },
        data: { isNew: false }
      });
    }

    // Enviar correo de confirmación
    const user = await req.prisma.user.findUnique({
      where: { id: req.user.id },
      select: { name: true, email: true }
    });
    
    sendAppointmentConfirmation(appointment, patient, user);

    return successResponse(res, appointment, 'Cita creada exitosamente', 201);
  } catch (error) {
    console.error('Error creando cita:', error);
    return errorResponse(res, 'Error al crear cita', 500);
  }
};

const update = async (req, res) => {
  try {
    const { id } = req.params;
    const { patientId, dateTime, duration = 30, notes } = req.body;

    // Verificar que la cita pertenece al usuario
    const existingAppointment = await req.prisma.appointment.findFirst({
      where: {
        id,
        userId: req.user.id
      }
    });

    if (!existingAppointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    // Verificar que el paciente pertenece al usuario
    const patient = await req.prisma.patient.findFirst({
      where: {
        id: patientId,
        userId: req.user.id
      }
    });

    if (!patient) {
      return errorResponse(res, 'Paciente no encontrado', 404);
    }

    // Verificar conflictos (excluyendo la cita que se está editando)
    const conflictMessage = await findConflict(req.prisma, req.user.id, dateTime, duration, id);
    if (conflictMessage) {
      return errorResponse(res, conflictMessage, 400);
    }

    const appointment = await req.prisma.appointment.update({
      where: { id },
      data: {
        patientId,
        dateTime: new Date(dateTime),
        duration,
        notes: notes || null,
        reminderSent: false,
        whatsappReminderSent: false
      },
      include: {
        patient: true
      }
    });

    return successResponse(res, appointment, 'Cita actualizada exitosamente');
  } catch (error) {
    console.error('Error actualizando cita:', error);
    return errorResponse(res, 'Error al actualizar cita', 500);
  }
};

const updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    // Verificar que la cita pertenece al usuario
    const existingAppointment = await req.prisma.appointment.findFirst({
      where: {
        id,
        userId: req.user.id
      }
    });

    if (!existingAppointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    const appointment = await req.prisma.appointment.update({
      where: { id },
      data: { status },
      include: {
        patient: true
      }
    });

    return successResponse(res, appointment, 'Estado de cita actualizado');
  } catch (error) {
    console.error('Error actualizando estado de cita:', error);
    return errorResponse(res, 'Error al actualizar estado', 500);
  }
};

const deleteAppointment = async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar que la cita pertenece al usuario
    const existingAppointment = await req.prisma.appointment.findFirst({
      where: {
        id,
        userId: req.user.id
      }
    });

    if (!existingAppointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    await req.prisma.appointment.delete({
      where: { id }
    });

    return successResponse(res, null, 'Cita eliminada exitosamente');
  } catch (error) {
    console.error('Error eliminando cita:', error);
    return errorResponse(res, 'Error al eliminar cita', 500);
  }
};

const saveTranscription = async (req, res) => {
  try {
    const { id } = req.params;
    const { transcription } = req.body;

    if (!transcription || typeof transcription !== 'string' || !transcription.trim()) {
      return errorResponse(res, 'La transcripción es requerida', 400);
    }

    const existingAppointment = await req.prisma.appointment.findFirst({
      where: { id, userId: req.user.id }
    });

    if (!existingAppointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    const appointment = await req.prisma.appointment.update({
      where: { id },
      data: { transcription: transcription.trim() },
      include: { patient: true }
    });

    return successResponse(res, appointment, 'Transcripción guardada exitosamente');
  } catch (error) {
    console.error('Error guardando transcripción:', error);
    return errorResponse(res, 'Error al guardar transcripción', 500);
  }
};

const summarize = async (req, res) => {
  try {
    const { id } = req.params;
    const { transcription: bodyTranscription } = req.body || {};

    const existingAppointment = await req.prisma.appointment.findFirst({
      where: { id, userId: req.user.id },
      include: {
        patient: { select: { firstName: true, lastName: true } },
        user: { select: { name: true } }
      }
    });

    if (!existingAppointment) {
      return errorResponse(res, 'Cita no encontrada', 404);
    }

    const text = bodyTranscription || existingAppointment.transcription;

    if (!text || !text.trim()) {
      return errorResponse(res, 'No hay transcripción disponible para resumir', 400);
    }

    const context = {
      patientName: `${existingAppointment.patient.firstName} ${existingAppointment.patient.lastName}`,
      professionalName: existingAppointment.user.name
    };

    const result = await generateConsultationSummary(text, context);

    if (!result.success) {
      return errorResponse(res, result.error || 'Error al generar resumen', 500);
    }

    const appointment = await req.prisma.appointment.update({
      where: { id },
      data: {
        aiSummary: result.summary,
        ...(bodyTranscription && { transcription: bodyTranscription.trim() })
      },
      include: { patient: true }
    });

    return successResponse(res, appointment, 'Resumen generado exitosamente');
  } catch (error) {
    console.error('Error generando resumen:', error);
    return errorResponse(res, 'Error al generar resumen', 500);
  }
};

module.exports = {
  getAll,
  getById,
  create,
  update,
  updateStatus,
  delete: deleteAppointment,
  saveTranscription,
  summarize
};
