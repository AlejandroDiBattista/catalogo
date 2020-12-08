require 'nokogiri'

require_relative 'utils'
require_relative 'archivo'

class Web
	attr_accessor :id_actual 

	def bajar
		puts " BAJANDO productos de #{carpeta.upcase}".titulo(ancho: 50) do 
			puts " ► Bajando clasificacion... ".subtitulo 
			clasificacion = bajar_clasificaciones()			
			puts " ► Bajando productos... (#{clasificacion.count}) ".subtitulo 
			return bajar_clasificacion(clasificacion).compact
		end
	end

	def bajar_todo(regenerar = true)
		destino = [carpeta, 'productos.dsv']
		puts " BAJANDO todos los datos de #{carpeta.upcase}".titulo(ancho: 50) do 
		
			puts " ► Bajando clasificacion... ".subtitulo 
			clasificacion = bajar_clasificaciones()			

			puts " ► Bajando productos... (#{clasificacion.count}) ".subtitulo 
			productos = bajar_clasificacion(clasificacion).compact
			puts "    Se bajaron #{productos.count} productos ".green

			puts " ► Completando ID... ".subtitulo 
			completar_id(destino, regenerar)

			puts " ► Bajando imagenes... ".subtitulo 
			Archivo.borrar_fotos(carpeta) if regenerar
			bajar_imagenes()

			puts "FIN.".green
		end
		self
	end

	def bajar_clasificacion(clasificaciones)
		productos = []
		clasificaciones.procesar(10) do |clasificacion|
			url = ubicar(:productos, clasificacion.url)
			Archivo.abrir(url) do |pagina|
				productos << bajar_productos(pagina, clasificacion.rubro).compact
			end
		end
		productos.flatten.uniq
	end

	def bajar_productos(pagina, rubro)
		nuevos = [] 
		begin
			seleccionar(pagina, :productos).each do |x| 
				nuevos << { 
					id: '',
					nombre: extraer_nombre(x), 
					rubro: rubro,
					precio: extraer_precio(x), 
					precio_1: oferta(x, 1), 
					precio_2: oferta(x, 2), 
					precio_3: oferta(x, 3),
					url_producto: extraer_producto(x), 
					url_imagen:  imagen(x),
				}
			end
		rescue Exception => e
			puts " ERROR #{e} ".error
		end
		nuevos.compact
	end

	def limpiar_errores
		Archivo.listar(carpeta, :productos).each do |origen|
        	Archivo.procesar(origen){|producto| !producto.nombre.vacio? }
		end
	end

	def limpiar_fotos
		ids   = Archivo.leer(carpeta, :productos).map(&:id)
		fotos = Archivo.listar_fotos(carpeta){|id| !ids.include?(id) }
		fotos.each{|origen| Archivo.borrar(origen) }
	end

	def bajar_imagenes(forzar=false)
		productos = []
		Archivo.listar(carpeta, :productos).last(1).procesar do |origen|
			Archivo.leer(origen).each  do |producto|
				productos << { url_imagen: producto.url_imagen, id: producto.id } 
			end
		end

		bajar = productos.uniq.select{|producto| (forzar || !File.exist?( foto(producto.id ))) && !producto.url_imagen.vacio? }
		puts "Bajando #{productos.count} imagenes"
		
		bajar.procesar do |producto|
			origen  = ubicar(:imagen, producto.url_imagen)
			destino = foto(producto.id)
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def seleccionar(pagina, selector)
		pagina.css(get_selector[selector])
	end

	def ubicar(modo, url = nil)
		return url if url && url[/^http/i]

		base = get_url[modo]
		base = "#{get_url[:base]}#{base}" if base[/^\//]
		base = base.gsub('*', url || '|')
		base 
	end

	def acortar(url)
		[:imagen, :clasificacion, :productos, :producto].each do |modo|
			segmento = ubicar(modo).split('|').first
			url = url.gsub(segmento, '')
		end
		url 
	end

	def completar_id(destino, regenerar = false)
		datos = {}

		Archivo.listar(carpeta, :productos).procesar do |origen|
			Archivo.leer(origen) do |producto| 
				datos[key(producto)] ||= generar_id(producto)
			end
		end

		if regenerar then
			Archivo.listar(carpeta, :productos) do |origen|
				Archivo.procesar(origen) do |producto| 
					producto[:id] = datos[key(producto)]
				end
			end
		else
			Archivo.procesar(destino) do |producto| 
				producto[:id] = datos[key(producto)]
			end
		end
	end

	def key(producto)
		[:nombre, :url_producto, :url_imagen, :rubro].map{|campo| producto[campo] }.to_key
		# "#{producto.nombre.to_key}-#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}-#{producto.rubro.to_key}"
	end

	def generar_id(producto)
		self.id_actual ||= "00000"
		if producto.id.vacio? 
			self.id_actual = self.id_actual.succ
		else
			self.id_actual = producto.id if producto.id > self.id_actual
			producto.id 
		end
	end
	
	def foto(id)
		"#{carpeta}/fotos/#{id}.jpg"
	end

	def carpeta
		self.class.to_s.downcase
	end

	def extraer_nombre(pagina)
		if item = seleccionar(pagina, :nombre)
			item.text.espacios
		else
			""
		end
	end 

	def extraer_precio(pagina)
		if item = seleccionar(pagina, :precio) 
			item.last && item.last.text.to_money 
		end || 0
	end

	def extraer_producto(pagina)
		if item = seleccionar(pagina, :producto)
			extraer_url(item)
		end
	end

	def extraer_url(item, compacto=true)
		url = item && item.first && item.first[:href] || ''
		compacto ? acortar(url) : url 
	end

	def oferta(pagina, i)
		nil
	end
	
	def extraer_img(item, compacto=true)
		url = item && item.first && item.first[:src] || ''
		compacto ? acortar(url) : url 
	end

	class << self
		def muestra(breve=true)
			tmp = new 
			puts "Bajando Muestra productos de #{tmp.carpeta.upcase}"

			clasificacion = tmp.bajar_clasificaciones()
			clasificacion = clasificacion.first(2) if breve
			productos = tmp.bajar_clasificacion(clasificacion)
			productos = productos.first(4) if breve
			productos.tabular

			productos
		end

		def leer
			base = new.carpeta
			Archivo.leer(base, 'productos.dsv')
		end
	end
end

require_relative './jumbo'
require_relative './tatito'
require_relative './tuchanguito'
require_relative './maxiconsumo'

def bajar_todo(regenerar=false)
	puts ' Bajando datos '.titulo do 
		Tatito.new.bajar_todo regenerar
		Jumbo.new.bajar_todo regenerar
		TuChanguito.new.bajar_todo regenerar
		Maxiconsumo.new.bajar_todo regenerar
	end
end	

def limpiar_errores
	puts ' Limpiando errores '.titulo do 
		Tatito.new.limpiar_errores
		Jumbo.new.limpiar_errores
		TuChanguito.new.limpiar_errores
		Maxiconsumo.new.limpiar_errores
	end
end

def limpiar_fotos
	puts ' Limpiando Fotos '.titulo do 
		Tatito.new.limpiar_fotos
		Jumbo.new.limpiar_fotos
		TuChanguito.new.limpiar_fotos
		Maxiconsumo.new.limpiar_fotos
	end
end

if __FILE__ == $0
	puts "PROBANDO CAMBIOS".pad(100).titulo
	Tatito.muestra
	TuChanguito.muestra
	Jumbo.muestra
	Maxiconsumo.muestra
	# bajar_todo true
	# limpiar_errores
	# limpiar_fotos
end
