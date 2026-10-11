DROP PROCEDURE IF EXISTS reporte_insumos_Pedido;

DELIMITER //

CREATE PROCEDURE reporte_insumos_Pedido(
    IN p_id_pedido INT
)
BEGIN
    SELECT
        i.id_insumo AS codigo_insumo,
        i.nombre AS insumo,
        SUM(ei.cantidad * d.cantidad) AS cantidad_requerida
    FROM Detalle_Pedido_Concesionaria d
    JOIN Linea_Montaje lm
        ON lm.fk_id_modelo = d.fk_id_modelo
    JOIN Estacion_Trabajo et
        ON et.fk_id_linea_montaje = lm.id_linea_montaje
    JOIN Estacion_Insumo ei
        ON ei.fk_id_estacion_trabajo = et.id_estacion_trabajo
    JOIN Insumo i
        ON i.id_insumo = ei.fk_id_insumo
    WHERE d.fk_id_pedido_concesionaria = p_id_pedido
    GROUP BY
        i.id_insumo,
        i.nombre
    ORDER BY i.id_insumo;
END //

DELIMITER ;

