CREATE OR ALTER PROCEDURE pa_modificar_horario @id_cancha INTEGER,
                                               @hora_inicio TIME(7),
                                               @hora_fin TIME(7),
                                               @dia_semana VARCHAR(9),
                                               @retorno INTEGER OUTPUT
AS
DECLARE
    @resta_inicio      INTEGER,
    @resta_fin         INTEGER,
    @hora_inicio_rango TIME,
    @hora_fin_rango    TIME
BEGIN TRY
    SET @hora_inicio_rango = dbo.fn_hora_rango(@id_cancha, @dia_semana, 1)
    SET @hora_fin_rango = dbo.fn_hora_rango(@id_cancha, @dia_semana, 0)
    SET @resta_inicio = DATEDIFF(HOUR, @hora_inicio, @hora_inicio_rango)
    SET @resta_fin = DATEDIFF(HOUR, @hora_fin, @hora_fin_rango)

    -- Hora de inicio
    IF @resta_inicio > 0
        IF dbo.fn_existencia_hora(@hora_inicio, @id_cancha, @dia_semana) = 1
            UPDATE horario
            SET estado = 1
            WHERE hora_inicio >= @hora_inicio
              AND hora_inicio < @hora_inicio_rango
              AND id_cancha = @id_cancha
              AND dia_semana = @dia_semana
        ELSE
            EXEC dbo.pa_insert_horario @id_cancha, @hora_inicio, @hora_inicio_rango, @dia_semana, 0
    ELSE
        IF @resta_inicio < 0
            UPDATE horario
            SET estado = 0
            WHERE hora_inicio >= @hora_inicio_rango
              AND hora_inicio < @hora_inicio
              AND id_cancha = @id_cancha
              AND dia_semana = @dia_semana

    -- Hora fin
    IF @resta_fin < 0
        BEGIN
            IF @hora_fin_rango >= '00:00' AND @hora_fin_rango < @hora_inicio_rango AND @hora_fin >= @hora_inicio_rango
                BEGIN
                    UPDATE horario
                    SET estado = 0
                    WHERE hora_fin > @hora_fin
                      AND id_cancha = @id_cancha
                      AND dia_semana = @dia_semana

                    UPDATE horario
                    SET estado = 0
                    WHERE hora_fin <= @hora_fin_rango
                      AND id_cancha = @id_cancha
                      AND dia_semana = @dia_semana
                END
            ELSE
                BEGIN
                    IF dbo.fn_existencia_hora(@hora_fin, @id_cancha, @dia_semana) = 1
                        UPDATE horario
                        SET estado = 1
                        WHERE hora_fin > @hora_fin_rango
                          AND hora_fin <= @hora_fin
                          AND id_cancha = @id_cancha
                          AND dia_semana = @dia_semana
                    ELSE
                        EXEC dbo.pa_insert_horario @id_cancha, @hora_fin_rango, @hora_fin, @dia_semana, 0
                END
        END
    ELSE
        BEGIN
            IF @resta_fin > 0
                BEGIN
                    IF @hora_fin >= '00:00' AND @hora_fin < @hora_inicio_rango
                        IF dbo.fn_existencia_hora(@hora_fin, @id_cancha, @dia_semana) = 1
                            BEGIN
                                UPDATE horario
                                SET estado = 1
                                WHERE hora_fin > @hora_fin_rango
                                  AND id_cancha = @id_cancha
                                  AND dia_semana = @dia_semana

                                UPDATE horario
                                SET estado = 1
                                WHERE hora_fin <= @hora_fin
                                  AND id_cancha = @id_cancha
                                  AND dia_semana = @dia_semana
                            END
                        ELSE
                            BEGIN
                                EXEC pa_insert_horario @id_cancha, @hora_fin_rango, @hora_fin, @dia_semana, 0
                            END
                    ELSE
                        BEGIN
                            UPDATE horario
                            SET estado = 0
                            WHERE hora_fin > @hora_fin
                              AND hora_fin <= @hora_fin_rango
                        END
                END
        END

    SET @retorno = 1
END TRY
BEGIN CATCH
    SET @retorno = -1
    SELECT ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE(), ERROR_NUMBER()
END CATCH


SELECT *
FROM horario
WHERE id_cancha = 3
  AND dia_semana = 'LUNES'

DECLARE @retorno INT
    EXEC pa_modificar_horario 3, '09:00', '01:00', 'LUNES', @retorno OUTPUT
SELECT @retorno

SELECT dbo.fn_existencia_hora('10:00', 3, 'LUNES')
SELECT dbo.fn_hora_rango(3, 'LUNES', 0)
SELECT dbo.fn_existencia_hora('22:00', 3, 'LUNES')
SELECT DATEDIFF(HOUR, '22:00', dbo.fn_hora_rango(3, 'LUNES', 0))