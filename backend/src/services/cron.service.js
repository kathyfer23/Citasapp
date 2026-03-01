const cron = require('node-cron');
const { sendAppointmentReminder } = require('./email.service');

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

      // Buscar citas que estén entre 23 y 24 horas en el futuro
      // y que no hayan recibido recordatorio por email
      const appointments = await prisma.appointment.findMany({
        where: {
          dateTime: {
            gte: in23Hours,
            lte: in24Hours
          },
          reminderSent: false,
          status: 'scheduled'
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

      for (const appointment of appointments) {
        const result = await sendAppointmentReminder(
          appointment,
          appointment.patient,
          appointment.user
        );

        if (result.success) {
          // Marcar como enviado
          await prisma.appointment.update({
            where: { id: appointment.id },
            data: { reminderSent: true }
          });
          console.log(`[CRON] Recordatorio enviado para cita ${appointment.id}`);
        } else {
          console.error(`[CRON] Error enviando recordatorio para cita ${appointment.id}:`, result.error);
        }
      }
    } catch (error) {
      console.error('[CRON] Error en el cron de recordatorios:', error);
    }
  });

  console.log('[CRON] Cron de recordatorios inicializado');
};

module.exports = { initReminderCron };
