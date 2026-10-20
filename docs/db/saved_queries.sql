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

-- proyectos_filtrados ($1 = carrera, $2 = habilidad, $3 = solo abiertos, $4 = tamaño de página, $5 = desplazamiento)
--   Usada por: feed de Descubrir (filtros y paginación en el servidor).
--   $1 y $2 son claves normalizadas (ver normalizeLabel en core/utils); '' = todas.
--   $3 es 'true' o 'false'. `total` = proyectos que cumplen el filtro, sin paginar.
--   Requiere project."createdAt" (timestamptz, con valor por defecto now()).
SELECT p._id, p._owner, p.title, p.description, p."imageUrl",
       p.jobs, p.skills, p.status, p.progress, p."createdAt",
       (SELECT COUNT(*) FROM project_member m
         WHERE m.project_id = p._id AND m.status = 'active') AS member_count,
       COUNT(*) OVER () AS total
FROM project p
WHERE ($3::text <> 'true' OR p.status = 'open')
  AND ($1::text = '' OR EXISTS (
        SELECT 1
        FROM jsonb_array_elements_text(p.jobs) AS j
        CROSS JOIN LATERAL (SELECT trim(regexp_replace(regexp_replace(
              translate(lower(j), 'áéíóúüñàèìòù', 'aeiouunaeiou'),
              '[.,/-]', ' ', 'g'), '\s+', ' ', 'g'))) AS n(key)
        WHERE n.key = $1::text))
  AND ($2::text = '' OR EXISTS (
        SELECT 1
        FROM jsonb_array_elements_text(p.skills) AS s
        CROSS JOIN LATERAL (SELECT trim(regexp_replace(regexp_replace(
              translate(lower(s), 'áéíóúüñàèìòù', 'aeiouunaeiou'),
              '[.,/-]', ' ', 'g'), '\s+', ' ', 'g'))) AS n(key)
        WHERE n.key = $2::text))
ORDER BY p."createdAt" DESC, p._id
LIMIT $4::int OFFSET $5::int;

-- opciones_filtros_proyectos ($1 = carrera elegida, $2 = solo abiertos)
--   Usada por: selectores de la hoja de filtros de Descubrir.
--   Una fila por opción: kind ('career' | 'skill'), key (normalizada), label (variante
--   más frecuente; en empate la primera alfabéticamente) y project_count.
--   Las carreras no dependen de la habilidad elegida; las habilidades sí de la carrera.
--   La normalización debe coincidir con normalizeLabel (core/utils/normalize_label.dart).
WITH base AS (
  SELECT p._id, p.jobs, p.skills FROM project p
  WHERE $2::text <> 'true' OR p.status = 'open'
),
c AS (
  SELECT DISTINCT b._id, 'career'::text AS kind, n.key, j AS label
  FROM base b
  CROSS JOIN LATERAL jsonb_array_elements_text(b.jobs) AS j
  CROSS JOIN LATERAL (SELECT trim(regexp_replace(regexp_replace(
        translate(lower(j), 'áéíóúüñàèìòù', 'aeiouunaeiou'),
        '[.,/-]', ' ', 'g'), '\s+', ' ', 'g'))) AS n(key)
  WHERE n.key <> ''
),
s AS (
  SELECT DISTINCT b._id, 'skill'::text AS kind, n.key, x AS label
  FROM base b
  CROSS JOIN LATERAL jsonb_array_elements_text(b.skills) AS x
  CROSS JOIN LATERAL (SELECT trim(regexp_replace(regexp_replace(
        translate(lower(x), 'áéíóúüñàèìòù', 'aeiouunaeiou'),
        '[.,/-]', ' ', 'g'), '\s+', ' ', 'g'))) AS n(key)
  WHERE n.key <> ''
    AND ($1::text = '' OR b._id IN (SELECT _id FROM c WHERE key = $1::text))
),
u AS (SELECT * FROM c UNION ALL SELECT * FROM s),
variants AS (SELECT kind, key, label, COUNT(*) AS n FROM u GROUP BY kind, key, label),
totals   AS (SELECT kind, key, COUNT(DISTINCT _id) AS project_count FROM u GROUP BY kind, key)
SELECT DISTINCT ON (v.kind, v.key) v.kind, v.key, v.label, t.project_count
FROM variants v JOIN totals t USING (kind, key)
ORDER BY v.kind, v.key, v.n DESC, v.label;
