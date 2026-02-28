const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { successResponse, errorResponse } = require('../utils/response');

const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

const register = async (req, res) => {
  try {
    const { email, password, name, profession, phone } = req.body;

    // Verificar si el email ya existe
    const existingUser = await req.prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return errorResponse(res, 'El email ya está registrado', 400);
    }

    // Hash de la contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const user = await req.prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        profession,
        phone: phone || null
      },
      select: {
        id: true,
        email: true,
        name: true,
        profession: true,
        phone: true,
        createdAt: true
      }
    });

    // Generar token
    const token = generateToken(user.id);

    return successResponse(res, { user, token }, 'Usuario registrado exitosamente', 201);
  } catch (error) {
    console.error('Error en registro:', error);
    return errorResponse(res, 'Error al registrar usuario', 500);
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Buscar usuario
    const user = await req.prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return errorResponse(res, 'Credenciales inválidas', 401);
    }

    if (!user.isActive) {
      return errorResponse(res, 'Cuenta desactivada', 401);
    }

    // Verificar contraseña
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      return errorResponse(res, 'Credenciales inválidas', 401);
    }

    // Generar token
    const token = generateToken(user.id);

    // Retornar usuario sin contraseña
    const { password: _, ...userWithoutPassword } = user;

    return successResponse(res, { user: userWithoutPassword, token }, 'Inicio de sesión exitoso');
  } catch (error) {
    console.error('Error en login:', error);
    return errorResponse(res, 'Error al iniciar sesión', 500);
  }
};

module.exports = {
  register,
  login
};
