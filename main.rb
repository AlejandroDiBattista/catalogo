$stdout.sync = true

require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

Campos = [:nombre, :precio, :rubro, :unidad, :url_producto, :url_imagen, :id]

class Producto < Struct.new(*Campos)
	def self.cargar(datos)
		new.tap{|tmp| Campos.each{|campo| tmp[campo] = datos[campo]}}.normalizar
	end

	def to_hash
		Hash[Campos.map{|campo|[campo, self[campo]]}]
	end

	def normalizar
		self.precio = self.precio.to_f
		self
	end
end

class Catalogo
	def self.leer(base)
		Archivo.leer(ubicar("#{base}/productos", false)).map{|producto| Producto.cargar(producto)}
	end
end

class Web
	def bajar_todo
		puts "BAJANDO todos los datos de #{carpeta.upcase}"
		Dir.chdir carpeta do 
			puts "► Bajando clasificacion..."
			clasificacion = bajar_clasificacion()
			# clasificacion = clasificacion.first(3)
			
			puts "► Bajando productos..."
			productos = bajar_productos(clasificacion).map{|x|Producto.cargar(x)}
			Archivo.escribir(productos.map(&:to_hash), :productos)
			
			puts "► Bajando imagenes..."
			# bajar_imagenes(productos)
		end
		puts "FIN."
		self
	end

	def carpeta
		self.class.to_s.downcase
	end

	def self.muestra(breve=false)
		inicio = Time.new
		tmp = new 

		puts "► Muestra productos de #{tmp.carpeta.upcase}"
		clasificacion = tmp.bajar_clasificacion
		clasificacion = clasificacion.first(3) if breve
		productos = tmp.bajar_productos(clasificacion)
		productos = productos.first(10) if breve
		Archivo.escribir(productos, "#{tmp.carpeta}/productos.dsv")
		productos.tabular
		puts "■ %0.1fs \n" % (Time.new - inicio)
		productos
	end

	def self.leer
		base = new.carpeta 
		Archivo.leer("#{base}/productos.dsv")
	end

	def registrar(productos)
		@datos ||= {}
		productos.each do |x|
			if x[:id].to_s.strip.size > 0
				@datos[x[:url_producto]] ||= x[:id]
			end
		end
	end

	def completar(productos)
		@datos ||= {}
		productos.each do |x|
			url = x[:url_producto]
			@datos[url] ||= sku(url)
			x[:id] = @datos[url]
		end
		puts
	end

	def registrados
		@datos ||=0
		@datos.count
	end

	def sku(url)
		url.to_key
	end
end

class Jumbo < Web
	URL = 'https://www.jumbo.com.ar'
	URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"

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

	def sku(url)
		print "•"
		abrir(ubicar(url, :producto)) do |page|
			return page.css(".skuReference").text
		end
	end

	def acortar_imagen(url)
		acortar(url).split("/")[1].split("-").first
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = ubicar(c[:url], :productos)
			print " - #{url} > "
			page = Nokogiri::HTML(URI.open(url))
			page.css('.product-shelf li').each do |x|
				if x.css(".product-item__name a").text.strip.size > 0 
					url    = x.css(".product-item__name a").first["href"]
					imagen = x.css(".product-item__image-link img").first["src"]
					productos << {
						nombre:  x.css(".product-item__name a").text,
						precio:  x.css(".product-prices__value--best-price").text.to_money,
						rubro: 	c[:rubro],
						# marca:   x.css(".product-item__brand").text,
						url_producto: acortar(url),
						url_imagen:   acortar_imagen(imagen),
						id: "", 
					}
					print "•"
				end
			end
			puts
		end
		productos.compact.uniq
	end

	def bajar_imagenes(productos, tamaño=512)
		productos.each{|x| x[:imagen] = "#{x[:url_imagen]}-#{tamaño}-#{tamaño}"} if tamaño
		
		productos.each.with_index do |producto, i|
			url = "#{producto[:url_imagen]}-#{tamaño}-#{tamaño}"
			origen  = ubicar(url, :imagen)
			destino = "fotos/#{producto[:url_imagen]}.jpg"
			unless File.exist?(destino)
				print "•"
				puts if i % 100 == 0
				puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino)
			end
		end
	end
end

class Tatito < Web
	URL = "http://tatito.com.ar/tienda"
	URL_Productos = "http://tatito.com.ar/tienda"
	URL_Producto  = "http://tatito.com.ar/producto"
	URL_Imagenes  = "http://tatito.com.ar/wp-content/uploads"

	def ubicar(url = nil, modo = :clasificacion)
		return url if url && url[":"]
		modo = url if Symbol === url 
		case modo
		when :clasificacion
			"#{URL}"
		when :productos 
			"#{URL_Productos}#{url}"
		when :producto
			"#{URL_Producto}#{url}"
		when :imagen 
			"#{URL_Imagenes}/#{url}"
		end
	end

	def acortar(url)
		url.gsub(URL,"").gsub(URL_Producto,"").gsub(URL_Productos,"").gsub(URL_Imagenes,"").gsub(/\/p$/,"")
	end
					
	def bajar_clasificacion
		url = ubicar(:clasificacion)
		p url
		page = Nokogiri::HTML(URI.open(url))
		rubros = [nil,nil]
		page.css('#checkbox_15_2 option').map do |x|
			rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 

			nivel = rubro[0..0] == "-" ? 1 : 0
			rubros[nivel] = rubro.gsub(/^-\s*/,"")
			id = x["value"]
			nivel == 1 ?  { rubro: rubros.to_rubro, url: "?filters=product_cat[#{id}]" } : nil 
		end.compact
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = ubicar(c[:url], :productos)
			print " - #{url} > "

			page = Nokogiri::HTML(URI.open(url))
			page.css('.item_tienda').each do |x|
				img = x.css("img").first
				url = x.css(".pad15 a").first["href"]
				detalle = Nokogiri::HTML(URI.open(url))
				productos << {
					nombre: x.css(".titulo_producto a").text,
					precio: x.css(".amount").text.to_money,
					rubro: 	c[:rubro],
					url_producto: acortar(url),
					url_imagen:   acortar(img(detalle)),
					id: sku(detalle),
				}
				print "•"
			end
			puts
		end
		productos.compact.uniq
	end

	def img(detalle)
		aux = detalle.css(".woocommerce-product-gallery__image a")
		!aux.nil? && !aux.first.nil? ? aux.first["href"] : ""
	end

	def sku(detalle)
		detalle.css(".sku_wrapper span").text
	end

	def bajar_imagenes(productos)
		productos.each.with_index do |producto, i|
			origen  = ubicar(producto[:url_imagen], :imagen)
			destino = "fotos/#{producto[:id]}.jpg"
			unless origen.viacia? || File.exist?(destino) 
				print(".")
				puts if i % 100 == 0
				puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino)
			end
		end
	end
end

class Maxiconsumo < Web
	URL = "http://www.maxiconsumo.com/sucursal_capital/"
	URL_Imagenes = "http://www.maxiconsumo.com/media/catalog/product/cache/29/small_image/115x115/9df78eab33525d08d6e5fb8d27136e95"

	def bajar_clasificacion
		page = Nokogiri::HTML(URI.open(URL))

		rubro = [nil, nil, nil]
		page.css('#root li a').map do |x|
			nivel = x["data-level"].to_i
			
			rubro[nivel] = x.text
			url = x["href"].gsub(URL,"")

			nivel == 2 ? { rubro: rubro.to_rubro, url: url } : nil 
		end	.compact
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = "#{URL}#{c[:url]}"
			print " - #{url} > "
			page = Nokogiri::HTML(URI.open(url))

			page.css('.products-grid li').each do |x|
				img = x.css("img").first["src"].gsub(URL_Imagenes,"")
				productos << {
					nombre: x.css("h2 a").first["title"],
					precio: x.css(".price").last.text.to_money,
					rubro: c[:rubro],
					url_producto: "", 
					url_imagen: img,
					id: x.css(".sku").text.gsub(/\D/,""),
				}
				print "•"
			end
			puts
		end
		productos.compact.uniq
	end

	def bajar_imagenes(productos)
		productos.each.with_index do |producto, i|
			origen  = "#{URL_Imagenes}#{producto[:imagen]}".gsub("small_image/115x115", "image/300x")
			destino = "fotos/#{producto[:id]}.jpg"
			unless origen.size == 0 || File.exist?(destino) 
				print(".")
				puts if i % 100 == 0
				puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino, true)
			end
		end
	end
end

def listar(base, filtro=nil, &condicion)
	aux = filtro ? lambda{|x| x.values.any?{|y| filtro === y} } : nil 

	# puts ">>#{base.to_s.capitalize}"
	lista = Archivo.leer("#{base}/productos.dsv")
	lista = lista.map{|x|{nombre: x.nombre, precio: x.precio, rubro: x.rubro}}
	lista = lista.select{|x| block_given? && condicion[x] || !aux.nil? && aux[x]}
	lista = lista.sort_by(&:nombre)#{|x|x.nombre}
	lista.listar("Listado #{base}")
end

if false
	a = Catalogo.leer(:maxiconsumo).map(&:nombre)
	b = a.map(&:separar_unidad).sort_by(&:first)
	b.select{|x|x.last}.map(&:last).uniq.sort.each{|x|pp x}
end
if false
	Jumbo.muestra
	Tatito.muestra
	Maxiconsumo.muestra
	return 
end

if false
	condicion = /arroz.*gallo/i
	listar :jumbo, condicion
	listar :maxiconsumo,condicion
	listar :tatito, condicion
	return
end

j = Jumbo.new

puts "REGISTRANDO"
Archivo.buscar("jumbo/producto", :todo).each do |origen|
	productos = Archivo.leer(origen)
	j.registrar(productos)
	puts " > #{origen} #{productos.count{|x|x[:id].vacio?}}"
end
puts "Hay #{j.registrados}"
puts "COMPLETANDO"

Archivo.buscar("jumbo/producto", :todo).reverse.each do |origen|
	puts origen
	productos = Archivo.leer(origen)
	vacios = productos.select{|x|x[:id].vacio?}
	puts vacios.size
	vacios.each_slice(10) do |lista|
		j.completar(lista)
		Archivo.escribir(productos, origen)
	end
end
return 

n = Jumbo.leer.map(&:nombre).uniq
n = n.select{|x| !separar(x).last }
n = n.select{|x| /d/ === x }

# pp n.map{|x|separar(x).first}.first(20)
puts n.first(20)
