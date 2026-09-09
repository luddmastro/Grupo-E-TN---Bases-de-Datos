# Crear una base de datos ---
create database if not exists terminal_automotriz_bd; 

# Seleccionar base de datos para trabajar ---
use terminal_automotriz_bd;

# Crear tablas ---
create table if not exists Linea_Montaje (
    # Atributos
    id_linea_montaje int not null auto_increment,
    nombre varchar(45) not null,
    prom_productivo float null,
    # Llave primaria
    primary key (id_linea_montaje)
);

create table if not exists Estacion_Trabajo (
    # Atributos
    id_estacion_trabajo int not null auto_increment,
    tarea varchar(45) not null,
    orden int not null,
    # Llave primaria
    primary key (id_estacion_trabajo),
    # Llave foranea
    fk_id_linea_montaje int not null
);

create table if not exists Insumo (
    # Atributos
    id_insumo int not null auto_increment,
    nombre varchar(45) not null,
    descripcion varchar(45) not null,
    # Llave primaria
    primary key (id_insumo)
);

create table if not exists Estacion_Insumo (
    # Atributos
    idEstacion_insumo int not null,
    # Llaves foraneas 
    fk_id_estacion_trabajo int not null,
    fk_id_insumo int not null,
    # Llave primaria compuesta
    primary key (idEstacion_insumo)
);

create table if not exists Proveedor (
    # Atributos
    id_proveedor int not null auto_increment,
    razon_social varchar(45) not null,
    cuit bigint not null,
    # Llave primaria
    primary key (id_proveedor),
    # Llave foranea
    fk_id_estacion_trabajo int not null
);

create table if not exists Proveedor_Insumo (
    # Atributos
    idProveedor_Insumo varchar(45) not null,
    precio float not null,
    # Llaves foraneas
    fk_id_insumo int not null,
    fk_id_proveedor int not null,
    # Llave primaria compuesta
    primary key (idProveedor_Insumo)
);

create table if not exists Modelo (
    # Atributos
    id_modelo int not null auto_increment,
    nombre varchar(45) not null,
    version varchar(45) not null,
    # Llave primaria
    primary key (id_modelo),
    # Llave foranea
    fk_id_linea_montaje int not null
);

create table if not exists Concesionaria (
    # Atributos
    id_concesionaria int not null auto_increment,
    nombre varchar(45) not null,
    contacto varchar(45) not null,
    # Llave primaria
    primary key (id_concesionaria)
);

create table if not exists Pedido_Concesionaria (
    # Atributos
    id_pedido_concesionaria int not null auto_increment,
    fecha_pedido datetime not null,
    fecha_entrega_estimada datetime null,
    # Llave primaria
    primary key (id_pedido_concesionaria),
    # Llave foranea
    fk_id_concesionaria int not null
);

create table if not exists Vehiculo (
    # Atributos
    patente varchar(45) not null,
    color varchar(45) not null,
    anio_fabricacion int null,
    fecha_ingreso datetime null,
    fecha_fin datetime null,
    # Llave primaria
    primary key (patente),
    # Llaves foraneas
    fk_id_modelo int not null,
    fk_id_estacion_trabajo int null,
    fk_id_pedido_concesionaria int not null
);

create table if not exists Registro_Paso (
    # Atributos
    id_registro_paso int not null auto_increment,
    fecha_hora_ingreso datetime not null,
    fecha_hora_egreso datetime not null,
    # Llave primaria
    primary key (id_registro_paso),
    # Llaves foraneas
    fk_id_estacion_trabajo int not null,
    fk_patente_vehiculo varchar(45) not null
);

create table if not exists Pedido_Proveedor (
    # Atributos
    id_pedido_proveedor int not null auto_increment,
    fecha_pedido datetime not null,
    fecha_entrega datetime null,
    estado char(1) not null,
    # Llave primaria
    primary key (id_pedido_proveedor),
    # Llave foranea
    fk_id_proveedor int not null
);

create table if not exists Detalle_Pedido_Proveedor (
    # Atributos
    id_detalle_pedido_proveedor int not null auto_increment,
    cantidad int not null,
    # Llave primaria
    primary key (id_detalle_pedido_proveedor),
    # Llaves foraneas
    fk_id_pedido_proveedor int not null,
    fk_id_insumo int not null
);

create table if not exists Detalle_Pedido_Concesionaria (
    # Atributos
    id_detalle_pedido_concesionaria int not null auto_increment,
    cantidad int not null,
    color varchar(45) not null,
    # Llave primaria
    primary key (id_detalle_pedido_concesionaria),
    # Llaves foraneas
    fk_id_modelo int not null,
    fk_id_pedido_concesionaria int not null
);

create table if not exists Direccion (
    # Atributos
    id_direccion int not null auto_increment,
    calle varchar(45) not null,
    altura int not null,
    localidad varchar(45) not null,
    # Llave primaria
    primary key (id_direccion),
    # Llaves foraneas
    fk_id_concesionaria int null,
    fk_id_proveedor int null
);

# Generar relaciones ---

alter table Estacion_Trabajo
add constraint linea_montaje_tiene_estaciones
foreign key (fk_id_linea_montaje)
references Linea_Montaje(id_linea_montaje);

alter table Estacion_Insumo
add constraint estacion_requiere_insumos
foreign key (fk_id_estacion_trabajo)
references Estacion_Trabajo(id_estacion_trabajo);

alter table Estacion_Insumo
add constraint insumo_usado_en_estaciones
foreign key (fk_id_insumo)
references Insumo(id_insumo);

alter table Proveedor
add constraint proveedor_abastece_estacion
foreign key (fk_id_estacion_trabajo)
references Estacion_Trabajo(id_estacion_trabajo);

alter table Proveedor_Insumo
add constraint insumo_provisto_por_proveedor
foreign key (fk_id_insumo)
references Insumo(id_insumo);

alter table Proveedor_Insumo
add constraint proveedor_ofrece_insumos
foreign key (fk_id_proveedor)
references Proveedor(id_proveedor);

alter table Modelo
add constraint linea_montaje_produce_modelos
foreign key (fk_id_linea_montaje)
references Linea_Montaje(id_linea_montaje);

alter table Pedido_Concesionaria
add constraint concesionaria_realiza_pedidos
foreign key (fk_id_concesionaria)
references Concesionaria(id_concesionaria);

alter table Vehiculo
add constraint modelo_tiene_vehiculos
foreign key (fk_id_modelo)
references Modelo(id_modelo);

alter table Vehiculo
add constraint estacion_procesa_vehiculo
foreign key (fk_id_estacion_trabajo)
references Estacion_Trabajo(id_estacion_trabajo);

alter table Vehiculo
add constraint pedido_concesionaria_incluye_vehiculo
foreign key (fk_id_pedido_concesionaria)
references Pedido_Concesionaria(id_pedido_concesionaria);

alter table Registro_Paso
add constraint estacion_registra_paso
foreign key (fk_id_estacion_trabajo)
references Estacion_Trabajo(id_estacion_trabajo);

alter table Registro_Paso
add constraint vehiculo_tiene_registros_paso
foreign key (fk_patente_vehiculo)
references Vehiculo(patente);

alter table Pedido_Proveedor
add constraint proveedor_recibe_pedidos
foreign key (fk_id_proveedor)
references Proveedor(id_proveedor);

alter table Detalle_Pedido_Proveedor
add constraint pedido_proveedor_tiene_detalles
foreign key (fk_id_pedido_proveedor)
references Pedido_Proveedor(id_pedido_proveedor);

alter table Detalle_Pedido_Proveedor
add constraint insumo_incluido_en_detalle_proveedor
foreign key (fk_id_insumo)
references Insumo(id_insumo);

alter table Detalle_Pedido_Concesionaria
add constraint modelo_incluido_en_detalle_concesionaria
foreign key (fk_id_modelo)
references Modelo(id_modelo);

alter table Detalle_Pedido_Concesionaria
add constraint pedido_concesionaria_tiene_detalles
foreign key (fk_id_pedido_concesionaria)
references Pedido_Concesionaria(id_pedido_concesionaria);

alter table Direccion
add constraint concesionaria_tiene_direccion
foreign key (fk_id_concesionaria)
references Concesionaria(id_concesionaria);

alter table Direccion
add constraint proveedor_tiene_direccion
foreign key (fk_id_proveedor)
references Proveedor(id_proveedor);