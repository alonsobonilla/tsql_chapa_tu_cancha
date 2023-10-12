CREATE FUNCTION fn_existencia_hora(@hora TIME, @id_cancha INTEGER, @dia_semana VARCHAR(9))
    RETURNS BIT
AS
BEGIN
    IF EXISTS(SELECT *
              FROM horario
              WHERE (hora_inicio = @hora
                  OR hora_fin = @hora)
                AND id_cancha = @id_cancha
                AND dia_semana = @dia_semana)
        RETURN 1
    RETURN 0
END

