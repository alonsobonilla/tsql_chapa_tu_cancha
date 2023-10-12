CREATE PROCEDURE pa_modificar_horario @id_cancha INTEGER, @estado BIT, @hora_inicio TIME(7), @hora_fin TIME(7),
                                      @fecha DATE, @id_horario INTEGER,
                                      @retorno INTEGER OUTPUT
AS
BEGIN TRY
    --validamos si ya existe ese horario registrado
    DECLARE @cont INTEGER
    SELECT @cont = COUNT(*) FROM horario WHERE id_cancha = @id_cancha AND hora_inicio = @hora_inicio

    IF @cont = 0
        UPDATE horario
        SET estado      = @estado,
            hora_inicio = @hora_inicio,
            hora_fin    = @hora_fin,
            fecha       = @fecha
        WHERE id_cancha = @id_cancha
          AND id_horario = @id_horario
    SET @retorno = 0
    SET @retorno = 1
END TRY
BEGIN CATCH
    SET @retorno = -1
    SELECT ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE(), ERROR_NUMBER()
END CATCH