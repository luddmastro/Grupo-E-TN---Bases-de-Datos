DROP PROCEDURE IF EXISTS tiempo_promedio_construccion;

DELIMITER //

CREATE PROCEDURE tiempo_promedio_construccion(
    IN p_id_linea INT
)
BEGIN
    SELECT 
        Linea_Montaje.nombre AS linea_montaje,
        AVG(TIMESTAMPDIFF(HOUR, Vehiculo.fecha_ingreso, Vehiculo.fecha_fin)) AS promedio_horas_construccion
    FROM Vehiculo
    INNER JOIN Modelo 
        ON Vehiculo.fk_id_modelo = Modelo.id_modelo
    INNER JOIN Linea_Montaje 
        ON Linea_Montaje.fk_id_modelo = Modelo.id_modelo
    WHERE Linea_Montaje.id_linea_montaje = p_id_linea
      AND Vehiculo.fecha_fin IS NOT NULL; 
END //

DELIMITER ;