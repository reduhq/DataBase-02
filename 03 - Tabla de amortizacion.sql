
-- creando la base de datos BANCOUNI

create database BANCOUNI
go 
use BANCOUNI
go 


-- creando un procedimiento almacenado el cual genera una tabla de amortizacion de pagos
-- con cuota fija para un prestamo bancario
alter procedure tabla_prestamo(
@monto_prestamo money,
@interes float,
@plazo_meses smallint,
@correo_electronico varchar(100)
)
as
begin 
	declare @tbl as table(meses int primary key, fecha_pago varchar(15), principal money, cuota_fija money, interes float, aporte_capital money, saldo_final money)
	declare @contador int
	declare @fecha date
	declare @cuota_fija money

	set @contador = 0
	set @fecha = getdate()

	-- sacando la cuota fija
	set @interes = @interes/12
	set @interes = @interes/100

	set @cuota_fija = (@monto_prestamo * @interes) / (1 - (power((1+@interes), -@plazo_meses))  )

	-----------------------------------------------------------------------
	WHILE (@contador) < @plazo_meses  
	BEGIN
		set @contador = @contador+1

		-- HACIENDO LOS CALCULOS
		-- calculando del saldo principal
		declare @saldo_principal money
		set @saldo_principal = @monto_prestamo

		-- sacando el interes
		declare @saldo_interes money
		set @saldo_interes = @monto_prestamo * @interes

		-- sacando el aporte al capital
		declare @aporte_capital money
		set @aporte_capital = @cuota_fija - @saldo_interes

		-- sacando el saldo final
		set @monto_prestamo = @monto_prestamo - @aporte_capital

		insert @tbl values (@contador, @fecha, round(@saldo_principal, 2), round(@cuota_fija, 2), round(@saldo_interes, 2), round(@aporte_capital, 2), round(@monto_prestamo, 2))

		-- CALCULANDO LA FECHA DE PAGO DESPUES DE 30 DIAS
		set @fecha =  DATEADD(DAY, 30, @fecha)
	END  
	select * from @tbl

	-- enviando el correo
	declare @table_html varchar(max)
	set @table_html =
	N'<html>'+
	N'<head>'+
	N'<style type="text/css">table{border: solid 1px;border-collapse:collapse;}td{text-align:"center";}.izq{text-align:left}th{text-align:"center";  background:"#808080"; color:"#ffffff";}</style>' +
	N'</head>'+
	N'<body>'+
	N'<h3><center><u>TABLA DE AMORTIZACION<u></center></h3>'+
	N'<table border =''1'' align = "center">' +
	N'<tr><th>    meses    </th>'+
	N'<th>    fecha de pago    </th>'+
	N'<th>    saldo principal    </th>'+
	N'<th>    cuota fija    </th>'+
	N'<th>    interes    </th>'+
	N'<th>    aporte al capital    </th>'+
	N'<th>    saldo final    </th>'+
	cast (
		(
			select td = tb.meses,
				td = tb.fecha_pago,
				td = cast(tb.principal as varchar),
				td = cast(cuota_fija as varchar),
				td = cast(interes as varchar),
				td = cast(aporte_capital as varchar), 
				td = cast(saldo_final as varchar)
			from @tbl as tb

			for xml raw('tr'), elements
		)
		as nvarchar (max)
	) + N'</table>'+
	N'<body>'+
	N'<html>';


	exec msdb.dbo.sp_send_dbmail
		@profile_name = 'reduhq - mail_profile',
		@recipients = @correo_electronico,
		@subject = 'Reporte - Tabla de amortizacion de pagos con cuota fija para un prestamo bancario',
		@body= @table_html,
		@body_format = 'HTML'
		--@query = 'select * from @tbl'
		--@attach_query_result_as_file = 1,
		--@query_attachment_filename = 'amortizacion.txt'
end


exec tabla_prestamo 1400, 15, 12, 'reyeduardohalsallquintero8@outlook.com'
exec tabla_prestamo 2500, 10, 5, 'reyeduardohalsallquintero8@outlook.com'