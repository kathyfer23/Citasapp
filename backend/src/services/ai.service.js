const OpenAI = require('openai');

let openaiClient = null;

const getClient = () => {
  if (!openaiClient && process.env.OPENAI_API_KEY) {
    openaiClient = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }
  return openaiClient;
};

/**
 * Genera un resumen estructurado de una consulta médica a partir de la transcripción.
 * @param {string} transcription - Texto transcrito de la consulta
 * @param {object} context - Contexto adicional (paciente, profesional)
 * @returns {object} { success: boolean, summary?: string, error?: string }
 */
const generateConsultationSummary = async (transcription, context = {}) => {
  const client = getClient();

  if (!client) {
    return { success: false, error: 'OpenAI no está configurado. Agregue OPENAI_API_KEY en las variables de entorno.' };
  }

  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

  const systemPrompt = `Eres un asistente médico especializado en generar resúmenes estructurados de consultas médicas.
A partir de la transcripción de una consulta, genera un resumen claro y profesional en español con las siguientes secciones (omite las que no apliquen):

**Motivo de consulta:** Razón principal por la que el paciente acude.
**Síntomas reportados:** Lista de síntomas mencionados por el paciente.
**Hallazgos clínicos:** Observaciones del profesional durante la consulta.
**Diagnóstico:** Diagnóstico o diagnósticos identificados.
**Tratamiento indicado:** Medicamentos, terapias o procedimientos recomendados.
**Próximos pasos:** Seguimiento, exámenes pendientes o próxima cita.

Sé conciso pero completo. Usa terminología médica apropiada pero comprensible.`;

  const userMessage = context.patientName
    ? `Paciente: ${context.patientName}\nProfesional: ${context.professionalName || 'N/A'}\n\nTranscripción de la consulta:\n${transcription}`
    : `Transcripción de la consulta:\n${transcription}`;

  try {
    const completion = await client.chat.completions.create({
      model,
      temperature: 0.3,
      max_tokens: 1500,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
    });

    const summary = completion.choices[0]?.message?.content;

    if (!summary) {
      return { success: false, error: 'No se generó resumen' };
    }

    return { success: true, summary };
  } catch (error) {
    console.error('[AI] Error generando resumen:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  generateConsultationSummary,
};
