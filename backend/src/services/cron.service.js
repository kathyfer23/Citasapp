const cron = require('node-cron');
const { sendAppointmentReminder } = require('./email.service');
const { sendWhatsAppReminder, isWhatsAppConfigured } = require('./whatsapp.service');

/**
 * Inicializa el cron job para enviar recordatorios automáticos
 * Se ejecuta cada hora y busca citas que estén a 24 horas
 */
const initReminderCron = (prisma) => {
  // Ejecutar cada hora en el minuto 0
  cron.schedule('0 * * * *', async () => {
    console.log('[CRON] Verificando citas para enviar recordatorios...');

    try {
      const now = new Date();
      const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      const in23Hours = new Date(now.getTime() + 23 * 60 * 60 * 1000);

      // Buscar citas que necesiten recordatorio (email o WhatsApp)
      const appointments = await prisma.appointment.findMany({
        where: {
          dateTime: {
            gte: in23Hours,
            lte: in24Hours
          },
          status: 'scheduled',
          OR: [
            { reminderSent: false },
            { whatsappReminderSent: false },
          ]
        },
        include: {
          patient: true,
          user: {
            select: {
              id: true,
              name: true,
              email: true
            }
          }
        }
      });

      console.log(`[CRON] Encontradas ${appointments.length} citas para recordatorio`);

      const whatsappEnabled = isWhatsAppConfigured();

      for (const appointment of appointments) {
        const updateData = {};

        // Enviar email si no se ha enviado
        if (!appointment.reminderSent) {
          const emailResult = await sendAppointmentReminder(
            appointment,
            appointment.patient,
            appointment.user
          );
          if (emailResult.success) {
            updateData.reminderSent = true;
            console.log(`[CRON] Email enviado para cita ${appointment.id}`);
          } else {
            console.error(`[CRON] Error email cita ${appointment.id}:`, emailResult.error);
          }
        }

        // Enviar WhatsApp si no se ha enviado, el paciente tiene teléfono y está configurado
        if (!appointment.whatsappReminderSent && whatsappEnabled && appointment.patient.phone) {
          const waResult = await sendWhatsAppReminder(
            appointment,
            appointment.patient,
            appointment.user
          );
          if (waResult.success) {
            updateData.whatsappReminderSent = true;
            console.log(`[CRON] WhatsApp enviado para cita ${appointment.id}`);
          } else {
            console.error(`[CRON] Error WhatsApp cita ${appointment.id}:`, waResult.error);
          }
        }

        // Actualizar flags independientemente
        if (Object.keys(updateData).length > 0) {
          await prisma.appointment.update({
            where: { id: appointment.id },
            data: updateData
          });
        }
      }
    } catch (error) {
      console.error('[CRON] Error en el cron de recordatorios:', error);
    }
  });

  console.log('[CRON] Cron de recordatorios inicializado');
};

module.exports = { initReminderCron };
