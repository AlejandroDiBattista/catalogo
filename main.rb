require_relative 'utils'
require_relative 'archivo'
require_relative 'web'
require_relative 'producto'
require_relative 'catalogo'
require 'erb'

def analizar(supermercado, filtro: '', periodo: :semana, cambios: true, verboso: false )
	t = Catalogo.leer(supermercado)
	# t -= t.filtrar(&:error?)
	periodo = 30 if Symbol === periodo && :mes    === periodo 
	periodo =  7 if Symbol === periodo && :semana === periodo  
	t.comparar(periodo) if periodo
	t = t.filtrar(&:vario?) if cambios
	t.listar_productos filtro, verboso
end

def arroz(*supermercados, periodo: :semana)
	puts "Analisis de variacion de precio del Arroz al #{Date.today} (perido: #{periodo})".on_red.white
	supermercados.each do |supermercado|
		analizar supermercado, filtro: 'arroz /arroz -garbanzo -ma.z -poroto -lentej -arvej -/listo', periodo: periodo
	end
end

def generar_pagina(supermercado)
	productos = Catalogo.leer(supermercado).generar_datos

	renderer = ERB.new(template)
	output = renderer.result()
	open("#{supermercado}.html",'w+'){|f|f.write output}
end

def generar_paginas
	productos, supermercado = [], "" 
	[:tatito, :tuchanguito, :maxiconsumo, :jumbo].each do |aux|
		supermercado = aux 
		puts " > Generando [#{supermercado}]  ".pad(50).on_yellow.blue
		productos = Catalogo.leer(supermercado).generar_datos
		Archivo.escribir_json(productos, "#{supermercado}/productos.json")
	
		template = open('catalogo.erb').read
		renderer = ERB.new(template)
		output = renderer.result(binding)

		open("#{supermercado}/catalogo.html",'w+'){|f|f.write output}
	end
end

# generar_paginas
# Archivo.borrar_fotos(:tatito)
# analizar :tatito , cambios: true
arroz(:jumbo, :tatito, :tuchanguito)
# t = Catalogo.leer(:tatito)
# t = t.filtrar{|x| x.contiene("arroz") }
# p t.count
return
# Catalogo.leer(:maxiconsumo).resumir
# return 

PARSE_NOMBRE = /(.{3,})\sx?\s?([0-9.,]+)\s?(\w+)\.?/i
# [:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre|	Catalogo.analizar(nombre, 7) }
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
