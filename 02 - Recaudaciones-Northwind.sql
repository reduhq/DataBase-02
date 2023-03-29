-- query 
select 
	distinct c.Region,
	round(sum(od.UnitPrice * od.Quantity), 2) as subtotal,
	round(sum(od.UnitPrice * od.Quantity * od.Discount), 2) as descuento,
	round(sum((od.UnitPrice * od.Quantity) * (1 - od.Discount)), 2) as total,
	count(distinct od.OrderID) as cantidad_ordenes
	
from Orders o inner join [Order Details] od on o.OrderID = od.OrderID
	inner join Customers c on c.CustomerID = o.CustomerID
where c.Region != ''
group by c.Region


-- creando un procedimiento para que devuelva una tabla
create procedure recaudaciones_region_northwind
as
begin 
	SET NOCOUNT ON;
	select distinct c.Region,
		cast(round(sum(od.UnitPrice * od.Quantity), 2) as nvarchar(25)) as subtotal,
		cast(round(sum(od.UnitPrice * od.Quantity * od.Discount), 2) as nvarchar(25)) as descuento,
		cast(round(sum((od.UnitPrice * od.Quantity) * (1 - od.Discount)), 2) as nvarchar(25)) as total,
		count(distinct od.OrderID) as cantidad_ordenes
	from Northwind.dbo.Orders o inner join Northwind.dbo.[Order Details] od on o.OrderID = od.OrderID
		inner join Northwind.dbo.Customers c on c.CustomerID = o.CustomerID
	where c.Region != ''
	group by c.Region
end


---------------------------------------------------------------------------------------------
-- creando un procedimiento almacenado para enviar un email de las recaudaciones por region 
create procedure enviar_email_recaudaciones_northwind
as
begin
	declare @table_html varchar(max)
	set @table_html =
	N'<html>'+
	N'<head>'+
	N'<style type="text/css">table{border: solid 1px;border-collapse:collapse;}td{text-align:"center";}.izq{text-align:left}th{text-align:"center";  background:"#808080"; color:"#ffffff";}</style>' +
	N'</head>'+
	N'<body>'+
	N'<h3><center><u>REPORTE DE RECAUDACIONES - NORTHWIND<u></center></h3>'+
	N'<table border =''1'' align = "center">' +
	N'<tr><th>Region</th>'+
	N'<th>subtotal</th>'+
	N'<th>descuento</th>'+
	N'<th>total</th>'+
	N'<th>cantidad_ordenes</th>'+
	cast (
		(
			select td = c.Region,
				td = cast(round(sum(od.UnitPrice * od.Quantity), 2) as nvarchar(25)),
				td = cast(round(sum(od.UnitPrice * od.Quantity * od.Discount), 2) as nvarchar(25)),
				td = cast(round(sum((od.UnitPrice * od.Quantity) * (1 - od.Discount)), 2) as nvarchar(25)),
				td = count(distinct od.OrderID)
			from Orders o inner join [Order Details] od on o.OrderID = od.OrderID
				inner join Customers c on c.CustomerID = o.CustomerID
			where c.Region != ''
			group by c.Region

			for xml raw('tr'), elements
		)
		as nvarchar (max)
	) + N'</table>'+
	N'<body>'+
	N'<html>';

	-- procedimiento para envío de correo:
	exec msdb.dbo.sp_send_dbmail
		@profile_name = 'reduhq - mail_profile',
		@recipients = 'reyeduardohalsallquintero8@outlook.com',
		@subject = 'Reporte Recaudacion Northwind',
		@body= @table_html,
		@body_format = 'html',
		@query = 'execute Northwind.dbo.recaudaciones_region_northwind',
		@attach_query_result_as_file = 1,
		@query_attachment_filename = 'northwind_regions.txt'
end

-- ejecutando el procedimiento almacenado para enviar un email
execute enviar_email_recaudaciones_northwind