-- =====================================================================
-- TP Integrador - Bases de Datos 1
-- Segunda etapa - Construccion de los ABMs importantes
--
-- Entidades solicitadas en la consigna:
--   a) Concesionarios
--   b) Pedidos (Cabecera + Detalle)
--   c) Proveedores
--   d) Insumos
--
-- Adaptado desde "terminal_automotriz_segunda_etapa_sql.old" (esquema
-- anterior) al esquema nuevo definido en "script_bd_automotriz.sql".
--
-- Motor: MySQL 8.0 / InnoDB
-- Base de datos: terminal_automotriz_bd
--
-- Formato de respuesta de TODOS los SP:
--   nResultado = 0  -> exito
--   nResultado < 0  -> problema
--   cMensaje vacio en caso de exito
--   cMensaje con descripcion en caso de error
--
-- Notas de diseño:
--   * Concesionaria e Insumo tienen PK autonumerica (no la recibe el
--     que llama), por lo que el chequeo de "clave duplicada" se
--     reemplaza por un chequeo de nombre duplicado (clave de negocio).
--   * Proveedor_Insumo tiene PK manual (idProveedor_Insumo varchar),
--     ahi si se valida la colision de clave primaria literal.
--   * La tabla Direccion (calle/altura/localidad) es compartida entre
--     Concesionaria y Proveedor. Como no se pide como ABM propio, se
--     administra embebida dentro del Insert/Update de cada una.
-- =====================================================================

USE terminal_automotriz_bd;


-- =====================================================================
-- =====================================================================
-- CONCESIONARIA
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- CONCESIONARIA - INSERT
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS concesionaria_Insert;

DELIMITER $$

CREATE PROCEDURE concesionaria_Insert(
    IN p_nombre VARCHAR(45),
    IN p_contacto VARCHAR(45),
    IN p_calle VARCHAR(45),
    IN p_altura INT,
    IN p_localidad VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_nuevo_id INT DEFAULT 0;

    -- Verificar si ya existe una concesionaria con ese nombre.
    SELECT COUNT(*)
      INTO v_existe
      FROM Concesionaria
     WHERE nombre = p_nombre;

    IF v_existe > 0 THEN

        SELECT -1 AS nResultado,
               'Ya existe una concesionaria con ese nombre' AS cMensaje;

    ELSE

        INSERT INTO Concesionaria (
            nombre,
            contacto
        )
        VALUES (
            p_nombre,
            p_contacto
        );

        SET v_nuevo_id = LAST_INSERT_ID();

        INSERT INTO Direccion (
            calle,
            altura,
            localidad,
            fk_id_concesionaria,
            fk_id_proveedor
        )
        VALUES (
            p_calle,
            p_altura,
            p_localidad,
            v_nuevo_id,
            NULL
        );

        SELECT 0 AS nResultado,
               '' AS cMensaje;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- CONCESIONARIA - UPDATE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS concesionaria_Update;

DELIMITER $$

CREATE PROCEDURE concesionaria_Update(
    IN p_id_concesionaria INT,
    IN p_nombre VARCHAR(45),
    IN p_contacto VARCHAR(45),
    IN p_calle VARCHAR(45),
    IN p_altura INT,
    IN p_localidad VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_dir INT DEFAULT 0;

    -- Verificar que la concesionaria exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Concesionaria
     WHERE id_concesionaria = p_id_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'La concesionaria no existe' AS cMensaje;

    ELSE

        -- Verificar que el nombre no pertenezca a otra concesionaria.
        SELECT COUNT(*)
          INTO v_existe
          FROM Concesionaria
         WHERE nombre = p_nombre
           AND id_concesionaria <> p_id_concesionaria;

        IF v_existe > 0 THEN

            SELECT -2 AS nResultado,
                   'Ya existe otra concesionaria con ese nombre' AS cMensaje;

        ELSE

            UPDATE Concesionaria
               SET nombre = p_nombre,
                   contacto = p_contacto
             WHERE id_concesionaria = p_id_concesionaria;

            -- Actualizar direccion si ya tenia, o crearla si no tenia.
            SELECT COUNT(*)
              INTO v_dir
              FROM Direccion
             WHERE fk_id_concesionaria = p_id_concesionaria;

            IF v_dir > 0 THEN

                UPDATE Direccion
                   SET calle = p_calle,
                       altura = p_altura,
                       localidad = p_localidad
                 WHERE fk_id_concesionaria = p_id_concesionaria;

            ELSE

                INSERT INTO Direccion (
                    calle,
                    altura,
                    localidad,
                    fk_id_concesionaria,
                    fk_id_proveedor
                )
                VALUES (
                    p_calle,
                    p_altura,
                    p_localidad,
                    p_id_concesionaria,
                    NULL
                );

            END IF;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- CONCESIONARIA - DELETE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS concesionaria_Delete;

DELIMITER $$

CREATE PROCEDURE concesionaria_Delete(
    IN p_id_concesionaria INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_pedidos INT DEFAULT 0;

    -- Verificar que la concesionaria exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Concesionaria
     WHERE id_concesionaria = p_id_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'La concesionaria no existe' AS cMensaje;

    ELSE

        -- Verificar si tiene pedidos asociados.
        SELECT COUNT(*)
          INTO v_pedidos
          FROM Pedido_Concesionaria
         WHERE fk_id_concesionaria = p_id_concesionaria;

        IF v_pedidos > 0 THEN

            SELECT -2 AS nResultado,
                   'No se puede eliminar la concesionaria porque tiene pedidos asociados'
                   AS cMensaje;

        ELSE

            DELETE FROM Direccion
             WHERE fk_id_concesionaria = p_id_concesionaria;

            DELETE FROM Concesionaria
             WHERE id_concesionaria = p_id_concesionaria;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- =====================================================================
-- PEDIDO_CONCESIONARIA - CABECERA
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- PEDIDO_CONCESIONARIA - INSERT
--
-- id_pedido_concesionaria es AUTO_INCREMENT, no se recibe como parametro.
-- fecha_entrega_estimada queda NULL inicialmente (se calcula en una
-- etapa posterior del TP, no en el ABM).
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS pedido_concesionaria_Insert;

DELIMITER $$

CREATE PROCEDURE pedido_concesionaria_Insert(
    IN p_fk_id_concesionaria INT,
    IN p_fecha_pedido DATETIME
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que exista la concesionaria.
    SELECT COUNT(*)
      INTO v_existe
      FROM Concesionaria
     WHERE id_concesionaria = p_fk_id_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'La concesionaria no existe' AS cMensaje;

    ELSE

        INSERT INTO Pedido_Concesionaria (
            fecha_pedido,
            fecha_entrega_estimada,
            fk_id_concesionaria
        )
        VALUES (
            p_fecha_pedido,
            NULL,
            p_fk_id_concesionaria
        );

        SELECT 0 AS nResultado,
               '' AS cMensaje;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PEDIDO_CONCESIONARIA - UPDATE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS pedido_concesionaria_Update;

DELIMITER $$

CREATE PROCEDURE pedido_concesionaria_Update(
    IN p_id_pedido_concesionaria INT,
    IN p_fk_id_concesionaria INT,
    IN p_fecha_pedido DATETIME,
    IN p_fecha_entrega_estimada DATETIME
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_concesionaria INT DEFAULT 0;

    -- Verificar que el pedido exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Pedido_Concesionaria
     WHERE id_pedido_concesionaria = p_id_pedido_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El pedido no existe' AS cMensaje;

    ELSE

        -- Verificar que exista la concesionaria.
        SELECT COUNT(*)
          INTO v_concesionaria
          FROM Concesionaria
         WHERE id_concesionaria = p_fk_id_concesionaria;

        IF v_concesionaria = 0 THEN

            SELECT -2 AS nResultado,
                   'La concesionaria no existe' AS cMensaje;

        ELSE

            UPDATE Pedido_Concesionaria
               SET fk_id_concesionaria = p_fk_id_concesionaria,
                   fecha_pedido = p_fecha_pedido,
                   fecha_entrega_estimada = p_fecha_entrega_estimada
             WHERE id_pedido_concesionaria = p_id_pedido_concesionaria;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PEDIDO_CONCESIONARIA - DELETE
--
-- No se puede eliminar un pedido que tenga vehiculos asociados.
-- Los detalles del pedido se eliminan manualmente antes de la cabecera
-- (la FK no tiene ON DELETE CASCADE en el esquema nuevo).
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS pedido_concesionaria_Delete;

DELIMITER $$

CREATE PROCEDURE pedido_concesionaria_Delete(
    IN p_id_pedido_concesionaria INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_vehiculos INT DEFAULT 0;

    -- Verificar que el pedido exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Pedido_Concesionaria
     WHERE id_pedido_concesionaria = p_id_pedido_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El pedido no existe' AS cMensaje;

    ELSE

        -- Verificar si existen vehiculos asociados al pedido.
        SELECT COUNT(*)
          INTO v_vehiculos
          FROM Vehiculo
         WHERE fk_id_pedido_concesionaria = p_id_pedido_concesionaria;

        IF v_vehiculos > 0 THEN

            SELECT -2 AS nResultado,
                   'No se puede eliminar el pedido porque tiene vehiculos asociados'
                   AS cMensaje;

        ELSE

            DELETE FROM Detalle_Pedido_Concesionaria
             WHERE fk_id_pedido_concesionaria = p_id_pedido_concesionaria;

            DELETE FROM Pedido_Concesionaria
             WHERE id_pedido_concesionaria = p_id_pedido_concesionaria;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- =====================================================================
-- DETALLE_PEDIDO_CONCESIONARIA
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- DETALLE_PEDIDO_CONCESIONARIA - INSERT
--
-- No se permite repetir la combinacion (pedido, modelo, color) dentro
-- del mismo pedido; si es el mismo color, corresponde modificar la
-- cantidad del detalle existente en vez de duplicarlo.
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS detalle_pedido_concesionaria_Insert;

DELIMITER $$

CREATE PROCEDURE detalle_pedido_concesionaria_Insert(
    IN p_fk_id_pedido_concesionaria INT,
    IN p_fk_id_modelo INT,
    IN p_cantidad INT,
    IN p_color VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que exista el pedido.
    SELECT COUNT(*)
      INTO v_existe
      FROM Pedido_Concesionaria
     WHERE id_pedido_concesionaria = p_fk_id_pedido_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El pedido no existe' AS cMensaje;

    ELSE

        -- Verificar que exista el modelo.
        SELECT COUNT(*)
          INTO v_existe
          FROM Modelo
         WHERE id_modelo = p_fk_id_modelo;

        IF v_existe = 0 THEN

            SELECT -2 AS nResultado,
                   'El modelo no existe' AS cMensaje;

        ELSE

            -- Verificar que la cantidad sea positiva.
            IF p_cantidad <= 0 THEN

                SELECT -3 AS nResultado,
                       'La cantidad debe ser mayor que cero' AS cMensaje;

            ELSE

                -- Verificar que no exista ya ese modelo/color en el pedido.
                SELECT COUNT(*)
                  INTO v_existe
                  FROM Detalle_Pedido_Concesionaria
                 WHERE fk_id_pedido_concesionaria = p_fk_id_pedido_concesionaria
                   AND fk_id_modelo = p_fk_id_modelo
                   AND color = p_color;

                IF v_existe > 0 THEN

                    SELECT -4 AS nResultado,
                           'Ese modelo y color ya existen en el detalle de ese pedido'
                           AS cMensaje;

                ELSE

                    INSERT INTO Detalle_Pedido_Concesionaria (
                        cantidad,
                        color,
                        fk_id_modelo,
                        fk_id_pedido_concesionaria
                    )
                    VALUES (
                        p_cantidad,
                        p_color,
                        p_fk_id_modelo,
                        p_fk_id_pedido_concesionaria
                    );

                    SELECT 0 AS nResultado,
                           '' AS cMensaje;

                END IF;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- DETALLE_PEDIDO_CONCESIONARIA - UPDATE
--
-- Se modifican cantidad y color. El pedido y el modelo no se modifican
-- (si se necesita cambiar de modelo, se debe dar de baja y crear otro).
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS detalle_pedido_concesionaria_Update;

DELIMITER $$

CREATE PROCEDURE detalle_pedido_concesionaria_Update(
    IN p_id_detalle_pedido_concesionaria INT,
    IN p_cantidad INT,
    IN p_color VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que exista el detalle.
    SELECT COUNT(*)
      INTO v_existe
      FROM Detalle_Pedido_Concesionaria
     WHERE id_detalle_pedido_concesionaria = p_id_detalle_pedido_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El detalle del pedido no existe' AS cMensaje;

    ELSE

        -- Verificar que la cantidad sea positiva.
        IF p_cantidad <= 0 THEN

            SELECT -2 AS nResultado,
                   'La cantidad debe ser mayor que cero' AS cMensaje;

        ELSE

            UPDATE Detalle_Pedido_Concesionaria
               SET cantidad = p_cantidad,
                   color = p_color
             WHERE id_detalle_pedido_concesionaria = p_id_detalle_pedido_concesionaria;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- DETALLE_PEDIDO_CONCESIONARIA - DELETE
--
-- No se puede eliminar un detalle si ya existen vehiculos generados
-- para ese pedido y ese modelo.
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS detalle_pedido_concesionaria_Delete;

DELIMITER $$

CREATE PROCEDURE detalle_pedido_concesionaria_Delete(
    IN p_id_detalle_pedido_concesionaria INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_vehiculos INT DEFAULT 0;
    DECLARE v_pedido INT DEFAULT 0;
    DECLARE v_modelo INT DEFAULT 0;

    -- Verificar que exista el detalle.
    SELECT COUNT(*)
      INTO v_existe
      FROM Detalle_Pedido_Concesionaria
     WHERE id_detalle_pedido_concesionaria = p_id_detalle_pedido_concesionaria;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El detalle del pedido no existe' AS cMensaje;

    ELSE

        SELECT fk_id_pedido_concesionaria, fk_id_modelo
          INTO v_pedido, v_modelo
          FROM Detalle_Pedido_Concesionaria
         WHERE id_detalle_pedido_concesionaria = p_id_detalle_pedido_concesionaria;

        -- Verificar si hay vehiculos asociados a ese pedido y modelo.
        SELECT COUNT(*)
          INTO v_vehiculos
          FROM Vehiculo
         WHERE fk_id_pedido_concesionaria = v_pedido
           AND fk_id_modelo = v_modelo;

        IF v_vehiculos > 0 THEN

            SELECT -2 AS nResultado,
                   'No se puede eliminar el detalle porque tiene vehiculos asociados'
                   AS cMensaje;

        ELSE

            DELETE FROM Detalle_Pedido_Concesionaria
             WHERE id_detalle_pedido_concesionaria = p_id_detalle_pedido_concesionaria;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- =====================================================================
-- PROVEEDOR
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- PROVEEDOR - INSERT
--
-- El esquema exige una estacion de trabajo a la que abastece el
-- proveedor (fk_id_estacion_trabajo NOT NULL).
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_Insert;

DELIMITER $$

CREATE PROCEDURE proveedor_Insert(
    IN p_razon_social VARCHAR(45),
    IN p_cuit BIGINT,
    IN p_fk_id_estacion_trabajo INT,
    IN p_calle VARCHAR(45),
    IN p_altura INT,
    IN p_localidad VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_nuevo_id INT DEFAULT 0;

    -- Verificar si ya existe un proveedor con el mismo CUIT.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor
     WHERE cuit = p_cuit;

    IF v_existe > 0 THEN

        SELECT -1 AS nResultado,
               'Ya existe un proveedor con ese CUIT' AS cMensaje;

    ELSE

        -- Verificar que exista la estacion de trabajo.
        SELECT COUNT(*)
          INTO v_existe
          FROM Estacion_Trabajo
         WHERE id_estacion_trabajo = p_fk_id_estacion_trabajo;

        IF v_existe = 0 THEN

            SELECT -2 AS nResultado,
                   'La estacion de trabajo no existe' AS cMensaje;

        ELSE

            INSERT INTO Proveedor (
                razon_social,
                cuit,
                fk_id_estacion_trabajo
            )
            VALUES (
                p_razon_social,
                p_cuit,
                p_fk_id_estacion_trabajo
            );

            SET v_nuevo_id = LAST_INSERT_ID();

            INSERT INTO Direccion (
                calle,
                altura,
                localidad,
                fk_id_concesionaria,
                fk_id_proveedor
            )
            VALUES (
                p_calle,
                p_altura,
                p_localidad,
                NULL,
                v_nuevo_id
            );

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PROVEEDOR - UPDATE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_Update;

DELIMITER $$

CREATE PROCEDURE proveedor_Update(
    IN p_id_proveedor INT,
    IN p_razon_social VARCHAR(45),
    IN p_cuit BIGINT,
    IN p_fk_id_estacion_trabajo INT,
    IN p_calle VARCHAR(45),
    IN p_altura INT,
    IN p_localidad VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_dir INT DEFAULT 0;

    -- Verificar que el proveedor exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor
     WHERE id_proveedor = p_id_proveedor;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El proveedor no existe' AS cMensaje;

    ELSE

        -- Verificar que el CUIT no pertenezca a otro proveedor.
        SELECT COUNT(*)
          INTO v_existe
          FROM Proveedor
         WHERE cuit = p_cuit
           AND id_proveedor <> p_id_proveedor;

        IF v_existe > 0 THEN

            SELECT -2 AS nResultado,
                   'El CUIT ya pertenece a otro proveedor' AS cMensaje;

        ELSE

            -- Verificar que exista la estacion de trabajo.
            SELECT COUNT(*)
              INTO v_existe
              FROM Estacion_Trabajo
             WHERE id_estacion_trabajo = p_fk_id_estacion_trabajo;

            IF v_existe = 0 THEN

                SELECT -3 AS nResultado,
                       'La estacion de trabajo no existe' AS cMensaje;

            ELSE

                UPDATE Proveedor
                   SET razon_social = p_razon_social,
                       cuit = p_cuit,
                       fk_id_estacion_trabajo = p_fk_id_estacion_trabajo
                 WHERE id_proveedor = p_id_proveedor;

                -- Actualizar direccion si ya tenia, o crearla si no tenia.
                SELECT COUNT(*)
                  INTO v_dir
                  FROM Direccion
                 WHERE fk_id_proveedor = p_id_proveedor;

                IF v_dir > 0 THEN

                    UPDATE Direccion
                       SET calle = p_calle,
                           altura = p_altura,
                           localidad = p_localidad
                     WHERE fk_id_proveedor = p_id_proveedor;

                ELSE

                    INSERT INTO Direccion (
                        calle,
                        altura,
                        localidad,
                        fk_id_concesionaria,
                        fk_id_proveedor
                    )
                    VALUES (
                        p_calle,
                        p_altura,
                        p_localidad,
                        NULL,
                        p_id_proveedor
                    );

                END IF;

                SELECT 0 AS nResultado,
                       '' AS cMensaje;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PROVEEDOR - DELETE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_Delete;

DELIMITER $$

CREATE PROCEDURE proveedor_Delete(
    IN p_id_proveedor INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_insumos INT DEFAULT 0;
    DECLARE v_pedidos INT DEFAULT 0;

    -- Verificar que el proveedor exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor
     WHERE id_proveedor = p_id_proveedor;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El proveedor no existe' AS cMensaje;

    ELSE

        -- Verificar si tiene insumos y precios asociados.
        SELECT COUNT(*)
          INTO v_insumos
          FROM Proveedor_Insumo
         WHERE fk_id_proveedor = p_id_proveedor;

        IF v_insumos > 0 THEN

            SELECT -2 AS nResultado,
                   'No se puede eliminar el proveedor porque tiene insumos y precios asociados'
                   AS cMensaje;

        ELSE

            -- Verificar si tiene pedidos a proveedor asociados.
            SELECT COUNT(*)
              INTO v_pedidos
              FROM Pedido_Proveedor
             WHERE fk_id_proveedor = p_id_proveedor;

            IF v_pedidos > 0 THEN

                SELECT -3 AS nResultado,
                       'No se puede eliminar el proveedor porque tiene pedidos asociados'
                       AS cMensaje;

            ELSE

                DELETE FROM Direccion
                 WHERE fk_id_proveedor = p_id_proveedor;

                DELETE FROM Proveedor
                 WHERE id_proveedor = p_id_proveedor;

                SELECT 0 AS nResultado,
                       '' AS cMensaje;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- =====================================================================
-- INSUMO
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- INSUMO - INSERT
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS insumo_Insert;

DELIMITER $$

CREATE PROCEDURE insumo_Insert(
    IN p_nombre VARCHAR(45),
    IN p_descripcion VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar si ya existe un insumo con ese nombre.
    SELECT COUNT(*)
      INTO v_existe
      FROM Insumo
     WHERE nombre = p_nombre;

    IF v_existe > 0 THEN

        SELECT -1 AS nResultado,
               'Ya existe un insumo con ese nombre' AS cMensaje;

    ELSE

        INSERT INTO Insumo (
            nombre,
            descripcion
        )
        VALUES (
            p_nombre,
            p_descripcion
        );

        SELECT 0 AS nResultado,
               '' AS cMensaje;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- INSUMO - UPDATE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS insumo_Update;

DELIMITER $$

CREATE PROCEDURE insumo_Update(
    IN p_id_insumo INT,
    IN p_nombre VARCHAR(45),
    IN p_descripcion VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que el insumo exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Insumo
     WHERE id_insumo = p_id_insumo;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El insumo no existe' AS cMensaje;

    ELSE

        -- Verificar que el nombre no pertenezca a otro insumo.
        SELECT COUNT(*)
          INTO v_existe
          FROM Insumo
         WHERE nombre = p_nombre
           AND id_insumo <> p_id_insumo;

        IF v_existe > 0 THEN

            SELECT -2 AS nResultado,
                   'Ya existe otro insumo con ese nombre' AS cMensaje;

        ELSE

            UPDATE Insumo
               SET nombre = p_nombre,
                   descripcion = p_descripcion
             WHERE id_insumo = p_id_insumo;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- INSUMO - DELETE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS insumo_Delete;

DELIMITER $$

CREATE PROCEDURE insumo_Delete(
    IN p_id_insumo INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_asociaciones INT DEFAULT 0;

    -- Verificar que el insumo exista.
    SELECT COUNT(*)
      INTO v_existe
      FROM Insumo
     WHERE id_insumo = p_id_insumo;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El insumo no existe' AS cMensaje;

    ELSE

        -- Verificar si esta asociado a estaciones, proveedores o pedidos.
        SELECT (
                  (SELECT COUNT(*) FROM Estacion_Insumo          WHERE fk_id_insumo = p_id_insumo)
                + (SELECT COUNT(*) FROM Proveedor_Insumo         WHERE fk_id_insumo = p_id_insumo)
                + (SELECT COUNT(*) FROM Detalle_Pedido_Proveedor WHERE fk_id_insumo = p_id_insumo)
               )
          INTO v_asociaciones;

        IF v_asociaciones > 0 THEN

            SELECT -2 AS nResultado,
                   'No se puede eliminar el insumo porque esta asociado a estaciones, proveedores o pedidos'
                   AS cMensaje;

        ELSE

            DELETE FROM Insumo
             WHERE id_insumo = p_id_insumo;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;



-- =====================================================================
-- =====================================================================
-- PROVEEDOR_INSUMO (extra: precio por insumo/proveedor)
--
-- No forma parte de los 4 ABMs pedidos explicitamente, pero se agrega
-- porque el precio de un insumo depende del proveedor (Insumo no tiene
-- columna precio) y asi se puede probar el flujo completo de Insumo +
-- Proveedor. La PK (idProveedor_Insumo) es manual, por eso aca si se
-- valida la colision de clave primaria literal.
-- =====================================================================
-- =====================================================================


-- ---------------------------------------------------------------------
-- PROVEEDOR_INSUMO - INSERT
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_insumo_Insert;

DELIMITER $$

CREATE PROCEDURE proveedor_insumo_Insert(
    IN p_idProveedor_Insumo VARCHAR(45),
    IN p_fk_id_proveedor INT,
    IN p_fk_id_insumo INT,
    IN p_precio FLOAT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar si ya existe un registro con esa clave primaria.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor_Insumo
     WHERE idProveedor_Insumo = p_idProveedor_Insumo;

    IF v_existe > 0 THEN

        SELECT -1 AS nResultado,
               'Ya existe un registro con ese identificador de proveedor-insumo' AS cMensaje;

    ELSE

        -- Verificar que exista el proveedor.
        SELECT COUNT(*)
          INTO v_existe
          FROM Proveedor
         WHERE id_proveedor = p_fk_id_proveedor;

        IF v_existe = 0 THEN

            SELECT -2 AS nResultado,
                   'El proveedor no existe' AS cMensaje;

        ELSE

            -- Verificar que exista el insumo.
            SELECT COUNT(*)
              INTO v_existe
              FROM Insumo
             WHERE id_insumo = p_fk_id_insumo;

            IF v_existe = 0 THEN

                SELECT -3 AS nResultado,
                       'El insumo no existe' AS cMensaje;

            ELSE

                -- Verificar que ese proveedor no tenga ya cargado ese insumo.
                SELECT COUNT(*)
                  INTO v_existe
                  FROM Proveedor_Insumo
                 WHERE fk_id_proveedor = p_fk_id_proveedor
                   AND fk_id_insumo = p_fk_id_insumo;

                IF v_existe > 0 THEN

                    SELECT -4 AS nResultado,
                           'Ese insumo ya esta asociado a ese proveedor' AS cMensaje;

                ELSE

                    -- Validar que el precio no sea negativo.
                    IF p_precio < 0 THEN

                        SELECT -5 AS nResultado,
                               'El precio no puede ser negativo' AS cMensaje;

                    ELSE

                        INSERT INTO Proveedor_Insumo (
                            idProveedor_Insumo,
                            precio,
                            fk_id_insumo,
                            fk_id_proveedor
                        )
                        VALUES (
                            p_idProveedor_Insumo,
                            p_precio,
                            p_fk_id_insumo,
                            p_fk_id_proveedor
                        );

                        SELECT 0 AS nResultado,
                               '' AS cMensaje;

                    END IF;

                END IF;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PROVEEDOR_INSUMO - UPDATE
--
-- Se modifica unicamente el precio. La clave primaria no se modifica.
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_insumo_Update;

DELIMITER $$

CREATE PROCEDURE proveedor_insumo_Update(
    IN p_idProveedor_Insumo VARCHAR(45),
    IN p_precio FLOAT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que exista el registro.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor_Insumo
     WHERE idProveedor_Insumo = p_idProveedor_Insumo;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El registro de proveedor-insumo no existe' AS cMensaje;

    ELSE

        -- Validar precio no negativo.
        IF p_precio < 0 THEN

            SELECT -2 AS nResultado,
                   'El precio no puede ser negativo' AS cMensaje;

        ELSE

            UPDATE Proveedor_Insumo
               SET precio = p_precio
             WHERE idProveedor_Insumo = p_idProveedor_Insumo;

            SELECT 0 AS nResultado,
                   '' AS cMensaje;

        END IF;

    END IF;

END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- PROVEEDOR_INSUMO - DELETE
-- ---------------------------------------------------------------------

DROP PROCEDURE IF EXISTS proveedor_insumo_Delete;

DELIMITER $$

CREATE PROCEDURE proveedor_insumo_Delete(
    IN p_idProveedor_Insumo VARCHAR(45)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Verificar que exista el registro.
    SELECT COUNT(*)
      INTO v_existe
      FROM Proveedor_Insumo
     WHERE idProveedor_Insumo = p_idProveedor_Insumo;

    IF v_existe = 0 THEN

        SELECT -1 AS nResultado,
               'El registro de proveedor-insumo no existe' AS cMensaje;

    ELSE

        DELETE FROM Proveedor_Insumo
         WHERE idProveedor_Insumo = p_idProveedor_Insumo;

        SELECT 0 AS nResultado,
               '' AS cMensaje;

    END IF;

END$$

DELIMITER ;

-- =====================================================================
-- FIN - SEGUNDA ETAPA
-- ABMs DE CONCESIONARIOS, PEDIDOS (CABECERA + DETALLE), PROVEEDORES
-- E INSUMOS (+ PROVEEDOR_INSUMO como extra)
-- =====================================================================
