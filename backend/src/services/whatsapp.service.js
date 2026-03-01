/**
 * Servicio de integración con WhatsApp Business Cloud API
 */

const isWhatsAppConfigured = () => {
  return !!(
    process.env.WHATSAPP_PHONE_NUMBER_ID &&
    process.env.WHATSAPP_ACCESS_TOKEN &&
    process.env.WHATSAPP_TEMPLATE_NAME
  );
};

/**
 * Enviar recordatorio de cita por WhatsApp
 * Usa mensajes de plantilla (template) aprobados por Meta
 */
const sendWhatsAppReminder = async (appointment, patient, professional) => {
  if (!isWhatsAppConfigured()) {
    return { success: false, error: 'WhatsApp no está configurado' };
  }

  if (!patient.phone) {
    return { success: false, error: 'El paciente no tiene número de teléfono' };
  }

  // Limpiar número de teléfono (solo dígitos, sin + ni espacios)
  const phoneNumber = patient.phone.replace(/\D/g, '');

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

  const templateName = process.env.WHATSAPP_TEMPLATE_NAME || 'appointment_reminder';
  const templateLanguage = process.env.WHATSAPP_TEMPLATE_LANGUAGE || 'es';

  const body = {
    messaging_product: 'whatsapp',
    to: phoneNumber,
    type: 'template',
    template: {
      name: templateName,
      language: { code: templateLanguage },
      components: [
        {
          type: 'body',
          parameters: [
            { type: 'text', text: `${patient.firstName} ${patient.lastName}` },
            { type: 'text', text: dateFormatted },
            { type: 'text', text: timeFormatted },
            { type: 'text', text: professional.name },
            { type: 'text', text: `${appointment.duration}` },
          ],
        },
      ],
    },
  };

  try {
    const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
    const accessToken = process.env.WHATSAPP_ACCESS_TOKEN;

    const response = await fetch(
      `https://graph.facebook.com/v18.0/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      }
    );

    const data = await response.json();

    if (!response.ok) {
      console.error('[WhatsApp] Error de API:', data);
      return { success: false, error: data.error?.message || 'Error de API WhatsApp' };
    }

    console.log(`[WhatsApp] Mensaje enviado a ${phoneNumber}, ID: ${data.messages?.[0]?.id}`);
    return { success: true, messageId: data.messages?.[0]?.id };
  } catch (error) {
    console.error('[WhatsApp] Error enviando mensaje:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendWhatsAppReminder,
  isWhatsAppConfigured,
};
