USE terminal_automotriz_bd;

INSERT INTO Vehiculo (numeroChasis, patente, color, anio_fabricacion, fecha_ingreso, fecha_fin, fk_id_modelo, fk_id_estacion_trabajo, fk_id_pedido_concesionaria)
VALUES
('CH-001', 'AB123CD', 'Blanco', 2026, '2026-10-11', '2026-10-15', 1, NULL, 1), 
('CH-002', 'AB124CD', 'Blanco', 2026, '2026-10-12', NULL, 1, 2, 1),            
('CH-003', 'AB125CD', 'Blanco', 2026, '2026-10-13', NULL, 1, 1, 1);