/**
 * Servicio de WhatsApp via wa.me links
 * Genera mensajes formateados para enviar por WhatsApp
 */

/**
 * Genera el texto del mensaje de recordatorio
 */
const formatReminderMessage = (appointment, patient, professional) => {
  const dateFormatted = new Date(appointment.dateTime).toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  const timeFormatted = new Date(appointment.dateTime).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit',
  });

  return `Hola ${patient.firstName} ${patient.lastName}, le recordamos que tiene una cita programada:\n\n` +
    `📅 Fecha: ${dateFormatted}\n` +
    `🕐 Hora: ${timeFormatted}\n` +
    `👨‍⚕️ Profesional: ${professional.name}\n` +
    `⏱️ Duración: ${appointment.duration} minutos\n\n` +
    `Si necesita reprogramar, por favor comuníquese con anticipación.`;
};

/**
 * Genera la URL wa.me con mensaje prellenado
 */
const generateWhatsAppLink = (phone, message) => {
  const cleanPhone = phone.replace(/\D/g, '');
  const encodedMessage = encodeURIComponent(message);
  return `https://wa.me/${cleanPhone}?text=${encodedMessage}`;
};

module.exports = {
  formatReminderMessage,
  generateWhatsAppLink,
};
