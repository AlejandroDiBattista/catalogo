require 'nokogiri'

require_relative 'utils'
require_relative 'archivo'

class Web
	attr_accessor :id_actual 

	def bajar
		puts " BAJANDO productos de #{carpeta.upcase}".pad(100).titulo do 
			puts " ► Bajando clasificacion... ".subtitulo 
			clasificacion = bajar_clasificaciones()			
			puts " ► Bajando productos... (#{clasificacion.count}) ".subtitulo 
			return bajar_clasificacion(clasificacion).compact
		end
	end

	def bajar_todo(regenerar = true)
		destino = [carpeta, 'productos.dsv']
		puts " BAJANDO todos los datos de #{carpeta.upcase} ".pad(100).titulo do 
		
			puts " ► Bajando clasificacion... ".green 
			clasificacion = bajar_clasificaciones()			

			puts " ► Bajando productos... (#{clasificacion.count}) ".green 
			productos = bajar_clasificacion(clasificacion).compact
			puts " Se bajaron #{productos.count} productos ".yellow

			Archivo.escribir(productos, destino)
			Archivo.preservar(destino)
			puts " ► Completando ID... ".green 
			completar_id(destino, regenerar)

			# puts " ► Bajando imagenes... ".green 
			# bajar_imagenes(regenerar)
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
		# puts " BAJAR_PRODUCTOS ".debug
		if items = seleccionar(pagina, :productos) 
			items.each do |x| 
				begin
					nuevos << { 
						id: '',
						nombre: extraer_nombre(x), 
						marca: extraer_marca(x),
						rubro: rubro,
						precio: extraer_precio(x),
						precio_unitario: extraer_precio_unitario(x), 
						precio_1: oferta(x, 1), 
						precio_2: oferta(x, 2), 
						precio_3: oferta(x, 3),
						url_producto: extraer_producto(x), 
						url_imagen:  imagen(x),
					}
						
				rescue => exception
					puts "ERROR : #{exception.message} #{caller[0]}".error 
					pp exception.backtrace					
				end
			end
		end
		# puts "Se bajaron #{nuevos.count} (en relidad #{nuevos.compact.count}) productos".debug
		nuevos.compact
	end

	def limpiar_errores
		Archivo.listar(carpeta, 'productos*.dsv').each do |origen|
        	Archivo.procesar(origen){|producto| !producto.nombre.vacio? }
		end
	end

	def limpiar_fotos
		ids   = Archivo.leer(carpeta, 'productos*.dsv').map(&:id)
		fotos = Archivo.listar_fotos(carpeta){|id| !ids.include?(id) }
		fotos.each{|origen| Archivo.borrar(origen) }
	end

	def bajar_imagenes(forzar = false)
		Archivo.borrar(carpeta, :fotos, '*.*') if forzar

		productos = []
		Archivo.listar(carpeta, 'productos*.dsv').last(1).procesar do |origen|
			Archivo.leer(origen).each  do |producto|
				productos << { url_imagen: producto.url_imagen, id: producto.id } 
			end
		end

		bajar = productos.uniq.select{|producto| (forzar || !File.exist?( nombre_foto(producto.id ))) && !producto.url_imagen.vacio? }
		puts "Bajando #{productos.count} imagenes"
		
		bajar.procesar do |producto|
			origen  = ubicar(:imagen, producto.url_imagen)
			destino = nombre_foto(producto.id)
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def seleccionar(pagina, selector)
		if origen = get_selector[selector]
			pagina.css(origen) if origen
		end 
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

		Archivo.listar(carpeta, 'productos*.dsv').procesar do |origen|
			Archivo.leer(origen) do |producto| 
				datos[key(producto)] ||= generar_id(producto)
			end
		end

		if regenerar then
			# puts "COMPLETAR_ID #{datos.count}"
			Archivo.listar(carpeta, 'productos*.dsv') do |origen|
				# puts origen 
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
		# "#{producto.nombre.to_key}-#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}-#{producto.rubro.to_key}"
		[:nombre, :url_producto, :url_imagen, :rubro].map{|campo| producto[campo] }.to_key
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
	
	def nombre_foto(id)
		"#{carpeta}/fotos/#{id}.jpg"
	end

	def carpeta
		self.class.to_s.downcase
	end

	def extraer_nombre(pagina)
		if item = seleccionar(pagina, :nombre)
			item.text.espacios
		end
	end 

	def extraer_marca(pagina)
		if item = seleccionar(pagina, :marca)
			item.text.espacios
		end
	end 

	def extraer_precio(pagina)
		if item = seleccionar(pagina, :precio) 
			item.last && item.last.text.to_money 
		end || 0
	end

	def extraer_precio_unitario(pagina)
		if item = seleccionar(pagina, :precio) 
			item.last && item.last.text.espacios
		end
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
			puts "Bajando Muestra productos de #{tmp.carpeta.upcase}".pad(100).titulo

			clasificacion = tmp.bajar_clasificaciones()
			clasificacion = clasificacion.first(2) if breve

			puts "Bajando Productos #{clasificacion.count}".error

			productos = tmp.bajar_clasificacion(clasificacion)
			# productos = productos.first(4) if breve
			productos.tabular

			productos
		end

		def leer
			base = new.carpeta
			Archivo.leer(base, 'productos.dsv')
		end

		def bajar_todo
			new.bajar_todo
		end 

		def limpiar_errores
			new.limpiar_errores
		end

		def limpiar_fotos
			new.limpiar_fotos
		end
	end
end

require_relative './jumbo'
require_relative './tatito'
require_relative './tu_changuito'
require_relative './maxiconsumo'

def bajar_todo
	Tatito.bajar_todo
	Jumbo.bajar_todo
	TuChanguito.bajar_todo
	Maxiconsumo.bajar_todo
	puts "FIN.".pad(100).error
end	

def limpiar_errores
	Tatito.limpiar_errores
	Jumbo.limpiar_errores
	TuChanguito.limpiar_errores
	Maxiconsumo.limpiar_errores
end

def limpiar_fotos
	Tatito.limpiar_fotos
	Jumbo.limpiar_fotos
	TuChanguito.limpiar_fotos
	Maxiconsumo.limpiar_fotos
end

if __FILE__ == $0
	# m = Maxiconsumo.new
	# p m.ubicar(:producto)
	# p m.acortar('http://maxiconsumo.com/sucursal_capital/catalog/product/view/id/2442/s/canasta-vim-citrus-podder-x5-55-gr-23856/category/248/')
	# return
	# puts "PROBANDO CAMBIOS".pad(100).yellow.on_red
	# Jumbo.bajar_todo
	
	# Tatito.muestra
	# TuChanguito.muestra
	# Maxiconsumo.muestra
	# Jumbo.muestra
	Jumbo.bajar_todo
	# bajar_todo
	# limpiar_errores
	# limpiar_fotos
end
