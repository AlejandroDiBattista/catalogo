require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Web
	def bajar_todo(regenerar=false)
		destino = [carpeta, :productos]
		puts "BAJANDO todos los datos de #{carpeta.upcase}".green
		
		puts " ► Bajando clasificacion...".cyan
		clasificacion = bajar_clasificaciones()

		puts " ► Bajando productos... (#{clasificacion.count})".cyan
		productos = bajar_clasificacion(clasificacion).compact
		puts "    Se bajaron #{productos.count} productos".green
		Archivo.escribir(productos, destino)

		puts " ► Completando ID...".cyan
		completar_id(regenerar)
		
		puts " ► Bajando imagenes...".cyan
		Archivo.borrar_fotos(carpeta) if regenerar
		bajar_imagenes()

		Archivo.preservar(destino)

		puts "FIN.".green
		puts
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
			pagina.css(selector_producto).each do |x| 
				nuevos << { 
					id: '',
					nombre: nombre(x), 
					rubro: rubro,
					precio: precio(x), 
					precio_1: oferta(x, 1),
					precio_2: oferta(x, 2),
					precio_3: oferta(x, 3),
					url_producto: producto(x), 
					url_imagen:  imagen(x),
				}
			end
		rescue Exception => e
			puts "ERROR #{e}".red
		end
		nuevos.compact
	end

	def bajar_imagenes(forzar=false)
		productos = []
		Archivo.listar(carpeta, :productos) do |origen|
			Archivo.leer(origen).each  do |producto|
				productos << { url_imagen: producto.url_imagen, id: producto.id } 
			end
		end
		productos = productos.uniq.select{|producto| (forzar || !File.exist?( foto(producto.id ))) && !producto.url_imagen.vacio? }
		puts "Bajando #{productos.count} imagenes"
		productos.procesar do |producto|
			origen  = ubicar(:imagen, producto.url_imagen)
			destino = foto(producto.id)
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def ubicar(modo = :clasificacion, url = nil)
		return url if url && url[/^http/i]
		base = get_url[modo]
		base = "#{get_url[:base]}#{base}" if base[/^\//]
		base = base.gsub('*', url || '|')
		base 
	end

	def acortar(url)
		[:imagen, :clasificacion, :productos, :producto].each do |modo|
			ubicar(modo).split('|').each do |x| 
				url = url.gsub(x,'')
			end
		end
		url 
	end

	def completar_id(regenerar=true)
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
			productos = productos.sort_by{|x|x.id}
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

	def oferta(pagina,i)
		nil
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
			clasificacion = tmp.bajar_clasificaciones()
			clasificacion = clasificacion.first(3) if breve
			productos = tmp.bajar_clasificacion(clasificacion)
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
	Tamaño = 512

	def get_url
		{base: 'https://www.jumbo.com.ar', clasificacion: '/api/catalog_system/pub/category/tree/3', productos: '/*?PS=99', producto: '/*/p', imagen: 'https://jumboargentina.vteximg.com.br/arquivos/ids/*'}
	end

	def incluir(item)
		validos = ['Almacén', 'Bebidas', 'Pescados y Mariscos', 'Quesos y Fiambres', 'Lácteos', 'Congelados', 'Panadería y Repostería', 'Comidas Preparadas', 'Perfumería', 'Limpieza']
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

	def bajar_clasificaciones()
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
		url = url && url.split("/")[1]
		url = url && "#{url.split("-").first}-#{Tamaño}-#{Tamaño}" 
	end
end

class Tatito < Web
	def get_url
		 {base: 'http://tatito.com.ar', clasificacion: '/tienda', productos: '/tienda/?filters=product_cat*', producto: '/producto/*', imagen: '/wp-content/uploads/*'}
	end

	def bajar_clasificaciones 
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

	def oferta(item, indice)
		item.css('.precio_mayor_cont').each_with_index do |x, i|
			if i + 1 == indice then
				cantidad, precio = *x.text.split('$')
				return "%s,%1.2f" % [cantidad.gsub(/\D/,'').to_i, precio.to_money]
			end
		end
		return nil 
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
	def get_url 
		{base: 'http://www.maxiconsumo.com/sucursal_capital', clasificacion: '/', productos: '/*', producto: '/catalog/product/view/id/*?product_list_limit=96', imagen: 'http://maxiconsumo.com/pub/media/catalog/product/cache/*' }
	end
		
	def bajar_clasificaciones
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

	def incluir(item)
		validos = ["Perfumeria", "Fiambreria", "Comestibles", "Bebidas Con Alcohol", "Bebidas Sin Alcohol", "Limpieza"]
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
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
	def get_url 
		{base: 'https://www.tuchanguito.com.ar', clasificacion: '/', productos: '/*', producto: '/productos/*', imagen: 'http://d26lpennugtm8s.cloudfront.net/stores/001/219/229/products/*'}
	end

	def incluir(item)
		!item[:rubro][/ver todo/i] && !item[:rubro][/ofertas/i]
	end

	def bajar_clasificaciones
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

	def producto(item)	
		extraer_url(item.css('.item-image a'))
	end

	def imagen(item)
		url = acortar('http:' + item.css('.item-image img')[0]['data-srcset'].split(' ')[-2])
		url[/no-foto/i] ? nil : url 
	end
end

if __FILE__ == $0
	Jumbo.new.bajar_todo
	TuChanguito.new.bajar_todo 
	Tatito.new.bajar_todo 
	Maxiconsumo.new.bajar_todo 
end
