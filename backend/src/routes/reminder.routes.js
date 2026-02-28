const express = require('express');
const router = express.Router();
const { param } = require('express-validator');
const reminderController = require('../controllers/reminder.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Validación para ID
const idValidation = [
  param('appointmentId')
    .isUUID()
    .withMessage('ID de cita inválido')
];

// Enviar recordatorio manual
router.post('/:appointmentId', idValidation, validate, reminderController.sendReminder);

module.exports = router;
