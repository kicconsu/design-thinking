-- Consultas guardadas que usa la app (se crean en la consola de ROBLE; la app
-- las llama por nombre con `executeQueryByName`). Si falta alguna, la
-- funcionalidad que depende de ella falla de forma visible, no con datos falsos.
--
-- Las que reciben varias personas toman los ids como UN texto separado por
-- comas ($1), para no depender de cómo ROBLE ata los arreglos.

-- usuario_por_correo ($1 = correo)
--   Usada por: invitaciones al crear un proyecto.
SELECT user_id, email FROM user_system WHERE lower(email) = lower($1);

-- metricas_compromiso_por_proyecto ($1 = ids separados por coma)
--   Usada por: features/trust (compromiso, tasa de respuesta, completados).
--   Una fila por (persona, proyecto); suma las estancias de la misma persona.
--   Depende de los contadores que mantiene features/tasks.
SELECT m.user_id, m.project_id,
       COALESCE(SUM(m.tasks_finished), 0) AS tasks_finished,
       COALESCE(SUM(m.tasks_taken), 0)    AS tasks_taken,
       p.total_tasks, p.progress
FROM project_member m
JOIN project p ON p._id = m.project_id
WHERE m.user_id = ANY(string_to_array($1, ',')::uuid[])
GROUP BY m.user_id, m.project_id, p.total_tasks, p.progress;

-- entregas_a_tiempo ($1 = ids separados por coma)
--   Usada por: features/trust (entrega a tiempo).
SELECT assignee_id AS user_id,
       COUNT(*) FILTER (WHERE finished_at IS NOT NULL
                          AND deadline IS NOT NULL) AS con_deadline,
       COUNT(*) FILTER (WHERE finished_at <= deadline) AS a_tiempo
FROM task
WHERE assignee_id = ANY(string_to_array($1, ',')::uuid[])
  AND status = 'done'
GROUP BY assignee_id;

-- proyectos_de_usuario ($1 = user_id)
--   Usada por: historial de colaboración (getProjectsParticipatedBy).
--   Todos los proyectos con estancia en cualquier estado; la app decide cuáles
--   son «anteriores».
SELECT DISTINCT p.*
FROM project p
JOIN project_member m ON m.project_id = p._id
WHERE m.user_id = $1::uuid;
