CREATE TABLE complejo
(
    id_complejo     INT IDENTITY
        PRIMARY KEY,
    ubicacion       VARCHAR(100) NOT NULL,
    cochera         BIT          NOT NULL,
    telefono        VARCHAR(9)   NOT NULL,
    distrito        VARCHAR(100) NOT NULL,
    ducha           BIT          NOT NULL,
    nombre_complejo VARCHAR(50)  NOT NULL
)
go

CREATE TABLE cancha
(
    id_cancha     INT IDENTITY
        PRIMARY KEY,
    id_complejo   INT            NOT NULL
        REFERENCES complejo,
    precio        NUMERIC(10, 2) NOT NULL,
    dimension     VARCHAR(7)     NOT NULL,
    descripcion   TEXT           NOT NULL,
    nombre_cancha VARCHAR(10)    NOT NULL
)
go

CREATE TABLE horario
(
    id_horario  INT IDENTITY
        PRIMARY KEY,
    id_cancha   INT           NOT NULL
        REFERENCES cancha,
    hora_inicio TIME          NOT NULL,
    hora_fin    TIME          NOT NULL,
    dia_semana  VARCHAR(9)    NOT NULL,
    estado      BIT DEFAULT 1 NOT NULL
)
go

CREATE TABLE usuario
(
    id_usuario         INT IDENTITY
        PRIMARY KEY,
    dni                CHAR(8)       NOT NULL,
    nombres            VARCHAR(100)  NOT NULL,
    apellidos          VARCHAR(100)  NOT NULL,
    correo             VARCHAR(100),
    telefono           VARCHAR(9)    NOT NULL,
    estado_concurrente BIT DEFAULT 0 NOT NULL
)
go

CREATE TABLE detalle_horario
(
    id_detalle     INT IDENTITY
        PRIMARY KEY,
    id_usuario     INT  NOT NULL
        REFERENCES usuario,
    id_horario     INT  NOT NULL
        REFERENCES horario,
    estado_horario CHAR NOT NULL
)
go

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
go

CREATE   FUNCTION fn_hora_rango(@id_cancha INTEGER,
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
go

CREATE FUNCTION fn_resta_h_fin(@id_cancha INTEGER, @h_inicio TIME, @dia_semana VARCHAR(9)) RETURNS INTEGER
AS
BEGIN
    DECLARE
        @h_fin_registro TIME
    SELECT top 1 @h_fin_registro = hora_inicio
    FROM horario
    WHERE id_cancha = @id_cancha
      AND dia_semana = @dia_semana
    and estado = 1
    order by id_horario desc

    return datediff(hour, @h_inicio, @h_fin_registro)
END
go

CREATE FUNCTION fn_resta_h_inicio(@id_cancha INTEGER, @h_inicio TIME, @dia_semana VARCHAR(9)) RETURNS INTEGER
AS
BEGIN
    DECLARE
        @h_inicio_registro TIME
    SELECT top 1 @h_inicio_registro = hora_inicio
    FROM horario
    WHERE id_cancha = @id_cancha
      AND dia_semana = @dia_semana
    and estado = 1
    order by id_horario

    return datediff(hour, @h_inicio, @h_inicio_registro)
END
go

CREATE   PROCEDURE pa_insert_complejo
    @nombre_complejo varchar(100),
    @ubicacion VARCHAR(100),
    @cochera bit,
    @telefono VARCHAR(9),
    @distrito VARCHAR(100),
    @ducha bit,
    @retorno int output

AS
BEGIN TRY
    INSERT INTO complejo (nombre_complejo, ubicacion, cochera, telefono, distrito, ducha)
    VALUES (@nombre_complejo, @ubicacion, @cochera, @telefono, @distrito, @ducha);
    set @retorno=0
END TRY
BEGIN CATCH
    set @retorno=-1
    Select ERROR_PROCEDURE(), ERROR_MESSAGE(),ERROR_LINE(),ERROR_NUMBER()
END CATCH
go

CREATE   PROCEDURE pa_insert_horario @id_cancha INTEGER, @hora_inicio_dia TIME, @hora_fin_dia TIME,
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
go

CREATE   PROCEDURE pa_modificar_horario @id_cancha INTEGER,
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
            IF @hora_fin_rango >= '00:00' and @hora_fin_rango < @hora_inicio_rango AND @hora_fin >= @hora_inicio_rango
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
                            update horario
                            set estado = 0
                            where hora_fin > @hora_fin
                            and hora_fin <= @hora_fin_rango
                        END
                END
        END

    SET @retorno = 1
END TRY
BEGIN CATCH
    SET @retorno = -1
    SELECT ERROR_PROCEDURE(), ERROR_MESSAGE(), ERROR_LINE(), ERROR_NUMBER()
END CATCH
go


