CREATE DATABASE BancoAlimentos_test
USE BancoAlimentos_test

DROP TABLE IF EXISTS SalidasLote
DROP TABLE IF EXISTS DetalleSolicitudes
DROP TABLE IF EXISTS Solicitudes
DROP TABLE IF EXISTS Lotes
DROP TABLE IF EXISTS Organizaciones
DROP TABLE IF EXISTS Alimentos
DROP TABLE IF EXISTS Donantes

--SEQUENCE para generar los folios de las solicitudes
CREATE SEQUENCE Seq_Folios
AS BIGINT
START WITH 1000
INCREMENT BY 1;


CREATE TABLE Donantes (
	IdDonante INT PRIMARY KEY,
	Nombre NVARCHAR(100) NOT NULL,
	Correo VARCHAR(150),
	IdentificadorFiscal VARBINARY(8000)
);

CREATE TABLE Alimentos (
	IdAlimento INT PRIMARY KEY,
	Nombre NVARCHAR(100) NOT NULL,
	Unidad VARCHAR(15) NOT NULL
);

CREATE TABLE Lotes (
	IdLote INT IDENTITY(1,1) PRIMARY KEY,
	IdDonante INT NOT NULL,
	IdAlimento INT NOT NULL,
	Recepcion DATE NOT NULL DEFAULT GETDATE(),
	Caducidad DATE NOT NULL,
	Existencia INT NOT NULL CHECK(Existencia >= 0),
	FOREIGN KEY (IdDonante) REFERENCES Donantes(IdDonante),
	FOREIGN KEY (IdAlimento) REFERENCES Alimentos(IdAlimento),
	CHECK(Caducidad >= Recepcion)
);

CREATE TABLE Organizaciones (
	IdOrganizacion INT PRIMARY KEY,
	Nombre NVARCHAR(120) NOT NULL,
	Zona NVARCHAR(80) NOT NULL,
	Documento VARBINARY(8000)  
);

CREATE TABLE Solicitudes (
	IdSolicitud INT IDENTITY(1,1) PRIMARY KEY,
	Folio BIGINT UNIQUE NOT NULL DEFAULT (NEXT VALUE FOR Seq_Folios),
	IdOrganizacion INT NOT NULL,
	Fecha DATE NOT NULL DEFAULT GETDATE(),
	Estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente' CHECK(Estado IN ('Pendiente', 'Confirmada', 'Cancelada')),
	FOREIGN KEY (IdOrganizacion) REFERENCES Organizaciones(IdOrganizacion)
);

CREATE TABLE DetalleSolicitudes (
	IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
	IdSolicitud INT NOT NULL,
	IdAlimento INT NOT NULL,
	Cantidad INT NOT NULL CHECK(Cantidad > 0),
	FOREIGN KEY (IdSolicitud) REFERENCES Solicitudes(IdSolicitud),
	FOREIGN KEY (IdAlimento) REFERENCES Alimentos(IdAlimento)
);

CREATE TABLE SalidasLote (
	IdSalida INT IDENTITY(1,1) PRIMARY KEY,
	IdDetalle INT NOT NULL,
	IdLote INT NOT NULL,
	Cantidad INT NOT NULL CHECK(Cantidad > 0),
	Fecha DATE,
	FOREIGN KEY (IdDetalle) REFERENCES DetalleSolicitudes(IdDetalle),
	FOREIGN KEY (IdLote) REFERENCES Lotes(IdLote)
);

--Cifrado
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'BancoAlimentos2026$$Fuerte'

CREATE CERTIFICATE CertificadoBanco
WITH SUBJECT = 'Certificado para cifrar datos del banco de alimentos'

CREATE SYMMETRIC KEY ClaveBanco
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoBanco


--Datos prueba
OPEN SYMMETRIC KEY ClaveBanco
DECRYPTION BY CERTIFICATE CertificadoBanco

--Datos prueba
OPEN SYMMETRIC KEY ClaveBanco
DECRYPTION BY CERTIFICATE CertificadoBanco

--Donantes
INSERT INTO Donantes(IdDonante, Nombre, Correo, IdentificadorFiscal) VALUES
(1, 'Supermercado La Central', 'donaciones@lacentral.com', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'SLC850101AB1')),
(2, 'Panaderia El Trigo', 'contacto@eltrigo.com', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'PET900202CD2')),
(3, 'Granja San Jose', 'granja@sanjose.com', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'GSJ950303EF3')),
(4, 'Lacteos del Valle', 'ventas@lacteosvalle.com', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'LDV000404GH4'));

--Alimentos
INSERT INTO Alimentos VALUES
(1, 'Arroz', 'kg'),
(2, 'Frijol', 'kg'),
(3, 'Leche', 'litro'),
(4, 'Pan de caja', 'pieza'),
(5, 'Atun enlatado', 'lata'),
(6, 'Manzana', 'kg');

--Organizaciones
INSERT INTO Organizaciones(IdOrganizacion, Nombre, Zona, Documento) VALUES
(1, 'Comedor Comunitario Norte', 'Norte', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'ACTA-2019-001')),
(2, 'Casa Hogar Esperanza', 'Sur', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'ACTA-2020-045')),
(3, 'Albergue Centro', 'Centro', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'ACTA-2018-112')),
(4, 'Asilo Buen Pastor', 'Norte', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'ACTA-2021-009'));

CLOSE SYMMETRIC KEY ClaveBanco

--Lotes
INSERT INTO Lotes(IdDonante, IdAlimento, Recepcion, Caducidad, Existencia) VALUES
(1, 1, '2025-11-10', '2027-06-30', 50),
(1, 2, '2025-12-05', '2027-02-28', 30),
(2, 4, '2026-01-15', '2026-01-20', 40),
(3, 6, '2026-10-01', '2026-11-20', 25),  
(4, 3, '2026-10-20', '2027-01-31', 60),
(1, 5, '2026-11-01', '2027-06-30', 100),
(3, 1, '2026-11-05', '2027-03-31', 80);

SELECT * FROM Donantes
SELECT * FROM Alimentos
SELECT * FROM Organizaciones
SELECT * FROM Lotes

--Auditoria

--ELIMINACION
--Los campos cifrados (IdentificadorFiscal y Documento) no se guardan en la auditoria
CREATE TABLE DonanteEliminado(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdDonante INT,
	Nombre NVARCHAR(100),
	Correo VARCHAR(150),
	FechaEliminacion DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_eli_DonanteEliminado
ON Donantes
AFTER DELETE
AS
BEGIN
	INSERT INTO DonanteEliminado(IdDonante, Nombre, Correo)
	SELECT IdDonante, Nombre, Correo
	FROM deleted
END

--******************
INSERT INTO Donantes VALUES
(5, 'Supermercado La Walmart', 'donaciones@walmart.com', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'SLC850202AB1'));

DELETE FROM Donantes 
WHERE IdDonante = 5
--*********************************

SELECT * FROM DonanteEliminado

CREATE TABLE AlimentoEliminado(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdAlimento INT,
	Nombre NVARCHAR(100),
	Unidad VARCHAR(15),
	FechaEliminacion DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_eli_AlimentoEliminado
ON Alimentos
AFTER DELETE
AS
BEGIN
	INSERT INTO AlimentoEliminado(IdAlimento, Nombre, Unidad)
	SELECT IdAlimento, Nombre, Unidad
	FROM deleted
END


--******************
INSERT INTO Alimentos VALUES
(8, 'Azucar', 'kg');

DELETE FROM Alimentos
WHERE IdAlimento = 8
--*********************************
SELECT * FROM AlimentoEliminado

CREATE TABLE OrganizacionEliminada(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdOrganizacion INT,
	Nombre NVARCHAR(120),
	Zona NVARCHAR(80),
	FechaEliminacion DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_eli_OrganizacionEliminada
ON Organizaciones
AFTER DELETE
AS
BEGIN
	INSERT INTO OrganizacionEliminada(IdOrganizacion, Nombre, Zona)
	SELECT IdOrganizacion, Nombre, Zona
	FROM deleted
END

--******************
INSERT INTO Organizaciones VALUES
(5, 'Donantes anonimos', 'Norte', ENCRYPTBYKEY(KEY_GUID('ClaveBanco'), 'ACTA-2025-109'));

DELETE FROM Organizaciones
WHERE IdOrganizacion = 5
--*********************************
SELECT * FROM OrganizacionEliminada


CREATE TABLE LoteEliminado(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdLote INT,
	IdDonante INT,
	IdAlimento INT,
	Recepcion DATE,
	Caducidad DATE,
	Existencia INT,
	FechaEliminacion DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_eli_LoteEliminado
ON Lotes
AFTER DELETE
AS
BEGIN
	INSERT INTO LoteEliminado(IdLote, IdDonante, IdAlimento, Recepcion, Caducidad, Existencia)
	SELECT IdLote, IdDonante, IdAlimento, Recepcion, Caducidad, Existencia
	FROM deleted
END

--******************
INSERT INTO Lotes VALUES
(3, 1, '2026-12-05', '2027-04-31', 70);

DELETE FROM Lotes
WHERE IdLote = 7
--*********************************

SELECT * FROM LoteEliminado

CREATE TABLE SolicitudEliminada(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdSolicitud INT,
	Folio BIGINT,
	IdOrganizacion INT,
	Fecha DATE,
	Estado VARCHAR(20),
	FechaEliminacion DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_eli_SolicitudEliminada
ON Solicitudes
AFTER DELETE
AS
BEGIN
	INSERT INTO SolicitudEliminada(IdSolicitud, Folio, IdOrganizacion, Fecha, Estado)
	SELECT IdSolicitud, Folio, IdOrganizacion, Fecha, Estado
	FROM deleted
END

--******************
INSERT INTO Solicitudes VALUES
(3, 1, '2026-12-05', '2027-04-31', 70);

DELETE FROM Solicitudes
WHERE IdSolicitud = 7
--*********************************

SELECT * FROM SolicitudEliminada

CREATE TABLE DetalleEliminado(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdDetalle INT,
	IdSolicitud INT,
	IdAlimento INT,
	Cantidad INT,
	FechaEliminacion DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_eli_DetalleEliminado
ON DetalleSolicitudes
AFTER DELETE
AS
BEGIN
	INSERT INTO DetalleEliminado(IdDetalle, IdSolicitud, IdAlimento, Cantidad)
	SELECT IdDetalle, IdSolicitud, IdAlimento, Cantidad
	FROM deleted
END


SELECT * FROM DetalleEliminado

CREATE TABLE SalidaEliminada(
	IdEliminacion INT IDENTITY(1,1) PRIMARY KEY,
	IdSalida INT,
	IdDetalle INT,
	IdLote INT,
	Cantidad INT,
	Fecha DATE,
	FechaEliminacion DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_eli_SalidaEliminada
ON SalidasLote
AFTER DELETE
AS
BEGIN
	INSERT INTO SalidaEliminada(IdSalida, IdDetalle, IdLote, Cantidad, Fecha)
	SELECT IdSalida, IdDetalle, IdLote, Cantidad, Fecha
	FROM deleted
END


SELECT * FROM SalidaEliminada

--INSERCION
CREATE TABLE DonanteAgregado(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdDonante INT,
	Nombre NVARCHAR(100),
	Correo VARCHAR(150),
	FechaInsert DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_ins_DonanteAgregado
ON Donantes
AFTER INSERT
AS
BEGIN
	INSERT INTO DonanteAgregado(IdDonante, Nombre, Correo)
	SELECT IdDonante, Nombre, Correo
	FROM inserted
END


SELECT * FROM DonanteAgregado

CREATE TABLE AlimentoAgregado(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdAlimento INT,
	Nombre NVARCHAR(100),
	Unidad VARCHAR(15),
	FechaInsert DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_ins_AlimentoAgregado
ON Alimentos
AFTER INSERT
AS
BEGIN
	INSERT INTO AlimentoAgregado(IdAlimento, Nombre, Unidad)
	SELECT IdAlimento, Nombre, Unidad
	FROM inserted
END


SELECT * FROM AlimentoAgregado

CREATE TABLE OrganizacionAgregada(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdOrganizacion INT,
	Nombre NVARCHAR(120),
	Zona NVARCHAR(80),
	FechaInsert DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_ins_OrganizacionAgregada
ON Organizaciones
AFTER INSERT
AS
BEGIN
	INSERT INTO OrganizacionAgregada(IdOrganizacion, Nombre, Zona)
	SELECT IdOrganizacion, Nombre, Zona
	FROM inserted
END


SELECT * FROM OrganizacionAgregada

CREATE TABLE LoteAgregado(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdLote INT,
	IdDonante INT,
	IdAlimento INT,
	Recepcion DATE,
	Caducidad DATE,
	Existencia INT,
	FechaInsert DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_ins_LoteAgregado
ON Lotes
AFTER INSERT
AS
BEGIN
	INSERT INTO LoteAgregado(IdLote, IdDonante, IdAlimento, Recepcion, Caducidad, Existencia)
	SELECT IdLote, IdDonante, IdAlimento, Recepcion, Caducidad, Existencia
	FROM inserted
END


SELECT * FROM LoteAgregado

CREATE TABLE SolicitudAgregada(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdSolicitud INT,
	Folio BIGINT,
	IdOrganizacion INT,
	Fecha DATE,
	Estado VARCHAR(20),
	FechaInsert DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_ins_SolicitudAgregada
ON Solicitudes
AFTER INSERT
AS
BEGIN
	INSERT INTO SolicitudAgregada(IdSolicitud, Folio, IdOrganizacion, Fecha, Estado)
	SELECT IdSolicitud, Folio, IdOrganizacion, Fecha, Estado
	FROM inserted
END


SELECT * FROM SolicitudAgregada

CREATE TABLE DetalleAgregado(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdDetalle INT,
	IdSolicitud INT,
	IdAlimento INT,
	Cantidad INT,
	FechaInsert DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_ins_DetalleAgregado
ON DetalleSolicitudes
AFTER INSERT
AS
BEGIN
	INSERT INTO DetalleAgregado(IdDetalle, IdSolicitud, IdAlimento, Cantidad)
	SELECT IdDetalle, IdSolicitud, IdAlimento, Cantidad
	FROM inserted
END


SELECT * FROM DetalleAgregado

CREATE TABLE SalidaAgregada(
	IdInsert INT IDENTITY(1,1) PRIMARY KEY,
	IdSalida INT,
	IdDetalle INT,
	IdLote INT,
	Cantidad INT,
	Fecha DATETIME2,
	FechaInsert DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_ins_SalidaAgregada
ON SalidasLote
AFTER INSERT
AS
BEGIN
	INSERT INTO SalidaAgregada(IdSalida, IdDetalle, IdLote, Cantidad, Fecha)
	SELECT IdSalida, IdDetalle, IdLote, Cantidad, Fecha
	FROM inserted
END


SELECT * FROM SalidaAgregada

--ACTUALIZACION 
CREATE TABLE DonanteActualizado(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdDonante INT,
	Nombre_Ant NVARCHAR(100),
	Correo_Ant VARCHAR(150),
	Nombre_Nuevo NVARCHAR(100),
	Correo_Nuevo VARCHAR(150),
	FechaAct DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_upd_DonanteActualizado
ON Donantes
AFTER UPDATE
AS
BEGIN
	INSERT INTO DonanteActualizado(IdDonante, Nombre_Ant, Correo_Ant, Nombre_Nuevo, Correo_Nuevo)
	SELECT inserted.IdDonante, deleted.Nombre, deleted.Correo, inserted.Nombre, inserted.Correo
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdDonante = deleted.IdDonante
END


SELECT * FROM DonanteActualizado

CREATE TABLE AlimentoActualizado(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdAlimento INT,
	Nombre_Ant NVARCHAR(100),
	Unidad_Ant VARCHAR(15),
	Nombre_Nuevo NVARCHAR(100),
	Unidad_Nueva VARCHAR(15),
	FechaAct DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_upd_AlimentoActualizado
ON Alimentos
AFTER UPDATE
AS
BEGIN
	INSERT INTO AlimentoActualizado(IdAlimento, Nombre_Ant, Unidad_Ant, Nombre_Nuevo, Unidad_Nueva)
	SELECT inserted.IdAlimento, deleted.Nombre, deleted.Unidad, inserted.Nombre, inserted.Unidad
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdAlimento = deleted.IdAlimento
END


SELECT * FROM AlimentoActualizado

CREATE TABLE OrganizacionActualizada(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdOrganizacion INT,
	Nombre_Ant NVARCHAR(120),
	Zona_Ant NVARCHAR(80),
	Nombre_Nuevo NVARCHAR(120),
	Zona_Nueva NVARCHAR(80),
	FechaAct DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_upd_OrganizacionActualizada
ON Organizaciones
AFTER UPDATE
AS
BEGIN
	INSERT INTO OrganizacionActualizada(IdOrganizacion, Nombre_Ant, Zona_Ant, Nombre_Nuevo, Zona_Nueva)
	SELECT inserted.IdOrganizacion, deleted.Nombre, deleted.Zona, inserted.Nombre, inserted.Zona
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdOrganizacion = deleted.IdOrganizacion
END


SELECT * FROM OrganizacionActualizada

CREATE TABLE LoteActualizado(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdLote INT,
	IdDonante_Ant INT,
	IdAlimento_Ant INT,
	Caducidad_Ant DATE,
	Existencia_Ant INT,
	IdDonante_Nuevo INT,
	IdAlimento_Nuevo INT,
	Caducidad_Nueva DATE,
	Existencia_Nueva INT,
	FechaAct DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_upd_LoteActualizado
ON Lotes
AFTER UPDATE
AS
BEGIN
	INSERT INTO LoteActualizado(IdLote, IdDonante_Ant, IdAlimento_Ant, Caducidad_Ant, Existencia_Ant, IdDonante_Nuevo, IdAlimento_Nuevo, Caducidad_Nueva, Existencia_Nueva)
	SELECT inserted.IdLote, deleted.IdDonante, deleted.IdAlimento, deleted.Caducidad, deleted.Existencia, inserted.IdDonante, inserted.IdAlimento, inserted.Caducidad, inserted.Existencia
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdLote = deleted.IdLote
END


SELECT * FROM LoteActualizado

CREATE TABLE SolicitudActualizada(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdSolicitud INT,
	Folio BIGINT,
	IdOrganizacion_Ant INT,
	Estado_Ant VARCHAR(20),
	IdOrganizacion_Nuevo INT,
	Estado_Nuevo VARCHAR(20),
	FechaAct DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_upd_SolicitudActualizada
ON Solicitudes
AFTER UPDATE
AS
BEGIN
	INSERT INTO SolicitudActualizada(IdSolicitud, Folio, IdOrganizacion_Ant, Estado_Ant, IdOrganizacion_Nuevo, Estado_Nuevo)
	SELECT inserted.IdSolicitud, inserted.Folio, deleted.IdOrganizacion, deleted.Estado, inserted.IdOrganizacion, inserted.Estado
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdSolicitud = deleted.IdSolicitud
END


SELECT * FROM SolicitudActualizada

CREATE TABLE DetalleActualizado(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdDetalle INT,
	IdSolicitud INT,
	IdAlimento_Ant INT,
	Cantidad_Ant INT,
	IdAlimento_Nuevo INT,
	Cantidad_Nueva INT,
	FechaAct DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_upd_DetalleActualizado
ON DetalleSolicitudes
AFTER UPDATE
AS
BEGIN
	INSERT INTO DetalleActualizado(IdDetalle, IdSolicitud, IdAlimento_Ant, Cantidad_Ant, IdAlimento_Nuevo, Cantidad_Nueva)
	SELECT inserted.IdDetalle, inserted.IdSolicitud, deleted.IdAlimento, deleted.Cantidad, inserted.IdAlimento, inserted.Cantidad
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdDetalle = deleted.IdDetalle
END


SELECT * FROM DetalleActualizado

CREATE TABLE SalidaActualizada(
	IdAct INT IDENTITY(1,1) PRIMARY KEY,
	IdSalida INT,
	IdDetalle_Ant INT,
	IdLote_Ant INT,
	Cantidad_Ant INT,
	IdDetalle_Nuevo INT,
	IdLote_Nuevo INT,
	Cantidad_Nueva INT,
	FechaAct DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_upd_SalidaActualizada
ON SalidasLote
AFTER UPDATE
AS
BEGIN
	INSERT INTO SalidaActualizada(IdSalida, IdDetalle_Ant, IdLote_Ant, Cantidad_Ant, IdDetalle_Nuevo, IdLote_Nuevo, Cantidad_Nueva)
	SELECT inserted.IdSalida, deleted.IdDetalle, deleted.IdLote, deleted.Cantidad, inserted.IdDetalle, inserted.IdLote, inserted.Cantidad
	FROM inserted
	INNER JOIN deleted
	ON inserted.IdSalida = deleted.IdSalida
END


SELECT * FROM SalidaActualizada


--VALIDAR SALIDAS
CREATE TRIGGER trg_val_SalidasLote
ON SalidasLote
AFTER INSERT
AS
BEGIN
	--El lote debe estar vigente en la fecha de salida
	IF EXISTS (
		SELECT * FROM inserted
		INNER JOIN Lotes
		ON inserted.IdLote = Lotes.IdLote
		WHERE Lotes.Caducidad < CAST(inserted.Fecha AS DATE)
	)
	BEGIN
		ROLLBACK TRANSACTION;
		THROW 50002, 'El lote esta caducado y no es elegible', 1;
	END
END

--Tabla para registrar los errores que capturan los procedimientos
CREATE TABLE Errores (
	IdError INT IDENTITY(1,1) PRIMARY KEY,
	Procedimiento NVARCHAR(100),
	NumeroError INT,
	Mensaje NVARCHAR(500),
	Fecha DATETIME DEFAULT GETDATE()
);


--Recibir un lote (Almacenista)
CREATE PROCEDURE RecibirLote
	@IdDonante INT,
	@IdAlimento INT,
	@Caducidad DATE,
	@Existencia INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
			IF @Existencia <= 0
				THROW 50003, 'La existencia debe ser un entero positivo', 1;

			INSERT INTO Lotes(IdDonante, IdAlimento, Recepcion, Caducidad, Existencia)
			VALUES (@IdDonante, @IdAlimento, GETDATE(), @Caducidad, @Existencia)
		COMMIT TRANSACTION
		PRINT 'Lote recibido'
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END

--Registrar una solicitud con su primer renglon (Representante)
--El folio se genera solo con la SEQUENCE
CREATE PROCEDURE RegistrarSolicitud
	@IdOrganizacion INT,
	@IdAlimento INT,
	@Cantidad INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			
			INSERT INTO Solicitudes(Folio, IdOrganizacion, Fecha, Estado)
			VALUES (NEXT VALUE FOR Seq_Folios, @IdOrganizacion, GETDATE(), 'Pendiente')

			
			INSERT INTO DetalleSolicitudes(IdSolicitud, IdAlimento, Cantidad)
			VALUES ((SELECT MAX(IdSolicitud) FROM Solicitudes WHERE IdOrganizacion = @IdOrganizacion), @IdAlimento, @Cantidad)
		COMMIT TRANSACTION
		PRINT 'Solicitud registrada'

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

			PRINT 'Ocurrio un error al registrar la solicitud'
			INSERT INTO Errores(Procedimiento, NumeroError, Mensaje)
			VALUES ('RegistrarSolicitud', ERROR_NUMBER(), ERROR_MESSAGE());
	END CATCH
END

--SURTIR POR CADUCIDAD
CREATE PROCEDURE LotePorCaducidad
	@IdAlimento INT
AS
BEGIN
	BEGIN TRANSACTION
		SELECT TOP 1 Lotes.IdLote, Alimentos.Nombre AS Alimento, Lotes.Caducidad, Lotes.Existencia, Donantes.Nombre AS Donante
		FROM Lotes
		INNER JOIN Alimentos
		ON Lotes.IdAlimento = Alimentos.IdAlimento
		INNER JOIN Donantes
		ON Lotes.IdDonante = Donantes.IdDonante
		WHERE Lotes.IdAlimento = @IdAlimento
			AND Lotes.Existencia > 0
			AND Lotes.Caducidad >= GETDATE()
		ORDER BY Lotes.Caducidad, Lotes.IdLote
	COMMIT TRANSACTION
END

EXEC LotePorCaducidad @IdAlimento = 7

--Consultar el origen de una salida
CREATE PROCEDURE ConsultarOrigenSalida
	@IdSalida INT
AS
BEGIN
	BEGIN TRANSACTION
		SELECT SalidasLote.IdSalida, SalidasLote.Fecha AS FechaSalida, SalidasLote.Cantidad,
			Alimentos.Nombre AS Alimento, Alimentos.Unidad,
			Lotes.IdLote, Lotes.Recepcion, Lotes.Caducidad,
			Donantes.Nombre AS Donante, Donantes.Correo,
			Solicitudes.Folio, Organizaciones.Nombre AS Organizacion
		FROM SalidasLote
		INNER JOIN Lotes
		ON SalidasLote.IdLote = Lotes.IdLote
		INNER JOIN Donantes
		ON Lotes.IdDonante = Donantes.IdDonante
		INNER JOIN Alimentos
		ON Lotes.IdAlimento = Alimentos.IdAlimento
		INNER JOIN DetalleSolicitudes
		ON SalidasLote.IdDetalle = DetalleSolicitudes.IdDetalle
		INNER JOIN Solicitudes
		ON DetalleSolicitudes.IdSolicitud = Solicitudes.IdSolicitud
		INNER JOIN Organizaciones
		ON Solicitudes.IdOrganizacion = Organizaciones.IdOrganizacion
		WHERE SalidasLote.IdSalida = @IdSalida
	COMMIT TRANSACTION
END

EXEC ConsultarOrigenSalida @IdSalida = 1


--************************************************************
--PIVOT
--************************************************************

SELECT Zona,
	ISNULL([Octubre], 0) AS Octubre,
	ISNULL([Noviembre], 0) AS Noviembre,
	ISNULL([Diciembre], 0) AS Diciembre
FROM (
	SELECT Organizaciones.Zona, Solicitudes.IdSolicitud,
		CASE MONTH(Solicitudes.Fecha)
			WHEN 10 THEN 'Octubre'
			WHEN 11 THEN 'Noviembre'
			WHEN 12 THEN 'Diciembre'
		END AS Mes
	FROM Solicitudes
	INNER JOIN Organizaciones
	ON Solicitudes.IdOrganizacion = Organizaciones.IdOrganizacion
	WHERE Solicitudes.Estado = 'Confirmada'
) AS Origen
PIVOT (
	COUNT(IdSolicitud)
	FOR Mes IN ([Octubre], [Noviembre], [Diciembre])
) AS PivotZona

--************************************
--Tecnicas avanzadas
--**********************************

--Clasificar lotes por vigencia con CASE
SELECT Lotes.IdLote, Alimentos.Nombre, Lotes.Caducidad, Lotes.Existencia,
CASE
	WHEN Lotes.Caducidad < CAST(GETDATE() AS DATE) THEN 'Caducado'
	WHEN Lotes.Caducidad <= DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) THEN 'Por caducar'
	ELSE 'Vigente'
END AS Vigencia
FROM Lotes
INNER JOIN Alimentos
ON Lotes.IdAlimento = Alimentos.IdAlimento
ORDER BY Lotes.Caducidad

--Union de salidas, lotes y donantes
SELECT SalidasLote.IdSalida, SalidasLote.Fecha, SalidasLote.Cantidad,
	Lotes.IdLote, Lotes.Caducidad,
	Alimentos.Nombre AS Alimento,
	Donantes.Nombre AS Donante
FROM SalidasLote
INNER JOIN Lotes
ON SalidasLote.IdLote = Lotes.IdLote
INNER JOIN Donantes
ON Lotes.IdDonante = Donantes.IdDonante
INNER JOIN Alimentos
ON Lotes.IdAlimento = Alimentos.IdAlimento
ORDER BY SalidasLote.IdSalida

--DENSE_RANK: ordenar organizaciones por solicitudes surtidas
--(las organizaciones con el mismo numero de solicitudes comparten posicion)
SELECT Organizaciones.Nombre, Organizaciones.Zona,
	COUNT(Solicitudes.IdSolicitud) AS SolicitudesSurtidas,
	DENSE_RANK() OVER (ORDER BY COUNT(Solicitudes.IdSolicitud) DESC) AS Posicion
FROM Organizaciones
LEFT JOIN Solicitudes
ON Organizaciones.IdOrganizacion = Solicitudes.IdOrganizacion AND Solicitudes.Estado = 'Confirmada'
GROUP BY Organizaciones.Nombre, Organizaciones.Zona

