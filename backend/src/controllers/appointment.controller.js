const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const { sendAppointmentConfirmation } = require('../services/email.service');

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
    const appointmentDateTime = new Date(dateTime);
    const endTime = new Date(appointmentDateTime.getTime() + duration * 60000);

    const conflictingAppointment = await req.prisma.appointment.findFirst({
      where: {
        userId: req.user.id,
        status: 'scheduled',
        AND: [
          {
            dateTime: {
              lt: endTime
            }
          },
          {
            dateTime: {
              gte: new Date(appointmentDateTime.getTime() - 480 * 60000) // 8 horas antes máximo
            }
          }
        ]
      },
      include: {
        patient: {
          select: {
            firstName: true,
            lastName: true
          }
        }
      },
      orderBy: {
        dateTime: 'asc'
      }
    });

    // Verificar si realmente hay traslape
    if (conflictingAppointment) {
      const conflictStart = new Date(conflictingAppointment.dateTime);
      const conflictEnd = new Date(conflictStart.getTime() + conflictingAppointment.duration * 60000);
      
      // Hay traslape si: la nueva cita empieza antes de que termine la existente
      // Y la nueva cita termina después de que empiece la existente
      if (appointmentDateTime < conflictEnd && endTime > conflictStart) {
        const conflictTimeStart = conflictStart.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
        const conflictTimeEnd = conflictEnd.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
        const patientName = `${conflictingAppointment.patient.firstName} ${conflictingAppointment.patient.lastName}`;
        
        return errorResponse(
          res, 
          `No se puede agendar: ya tienes una cita con ${patientName} de ${conflictTimeStart} a ${conflictTimeEnd}`,
          400
        );
      }
    }

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

    const appointment = await req.prisma.appointment.update({
      where: { id },
      data: {
        patientId,
        dateTime: new Date(dateTime),
        duration,
        notes: notes || null,
        reminderSent: false // Resetear para enviar nuevo recordatorio
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

module.exports = {
  getAll,
  getById,
  create,
  update,
  updateStatus,
  delete: deleteAppointment
};
