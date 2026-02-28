const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');

const getAll = async (req, res) => {
  try {
    const { search, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {
      userId: req.user.id,
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } }
        ]
      })
    };

    const [patients, total] = await Promise.all([
      req.prisma.patient.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          _count: {
            select: { appointments: true }
          }
        }
      }),
      req.prisma.patient.count({ where })
    ]);

    return paginatedResponse(res, patients, {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    });
  } catch (error) {
    console.error('Error obteniendo pacientes:', error);
    return errorResponse(res, 'Error al obtener pacientes', 500);
  }
};

const getById = async (req, res) => {
  try {
    const { id } = req.params;

    const patient = await req.prisma.patient.findFirst({
      where: {
        id,
        userId: req.user.id
      },
      include: {
        appointments: {
          orderBy: { dateTime: 'desc' },
          take: 10
        }
      }
    });

    if (!patient) {
      return errorResponse(res, 'Paciente no encontrado', 404);
    }

    return successResponse(res, patient);
  } catch (error) {
    console.error('Error obteniendo paciente:', error);
    return errorResponse(res, 'Error al obtener paciente', 500);
  }
};

const create = async (req, res) => {
  try {
    const { email, firstName, lastName, phone, birthDate, notes } = req.body;

    // Verificar si ya existe un paciente con ese email para este usuario
    const existingPatient = await req.prisma.patient.findFirst({
      where: {
        email,
        userId: req.user.id
      }
    });

    if (existingPatient) {
      return errorResponse(res, 'Ya existe un paciente con ese email', 400);
    }

    const patient = await req.prisma.patient.create({
      data: {
        email,
        firstName,
        lastName,
        phone: phone || null,
        birthDate: birthDate ? new Date(birthDate) : null,
        notes: notes || null,
        isNew: true,
        userId: req.user.id
      }
    });

    return successResponse(res, patient, 'Paciente creado exitosamente', 201);
  } catch (error) {
    console.error('Error creando paciente:', error);
    return errorResponse(res, 'Error al crear paciente', 500);
  }
};

const update = async (req, res) => {
  try {
    const { id } = req.params;
    const { email, firstName, lastName, phone, birthDate, notes } = req.body;

    // Verificar que el paciente pertenece al usuario
    const existingPatient = await req.prisma.patient.findFirst({
      where: {
        id,
        userId: req.user.id
      }
    });

    if (!existingPatient) {
      return errorResponse(res, 'Paciente no encontrado', 404);
    }

    // Verificar si el nuevo email ya está en uso por otro paciente
    if (email !== existingPatient.email) {
      const emailInUse = await req.prisma.patient.findFirst({
        where: {
          email,
          userId: req.user.id,
          NOT: { id }
        }
      });

      if (emailInUse) {
        return errorResponse(res, 'El email ya está en uso por otro paciente', 400);
      }
    }

    const patient = await req.prisma.patient.update({
      where: { id },
      data: {
        email,
        firstName,
        lastName,
        phone: phone || null,
        birthDate: birthDate ? new Date(birthDate) : null,
        notes: notes || null
      }
    });

    return successResponse(res, patient, 'Paciente actualizado exitosamente');
  } catch (error) {
    console.error('Error actualizando paciente:', error);
    return errorResponse(res, 'Error al actualizar paciente', 500);
  }
};

const deletePatient = async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar que el paciente pertenece al usuario
    const existingPatient = await req.prisma.patient.findFirst({
      where: {
        id,
        userId: req.user.id
      }
    });

    if (!existingPatient) {
      return errorResponse(res, 'Paciente no encontrado', 404);
    }

    await req.prisma.patient.delete({
      where: { id }
    });

    return successResponse(res, null, 'Paciente eliminado exitosamente');
  } catch (error) {
    console.error('Error eliminando paciente:', error);
    return errorResponse(res, 'Error al eliminar paciente', 500);
  }
};

module.exports = {
  getAll,
  getById,
  create,
  update,
  delete: deletePatient
};
