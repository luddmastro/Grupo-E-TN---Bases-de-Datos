-- =================================================================
-- SCRIPT DE PRUEBA: AVANZAR VEHICULO A LA SIGUIENTE ESTACION
-- Punto 5 - Etapa 3
-- Requiere que exista el procedimiento AvanzarVehiculoEstacion.
-- Diseñado para MySQL 8.0.
-- =================================================================

USE terminal_automotriz_bd;

-- -----------------------------------------------------------------
-- 0. LIMPIEZA DE UNA EJECUCION ANTERIOR DE ESTE MISMO TEST
-- Se utilizan nombres y patentes con prefijo P5TEST.
-- -----------------------------------------------------------------

DELETE FROM Registro_Paso
WHERE fk_numeroChasis_vehiculo IN
      ('P5TEST001', 'P5TEST002', 'P5TEST003', 'P5TEST004', 'P5TEST005');

DELETE FROM Vehiculo
WHERE numeroChasis IN
      ('P5TEST001', 'P5TEST002', 'P5TEST003', 'P5TEST004', 'P5TEST005');

DELETE FROM Pedido_Concesionaria
WHERE id_pedido_concesionaria IN (
    SELECT id_pedido FROM (
        SELECT PC.id_pedido_concesionaria AS id_pedido
        FROM Pedido_Concesionaria PC
        INNER JOIN Concesionaria C
            ON C.id_concesionaria = PC.fk_id_concesionaria
        WHERE C.nombre = 'P5TEST Concesionaria'
    ) AS pedidos_test
);

DELETE FROM Concesionaria
WHERE nombre = 'P5TEST Concesionaria';

DELETE FROM Estacion_Trabajo
WHERE fk_id_linea_montaje IN (
    SELECT id_linea FROM (
        SELECT LM.id_linea_montaje AS id_linea
        FROM Linea_Montaje LM
        INNER JOIN Modelo M ON M.id_modelo = LM.fk_id_modelo
        WHERE M.nombre IN ('P5TEST Modelo')
    ) AS lineas_test
);

DELETE FROM Linea_Montaje
WHERE fk_id_modelo IN (
    SELECT id_modelo FROM (
        SELECT id_modelo
        FROM Modelo
        WHERE nombre = 'P5TEST Modelo'
    ) AS modelos_test
);

DELETE FROM Modelo
WHERE nombre = 'P5TEST Modelo';

-- -----------------------------------------------------------------
-- 1. CREACION DE DATOS DE PRUEBA
-- Se crea una línea con tres estaciones: 1, 2 y 3.
-- -----------------------------------------------------------------

INSERT INTO Modelo (nombre, version)
VALUES ('P5TEST Modelo', 'Prueba punto 5');
SET @id_modelo_p5 = LAST_INSERT_ID();

INSERT INTO Linea_Montaje (nombre, prom_productivo, fk_id_modelo)
VALUES ('P5TEST Linea', NULL, @id_modelo_p5);
SET @id_linea_p5 = LAST_INSERT_ID();

INSERT INTO Estacion_Trabajo (tarea, orden, fk_id_linea_montaje)
VALUES ('P5TEST Estacion 1', 1, @id_linea_p5);
SET @id_estacion_1_p5 = LAST_INSERT_ID();

INSERT INTO Estacion_Trabajo (tarea, orden, fk_id_linea_montaje)
VALUES ('P5TEST Estacion 2', 2, @id_linea_p5);
SET @id_estacion_2_p5 = LAST_INSERT_ID();

INSERT INTO Estacion_Trabajo (tarea, orden, fk_id_linea_montaje)
VALUES ('P5TEST Estacion 3', 3, @id_linea_p5);
SET @id_estacion_3_p5 = LAST_INSERT_ID();

INSERT INTO Concesionaria (nombre, contacto)
VALUES ('P5TEST Concesionaria', 'Prueba punto 5');
SET @id_concesionaria_p5 = LAST_INSERT_ID();

INSERT INTO Pedido_Concesionaria
    (fecha_pedido, fecha_entrega_estimada, fk_id_concesionaria)
VALUES
    (NOW(), NULL, @id_concesionaria_p5);
SET @id_pedido_p5 = LAST_INSERT_ID();

-- Vehículo 1: en estación 1. Se usará para probar estación ocupada
-- y, después de liberar la estación 2, avance exitoso.
-- Vehículo 2: ocupa la estación 2 y luego avanzará a la estación 3.
-- Vehículo 3: está en la última estación para probar finalización.
-- Vehículo 4: todavía no inició el montaje.
-- Vehículo 5: ya está finalizado.

INSERT INTO Vehiculo
    (numeroChasis, patente, color, anio_fabricacion, fecha_ingreso,
     fecha_fin, fk_id_modelo, fk_id_estacion_trabajo,
     fk_id_pedido_concesionaria)
VALUES
    ('P5TEST001', 'P5T001', 'Blanco', NULL, NOW(), NULL,
     @id_modelo_p5, @id_estacion_1_p5, @id_pedido_p5),
    ('P5TEST002', 'P5T002', 'Azul', NULL, NOW(), NULL,
     @id_modelo_p5, @id_estacion_2_p5, @id_pedido_p5),
    ('P5TEST003', 'P5T003', 'Rojo', NULL, NOW(), NULL,
     @id_modelo_p5, @id_estacion_3_p5, @id_pedido_p5),
    ('P5TEST004', 'P5T004', 'Gris', NULL, NULL, NULL,
     @id_modelo_p5, NULL, @id_pedido_p5),
    ('P5TEST005', 'P5T005', 'Negro', NULL, NOW(), NOW(),
     @id_modelo_p5, NULL, @id_pedido_p5);

-- Crear registros de paso abiertos para los vehículos que ya están
-- en una estación. El vehículo 4 no tiene registro porque no inició.
INSERT INTO Registro_Paso
    (fecha_hora_ingreso, fecha_hora_egreso,
     fk_id_estacion_trabajo, fk_numeroChasis_vehiculo)
VALUES
    (NOW(), NULL, @id_estacion_1_p5, 'P5TEST001'),
    (NOW(), NULL, @id_estacion_2_p5, 'P5TEST002'),
    (NOW(), NULL, @id_estacion_3_p5, 'P5TEST003');

-- -----------------------------------------------------------------
-- 2. PRUEBAS DE EJECUCION
-- -----------------------------------------------------------------

-- PRUEBA 1: Error - patente inexistente. Esperado: nResultado = -1.
CALL AvanzarVehiculoEstacion('P5T999');

-- PRUEBA 2: Error - estación siguiente ocupada por P5T002.
-- El vehículo P5T001 está en estación 1 y la estación 2 está ocupada.
-- Esperado: nResultado = -5, con chasis P5TEST002 y patente P5T002.
CALL AvanzarVehiculoEstacion('P5T001');

-- PRUEBA 3: Última estación - finalizar P5T003.
-- Se hace antes de avanzar P5T002 para liberar la estación 3.
-- Esperado: nResultado = 0 y Vehiculo.fecha_fin actualizado.
CALL AvanzarVehiculoEstacion('P5T003');

-- PRUEBA 4: Avance exitoso del vehículo P5T002 de estación 2 a 3.
-- La estación 3 quedó libre tras finalizar P5T003. Esperado: nResultado = 0.
CALL AvanzarVehiculoEstacion('P5T002');

-- PRUEBA 5: Avance exitoso del vehículo P5T001 de estación 1 a 2,
-- ahora que la estación 2 quedó libre. Esperado: nResultado = 0.
CALL AvanzarVehiculoEstacion('P5T001');

-- PRUEBA 6: Vehículo sin iniciar el montaje. Esperado: nResultado = -2.
CALL AvanzarVehiculoEstacion('P5T004');

-- PRUEBA 7: Vehículo ya finalizado. Esperado: nResultado = -3.
CALL AvanzarVehiculoEstacion('P5T005');

-- -----------------------------------------------------------------
-- 3. CONSULTAS DE VERIFICACION
-- -----------------------------------------------------------------

-- Estado de los vehículos de prueba y estación actual.
SELECT
    V.numeroChasis,
    V.patente,
    V.fecha_ingreso,
    V.fecha_fin,
    V.fk_id_estacion_trabajo AS id_estacion_actual,
    ET.tarea AS estacion_actual
FROM Vehiculo V
LEFT JOIN Estacion_Trabajo ET
    ON ET.id_estacion_trabajo = V.fk_id_estacion_trabajo
WHERE V.numeroChasis IN
      ('P5TEST001', 'P5TEST002', 'P5TEST003', 'P5TEST004', 'P5TEST005')
ORDER BY V.numeroChasis;

-- Historial de pasos: los registros anteriores deben tener egreso;
-- los registros de las estaciones actuales deben seguir abiertos.
SELECT
    RP.id_registro_paso,
    RP.fk_numeroChasis_vehiculo AS chasis,
    V.patente,
    ET.tarea AS estacion,
    RP.fecha_hora_ingreso,
    RP.fecha_hora_egreso
FROM Registro_Paso RP
INNER JOIN Vehiculo V
    ON V.numeroChasis = RP.fk_numeroChasis_vehiculo
INNER JOIN Estacion_Trabajo ET
    ON ET.id_estacion_trabajo = RP.fk_id_estacion_trabajo
WHERE RP.fk_numeroChasis_vehiculo IN
      ('P5TEST001', 'P5TEST002', 'P5TEST003', 'P5TEST004', 'P5TEST005')
ORDER BY RP.fk_numeroChasis_vehiculo, RP.fecha_hora_ingreso;
