require 'nokogiri'

require_relative 'archivo'
require_relative 'normalizar'
class Web
	attr_accessor :id_actual 

	def bajar(guardar=true)
		clasificacion = bajar_clasificaciones()			
		productos = bajar_clasificacion(clasificacion).compact
		if guardar 
			destino = [carpeta, 'productos.dsv']
			Archivo.escribir(productos, destino)
			Archivo.preservar(destino)
		end
		productos
	end

	def bajar_todo(regenerar = false)
		destino = [carpeta, 'productos.dsv']
		puts " BAJANDO todos los datos de #{carpeta.upcase} ".pad(120).titulo do 
		
			puts " ► Bajando clasificacion... ".green 
			clasificacion = bajar_clasificaciones()			

			puts " ► Bajando productos... (#{clasificacion.count}) ".green 
			productos = bajar_clasificacion(clasificacion).compact
			puts " Se bajaron #{productos.count} productos ".yellow

			Archivo.escribir(productos, destino)
			Archivo.preservar(destino)
			# puts " ► Completando ID... ".green 
			# completar_id(regenerar, destino)

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

	def bajar_clasificaciones
		nil #Reescribir
	end

	def bajar_productos(pagina, rubro)
		nuevos = [] 
		if items = seleccionar(pagina, :productos) 
			items.each do |x| 
				begin
					nuevos << { 
						id: '',
						nombre: extraer_nombre(x).limpiar_nombre, 
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
		nuevos.compact
	end

	def limpiar_errores
		puts "Limpiando Productos con Errores" do 
			Archivo.listar(carpeta, 'productos_*.dsv').each do |origen|
				puts " > #{origen}"
				Archivo.procesar(origen) do |producto| 
					producto.nombre = producto.nombre.limpiar_nombre
					!producto.nombre.vacio? 
				end
			end
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

		bajar = productos.uniq.select{|producto| producto.url_imagen.existe? && (forzar || !existe_foto?(producto))  }

		puts "Bajando #{productos.count} imagenes"
		bajar.procesar{ |producto| bajar_foto(producto, forzar) }
	end

	def nombre_foto(id)
		"#{carpeta}/fotos/#{id}.jpg"
	end

	def existe_foto?(producto)
		producto.url_imagen.existe? && File.exist?( nombre_foto(producto.id) )
	end

	def bajar_foto(producto, forzar=false)
		origen  = ubicar(:imagen, producto.url_imagen)
		destino = nombre_foto(producto.id)
		Archivo.crear_carpeta(destino)
		Archivo.bajar(origen, destino, forzar)
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

	def generar_id(producto)
		self.id_actual ||= "00000"
		if producto.id.vacio? 
			self.id_actual = self.id_actual.succ
		else
			self.id_actual = producto.id if producto.id > self.id_actual
			producto.id 
		end
	end
	
	def key(producto)
		[:nombre, :url_producto, :url_imagen].map{|campo| producto[campo] }.to_key
	end
	
	def completar_id(regenerar = false, destino=nil)
		self.id_actual = '00000' 
		datos = {}

		Archivo.listar(carpeta, 'productos*.dsv').procesar do |origen|
			Archivo.leer(origen) do |producto| 
				datos[key(producto)] ||= generar_id(producto)
			end
		end

		if regenerar then
			Archivo.listar(carpeta, 'productos*.dsv') do |origen|
				Archivo.procesar(origen) do |producto| 
					producto[:id] = datos[key(producto)]
				end
			end
		elsif destino then
			Archivo.procesar(destino) do |producto| 
				producto[:id] = datos[key(producto)]
			end
		end
	end

	def carpeta
		self.class.to_key
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
		if item = seleccionar(pagina, :precio_unitario) 
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

	def extraer_img(item, compacto=true)
		url = item && item.first && item.first[:src] || ''
		compacto ? acortar(url) : url 
	end

	def oferta(pagina, i)
		nil
	end

	class << self
		def muestra(breve=true)
			tmp = new 
			puts "Bajando Muestra productos de #{tmp.carpeta.upcase}".pad(100).titulo

			clasificacion = tmp.bajar_clasificaciones()
			clasificacion = clasificacion.first(2) if breve

			puts "Bajando Productos #{clasificacion.count}".error

			productos = tmp.bajar_clasificacion(clasificacion)
			productos = productos.first(4) if breve
			productos.tabular

			productos
		end

		def leer
			base = new.carpeta
			Archivo.leer(base, 'productos.dsv')
		end

		def crear(nombre)
			return nombre.to_class.new 
			nombre = nombre.name if Class === nombre
			nombre = nombre.to_s.split('_').map(&:capitalize).join 
			clazz = Object.const_get(nombre).new 	
		end
	end
end

require_relative './jumbo/jumbo'
require_relative './tatito/tatito'
require_relative './tu_changuito/tu_changuito'
require_relative './maxiconsumo/maxiconsumo'

def correr(accion, modulos: [:tatito, :tu_changuito, :jumbo, :maxiconsumo])
	medir "Procesando datos [#{accion}] en #{modulos.count} modulos" do 
		modulos.each{|modulo|Web.crear(modulo).send(accion) }
	end
	puts " FIN.".pad(120).error
end

def pull
    puts `git status -s`
	`git add .`
	`git commit -m "Upload automatic #{Date.today.to_s}"`
	`git push`
end

if __FILE__ == $0
	# limpiar_errores
	# completar_id
	# correr :limpiar_errores
	# correr :completar_id
	# correr :limpiar_fotos
	correr :bajar_todo
	# pull
end
