CREATE PROCEDURE pa_eliminar_horario @id_horario INTEGER, @retorno INTEGER OUTPUT
AS
BEGIN TRY
    DELETE
    FROM horario
    WHERE id_horario = @id_horario
    SET @retorno = 0
END TRY
BEGIN CATCH
    SET @retorno = -1
    SELECT ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE(), ERROR_NUMBER()
END CATCH