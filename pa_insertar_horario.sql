CREATE OR ALTER PROCEDURE pa_insert_horario @id_cancha INTEGER, @hora_inicio_dia TIME, @hora_fin_dia TIME,
                                            @dia_semana VARCHAR(9),
                                            @retorno INTEGER OUTPUT
AS
DECLARE
    @tmp TIME
BEGIN TRY
    WHILE DATEDIFF(HOUR, @hora_inicio_dia, @hora_fin_dia) != 0
        BEGIN
            SET @tmp = @hora_inicio_dia
            SET @hora_inicio_dia = DATEADD(HOUR, 1, @hora_inicio_dia)

            INSERT INTO horario(id_cancha, hora_inicio, hora_fin, dia_semana)
            VALUES (@id_cancha,
                    @tmp,
                    @hora_inicio_dia,
                    UPPER(@dia_semana))
        END
    SET @retorno = 0
END TRY
BEGIN CATCH
    SET @retorno = -1
    SELECT ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE(), ERROR_NUMBER()
END CATCH