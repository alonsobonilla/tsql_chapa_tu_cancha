SELECT c2.nombre_cancha, consulta.*
FROM (SELECT h.id_cancha,
             dia_semana,
             (SELECT TOP 1 hora_inicio
              FROM horario
              WHERE id_cancha = h.id_cancha
                AND horario.dia_semana = h.dia_semana
              ORDER BY id_horario)      AS hora_inicio,
             (SELECT TOP 1 hora_fin
              FROM horario
              WHERE horario.id_cancha = h.id_cancha
                AND horario.dia_semana = h.dia_semana
              ORDER BY id_horario DESC) AS hora_fin
      FROM horario h
               INNER JOIN cancha c ON h.id_cancha = c.id_cancha
      WHERE c.id_complejo = 1
      GROUP BY h.id_cancha, dia_semana) AS consulta
         INNER JOIN cancha c2 ON c2.id_cancha = consulta.id_cancha