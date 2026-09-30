
INSERT INTO Proveedor VALUES ('Lubricentro',30111111110,NULL)
INSERT INTO Proveedor VALUES ('GoodYear',33123456789,NULL)
INSERT INTO Proveedor VALUES ('Sherwin Williams',33987654321,NULL)


INSERT INTO Insumo VALUES ('Pintura','Pintura para autos')
INSERT INTO Insumo VALUES ('Neumático','Neumático completo')
INSERT INTO Insumo VALUES ('Aceite','Aceite para motor')
ALTER TABLE Linea_Montaje
ADD  IDModelo INT 
INSERT INTO Linea_Montaje VALUES ('Alpha',5.5,NULL)
INSERT INTO Linea_Montaje VALUES ('Beta',3.5,NULL)


INSERT INTO Estacion_Trabajo VALUES ('Pintar la carroceria',1,1)
INSERT INTO Estacion_Trabajo VALUES ('Ensamblado de neumáticos',2,1)
INSERT INTO Estacion_Trabajo VALUES ('Agregar el aceite',3,1)

INSERT INTO Estacion_Insumo VALUES (1,10,1,1)
INSERT INTO Estacion_Insumo VALUES (2,4,2,2)
INSERT INTO Estacion_Insumo VALUES (3,1,3,3)

INSERT INTO Modelo VALUES ('Fiesta','1.6')
INSERT INTO Modelo VALUES ('Gol','1.6')

INSERT INTO Concesionaria VALUES ('Norauto',1122334455)

INSERT INTO Pedido_Concesionaria VALUES ('20260928','20261006',1)

INSERT INTO Detalle_Pedido_Concesionaria VALUES (1,'Blanco',1,1)
INSERT INTO Detalle_Pedido_Concesionaria VALUES (1,'Negro',2,1)

