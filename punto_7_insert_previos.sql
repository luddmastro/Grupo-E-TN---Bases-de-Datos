USE terminal_automotriz_bd;

-- =====================================================
-- 1. MODELOS
-- =====================================================

INSERT INTO Modelo (nombre, version)
VALUES
('Auto Compacto', '2026'),
('Sedan Familiar', '2026'),
('SUV', '2026'),
('Pickup', '2026'),
('Deportivo', '2026');


-- =====================================================
-- 2. LINEAS DE MONTAJE
-- =====================================================

INSERT INTO Linea_Montaje (nombre, prom_productivo, fk_id_modelo)
VALUES
('Linea Compactos', 200, 1),
('Linea Sedan', 150, 2),
('Linea SUV', 120, 3),
('Linea Pickup', 100, 4),
('Linea Deportivos', 80, 5);


-- =====================================================
-- 3. ESTACIONES DE TRABAJO
-- Tres estaciones por linea
-- =====================================================

INSERT INTO Estacion_Trabajo (tarea, orden, fk_id_linea_montaje)
VALUES
-- Modelo 1: Auto Compacto
('Montaje mecanico', 1, 1),
('Instalacion electrica', 2, 1),
('Pintura y terminacion', 3, 1),

-- Modelo 2: Sedan Familiar
('Montaje mecanico', 1, 2),
('Instalacion electrica', 2, 2),
('Pintura y terminacion', 3, 2),

-- Modelo 3: SUV
('Montaje mecanico', 1, 3),
('Instalacion electrica', 2, 3),
('Pintura y terminacion', 3, 3),

-- Modelo 4: Pickup
('Montaje mecanico', 1, 4),
('Instalacion electrica', 2, 4),
('Pintura y terminacion', 3, 4),

-- Modelo 5: Deportivo
('Montaje mecanico', 1, 5),
('Instalacion electrica', 2, 5),
('Pintura y terminacion', 3, 5);


-- =====================================================
-- 4. INSUMOS
-- =====================================================

INSERT INTO Insumo (nombre, descripcion)
VALUES
('Rueda', 'Rueda para vehiculo'),
('Motor', 'Motor completo'),
('Puerta', 'Puerta de vehiculo'),
('Pintura', 'Pintura para carroceria'),
('Cable', 'Cableado electrico'),
('Bateria', 'Bateria del vehiculo'),
('Parabrisas', 'Vidrio delantero'),
('Asiento', 'Asiento de vehiculo'),
('Faro LED', 'Faro de iluminacion'),
('Neumatico deportivo', 'Neumatico de alto rendimiento');


-- =====================================================
-- 5. INSUMOS UTILIZADOS EN CADA ESTACION
-- La cantidad representa el consumo por vehiculo
-- =====================================================

INSERT INTO Estacion_Insumo
    (idEstacion_insumo, cantidad,
     fk_id_estacion_trabajo, fk_id_insumo)
VALUES
-- Modelo 1: Auto Compacto
(1, 4, 1, 1),
(2, 1, 1, 2),
(3, 4, 1, 3),
(4, 1, 2, 5),
(5, 1, 3, 4),

-- Modelo 2: Sedan Familiar
(6, 4, 4, 1),
(7, 1, 4, 2),
(8, 4, 4, 3),
(9, 1, 5, 6),
(10, 1, 6, 7),

-- Modelo 3: SUV
(11, 4, 7, 1),
(12, 1, 7, 2),
(13, 1, 8, 6),
(14, 1, 8, 8),
(15, 1, 9, 4),

-- Modelo 4: Pickup
(16, 4, 10, 1),
(17, 1, 10, 2),
(18, 1, 11, 5),
(19, 1, 11, 9),
(20, 1, 12, 7),

-- Modelo 5: Deportivo
(21, 4, 13, 10),
(22, 1, 13, 2),
(23, 2, 14, 9),
(24, 1, 14, 5),
(25, 1, 15, 4);


-- =====================================================
-- 6. VERIFICACION DE LOS DATOS
-- =====================================================

SELECT * FROM Modelo;

SELECT * FROM Linea_Montaje;

SELECT * FROM Estacion_Trabajo;

SELECT * FROM Insumo;

SELECT * FROM Estacion_Insumo;


-- =====================================================
-- 7. CONSULTA PARA VER LOS INSUMOS POR MODELO
-- =====================================================

SELECT
    m.id_modelo,
    m.nombre AS modelo,
    et.tarea AS estacion,
    i.id_insumo,
    i.nombre AS insumo,
    ei.cantidad AS cantidad_por_vehiculo
FROM Modelo m
JOIN Linea_Montaje lm
    ON lm.fk_id_modelo = m.id_modelo
JOIN Estacion_Trabajo et
    ON et.fk_id_linea_montaje = lm.id_linea_montaje
JOIN Estacion_Insumo ei
    ON ei.fk_id_estacion_trabajo = et.id_estacion_trabajo
JOIN Insumo i
    ON i.id_insumo = ei.fk_id_insumo
ORDER BY
    m.id_modelo,
    et.orden,
    i.id_insumo;
	
	
-- 1. Crear una concesionaria	
INSERT INTO Concesionaria (nombre, contacto)
VALUES ('Concesionaria Central', 'Juan Perez');

-- 2. Crear un pedido para esa concesionaria
INSERT INTO Pedido_Concesionaria
    (fecha_pedido, fecha_entrega_estimada, fk_id_concesionaria)
VALUES
    ('2026-10-10 10:00:00', '2026-11-10 10:00:00', 1);

-- 3. Agregar el detalle del pedido  
INSERT INTO Detalle_Pedido_Concesionaria
    (cantidad, color, fk_id_modelo, fk_id_pedido_concesionaria)
VALUES
    (3, 'Blanco', 1, 1),
    (2, 'Negro', 3, 1),
    (1, 'Rojo', 5, 1);
	
	
	
