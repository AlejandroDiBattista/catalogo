require_relative 'utils'
require_relative 'archivo'
require_relative 'web'
require_relative 'producto'
require_relative 'catalogo'
require 'erb'

def analizar(supermercado, filtro: '', periodo: :semana, cambios: true, verboso: false )
	t = Catalogo.leer(supermercado)
	periodo = 30 if Symbol === periodo && :mes    === periodo 
	periodo =  7 if Symbol === periodo && :semana === periodo  
	t.comparar(periodo) if periodo
	# t = t.filtrar(&:vario?) if cambios
	t.listar_productos filtro, verboso
end

def arroz(*supermercados, periodo: :semana)
	puts " Análisis de variación de precio del Arroz al #{Date.today} (Período: #{periodo})".pad(113).error
	supermercados.each do |supermercado|
		analizar supermercado, filtro: '/arroz arroz -garbanzo -ma.z -poroto -lentej -arvej -/listo 500', periodo: periodo
	end
end

def generar_paginas(publicar: false)
	productos, supermercado = [], '' 

	[:tatito, :tuchanguito, :maxiconsumo, :jumbo].each do |aux|
		supermercado = aux 
		puts " > Generando [#{supermercado}] ".pad(120).titulo

		productos = Catalogo.leer(supermercado).generar_datos
		# productos = Catalogo.cargar_todo(supermercado).activos.generar_datos
		Archivo.escribir(productos, [supermercado, 'productos.json'])
	
		template = open('catalogo.erb').read
		renderer = ERB.new(template)
		output   = renderer.result(binding)

		Archivo.copiar('catalogo.css', [supermercado, 'catalogo.css'])
		Archivo.escribir(output, [supermercado, 'catalogo.html'])

		if publicar 
			# Copiar Página
			Archivo.copiar [supermercado, 'catalogo.*'], [:publicar, supermercado] 
			
			# Sincronizar Fotos 
			Archivo.borrar :publicar, supermercado, :fotos, '*.jpg'
			Archivo.copiar [supermercado, :fotos, '*.jpg'], [:publicar, supermercado, :fotos] 
		end
	end
end

# Catalogo.leer(:jumbo).resumir
# Catalogo.leer(:tatito).resumir
# Catalogo.leer(:tuchanguito).listar_productos "/arroz arroz -lenteja -garbanzo -maíz"

# Archivo.copiar [:tatito, :fotos, '*.jpg'], [:publicar, :tatito, :fotos]
# generar_paginas publicar: true 
# Archivo.borrar_fotos(:tatito)
# analizar :tatito , cambios: true
arroz(:jumbo, :tatito, :tuchanguito, periodo: :mes)
return

# Catalogo.leer(:maxiconsumo).resumir
# return 

PARSE_NOMBRE = /(.{3,})\sx?\s?([0-9.,]+)\s?(\w+)\.?/i
# [:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre| Catalogo.analizar(nombre, 7) }
# [:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre| Catalogo.leer(nombre).filtrar{|x| !x.error? }.escribir}

t = Catalogo.leer(:jumbo)
# t -= t.filtrar(&:error?)
# t.escribir(:json)
# t.escribir(:dsv)
# t.resumir 
t.filtrar(&:vario?).listar_productos 'jugo de limón'
# t.resumir
return

nombres = t.map(&:nombre).uniq.sort
# pp nombres.select{|x|x['(']}
# return
lista =  nombres.map{|x| x.scan(PARSE_NOMBRE).first}
pp  nombres.select{|x| !x.scan(PARSE_NOMBRE).first}
p lista.compact.map(&:last).map(&:downcase).compact.uniq.sort
