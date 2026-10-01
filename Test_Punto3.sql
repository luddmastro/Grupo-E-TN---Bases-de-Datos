-- =================================================================
-- PRUEBA DE EJECUCIÓN: GENERACIÓN DE VEHÍCULOS POR PEDIDO
-- =================================================================

USE terminal_automotriz_bd;

-- =================================================================
-- CREACIÓN DE REGISTROS DE PRUEBA 
-- =================================================================

-- 1. LÍNEAS DE MONTAJE Y SUS RESPECTIVOS MODELOS
-- Línea 1 y Modelo 1 (ID_Modelo = 1)
INSERT INTO Linea_Montaje (nombre, prom_productivo) 
VALUES ('Línea Compactos - Fiesta', NULL);

INSERT INTO Modelo (nombre, version, fk_id_linea_montaje) 
VALUES ('Fiesta', '1.6 SE', 1);

-- Línea 2 y Modelo 2 (ID_Modelo = 2)
INSERT INTO Linea_Montaje (nombre, prom_productivo) 
VALUES ('Línea Medianos - Focus', NULL);

INSERT INTO Modelo (nombre, version, fk_id_linea_montaje) 
VALUES ('Focus', '2.0 Titanium', 2);

-- 2. CONCESIONARIA
INSERT INTO Concesionaria (nombre, contacto) 
VALUES ('Concesionaria Central', '1144332211');

-- 3. CREACIÓN DEL PEDIDO (ID_PEDIDO = 1)
INSERT INTO Pedido_Concesionaria (fecha_pedido, fecha_entrega_estimada, fk_id_concesionaria) 
VALUES (NOW(), NULL, 1);

-- 4. DETALLES DEL PEDIDO (ID_PEDIDO = 1)
-- Encargamos: 2 Fiesta Blancos, 1 Fiesta Rojo y 2 Focus Negros
INSERT INTO Detalle_Pedido_Concesionaria (cantidad, color, fk_id_modelo, fk_id_pedido_concesionaria) 
VALUES 
(2, 'Blanco', 1, 1),
(1, 'Rojo', 1, 1),
(2, 'Negro', 2, 1);

-- =================================================================
-- EJECUCIÓN DEL PROCEDIMIENTO PRINCIPAL
-- =================================================================

CALL CrearVehiculosPorPedido(1);

-- =================================================================
-- CONSULTA DE VERIFICACIÓN 
-- =================================================================

SELECT *
FROM Vehiculo V
INNER JOIN Modelo M 
    ON M.id_modelo = V.fk_id_modelo;