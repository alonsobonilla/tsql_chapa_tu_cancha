SELECT c2.nombre_cancha, consulta.*
FROM (SELECT h.id_cancha,
             datename(weekday, fecha) as dia,
             fecha,
             dbo.fn_hora_rango(h.id_cancha, fecha, 1)
                 AS hora_inicio,
             dbo.fn_hora_rango(h.id_cancha, fecha, 0)
                 AS hora_fin
      FROM horario h
               INNER JOIN cancha c ON h.id_cancha = c.id_cancha
      WHERE c.id_complejo = 1
        and fecha >= cast(getdate() as date)
      GROUP BY h.id_cancha, fecha) AS consulta
         INNER JOIN cancha c2 ON c2.id_cancha = consulta.id_cancha