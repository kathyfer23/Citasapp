const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const appointmentController = require('../controllers/appointment.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Validaciones para crear/actualizar cita
const appointmentValidation = [
  body('patientId')
    .isUUID()
    .withMessage('ID de paciente inválido'),
  body('dateTime')
    .isISO8601()
    .withMessage('Fecha y hora inválida'),
  body('duration')
    .optional()
    .isInt({ min: 15, max: 480 })
    .withMessage('La duración debe estar entre 15 y 480 minutos'),
  body('notes')
    .optional()
    .trim()
];

// Validación para actualizar estado
const statusValidation = [
  body('status')
    .isIn(['scheduled', 'completed', 'cancelled'])
    .withMessage('Estado inválido')
];

// Validación para ID
const idValidation = [
  param('id')
    .isUUID()
    .withMessage('ID inválido')
];

// Rutas
router.get('/', appointmentController.getAll);
router.get('/:id', idValidation, validate, appointmentController.getById);
router.post('/', appointmentValidation, validate, appointmentController.create);
router.put('/:id', [...idValidation, ...appointmentValidation], validate, appointmentController.update);
router.patch('/:id/status', [...idValidation, ...statusValidation], validate, appointmentController.updateStatus);
router.delete('/:id', idValidation, validate, appointmentController.delete);

module.exports = router;
