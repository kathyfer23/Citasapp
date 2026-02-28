const nodemailer = require('nodemailer');

// Configurar transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT),
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

/**
 * Enviar correo de recordatorio de cita
 */
const sendAppointmentReminder = async (appointment, patient, professional) => {
  const transporter = createTransporter();
  
  const dateFormatted = new Date(appointment.dateTime).toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
  
  const timeFormatted = new Date(appointment.dateTime).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  });

  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: patient.email,
    subject: `Recordatorio de cita - ${professional.name}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2563eb;">Recordatorio de Cita</h2>
        <p>Estimado/a <strong>${patient.firstName} ${patient.lastName}</strong>,</p>
        <p>Le recordamos que tiene una cita programada:</p>
        <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Fecha:</strong> ${dateFormatted}</p>
          <p><strong>Hora:</strong> ${timeFormatted}</p>
          <p><strong>Profesional:</strong> ${professional.name}</p>
          <p><strong>Duración:</strong> ${appointment.duration} minutos</p>
          ${appointment.notes ? `<p><strong>Notas:</strong> ${appointment.notes}</p>` : ''}
        </div>
        <p>Si necesita reprogramar o cancelar su cita, por favor comuníquese con nosotros con anticipación.</p>
        <p style="color: #6b7280; font-size: 14px; margin-top: 30px;">
          Este es un correo automático, por favor no responda a este mensaje.
        </p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error enviando correo:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Enviar correo de confirmación de cita nueva
 */
const sendAppointmentConfirmation = async (appointment, patient, professional) => {
  const transporter = createTransporter();
  
  const dateFormatted = new Date(appointment.dateTime).toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
  
  const timeFormatted = new Date(appointment.dateTime).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  });

  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: patient.email,
    subject: `Confirmación de cita - ${professional.name}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #059669;">Cita Confirmada</h2>
        <p>Estimado/a <strong>${patient.firstName} ${patient.lastName}</strong>,</p>
        <p>Su cita ha sido agendada exitosamente:</p>
        <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Fecha:</strong> ${dateFormatted}</p>
          <p><strong>Hora:</strong> ${timeFormatted}</p>
          <p><strong>Profesional:</strong> ${professional.name}</p>
          <p><strong>Duración:</strong> ${appointment.duration} minutos</p>
        </div>
        <p>Le enviaremos un recordatorio antes de su cita.</p>
        <p style="color: #6b7280; font-size: 14px; margin-top: 30px;">
          Este es un correo automático, por favor no responda a este mensaje.
        </p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error enviando correo:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendAppointmentReminder,
  sendAppointmentConfirmation
};
