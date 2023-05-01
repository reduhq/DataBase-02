/* 5. En la BD Northwind, agregar una columna en la tabla Order Detail llamada Estado, por
defecto al ingresar un detalle de orden su valor será Aceptado, en caso de retirar dicho
producto de la orden no se deberá eliminar sino que el estado será Cancelado y deberá
notificar vía alerta del sistema el nombre de usuario que realiza la operación, fecha y
hora, producto y la cantidad a comprar, administrarlo vía procedimiento almacenado. */

use Northwind
go 

-- agregando la columna estado
alter table [Order Details]
add Estado varchar(30) default 'aceptado'
check(Estado = 'aceptado' or Estado = 'cancelado')

update [Order Details] set Estado = 'aceptado'

-- creando procedimiento almacenado para cancelar el producto y mostrando alerta del sistema
alter procedure RetirarProducto 
@order_id int,
@product_id int
as 
begin
	-- actualizando el estado a cancelado
	update [Order Details] set Estado = 'cancelado'
	where OrderID = @order_id and ProductID = @product_id

	-- extrayendo el nombre del usuario que esta haciendo la compra
	declare @username varchar(100)
	select @username = c.ContactName
	from [Order Details] od inner join Orders o on od.OrderID = o.OrderID
	inner join Customers c on c.CustomerID = o.CustomerID
	where od.OrderID = @order_id and od.ProductID = @product_id

	-- extrayendo el nombre del producto
	declare @product_name varchar(100)
	select @product_name = p.ProductName
	from Products p
	where p.ProductID = @product_id

	-- extrayendo la cantidad del producto cancelado
	declare @cantidad smallint
	select @cantidad = od.Quantity
	from [Order Details] od
	where od.OrderID = @order_id and od.ProductID = @product_id


	-- notificando via alerta del sistema
	declare @msg varchar(250)
    SET @msg = CONCAT('El usuario ', @username, ' ha cancelado la compra del producto ', @product_name, ' (cantidad: ', @cantidad, ') en la orden numero ', @order_id, ' | dia y hora: ', CONVERT(VARCHAR(20), GETDATE(), 120), '.');

	RAISERROR(@msg, 0, 1) WITH NOWAIT;
end

-- ejecutando el procedimiento almacenado
exec RetirarProducto 10248, 42

select * from [Order Details]


/* Notificar una alerta al sistema cuando no se tengan permisos suficientes de acceso a los
objetos de la base de datos Northwind. */

-- creando un usuario y un login sin permiso a la tabla [Order Details] de la bd Northwind

-- creando login 
create login reduhq with password = '12345678'

-- creando usuario
use Northwind
go 
sp_adduser reduhq, contador

-- revocando el acceso a la tabla Order Details
revoke select on [Order Details] to contador
