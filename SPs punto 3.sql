DELIMITER $$

DROP PROCEDURE IF EXISTS CrearVehiculosPorPedido$$

CREATE PROCEDURE CrearVehiculosPorPedido(
    IN p_id_pedido_concesionaria INT
)
BEGIN

    DECLARE v_cantidad INT;
    DECLARE v_color VARCHAR(20);
    DECLARE v_fk_id_modelo INT;
    DECLARE v_fk_id_pedido_concesionaria INT;
    DECLARE v_fecha_entrega_estimada DATE;
    DECLARE v_fin BOOLEAN DEFAULT FALSE;

    DECLARE RecorrerPedido CURSOR FOR
        SELECT
            D.cantidad,
            D.color,
            D.fk_id_modelo,
            D.fk_id_pedido_concesionaria,
            D.fecha_entrega_estimada
        FROM Detalle_Pedido_Concesionaria D
        INNER JOIN Pedido_Concesionaria P
            ON P.id_pedido_concesionaria = D.fk_id_pedido_concesionaria
        WHERE D.fk_id_pedido_concesionaria = p_id_pedido_concesionaria;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    OPEN RecorrerPedido;

    FETCH RecorrerPedido
    INTO
        v_cantidad,
        v_color,
        v_fk_id_modelo,
        v_fk_id_pedido_concesionaria,
        v_fecha_entrega_estimada;

    WHILE v_fin = FALSE DO

        CALL CrearVehiculosPorDetallePedido(
            v_cantidad,
            v_color,
            v_fk_id_modelo,
            v_fk_id_pedido_concesionaria,
            v_fecha_entrega_estimada
        );

        FETCH RecorrerPedido
        INTO
            v_cantidad,
            v_color,
            v_fk_id_modelo,
            v_fk_id_pedido_concesionaria,
            v_fecha_entrega_estimada;

    END WHILE;

    CLOSE RecorrerPedido;

END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS GenerarPatente$$

CREATE PROCEDURE GenerarPatente(
    OUT p_Patente VARCHAR(45)
)
BEGIN

    DECLARE v_abecedario VARCHAR(26) DEFAULT 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE v_Rand INT;
    DECLARE v_Caracter1 CHAR(1);
    DECLARE v_Caracter2 CHAR(1);
    DECLARE v_Caracter3 CHAR(1);
    DECLARE v_Caracter4 CHAR(1);
    DECLARE v_Caracter5 CHAR(1);
    DECLARE v_Caracter6 CHAR(1);

    SET v_Rand = FLOOR(RAND() * 26);
    SET v_Caracter1 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

    SET v_Rand = FLOOR(RAND() * 26);
    SET v_Caracter2 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

    SET v_Rand = FLOOR(RAND() * 26);
    SET v_Caracter3 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

    SET v_Caracter4 = FLOOR(RAND() * 10);
    SET v_Caracter5 = FLOOR(RAND() * 10);
    SET v_Caracter6 = FLOOR(RAND() * 10);

    SET p_Patente = CONCAT(
        v_Caracter1,
        v_Caracter2,
        v_Caracter3,
        v_Caracter4,
        v_Caracter5,
        v_Caracter6
    );

    WHILE EXISTS (
        SELECT 1
        FROM Vehiculo
        WHERE patente = p_Patente
    ) DO

        SET v_Rand = FLOOR(RAND() * 26);
        SET v_Caracter1 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

        SET v_Rand = FLOOR(RAND() * 26);
        SET v_Caracter2 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

        SET v_Rand = FLOOR(RAND() * 26);
        SET v_Caracter3 = SUBSTRING(v_abecedario, v_Rand + 1, 1);

        SET v_Caracter4 = FLOOR(RAND() * 10);
        SET v_Caracter5 = FLOOR(RAND() * 10);
        SET v_Caracter6 = FLOOR(RAND() * 10);

        SET p_Patente = CONCAT(
            v_Caracter1,
            v_Caracter2,
            v_Caracter3,
            v_Caracter4,
            v_Caracter5,
            v_Caracter6
        );

    END WHILE;

END$$


DROP PROCEDURE IF EXISTS CrearVehiculo$$

CREATE PROCEDURE CrearVehiculo(
    IN p_color VARCHAR(20),
    IN p_fk_id_modelo INT,
    IN p_fk_id_pedido_concesionaria INT,
    IN p_fecha_entrega_estimada DATE
)
BEGIN

    DECLARE v_ProximoChasis VARCHAR(45);
    DECLARE v_ProximaPatente VARCHAR(45);
    DECLARE v_PrimerRegistro INT;
    DECLARE v_MaxChasis INT;

    SET v_PrimerRegistro = (
        SELECT COUNT(*)
        FROM Vehiculo
    );

    IF v_PrimerRegistro = 0 THEN

        SET v_ProximoChasis = '00001';

        CALL GenerarPatente(v_ProximaPatente);

    ELSE

        SET v_MaxChasis = (
            SELECT MAX(CAST(numeroChasis AS UNSIGNED)) + 1
            FROM Vehiculo
        );

        SET v_ProximoChasis = LPAD(v_MaxChasis, 5, '0');

        CALL GenerarPatente(v_ProximaPatente);

    END IF;

    INSERT INTO Vehiculo
    VALUES (
        v_ProximoChasis,
        v_ProximaPatente,
        p_color,
        YEAR(CURDATE()),
        CURRENT_TIMESTAMP,
        p_fecha_entrega_estimada,
        p_fk_id_modelo,
        NULL,
        p_fk_id_pedido_concesionaria
    );

END$$


DROP PROCEDURE IF EXISTS CrearVehiculosPorDetallePedido$$

CREATE PROCEDURE CrearVehiculosPorDetallePedido(
    IN p_cantidad INT,
    IN p_color VARCHAR(20),
    IN p_fk_id_modelo INT,
    IN p_fk_id_pedido_concesionaria INT,
    IN p_fecha_entrega_estimada DATE
)
BEGIN

    DECLARE v_cantidad INT;

    SET v_cantidad = p_cantidad;

    WHILE v_cantidad <> 0 DO

        CALL CrearVehiculo(
            p_color,
            p_fk_id_modelo,
            p_fk_id_pedido_concesionaria,
            p_fecha_entrega_estimada
        );

        SET v_cantidad = v_cantidad - 1;

    END WHILE;

END$$

DELIMITER ;