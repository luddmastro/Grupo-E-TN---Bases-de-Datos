USE terminal_automotriz_bd;

DELIMITER $$

DROP PROCEDURE IF EXISTS AvanzarVehiculoEstacion$$

CREATE PROCEDURE AvanzarVehiculoEstacion(
    IN p_patente VARCHAR(45)
)
BEGIN
    DECLARE v_chasis VARCHAR(45) DEFAULT NULL;
    DECLARE v_estacion_actual INT DEFAULT NULL;
    DECLARE v_linea_id INT DEFAULT NULL;
    DECLARE v_orden_actual INT DEFAULT NULL;
    DECLARE v_estacion_siguiente INT DEFAULT NULL;
    DECLARE v_chasis_ocupante VARCHAR(45) DEFAULT NULL;
    DECLARE v_patente_ocupante VARCHAR(45) DEFAULT NULL;
    DECLARE v_fecha_fin DATETIME DEFAULT NULL;
    DECLARE v_existe_vehiculo INT DEFAULT 0;
    DECLARE v_registro_abierto INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT -99 AS nResultado,
               'Ocurrió un error al procesar el avance del vehículo.' AS cMensaje;
    END;

    START TRANSACTION;

    -- Verificar que exista un vehículo con la patente indicada.
    SELECT COUNT(*)
      INTO v_existe_vehiculo
      FROM Vehiculo
     WHERE patente = p_patente;

    IF v_existe_vehiculo = 0 THEN
        ROLLBACK;
        SELECT -1 AS nResultado,
               'No existe ningún vehículo registrado con esa patente.' AS cMensaje;
    ELSE
        -- Obtener el chasis, la estación actual y la fecha de finalización.
        SELECT numeroChasis, fk_id_estacion_trabajo, fecha_fin
          INTO v_chasis, v_estacion_actual, v_fecha_fin
          FROM Vehiculo
         WHERE patente = p_patente
         LIMIT 1
         FOR UPDATE;

        IF v_fecha_fin IS NOT NULL THEN
            ROLLBACK;
            SELECT -3 AS nResultado,
                   'El vehículo ya se encuentra finalizado.' AS cMensaje;

        ELSEIF v_estacion_actual IS NULL THEN
            ROLLBACK;
            SELECT -2 AS nResultado,
                   'El vehículo todavía no inició el montaje o no está asignado a una estación.' AS cMensaje;

        ELSE
            -- Verificar que haya un registro de paso abierto en la estación actual.
            SELECT COUNT(*)
              INTO v_registro_abierto
              FROM Registro_Paso
             WHERE fk_numeroChasis_vehiculo = v_chasis
               AND fk_id_estacion_trabajo = v_estacion_actual
               AND fecha_hora_egreso IS NULL;

            IF v_registro_abierto = 0 THEN
                ROLLBACK;
                SELECT -4 AS nResultado,
                       'No existe un registro de paso abierto para la estación actual del vehículo.' AS cMensaje;
            ELSE
                -- Obtener la línea y el orden de la estación actual.
                SELECT fk_id_linea_montaje, orden
                  INTO v_linea_id, v_orden_actual
                  FROM Estacion_Trabajo
                 WHERE id_estacion_trabajo = v_estacion_actual;

                -- Buscar la estación siguiente según el orden de la línea.
                SET v_estacion_siguiente = NULL;

                SELECT id_estacion_trabajo
                  INTO v_estacion_siguiente
                  FROM Estacion_Trabajo
                 WHERE fk_id_linea_montaje = v_linea_id
                   AND orden > v_orden_actual
                 ORDER BY orden ASC
                 LIMIT 1;

                IF v_estacion_siguiente IS NULL THEN
                    -- Última estación: cerrar el paso y finalizar el vehículo.
                    UPDATE Registro_Paso
                       SET fecha_hora_egreso = NOW()
                     WHERE fk_numeroChasis_vehiculo = v_chasis
                       AND fk_id_estacion_trabajo = v_estacion_actual
                       AND fecha_hora_egreso IS NULL;

                    UPDATE Vehiculo
                       SET fk_id_estacion_trabajo = NULL,
                           fecha_fin = NOW()
                     WHERE numeroChasis = v_chasis;

                    COMMIT;
                    SELECT 0 AS nResultado,
                           'El vehículo completó la última estación y fue marcado como finalizado.' AS cMensaje;
                ELSE
                    -- Verificar si la estación siguiente está ocupada por otro vehículo.
                    SET v_chasis_ocupante = NULL;
                    SET v_patente_ocupante = NULL;

                    SELECT numeroChasis, patente
                      INTO v_chasis_ocupante, v_patente_ocupante
                      FROM Vehiculo
                     WHERE fk_id_estacion_trabajo = v_estacion_siguiente
                       AND numeroChasis <> v_chasis
                       AND fecha_fin IS NULL
                     LIMIT 1
                     FOR UPDATE;

                    IF v_chasis_ocupante IS NOT NULL THEN
                        ROLLBACK;
                        SELECT -5 AS nResultado,
                               'No es posible avanzar: la estación siguiente se encuentra ocupada.' AS cMensaje,
                               v_chasis_ocupante AS chasis_ocupante,
                               v_patente_ocupante AS patente_ocupante;
                    ELSE
                        -- Cerrar el registro de la estación actual.
                        UPDATE Registro_Paso
                           SET fecha_hora_egreso = NOW()
                         WHERE fk_numeroChasis_vehiculo = v_chasis
                           AND fk_id_estacion_trabajo = v_estacion_actual
                           AND fecha_hora_egreso IS NULL;

                        -- Asignar el vehículo a la estación siguiente.
                        UPDATE Vehiculo
                           SET fk_id_estacion_trabajo = v_estacion_siguiente
                         WHERE numeroChasis = v_chasis;

                        -- Registrar el ingreso a la estación siguiente.
                        INSERT INTO Registro_Paso (
                            fecha_hora_ingreso,
                            fecha_hora_egreso,
                            fk_id_estacion_trabajo,
                            fk_numeroChasis_vehiculo
                        )
                        VALUES (
                            NOW(),
                            NULL,
                            v_estacion_siguiente,
                            v_chasis
                        );

                        COMMIT;
                        SELECT 0 AS nResultado,
                               'El vehículo avanzó correctamente a la siguiente estación.' AS cMensaje;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
