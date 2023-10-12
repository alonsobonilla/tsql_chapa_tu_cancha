CREATE OR ALTER FUNCTION fn_hora_rango(@id_cancha INTEGER,
                                       @dia_semana VARCHAR(9),
                                       @hora_inicio BIT)
    RETURNS TIME
AS
BEGIN
    IF @hora_inicio = 1
        RETURN (SELECT TOP 1 MIN(hora_inicio)
                FROM horario
                WHERE id_cancha = @id_cancha
                  AND dia_semana = @dia_semana
                  AND estado = 1
                  AND hora_inicio NOT IN
                      (SELECT hora_fin
                       FROM horario
                       WHERE id_cancha = @id_cancha
                         AND dia_semana = @dia_semana
                         AND estado = 1))

    RETURN (SELECT MAX(hora_fin)
            FROM horario
            WHERE id_cancha = @id_cancha
              AND dia_semana = @dia_semana
              AND estado = 1
              AND hora_fin NOT IN
                  (SELECT hora_inicio
                   FROM horario
                   WHERE id_cancha = @id_cancha
                     AND dia_semana = @dia_semana
                     AND estado = 1))
END