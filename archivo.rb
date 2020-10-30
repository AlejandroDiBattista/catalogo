require 'open-uri'
require 'csv'
require 'fileutils'
require 'colorize'
require_relative 'utils'
require 'json'

module Archivo

	def ubicar(*camino)
		camino = [camino].flatten
		if fecha = (TrueClass === camino.last)
			camino.pop 
		end
		camino = camino.map(&:to_s).join("/")
		camino = "#{camino}.dsv" unless camino[/\.\w+/]
		camino = camino.sub(".", Time.now.strftime("_%F.")) if fecha
		camino
	end

	def listar(*camino)
		camino = [camino].flatten.map(&:to_s).join("/")
		camino = "#{camino}*.dsv" unless camino["."]
		lista = Dir[camino].sort
		
		lista.each{|x| yield x} if block_given? 
		lista 
	end

	def leer(*camino)
		origen = ubicar(*camino)
		csv  = CSV.open(origen, :col_sep => "|")
		campos = csv.shift.map(&:to_key)
		datos  = csv.map{|valores| Hash(campos, valores) }.normalizar
		datos.each{|item|yield(item)} if block_given?
		datos 
	end

	def escribir(datos, *camino)
		datos = datos.map(&:to_hash)
		destino = ubicar(camino)
		if File.extname(destino) == '.json'
			escribir_json(datos, destino)
		else
			escribir_dsv(datos, destino)
		end
	end

	def escribir_dsv(datos, *camino)
		destino = ubicar(camino)
		campos = datos.map(&:keys).flatten.uniq
		separador = destino['.dsv'] ? '|' : ';'
		CSV.open(destino, 'wb', :col_sep => separador) do |csv|
			csv << campos.map(&:to_key)
			datos.each{|valores| csv << campos.map{|campo| valores[campo] } }
		end
		datos
	end

	def escribir_json(datos, *camino)
		destino = ubicar(*camino)
		open(destino, 'wb') do |f|
			f.write JSON.pretty_generate(datos)
		end
		datos
	end

	def procesar(*camino)
		origen = ubicar(*camino)
		datos = leer(*camino)
		datos.each{|item| yield(item)}
		escribir(datos, origen)
	end

	def preservar(*camino)
		datos = Archivo.leer(*camino)
		Archivo.escribir(datos, [camino, true])
	end

	def limpiar(*camino)
		Archivo.procesar(*camino) do |producto|
			producto[:id] = 0
		end
	end

	def bajar(origen, destino, forzar=false)
		destino = destino.to_s 
		destino += File.extname(origen) unless destino[/\.\w+$/]
		begin
			if forzar || !File.exist?(destino)
				URI.open(origen){|f|  File.open(destino, 'wb'){|file| file.puts f.read }} 
				nil
			else
				true 
			end
		rescue => e 
			false
		end
	end

	def borrar(destino)
		puts destino
		begin
			File.delete(destino)
		rescue
			false				
		end
	end
	
	def abrir(url)
		begin
			if block_given?
				URI.open(url){|f| yield(Nokogiri::HTML(f)) }
			else
				Nokogiri::HTML(URI.open(url))
			end
		rescue 
		end
	end

end
module Enumerable
	def escribir(*camino)
		Archivo.datos(self, camino)
	end
end

include Archivo

if __FILE__ == $0 

	p origen  = ubicar(:jumbo, :productos)
	p destino = ubicar(:jumbo, :productos, true)

	[:jumbo, :tatito, :maxiconsumo].each do |base| 
		Archivo.listar(base, :productos) do |origen|
			Archivo.limpiar(origen)
		end
	end

	# Archivo.preservar(:jumbo, :productos)
	# Archivo.preservar(:tatito, :productos)
	# Archivo.preservar(:maxiconsumo, :productos)

	# Archivo.limpiar(:jumbo, :productos)
	# Archivo.limpiar(:tatito, :productos)
	# Archivo.limpiar(:maxiconsumo, :productos)

	# pp listar("jumbo/productos")
	# pp listar("tatito/productos")
	# pp listar("maxiconsumo/productos")
end

# Archivo.listar(:maxiconsumo, :productos){|o| Archivo.limpiar(o)}