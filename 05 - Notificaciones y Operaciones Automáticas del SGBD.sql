
use Northwind 
go

/*
En la BD Northwind, realizar un procedimiento almacenado para generar de forma
automática las credenciales de acceso a un nuevo usuario del Sistema de Información, a
la vez notificar al nuevo usuario dichas credenciales vía correo electrónico,

para ello se deberá crear una tabla Usuario (
IdUsuario int,
nombreUsuario varchar(60),
nombres varchar(60),
apellidos varchar(60),
correo varchar(60),
clave varchar(60),
rol varchar(60) (Administrador, Supervisor, Ventas, Contador), 
Estado (Habilitado / Deshabilitado)).
*/

create table Usuario(
	id_usuario int primary key identity(1,1),
	username varchar(60),
	nombre varchar(60),
	apellidos varchar(60),
	correo varchar(60),
	password varbinary(64),
	rol varchar(60) check(rol = 'administrador'or rol = 'supervisor'or rol = 'ventas' or rol = 'contador'),
	estado varchar(60) check(estado = 'habilitado' or estado = 'deshabilitado')
)
select * from Usuario

/*
El procedimiento deberá:
• Recibir los parámetros de nombres, apellidos, correo electrónico y rol del
Sistema.
• La clave no será ingresada como parámetro, sino que deberá ser generada de
forma automática y encriptada en la tabla usuario.
• Al ejecutarse el procedimiento deberá enviar dichas credenciales al usuario
incluyendo la contraseña, utilizando el servicio de correo electrónico de SQL
Server. 
*/

-- creando un procedimiento para crear el password
create function GenerarPassword(@uid uniqueidentifier)
returns varchar(10)
as
begin
	return right(@uid, 10)
end

-- creando procedimiento para hashear el password
create procedure HashedPassword
as
begin
	declare @tbl table([password] varchar(10), hashed_password varbinary(64))
	declare @password as varchar(10) 

	select @password = dbo.GenerarPassword(newid())

	-- hasheando la password
	declare @hashed_password as varbinary(64)
	SET @hashed_password = HASHBYTES('SHA1', @password);
	insert into @tbl values (@password, @hashed_password)

	select * from @tbl
end


-- creando procedimiento para crear el nuevo usuario
create procedure CreateNewUser
@nombres varchar(60), 
@apellidos varchar(60),
@email varchar(60),
@rol varchar(60)
as
begin 
	-- extrayendo la password normal y password hasheada
	declare @tbl table([password] varchar(10), hashed_password varbinary(64))
	insert into @tbl exec HashedPassword

	-- creando usuario con password hasheada
	declare @username varchar(10) = concat(left(@nombres, 3), left(@apellidos, 3))
	insert into Usuario 
	values (
		lower(@username),
		@nombres,
		@apellidos,
		@email,
		(select hashed_password from @tbl),
		@rol,
		'habilitado'
	)

	-- enviando correo electronico para notificar que el usuario ha sido creado
	declare @table_html varchar(max)
	set @table_html =
	N'<html>'+
	N'<body>'+
	N'<h3><center><u>Nuevo Usuario Creado Exitosamente<u></center></h3>'+
	N'<p>Nombre de Usuario: @'+ lower(@username) + '</p>'+
	N'<p>Password: '+ (select [password] from @tbl) + '</p>' +
	N'<body>'+
	N'<html>';
	exec msdb.dbo.sp_send_dbmail @profile_name = 'reduhq - mail_profile',
								@recipients = @email,
								@subject = 'Nueva Cuenta Creada',
								@body= @table_html,
								@body_format = 'html'
end


-- ejecutando el procedimiento almacenado
exec CreateNewUser @nombres = 'Rey Eduardo',
				@apellidos = 'Halsall Quintero',
				@email = 'reyeduardohalsallquintero8@outlook.com',
				@rol = 'contador'

---------------------------------------------------------------------------------------------------
/* Tomando de referencia el ejercicio anterior, realizar un procedimiento almacenado que
valide el ingreso al Sistema de Información recibiendo como parámetro el nombre de
usuario y contraseña, validar el acceso comparando los datos proporcionados con los
registros de la tabla usuario: nombreUsuario, clave (encriptada) y estado en habilitado,-------------
 - en caso de acceso exitoso retornar el IdUsuario, nombre completo y rol en el sistema,
 - en caso contrario retornar “Acceso denegado” y notificar al DBA utilizando el servicio de
correo electrónico enviando el nombreUsuario, la fecha y hora de acceso denegado */

-- validar ingreso al sistema (nombre de usuario y password)

create procedure ValidarAcceso
@username varchar(10),
@password varchar(50)
as
begin
	-- tabla usuario 
	declare @usuario table(
		id_usuario int,
		username varchar(60),
		nombre varchar(60),
		apellidos varchar(60),
		correo varchar(60),
		password varbinary(64),
		rol varchar(60) check(rol = 'administrador'or rol = 'supervisor'or rol = 'ventas' or rol = 'contador'),
		estado varchar(60) check(estado = 'habilitado' or estado = 'deshabilitado')
	)
	-- buscando si existe el username
	insert into @usuario select top 1 * from Usuario where username = @username
	if (select count(*) from @usuario) = 0 --si no encontro ningun usuario con ese username:
	begin
		print 'Acceso denegado'
		exec AccesoDenegado @username
		return
	end
	-- si el password es valido
	if ( select dbo.ValidarPassword(@password, (select password from @usuario)) ) = 1
	begin
		select id_usuario, concat(nombre, apellidos) NombreCompleto, rol from @usuario
	end
	else -- si el password no es valido
	begin
		print 'Acceso denegado'
		exec AccesoDenegado @username
	end
end


alter procedure AccesoDenegado
@username varchar(10)
as -- notificando al DBA por correo electronico
begin
	
	-- enviando correo electronico para notificar al DBA
	declare @table_html varchar(max)
	set @table_html =
	N'<html>'+
	N'<body>'+
	N'<h3><center><u>Acceso Denegado Al Entrar a una Cuenta<u></center></h3>'+
	N'<p>Nombre de Usuario: @'+ lower(@username) + '</p>'+
	N'<p>Fecha y Hora: '+ (select convert(varchar, getdate())) + '</p>' +
	N'<body>'+
	N'<html>';
	exec msdb.dbo.sp_send_dbmail @profile_name = 'reduhq - mail_profile',
								@recipients = 'reyeduardohalsallquintero8@outlook.com',
								@subject = 'Acceso Denegado Al Entrar a una Cuenta',
								@body= @table_html,
								@body_format = 'html'

end

-- creando un procedimiento almacenado para comparar la password ingresada con la de la bd
alter function ValidarPassword(@password varchar(100), @hashed_password_db varbinary(64))
returns smallint
as 
begin
	declare @hashed_password as varbinary(64)
	SET @hashed_password = HASHBYTES('SHA1', @password);

	if @hashed_password = @hashed_password_db
		return 1
	return 0
end

-- validando el acceso
exec ValidarAcceso 'reyhal', 'E203657216'

----------------------------------------------------------------------------------