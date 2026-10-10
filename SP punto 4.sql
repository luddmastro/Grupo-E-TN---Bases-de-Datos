DELIMITER $$

-- =================================================================
-- PROCEDIMIENTO: IniciarMontajeVehiculo
-- =================================================================
DROP PROCEDURE IF EXISTS IniciarMontajeVehiculo$$

CREATE PROCEDURE IniciarMontajeVehiculo(
    IN p_patente VARCHAR(45)
)
BEGIN
    DECLARE v_chasis VARCHAR(45);
    DECLARE v_modelo_id INT;
    DECLARE v_estacion_actual INT;
    DECLARE v_linea_id INT;
    DECLARE v_primer_estacion_id INT;
    DECLARE v_chasis_ocupante VARCHAR(45);
    DECLARE v_patente_ocupante VARCHAR(45);
    DECLARE v_existe_vehiculo INT DEFAULT 0;

    -- Verificar si el vehículo existe
    SELECT COUNT(*)
    INTO v_existe_vehiculo
    FROM Vehiculo
    WHERE patente = p_patente;

    IF v_existe_vehiculo = 0 THEN
        SELECT -1 AS nResultado, 
               'No existe ningún vehículo registrado con esa patente' AS cMensaje;
    
    ELSE
        -- Traer datos del vehículo a procesar
        SELECT numeroChasis, fk_id_modelo, fk_id_estacion_trabajo
        INTO v_chasis, v_modelo_id, v_estacion_actual
        FROM Vehiculo
        WHERE patente = p_patente;

        -- Validación: Si ya está en una estación
        IF v_estacion_actual IS NOT NULL THEN
            SELECT -3 AS nResultado, 
                   'El vehículo ya se encuentra en proceso de montaje (asignado a una estación de trabajo)' AS cMensaje;
        
        ELSE
            -- Obtener la línea de montaje asignada al modelo del vehículo
            SELECT id_linea_montaje
            INTO v_linea_id
            FROM Linea_Montaje
            WHERE fk_id_modelo = v_modelo_id;

            -- Obtener la primera estación de trabajo de esa línea (menor orden)
            SELECT id_estacion_trabajo
            INTO v_primer_estacion_id
            FROM Estacion_Trabajo
            WHERE fk_id_linea_montaje = v_linea_id
            ORDER BY orden ASC
            LIMIT 1;

            -- Verificar si la primera estación está ocupada
            SELECT numeroChasis, patente
            INTO v_chasis_ocupante, v_patente_ocupante
            FROM Vehiculo
            WHERE fk_id_estacion_trabajo = v_primer_estacion_id
            LIMIT 1;

            IF v_chasis_ocupante IS NOT NULL THEN
                -- Estación ocupada
                SELECT -2 AS nResultado, 
                       'No es posible ingresar el vehículo. La primer estación se encuentra ocupada.' AS cMensaje, 
                       v_chasis_ocupante AS chasis_ocupante, 
                       v_patente_ocupante AS patente_ocupante;
            
            ELSE
                -- Éxito: Posicionar el vehículo y registrar el ingreso
                UPDATE Vehiculo
                SET fk_id_estacion_trabajo = v_primer_estacion_id,
                    fecha_ingreso = NOW()
                WHERE numeroChasis = v_chasis;

                INSERT INTO Registro_Paso (
                    fecha_hora_ingreso,
                    fecha_hora_egreso,
                    fk_id_estacion_trabajo,
                    fk_numeroChasis_vehiculo
                )
                VALUES (
                    NOW(),
                    NULL,
                    v_primer_estacion_id,
                    v_chasis
                );

                SELECT 0 AS nResultado, 
                       'El vehículo ha sido posicionado exitosamente en la primer estación de montaje' AS cMensaje;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;