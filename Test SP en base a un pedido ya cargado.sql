START TRANSACTION;

CALL CrearVehiculosPorPedido(1);

SELECT *
FROM Vehiculo V
INNER JOIN Modelo M 
    ON M.id_modelo = V.fk_id_modelo;

ROLLBACK;