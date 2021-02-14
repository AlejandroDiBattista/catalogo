require 'fileutils'
require 'open-uri'
require 'csv'
require 'json'
require 'colorize'
require_relative 'utils'

module Archivo
	Publicar = 'C:/Users/administrator/Documents/GitHub/vecinosyb/docs' 
	
	def ubicar(*camino)
		camino = [camino].flatten
		if fecha = (TrueClass === camino.last)
			camino.pop 
		end
		camino[0] = Dir.pwd  if camino.first == '.'
		camino[0] = Publicar if camino.first == :publicar
		camino = camino.map(&:to_s).join('/')
		
		camino = camino.sub('.', Time.now.strftime('_%F.')) if fecha
		camino
	end

	def nombre(*camino)
		origen = ubicar(camino)
		File.basename(origen, '.*')
	end

	def extension(*camino)
		origen = ubicar(camino)
		tipo = File.extname(origen).gsub('.', '')
		tipo.vacio? ? nil : tipo.to_key
	end

	def extraer_fecha(*camino)
		origen = nombre(camino)
		origen.split('_').last.to_date 
	end

	def crear_carpeta(*camino)
		carpeta = File.dirname(ubicar(camino))
		# puts "Crear Carpeta: #{carpeta}"
		FileUtils.mkdir_p carpeta unless File.exist?(carpeta)
	end

	def abrir(url)
		begin
			pagina = Nokogiri::HTML( URI.open(url) )
			yield(pagina) if block_given?
			pagina
		rescue
			nil
		end
	end

	def leer(*camino)
		origen = ubicar(camino)
		separador = extension(origen) == :dsv ? '|' : ';' 
		csv    = CSV.open(origen, :col_sep => separador)
		campos = csv.shift.map(&:to_key)
		datos = csv.map{|valores| Struct.new(*campos).new(*valores.normalizar) }
		datos = datos.map{|item| yield(item) } if block_given?
		datos.compact
	end
	
	def leer_json(*camino)
		origen = ubicar(camino)
		open(origen){|f| return JSON.parse(f.read) }
	end

	def escribir(datos, *camino)
		destino = ubicar(camino)
		datos = datos.map(&:to_hash) unless String === datos
		puts "ESCRIBIR > destino: #{destino} ext: #{extension(destino)}"
		case extension(destino)
		when :txt, :html, :rb
			puts datos 
			puts destino
				open(destino, 'w+') do |f|
				f.write datos
			end
		when :json
			open(destino, 'w+') do |f|
				f.write JSON.pretty_generate(datos)
			end
		when :dsv, :csv
			campos = datos.map(&:keys).flatten.uniq.sort
			separador = extension(destino) == :dsv ? '|' : ';'
			CSV.open(destino, 'w+', :col_sep => separador) do |csv|
				csv << campos.map(&:to_key)
				datos.each{|valores| csv << campos.map{|campo| valores[campo] } }
			end
		end
		datos 
	end

	def preservar(*camino)
		datos = leer(camino)
		escribir(datos, [camino, true])
	end

	def procesar(*camino)
		datos = leer(camino)
		datos = datos.select{|item| yield(item) }
		escribir(datos, camino)
	end

	def listar(*camino)
		origen = ubicar(camino).gsub('/.', '/*.').gsub(/\.$/, '.*')
		lista  = Dir[origen].sort
		
		block_given? ? lista.select{|item| yield item } : lista   
	end

	def listar_fotos(*camino)
		listar(camino, :fotos, '.jpg'){|origen| yield origen }
	end
	
	def limpiar(*camino)
		procesar(*camino){|producto| producto[:id] = 0; true }
	end

	def bajar(origen, destino, forzar = false)
		destino = ubicar(destino) 
		destino += File.extname(origen) unless extension(destino)
		crear_carpeta destino
		begin
			if forzar || !File.exist?(destino)
				URI.open(origen, 'rb'){|f|  File.open(destino, 'wb'){|file| file.puts(f.read) }} 
				true
			end
		rescue 
			false
		end
	end

	def borrar(*camino)
		listar(camino).procesar do |origen|
			begin
				if File.exist?(origen)
					File.delete(origen)
					true
				end				
			rescue
				false
			end
		end
	end

	def copiar(origenes, destino)
		origenes = ubicar(origenes)
		origenes += "/*.*" unless origenes['*']
		
		destino  = ubicar(destino)

		listar(origenes).procesar do |origen|
			begin
				FileUtils.cp origen, ubicar(destino, "#{nombre(origen)}.#{extension(origen)}")
			rescue
				false
			end
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
	# Archivo.crear_carpeta()
	p Archivo.extension('tatito/seed.rb')
end
