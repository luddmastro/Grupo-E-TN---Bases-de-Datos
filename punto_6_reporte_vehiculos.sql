DROP PROCEDURE IF EXISTS reporte_vehiculos_Pedido;

DELIMITER //

CREATE PROCEDURE reporte_vehiculos_Pedido(
    IN p_id_pedido INT
)
BEGIN
    SELECT
        v.numeroChasis AS chasis,
        IF(v.fecha_fin IS NULL, 'No terminado', 'Finalizado') AS estado_vehiculo,
        IF(et.tarea IS NULL, 'Terminado / Sin estacion asignada', et.tarea) AS estacion_actual
    FROM Vehiculo v
    LEFT JOIN Estacion_Trabajo et
        ON et.id_estacion_trabajo = v.fk_id_estacion_trabajo
    WHERE v.fk_id_pedido_concesionaria = p_id_pedido;
END //
DELIMITER ;