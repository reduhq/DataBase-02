

-- creando la base de datos BD_Repositorio y la tabla Recaudacion
create database BD_Repositorio 
go
use BD_Repositorio
go

create table Recaudacion( 
	id int primary key identity(1,1),
	fecha datetime,
	bd_name varchar(50),
	anio smallint,
	mes smallint,
	monto money,
	descuento money,
	monto_total money,
	cantidad_ordenes int,
	cantidad_descuento int,
	cantidad_clientes int
)


-- Insertando el seguimiento de cuanto recaudamos por mes a la base de datos BD_Repositorio dentro de la tabla Recaudacion
declare @tmp_current_date datetime = DATEADD(year, -17, GETDATE()) --2006
insert into BD_Repositorio.dbo.Recaudacion
select 
	 @tmp_current_date as fecha,
	'Adventure' as bd_name,
	(select distinct year(ModifiedDate) from Sales.SalesOrderDetail where year(ModifiedDate) = year(@tmp_current_date) and MONTH(ModifiedDate) = MONTH(@tmp_current_date)) as anio,
	(select distinct month(ModifiedDate) from Sales.SalesOrderDetail where year(ModifiedDate) = year(@tmp_current_date) and MONTH(ModifiedDate) = MONTH(@tmp_current_date)) as mes,
	sum(UnitPrice*OrderQty) as monto,
	sum((UnitPrice*OrderQty)*UnitPriceDiscount) as descuento,
	sum(LineTotal) as monto_total,
	count(*) as cantidad_ordenes,
	(select count(UnitPriceDiscount) from Sales.SalesOrderDetail where UnitPriceDiscount != 0 and year(ModifiedDate) = year(@tmp_current_date) and MONTH(ModifiedDate) = MONTH(@tmp_current_date)) as cantidad_descuento,
	count(distinct c.CustomerID) as cantidad_clientes
from Sales.SalesOrderDetail sod inner join Sales.SalesOrderHeader soh on sod.SalesOrderID = soh.SalesOrderID
	inner join Sales.Customer c on soh.CustomerID = c.CustomerID
where year(sod.ModifiedDate) = year(@tmp_current_date) 
	  and 
	  MONTH(sod.ModifiedDate) = MONTH(@tmp_current_date)

-- comprtobando que todo se inserto correcatmente
select * from BD_Repositorio.dbo.Recaudacion

delete from BD_Repositorio.dbo.Recaudacion