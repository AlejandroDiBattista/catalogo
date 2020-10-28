require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Web
	def bajar_todo
		destino = [carpeta, :productos]
		puts "BAJANDO todos los datos de #{carpeta.upcase}".green
		
		puts " ► Bajando clasificacion...".blue
		clasificacion = bajar_clasificacion()#.first(3)
		puts " ► Bajando productos... (#{clasificacion.count})"
		productos = bajar_productos(clasificacion).compact
		puts productos.count
		Archivo.escribir(productos, destino)

		puts " ► Completando ID...".blue
		completar_id()

		puts " ► Bajando imagenes...".blue
		bajar_imagenes()

		Archivo.preservar(destino)

		puts "FIN.".green
		puts
		self
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.procesar(10) do |c| # Limitador por Maxiconsumo
			url = ubicar(c[:url], :productos)
			Archivo.abrir(url) do |pagina|
				nuevos = bajar_producto(pagina).compact
				nuevos.each{|x| x[:rubro], x[:id] = c[:rubro], ''}
				productos += nuevos
			end
		end
		productos.compact.uniq
	end

	def bajar_producto(pagina)
		nuevos = [] 
		begin
			pagina.css(selector_producto).each do |x| 
				nuevos << { 
					nombre: nombre(x), 
					precio: precio(x), 
					url_producto: producto(x), 
					url_imagen:  imagen(x) 
				} 
			end
		rescue Exception => e
			puts "ERROR #{e}"			
		end
		nuevos
	end

	def bajar_imagenes(forzar=true)
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
			puts " #{origen} > #{destino}"
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


	def proximo_id(datos)
		datos.count == 0 ? "00001" : datos.values.max.succ
	end
	
	def foto(id)
		"#{carpeta}/fotos/#{id}.jpg"
	end

	def key(producto)
		"#{producto.nombre.to_key}-#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}-#{producto.rubro.to_key}"
	end

	def carpeta
		self.class.to_s.downcase
	end

	def extraer_precio(item)
		item && item.last ? item.last.text.to_money : 0
	end

	def extraer_url(item, compacto=true)
		url = item && item.first && item.first[:href] || ''
		compacto ? acortar(url) : url 
	end

	def extraer_img(item, compacto=true)
		url = item && item.first && item.first[:src] || ''
		compacto ? acortar(url) : url 
	end

	class << self 
		def muestra(breve=true)
			inicio = Time.new
			tmp = new 

			puts "► Muestra productos de #{tmp.carpeta.upcase}"
			clasificacion = tmp.bajar_clasificacion
			clasificacion = clasificacion.first(3) if breve
			productos = tmp.bajar_productos(clasificacion)
			productos = productos.first(10) if breve
			productos.tabular
			puts "■ %0.1fs \n" % (Time.new - inicio)
			productos
		end

		def leer
			base = new.carpeta 
			Archivo.leer("#{base}/productos.dsv")
		end
	end
end

class Jumbo < Web
	URL = 'https://www.jumbo.com.ar'
	URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"
	Tamaño = 512

	def incluir(item)
		validos = ['Almacén', 'Bebidas', 'Pescados y Mariscos', 'Quesos y Fiambres', 'Lácteos', 'Congelados', 'Panadería y Repostería', 'Comidas Preparadas', 'Perfumería', 'Limpieza']
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
		url ? url.gsub(URL,'').gsub(URL_Imagenes,'').gsub(/\/p$/,'').gsub(/\?PS=99$/,'') : ''
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
		extraer_precio(item.css('.product-prices__value--best-price'))
	end

	def producto(item)
		extraer_url(item.css('.product-item__name a'))
	end

	def imagen(item)
		url = extraer_img(item.css('.product-item__image-link img'))
		url = url && aux.split("/")[1]
		url = url && "#{url.split("-").first}-#{Tamaño}-#{Tamaño}" 
	end
end

class Tatito < Web
	URL = 'http://tatito.com.ar/tienda'
	URL_Productos = 'http://tatito.com.ar/producto'
	URL_Producto  = 'http://tatito.com.ar/tienda/?filters=product_cat'
	URL_Imagenes  = 'http://tatito.com.ar/wp-content/uploads'

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
		url.gsub(URL,'').gsub(URL_Producto,'').gsub(URL_Productos,'').gsub(URL_Imagenes,'')
	end
					
	def bajar_clasificacion
		url = ubicar(:clasificacion)
		rubros = [nil, nil]
		Archivo.abrir(url) do |pagina|
			return pagina.css('#checkbox_15_2 option').map do |x|
				rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 

				nivel = rubro[0..0] == "-" ? 1 : 0
				rubros[nivel] = rubro.gsub(/^-\s*/,'')
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
		extraer_precio(item.css('.amount'))
	end

	def producto(item)
		extraer_url(item.css('.pad15 a'))
	end

	def imagen(item)
		url = extraer_url(item.css('.pad15 a'), false)
		Archivo.abrir(url) do |pagina|
			aux = pagina.css('.woocommerce-product-gallery__image a')
			return extraer_url(aux)
		end
	end
end

class Maxiconsumo < Web
	attr_accessor :cache
	URL = 'http://www.maxiconsumo.com/sucursal_capital'
	URL_Producto = 'http://maxiconsumo.com/sucursal_capital/catalog/product/view/id'
	URL_Imagenes = 'http://maxiconsumo.com/pub/media/catalog/product/cache'

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}"
		when :producto 
			"#{URL_Producto}/#{url}?product_list_limit=96"
		when :productos 
			"#{URL}/#{url}"
		when :imagen 
			aux = url.split("-")
			aux = aux.unshift(cache.to_s) if aux.size == 1 
			"#{URL_Imagenes}" % aux
		end
	end

	def acortar(url)
		url.gsub(URL,'').gsub(URL_Producto,'').gsub(URL_Imagenes,'').gsub(/^\//,'')
	end

	def incluir(item)
		validos = ["Perfumeria", "Fiambreria", "Comestibles", "Bebidas Con Alcohol", "Bebidas Sin Alcohol", "Limpieza"]
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

	def bajar_clasificacion
		url = ubicar(:clasificacion)
		Archivo.abrir(url) do |pagina|
			lista = pagina.css('#maxiconsumo-megamenu  a').map do |x|
				url = x[:href] = x[:href].split("/")[4..-1]
				{ rubro: x.text, nivel: url.count, url: url.join("/") }
			end

			anterior, rubro, nivel, url = [],  [], 0 , nil 
			lista.compact.each do |x|
				if x.nivel <= nivel
					rubro << { rubro: anterior[1..nivel].to_rubro, url: url } 
				end
				nivel, url = x.nivel , x.url 
				anterior[x.nivel] = x.rubro
			end
			rubro <<  { rubro: anterior[1..nivel].to_rubro, url: url }

			return rubro.select{|x| incluir(x) }
		end
	end

	def selector_producto
		'.product-item-info'
	end

	def nombre(item)
		item.css('a.product-item-link').text.espacios
	end

	def precio(item)
		extraer_precio(item.css('.price'))
	end

	def producto(item)
		extraer_url(item.css('a.product-item-link'))
	end

	def imagen(item)
		extraer_img(item.css('.image'))
	end
end

class TuChanguito < Web
	attr_accessor :cache
	URL = 'https://www.tuchanguito.com.ar'
	URL_Producto = 'https://www.tuchanguito.com.ar/productos'
	URL_Imagenes = 'http://d26lpennugtm8s.cloudfront.net/stores/001/219/229/products'

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url
		case modo
		when :clasificacion
			"#{URL}"
		when :producto 
			"#{URL_Producto}/#{url}"
		when :productos 
			"#{URL}/#{url}"
		when :imagen 
			"#{URL_Imagenes}/#{url}"
		end
	end

	def acortar(url)
		url
			.gsub(URL_Producto,'')
			.gsub(URL_Imagenes,'')
			.gsub(URL,'')
			.gsub(/^\//,'')
	end

	def incluir(item)
		!item[:rubro][/ver todo/i] && !item[:rubro][/ofertas/i]
	end

	def bajar_clasificacion
		url = ubicar(:clasificacion)
		Archivo.abrir(url) do |pagina|
			rubros = {}
			pagina.css('.nav-desktop-list li.nav-item-desktop').each do |x|
				if y = x.at('.nav-item-container')
					rubro = y.text.espacios
					x.css('.desktop-dropdown a').each{|y| rubros[y.text.espacios] = rubro }
				end 
			end
			salida = pagina.css('.nav-item-desktop a').map do |y|
				subrubro = y.text.espacios
				{ rubro: [rubros[subrubro], subrubro].to_rubro, url: acortar(y[:href]) }
			end
			rubros = rubros.values.uniq 
			return salida.select{|x| incluir(x) && !rubros.include?(x.rubro) }
		end
	end

	def selector_producto
		'.js-item-product'
	end

	def nombre(item)
		item.css("div.item-name").text.espacios
	end

	def precio(item)
		extraer_precio(item.css('.item-price'))
	end

	# JSON.parse(item.css("div.js-quickshop-container")[0]["data-variants"])
	def producto(item)	
		extraer_url(item.css('.item-image a'))
	end

	def imagen(item)
		url = acortar(item.css(".item-image img")[0]["data-srcset"].split(" ")[-2])
		url[/no-foto/i] ? nil : url 
	end
end

if __FILE__ == $0

	# tc = TuChanguito.leer
	# puts tc.count
	# puts tc.map(&:url_imagen).uniq.sort 

	# Dir.chdir "C:/Users/Algacom/Documents/GitHub/catalogo/" do 
		TuChanguito.new.bajar_todo
		# Jumbo.new.bajar_todo
		# Tatito.new.bajar_todo
		# Maxiconsumo.new.bajar_todo
		T
end

