-- =================================================================
-- PRUEBA DE EJECUCIÓN: INICIAR MONTAJE DE VEHICULO
-- =================================================================

USE terminal_automotriz_bd;

-- =================================================================
-- CREACIÓN DE REGISTROS DE PRUEBA 
-- ACLARACIÓN: Omitimos el SP de CrearVehiculosPorPedido y cargamos los datos basicos manualmente para acelerar la prueba
-- =================================================================

-- 1. Registrar Modelos
INSERT INTO Modelo (id_modelo, nombre, version) 
VALUES (1, 'Fiesta', '1.6 SE'),
       (2, 'Focus', '2.0 Titanium');

-- 2. Registrar Líneas de Montaje (apuntando al modelo correspondiente)
INSERT INTO Linea_Montaje (id_linea_montaje, nombre, prom_productivo, fk_id_modelo) 
VALUES (1, 'Línea Fiesta', NULL, 1),
       (2, 'Línea Focus', NULL, 2);

-- 3. Registrar Estaciones de Trabajo para cada línea 
-- (La primera estación de cada línea será la de menor orden: orden = 1)
INSERT INTO Estacion_Trabajo (id_estacion_trabajo, tarea, orden, fk_id_linea_montaje) 
VALUES 
(1, 'Chasis y Soldadura Fiesta', 1, 1),
(2, 'Pintura Fiesta', 2, 1),
(3, 'Chasis y Soldadura Focus', 1, 2);

-- 4. Registrar Concesionaria y Pedido para poder crear vehículos de prueba
INSERT INTO Concesionaria (id_concesionaria, nombre, contacto) 
VALUES (1, 'Motors Sur', '1122334455');

INSERT INTO Pedido_Concesionaria (id_pedido_concesionaria, fecha_pedido, fk_id_concesionaria) 
VALUES (1, NOW(), 1);

-- 5. Crear Vehículos de Prueba
INSERT INTO Vehiculo (numeroChasis, patente, color, anio_fabricacion, fecha_ingreso, fecha_fin, fk_id_modelo, fk_id_estacion_trabajo, fk_id_pedido_concesionaria) 
VALUES 
('10001', 'ABC123AA', 'Blanco', NULL, NULL, NULL, 1, NULL, 1),
('10002', 'XYZ988ZZ', 'Rojo', NULL, NULL, NULL, 1, NULL, 1),
('10003', 'DEF456BB', 'Negro', NULL, NULL, NULL, 2, NULL, 1);


-- =================================================================
-- PRUEBAS DE EJECUCIÓN 
-- =================================================================

-- -----------------------------------------------------------------
-- PRUEBA 1: Error - Patente inexistente 
-- -----------------------------------------------------------------
CALL IniciarMontajeVehiculo('PATENTE_Falsa');


-- -----------------------------------------------------------------
-- PRUEBA 2: Éxito - Iniciar montaje del Vehículo 1 ('ABC123AA') 
-- -----------------------------------------------------------------
CALL IniciarMontajeVehiculo('ABC123AA');


-- -----------------------------------------------------------------
-- PRUEBA 3: Error - Intentar meter el Vehículo 2 ('XYZ988ZZ') a la misma línea
-- pero la estación 1 ya está ocupada por el vehículo 1 
-- -----------------------------------------------------------------
CALL IniciarMontajeVehiculo('XYZ988ZZ');


-- -----------------------------------------------------------------
-- PRUEBA 4: Error - Intentar pasar OTRA VEZ el Vehículo 1 ('ABC123AA') que ya está en curso 
-- -----------------------------------------------------------------
CALL IniciarMontajeVehiculo('ABC123AA');


-- -----------------------------------------------------------------
-- PRUEBA 5: Éxito - Iniciar montaje del Vehículo 3 ('DEF456BB') de otra línea
-- -----------------------------------------------------------------
CALL IniciarMontajeVehiculo('DEF456BB');


-- =================================================================
-- 3. CONSULTAS DE VERIFICACIÓN FINAL
-- =================================================================

-- === ESTADO FINAL DE LOS VEHÍCULOS ===
SELECT 
    V.numeroChasis,
    V.patente,
    V.color,
    V.fecha_ingreso,
    M.nombre AS modelo,
    LM.nombre AS linea_montaje,
    ET.id_estacion_trabajo,
    ET.tarea AS estacion_actual
FROM Vehiculo V
INNER JOIN Modelo M 
    ON M.id_modelo = V.fk_id_modelo
INNER JOIN Linea_Montaje LM 
    ON LM.fk_id_modelo = M.id_modelo
LEFT JOIN Estacion_Trabajo ET 
    ON ET.id_estacion_trabajo = V.fk_id_estacion_trabajo;

-- === REGISTROS DE PASO ===
SELECT * FROM Registro_Paso;