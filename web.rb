require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Web

	def bajar_todo
		destino = [carpeta, :productos]
		puts "BAJANDO todos los datos de #{carpeta.upcase}"
		
		puts " ► Bajando clasificacion..."
		clasificacion = bajar_clasificacion()#.first(3)
		puts clasificacion.count
		puts " ► Bajando productos..."
		productos = bajar_productos(clasificacion).compact
		puts productos.count
		Archivo.escribir(productos, destino)

		puts " ► Completando ID..."
		completar_id()

		puts " ► Bajando imagenes..."
		bajar_imagenes()

		Archivo.preservar(destino)

		puts "FIN."
		puts
		self
	end

	def foto(id)
		"#{carpeta}/fotos/#{id}.jpg"
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.procesar do |c|
			url = ubicar(c[:url], :productos)
			Archivo.abrir(url) do |pagina|
				nuevos = bajar_producto(pagina).compact
				# pp [nuevos.size, nuevos.first]
				nuevos.each do |x|
					x[:rubro] = c[:rubro]
					x[:id] = ""
				end
				productos += nuevos
			end
		end
		productos.compact.uniq
	end

	def bajar_producto(pagina)
		nuevos = [] 
		begin
			pagina.css(selector_producto).each{|x| nuevos << { nombre: nombre(x), precio: precio(x), url_producto: producto(x), url_imagen:  imagen(x) } }
		rescue Exception => e
			puts "ERROR #{e}"			
		end
		nuevos
	end

	def bajar_imagenes(forzar=false)
		productos = []
		Archivo.listar(carpeta, :productos) do |origen|
			Archivo.leer(origen).each  do |producto|
				productos << { url_imagen: producto.url_imagen, id: producto.id } 
			end
		end
		productos = productos.uniq.select{|producto| (forzar || ! File.exist?( foto(producto.id ))) && ! producto.url_imagen.vacio? }
		puts "Bajando #{productos.count} imagenes"
		productos.procesar do |producto|
			origen  = ubicar(producto.url_imagen, :imagen)
			destino = foto(producto.id)
			# print " #{producto.id}" unless 
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def completar_id(regenerar=false)
		datos = {}
		if regenerar then
			Archivo.listar(carpeta, :productos) do |origen|
				Archivo.limpiar(origen)
			end
		else
			Archivo.listar(carpeta, :productos) do |origen|
				Archivo.leer(origen).each do |producto| 
					datos[key(producto)] = producto.id unless producto.id.vacio?
				end
			end
		end

		Archivo.listar(carpeta, :productos) do |origen|
			productos = Archivo.leer(origen)
			productos.each do |producto| 
				producto[:id] = (datos[key(producto)] ||= proximo_id(datos))
			end
			Archivo.escribir(productos, origen)
		end
	end

	def key(producto)
		"#{producto.nombre.to_key}-#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}-#{producto.rubro.to_key}"
	end

	def proximo_id(datos)
		datos.count == 0 ? "00001" : datos.values.max.succ
	end

	def self.muestra(breve=true)
		inicio = Time.new
		tmp = new 

		puts "► Muestra productos de #{tmp.carpeta.upcase}"
		clasificacion = tmp.bajar_clasificacion
		clasificacion = clasificacion.first(3) if breve
		productos = tmp.bajar_productos(clasificacion)
		productos = productos.first(10) if breve
		# Archivo.escribir(productos, "#{tmp.carpeta}/productos.dsv")
		productos.tabular
		puts "■ %0.1fs \n" % (Time.new - inicio)
		productos
	end

	def self.leer
		base = new.carpeta 
		Archivo.leer("#{base}/productos.dsv")
	end

	def carpeta
		self.class.to_s.downcase
	end

	def href(item)
		!item.nil? && !item.first.nil? && item.first[:href] || ""
	end

	def src(item)
		item && item.first && item.first[:src] || ""
	end
	
end

class Jumbo < Web
	URL = 'https://www.jumbo.com.ar'
	URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"
	Tamaño = 512

	def incluir(item)
		validos = ["Almacén", "Bebidas", "Pescados y Mariscos", "Quesos y Fiambres", "Lácteos", "Congelados", "Panadería y Repostería", "Comidas Preparadas", "Perfumería", "Limpieza"]
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}/api/catalog_system/pub/category/tree/3"
		when :productos 
			"#{URL}#{url}?PS=99"
		when :producto
			"#{URL}#{url}/p"
		when :imagen 
			"#{URL_Imagenes}/#{url}"
		end
	end
	
	def acortar(url)
		url ? url.gsub(URL,"").gsub(URL_Imagenes,"").gsub(/\/p$/,"").gsub(/\?PS=99$/,"") : ""
	end

	def bajar_clasificacion()
		datos = JSON(URI.open(ubicar(:clasificacion)).read).normalizar
		datos.map do |d|
			d[:children].map do |c|
				if c[:children].size > 0
					c[:children].map{|s|  {rubro: [ d[:name], c[:name], s[:name]].to_rubro, url: acortar(s[:url]) } }
				else
					{rubro: [d[:name], c[:name]].to_rubro, url: acortar(c[:url]) }
				end
			end
		end.flatten.select{|x| incluir(x) }
	end

	def selector_producto
		'.product-shelf li'
	end

	def nombre(item)
		item.css(".product-item__name a").text
	end

	def precio(item)
		item.css(".product-prices__value--best-price").text.to_money
	end

	def producto(item)
		acortar(href(item.css(".product-item__name a")))
	end

	def imagen(item)
		url = src(item.css(".product-item__image-link img"))
		aux = acortar(url)
		aux = aux && aux.split("/")[1]
		aux = aux && "#{aux.split("-").first}-#{Tamaño}-#{Tamaño}" 
	end
end

class Tatito < Web
	URL = "http://tatito.com.ar/tienda"
	URL_Productos = "http://tatito.com.ar/producto"
	URL_Producto  = "http://tatito.com.ar/tienda/?filters=product_cat"

	URL_Imagenes  = "http://tatito.com.ar/wp-content/uploads"

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}"
		when :productos 
			"#{URL_Producto}#{url}"
		when :producto
			"#{URL_Producto}#{url}"
		when :imagen 
			"#{URL_Imagenes}#{url}"
		end
	end

	def acortar(url)
		url.gsub(URL,"").gsub(URL_Producto,"").gsub(URL_Productos,"").gsub(URL_Imagenes,"")
	end
					
	def bajar_clasificacion
		url = ubicar(:clasificacion)
		rubros = [nil, nil]
		Archivo.abrir(url) do |pagina|
			return pagina.css('#checkbox_15_2 option').map do |x|
				rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 

				nivel = rubro[0..0] == "-" ? 1 : 0
				rubros[nivel] = rubro.gsub(/^-\s*/,"")
				id = x["value"]
				nivel == 1 ?  { rubro: rubros.to_rubro, url: "[#{id}]" } : nil 
			end.compact
		end
	end

	def selector_producto
		'.item_tienda'
	end

	def nombre(item)
		item.css(".titulo_producto a").text
	end

	def precio(item)
		item.css(".amount").text.to_money
	end

	def producto(item)
		acortar(href(item.css(".pad15 a")))
	end

	def imagen(item)
		url = href(item.css(".pad15 a"))
		Archivo.abrir(url) do |pagina|
			aux = pagina.css(".woocommerce-product-gallery__image a")
			return acortar(href(aux)) 
		end
	end
end

class Maxiconsumo < Web
	attr_accessor :cache
	URL = "http://www.maxiconsumo.com/sucursal_capital"
	URL_Imagenes = "http://www.maxiconsumo.com/media/catalog/product/cache/%s/image/300x/%s"

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}"
		when :productos 
			"#{URL}/#{url}"
		when :imagen 
			aux = url.split("-")
			aux = aux.unshift(cache.to_s) if aux.size == 1 
			"#{URL_Imagenes}" % aux
		end
	end

	def acortar(url)
		url.gsub(URL,"").gsub(URL_Imagenes,"")
	end

	def incluir(item)
		validos = ["Perfumeria", "Fiambreria", "Comestibles", "Bebidas Con Alcohol", "Bebidas Sin Alcohol", "Limpieza"]
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

	def bajar_clasificacion
		incluir = 
		url = ubicar(:clasificacion)
		rubro = [nil, nil, nil]
		Archivo.abrir(URL) do |pagina|
			lista = pagina.css('#maxiconsumo-megamenu  a').map do |x|
				url = x[:href] = x[:href].split("/")[4..-1]
				{rubro: x.text, nivel: url.count, url: url.join("/") }
			end.compact
			anterior, nivel = [], 0 
			salida = []
			ant_nivel = 0
			ant_url   = nil 
			lista.each do |x|
				if x.nivel <= ant_nivel then
					salida << { rubro: anterior[1..ant_nivel].join(" > "), url: ant_url}
				end
				ant_nivel = x.nivel 
				ant_url = x.url 
				anterior[x.nivel] = x.rubro
			end
			salida <<  { rubro: anterior[0..ant_nivel].join(" > "), url: ant_url}
			return salida.select{|x| incluir(x) }
		end

	end

	def selector_producto
		'.products-grid li'
	end

	def nombre(item)
		item.css("h2 a").first["title"]
	end

	def precio(item)
		item.css(".price").last.text.to_money
	end

	def producto(item)	
		nil
	end

	def imagen(item)
		url = src(item.css("img"))
		if a = url && url.match(/(\d+)\/small_image\/115x115(.*)$/i)
			"#{a[1]}-#{a[2]}"
		else
			nil
		end
	end
end

if __FILE__ == $0 
	Dir.chdir "C:/Users/Algacom/Documents/GitHub/catalogo/" do 
		Jumbo.new.bajar_todo
		Tatito.new.bajar_todo
		# Maxiconsumo.new.bajar_todo
	end
end

# m = Maxiconsumo.new
# if c = m.bajar_clasificacion
# 	c.tabular
# 	pp m.bajar_productos(c)
# end