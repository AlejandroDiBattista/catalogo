require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Web
	def bajar_todo
		destino = [carpeta, :productos]
		puts "BAJANDO todos los datos de #{carpeta.upcase}"
		
		puts "► Bajando clasificacion..."
		clasificacion = bajar_clasificacion().first(3)
		
		puts "► Bajando productos..."
		productos = bajar_productos(clasificacion)
		Archivo.escribir(productos, destino)
		Archivo.preservar(destino)

		puts "► Bajando imagenes..."
		completar_id()
		# bajar_imagenes(productos)
		puts "FIN."
		self
	end

	def datos
		@datos ||= {}
	end

	def completar_id
		Archivo.listar(carpeta, :productos) do |origen|
			registrar_id( Archivo.leer(origen) )
		end

		Archivo.listar(carpeta, :productos) do |origen|
			productos = Archivo.leer(origen)
			productos.each{|producto| producto[:id] = buscar_id(producto)}
			Archivo.escribir(productos, origen)
		end
	end

	def registrar_id(*productos)
		productos = [productos].flatten.select{|producto| ! producto.id.vacio? }
		productos.each{|producto| datos[key(producto)] ||= producto.id }
	end

	def buscar_id(producto)
		datos[key(producto)] ||= proximo_id 
	end

	def key(producto)
		"#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}"
	end

	def proximo_id
		print "."
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

	def bajar_imagenes(productos, forzar=false)
		productos.each{|producto| producto.id = buscar_id(producto)}
		productos.each.with_index do |producto, i|
			destino = "fotos/#{producto.id}.jpg"
			unless producto.url_imagen.vacio? || File.exist?(destino) 
				origen  = ubicar(producto.url_imagen, :imagen)
				print(".")
				puts if i % 100 == 0
				puts "#{origen} => #{destino}" unless Archivo.bajar(origen, destino, forzar)
			end
		end
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
		url.gsub(URL,"").gsub(URL_Imagenes,"").gsub(/\/p$/,"")
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

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = ubicar(c[:url], :productos)
			print " - #{url} > "
			page = Nokogiri::HTML(URI.open(url))
			page.css('.product-shelf li').each do |x|
				if x.css(".product-item__name a").text.strip.size > 0 
					productos << {
						nombre:  nombre(x),
						precio:  precio(x),
						rubro: 	c[:rubro],						# marca:   x.css(".product-item__brand").text,
						url_producto: acortar(url),
						url_imagen:  imagen(x),
						id: nil, 
					}
					print "•"
				end
			end
			puts
		end
		productos.compact.uniq
	end

	def nombre(item)
		item.css(".product-item__name a").text
	end

	def precio(item)
		item.css(".product-prices__value--best-price").text.to_money
	end

	def producto(item)
		acortar(item.css(".product-item__name a").first["href"])
	end

	def imagen(item)
		url = item.css(".product-item__image-link img").first["src"]
		acortar(url).split("/")[1].split("-").first+"-#{Tamaño}-#{Tamaño}"
	end

	def sku(url)
		print "•"
		abrir(ubicar(url, :producto)) do |page|
			return page.css(".skuReference").text
		end
	end
end

class Tatito < Web
	URL = "http://tatito.com.ar/tienda"
	URL_Productos = "http://tatito.com.ar/tienda"
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
			"#{URL_Imagenes}/#{url}"
		end
	end

	def acortar(url)
		url.gsub(URL,"").gsub(URL_Producto,"").gsub(URL_Productos,"").gsub(URL_Imagenes,"")
	end
					
	def bajar_clasificacion
		url = ubicar(:clasificacion)
		page = Nokogiri::HTML(URI.open(url))
		rubros = [nil, nil]
		page.css('#checkbox_15_2 option').map do |x|
			rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 

			nivel = rubro[0..0] == "-" ? 1 : 0
			rubros[nivel] = rubro.gsub(/^-\s*/,"")
			id = x["value"]
			nivel == 1 ?  { rubro: rubros.to_rubro, url: "[#{id}]" } : nil 
		end.compact
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = ubicar(c[:url], :productos)
			print " - #{url} > "

			page = Nokogiri::HTML(URI.open(url))
			page.css('.item_tienda').each do |x|
				url = x.css(".pad15 a").first["href"]
				detalle = Nokogiri::HTML(URI.open(url))
				productos << {
					nombre: nombre(x),
					precio: precio(x),
					rubro: 	c[:rubro],
					url_producto: producto(x),
					url_imagen:   imagen(detalle),
					id: sku(detalle),
				}
				print "•"
			end
			puts
		end
		productos.compact.uniq
	end

	def nombre(item)
		item.css(".titulo_producto a").text
	end

	def precio(item)
		item.css(".amount").text.to_money
	end

	def producto(item)
		acortar(item.css(".pad15 a").first["href"])
	end

	def imagen(detalle)
		aux = detalle.css(".woocommerce-product-gallery__image a")
		aux && aux.first ? acortar(aux.first["href"]) : nil
	end

	def sku(detalle)
		detalle.css(".sku_wrapper span").text
	end
end

class Maxiconsumo < Web
	URL = "http://www.maxiconsumo.com/sucursal_capital"
	URL_Imagenes = "http://www.maxiconsumo.com/media/catalog/product/cache/1/image/300x"

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}"
		when :productos 
			"#{URL}#{url}"
		when :imagen 
			"#{URL_Imagenes}/#{url}"
		end
	end
	
	def acortar(url)
		url.gsub(URL,"").gsub(URL_Imagenes,"")
	end

	def bajar_clasificacion
		url = ubicar(:clasificacion)
		page = Nokogiri::HTML(URI.open(URL))

		rubro = [nil, nil, nil]
		page.css('#root li a').map do |x|
			nivel = x["data-level"].to_i
			rubro[nivel] = x.text

			nivel == 2 ? { rubro: rubro.to_rubro, url: acortar(x["href"]) } : nil 
		end.compact
	end

	def bajar_productos(clasificacion)
		clasificacion.tabular
		productos = []
		clasificacion.each do |c|
			url = ubicar(c[:url], :productos)
			print " - #{url} > "
			page = Nokogiri::HTML(URI.open(url))

			page.css('.products-grid li').each do |x|
				productos << {
					nombre: nombre(x),
					precio: precio(x),
					rubro: 	c[:rubro],
					url_producto: nil,
					url_imagen: imagen(x),
					id: sku(x),
				}
				print "•"
			end
			puts
		end
		productos.compact.uniq
	end

	def nombre(item)
		item.css("h2 a").first["title"]
	end
	
	def precio(item)
		item.css(".price").last.text.to_money
	end

	def sku(item)
		item.css(".sku").text.gsub(/\D/,"")
	end

	def imagen(item)
		url = item.css("img").first["src"]
		if a = url.match(/small_image\/115x115(.*)$/i)
			a[1]
		else
			nil
		end
	end
end


Jumbo.new.bajar_todo
Tatito.new.bajar_todo
Maxiconsumo.new.bajar_todo