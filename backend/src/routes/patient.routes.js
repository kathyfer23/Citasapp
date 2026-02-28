const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const patientController = require('../controllers/patient.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Validaciones para crear/actualizar paciente
const patientValidation = [
  body('email')
    .isEmail()
    .withMessage('Email inválido')
    .normalizeEmail(),
  body('firstName')
    .trim()
    .notEmpty()
    .withMessage('El nombre es requerido'),
  body('lastName')
    .trim()
    .notEmpty()
    .withMessage('El apellido es requerido'),
  body('phone')
    .optional()
    .trim(),
  body('birthDate')
    .optional()
    .isISO8601()
    .withMessage('Fecha de nacimiento inválida'),
  body('notes')
    .optional()
    .trim()
];

// Validación para ID
const idValidation = [
  param('id')
    .isUUID()
    .withMessage('ID inválido')
];

// Rutas
router.get('/', patientController.getAll);
router.get('/:id', idValidation, validate, patientController.getById);
router.post('/', patientValidation, validate, patientController.create);
router.put('/:id', [...idValidation, ...patientValidation], validate, patientController.update);
router.delete('/:id', idValidation, validate, patientController.delete);

module.exports = router;
