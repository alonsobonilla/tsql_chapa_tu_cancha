SELECT c2.nombre_cancha, consulta.*
FROM (SELECT h.id_cancha,
             dia_semana,
             dbo.fn_hora_rango(h.id_cancha, dia_semana, 1)
                 AS hora_inicio,
             dbo.fn_hora_rango(h.id_cancha, dia_semana, 0)
                 AS hora_fin
      FROM horario h
               INNER JOIN cancha c ON h.id_cancha = c.id_cancha
      WHERE c.id_complejo = 1
      GROUP BY h.id_cancha, dia_semana) AS consulta
         INNER JOIN cancha c2 ON c2.id_cancha = consulta.id_cancha