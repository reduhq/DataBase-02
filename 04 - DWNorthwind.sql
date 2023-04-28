
-- 1 Creacion del DataWarehouse de la BD Northwind
Create database DWNorthwind
go 
use DWNorthwind

-- conformacion de Dimensiones 
create view DimEmpresa
as
	Select a.ShipperID, 
			a.CompanyName [Nombre de Empresa Envio]
	from Northwind.dbo.Shippers a



create view DimCliente
as 
	select c.CustomerID,
			c.CompanyName [Nombre Empresa],
			c.ContactName [Nombre del Contacto],
			c.City Ciudad,
			c.Country Pais
	from Northwind.dbo.Customers c

create view DimEmpleado
as
	select e.EmployeeID,
			e.FirstName Nombre,
			e.LastName Apellido,
			e.BirthDate [Fecha de Nacimiento],
			e.City ciudad,
			e.Country Pais,
			R.RegionDescription Region
	from Northwind.dbo.Employees e
	inner join ( -- se agrego la region de la consulta de la dimension del empleado
		select distinct et.EmployeeID, r.RegionDescription from Northwind.dbo.EmployeeTerritories et
		inner join Northwind.dbo.Territories t
		on et.TerritoryID = t.TerritoryID
		inner join Northwind.dbo.Region r
		on r.RegionID = t.RegionID 
	) R
	on R.EmployeeID = e.EmployeeID


-- creacion de la dimension del tiempo

create view DimFecha
as
	select distinct o.orderdate DateId,
					YEAR(o.OrderDate) Anio,
					MONTH(o.OrderDate) Mes,
					DATEPART(qq, o.OrderDate) Trimestre,
					DATENAME(month, o.OrderDate) [Nombre Mes],
					DATENAME(WEEKDAY, o.OrderDate) [Nombre Dia]
	from Northwind.dbo.Orders o

-----------------------------------------------------
go
-- Creacion de la tabla de hechos utilizando la tabla Orders

-- valores de medida de la tabla de hechos
create view HechosOrdenes
as
	select
			-- Llaves Foraneas de las tablas dimensionales
			o.CustomerID,
			o.EmployeeID,
			o.ShipVia,
			o.OrderDate FechaId,
			-- Valores de Medida de la tabla de Hechos
			count(distinct o.OrderID) [Cantidad de Ordenes],
			count(o.OrderID) [Cantidad de Productos],
			round( sum((od.UnitPrice * od.Quantity)), 2) Monto,
			round( sum((od.UnitPrice * od.Quantity * od.Discount)), 2) Descuento,
			round( sum(((od.UnitPrice * od.Quantity)* (1 - od.Discount))), 2) Subtotal,
			o.Freight [Cargo por Envio],
			round( sum(((od.UnitPrice * od.Quantity)* (1 - od.Discount))), 2) + o.Freight [Total (Subtotal + Envio)]
	from Northwind.dbo.Orders o
	inner join Northwind.dbo.[Order Details] od
	on od.OrderID = o.OrderID
	group by o.Freight, o.EmployeeID, o.ShipVia, o.OrderDate, o.CustomerID