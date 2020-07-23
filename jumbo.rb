$stdout.sync = true

require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Web
	def bajar_todo(nivel=0)
		puts "BAJANDO todos los datos de #{carpeta.upcase}"
		Dir.chdir carpeta do 
			puts "- Bajando clasificacion..."
			clasificacion = bajar_clasificacion()
			Archivo.escribir(clasificacion, "clasificacion+")
			Archivo.escribir(clasificacion, "clasificacion")
			
			puts "- Bajando productos..."
			clasificacion = clasificacion.select{|x|x[:nivel] == nivel} if nivel > 0 
			productos = bajar_productos(clasificacion)
			Archivo.escribir(productos, "productos+")
			Archivo.escribir(productos, "productos")
			
			puts "- Bajando imagenes.."
			bajar_imagenes(productos)
		end
		puts "FIN."
	end

	def carpeta
		self.class.to_s.downcase
	end

	def self.muestra
		inicio = Time.new
		tmp = new 

		puts "► Muestra productos de #{tmp.carpeta.upcase}"
		tmp.bajar_productos(tmp.bajar_clasificacion.first(3)).first(10).tabular
		puts "■ %0.1fs \n" % (Time.new - inicio)
	end
end

class Jumbo < Web
	URL = 'https://www.jumbo.com.ar/'
	URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"

	def incluir(item)
		validos = ["Almacén", "Bebidas", "Pescados y Mariscos", "Quesos y Fiambres", "Lácteos", "Congelados", "Panadería y Repostería", "Comidas Preparadas", "Perfumería", "Limpieza"]
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

	def bajar_clasificacion()
		datos = JSON(URI.open("#{URL}api/catalog_system/pub/category/tree/3").read).normalizar
		datos.map do |d|
			d[:children].map do |c|
				if c[:children].size > 0
					c[:children].map{|s|  {rubro: [ d[:name], c[:name], s[:name]].join(" > "), url: s[:url].gsub(URL,"") } }
				else
					{rubro: [d[:name], c[:name]].join(" > "), url: c[:url].gsub(URL,"")}
				end
			end
		end.flatten.select{|x| incluir(x) }
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = "#{URL}#{c[:url]}?PS=99"

			print " - #{url} > "
			page = Nokogiri::HTML(URI.open(url))
			page.css('.product-shelf li').each do |x|
				if x.css(".product-item__name a").text.strip.size > 0 
					url = x.css(".product-item__name a").first["href"]
					imagen = x.css(".product-item__image-link img").first["src"][/.*\/(\d+)-.*/, 1]
					productos << {
						nombre:  x.css(".product-item__name a").text,
						precio:  x.css(".product-prices__value--best-price").text.to_money,
						rubro: c[:rubro],
						marca:   x.css(".product-item__brand").text,
						url:    url.split("/")[3],
						url_imagen:  imagen,
						# id: sku(url), 
					}
					print "."
				end
			end
			puts
		end
		productos.compact.uniq
	end

	def sku(url)	
		Nokogiri::HTML(URI.open(url)).css(".skuReference").text
	end

	def bajar_imagenes(productos, tamaño=512)
		productos.each{|x| x[:imagen] = "#{x[:imagen]}-#{tamaño}-#{tamaño}"} if tamaño
		
		productos.each.with_index do |producto, i|
			origen  = "#{URL_Imagenes}/#{producto[:imagen]}"
			destino = "fotos/#{producto[:id]}.jpg"
			unless File.exist?(destino)
				print "."
				puts if i % 100 == 0
				puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino)
			end
		end
	end
end

class Tatito < Web
	URL = "http://tatito.com.ar/tienda"
	URL_Productos = "http://tatito.com.ar/producto"
	URL_Imagenes = "http://tatito.com.ar/wp-content/uploads"
					
	def bajar_clasificacion
		page = Nokogiri::HTML(URI.open(URL))
		rubros = [nil,nil]
		page.css('#checkbox_15_2 option').map do |x|
			rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 

			nivel = rubro[0..0] == "-" ? 1 : 0
			rubros[nivel] = rubro.gsub(/^-\s*/,"")
			id = x["value"]
			nivel == 1 ?  { rubro: rubros.join(" > "), url: "?filters=product_cat[#{id}]" } : nil 
		end.compact
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = "#{URL}/#{c[:url]}"
			print " - #{url} > "

			page = Nokogiri::HTML(URI.open(url))
			page.css('.item_tienda').each do |x|
				img = x.css("img").first
				url = x.css(".pad15 a").first["href"]
				detalle = Nokogiri::HTML(URI.open(url))
				productos << {
					nombre:  x.css(".titulo_producto a").text,
					precio:  x.css(".amount").text.to_money,
					rubro: c[:rubro],
					url: url.gsub(URL_Productos,""),
					url_imagen: img(detalle).gsub(URL_Imagenes,""),
					id: sku(detalle),
				}
				print "."
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
			origen  = "#{URL_Imagenes}#{producto[:imagen]}"
			destino = "fotos/#{producto[:id]}.jpg"
			unless origen.size == 0 || File.exist?(destino) 
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

			nivel == 2 ? {rubro: rubro.join(" > "), url: url } : nil 
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
					url: "", 
					url_imagen: img,
					nivel: c[:nivel],
					id: x.css(".sku").text.gsub(/\D/,""),
				}
				print "."
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


# Jumbo.new.bajar_clasificacion.tabular
# Tatito.new.bajar_clasificacion.tabular

# Maxiconsumo.new.bajar_clasificacion.tabular
# Jumbo.new.bajar_todo
# Tatito.new.bajar_todo(1)
# Maxiconsumo.new.bajar_todo(2)
# departamento|categoria|subcategoria

# buscar("jumbo/clasificacion*.*", :todo).first(100).each do |origen|
# 	salida = []
# 	Archivo.leer(origen).each do |x|
# 		rubro = [x[:departamento], x[:categoria],x[:subcategoria]].select{|x|x.size > 1 }
# 		salida << {rubro: rubro.join(" > "), url: x[:url].gsub("https://www.jumbo.com.ar/","")}
# 	end

# 	salida.each{|x|puts "%-80s -> %s" % [x[:rubro], x[:url]]}

# 	aux = salida.map{|x|x[:url]}
# 	Archivo.escribir(salida, origen)
# end
# buscar("jumbo/clasificacion*.*", :todo).first(1).each do |origen|
# 	salida = []
# 	rubro  = [nil,nil,nil]
# 	Archivo.leer(origen).each do |x|
# 		nivel =  x[:nivel].to_i
# 		rubro[nivel] = x[:rubro]
# 		rubro[1] = nil if nivel < 1
# 		rubro[2] = nil if nivel < 2
# 		p rubro.compact.join(" > ") if nivel >= 0
# 		salida << {rubro: rubro.compact.join(" > "), url: x[:url]} if nivel == 1
# 	end

# 	salida.each{|x|puts "%-80s -> %s" % [x[:rubro], x[:url]]}

# 	aux = salida.map{|x|x[:url]}
# 	# Archivo.escribir(salida, origen)
# end

# nombre|precio|url|imagen|rubro|nivel|id

# Jumbo.muestra
# Tatito.muestra
# Maxiconsumo.muestra
buscar("jumbo/productos*.*", :todo).first(1).each do |o|
	a = Archivo.leer(o).map do |x|
		x[:rubro] = [x[:departamento], x[:categoria], x[:subcategoria]].to_rubro
		x.delete(:departamento)
		x.delete(:categoria)
		x.delete(:subcategoria)
		x
	end

	Archivo.escribir(a, o)
	puts o 
	a.repetidos{|x|{nombre: x.nombre, marca: x.marca}}.tabular
	p( [o, a.size,	a.map{|x|[x.nombre, x.marca, x.rubro, x.precio]}.uniq.size])
end
