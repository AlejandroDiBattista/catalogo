$stdout.sync = true

require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

def incluir(item)
	departamento = ["Almacén", "Bebidas", "Pescados y Mariscos", "Quesos y Fiambres", "Lácteos", "Congelados", "Panadería y Repostería", "Comidas Preparadas", "Perfumería", "Limpieza"]
	departamento.include?(item.departamento)	
end

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
end

class Jumbo < Web
	URL = 'https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3'
	URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"

	def bajar_clasificacion()
		datos = JSON(URI.open(URL).read)
		datos.map do |d|
			d["children"].map do |c|
				if c["children"].size > 0
					c["children"].map{|s|  {departamento: d["name"], categoria: c["name"], subcategoria: s["name"], url: s["url"].gsub(URL,"") } }
				else
					{departamento: d["name"], categoria: c["name"],  subcategoria: "-", url: c["url"].gsub(URL,"")}
				end
			end
		end.flatten.select{|x| incluir(x) }
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			# url = "#{URL}/#{c[:url]}?PS=99"
			url = "#{c[:url]}?PS=99"

			print url
			page = Nokogiri::HTML(URI.open(url))
			page.css('.product-shelf li').each do |x|
				if x.css(".product-item__name a").text.strip.size > 0 
					imagen = x.css(".product-item__image-link img").first["src"][/.*\/(\d+)-.*/, 1]
					productos << {
						nombre:  x.css(".product-item__name a").text,
						marca:   x.css(".product-item__brand").text,
						precio:  x.css(".product-prices__value--best-price").text.to_money,
						link:    x.css(".product-item__name a").first["href"].split("/")[3],
						imagen:  imagen,
						id: imagen, 
						departamento: c[:departamento],
						categoria:    c[:categoria],
						subcategoria: c[:subcategoria],
					}
					print "."
				end
			end
			puts
		end
		productos.compact.uniq
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
		page.css('#checkbox_15_2 option').map do |x|
			rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 
			nivel = rubro[0..0] == "-" ? 1 : 0
			url   = "?filters=product_cat[#{x["value"]}]"
			{ rubro: rubro.gsub(/^-\s*/,""), nivel: nivel, url: url }
		end	
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = "#{URL}/#{c[:url]}"
			page = Nokogiri::HTML(URI.open(url))
			print url
			page.css('.item_tienda').each do |x|
				img = x.css("img").first
				aux = x.css(".pad15 a").first["href"]
				productos << {
					nombre:  x.css(".titulo_producto a").text,
					precio:  x.css(".amount").text.to_money,
					url: aux.gsub(URL_Productos,""),
					imagen: img(aux).gsub(URL_Imagenes,""),
					id: sku(aux),
					rubro: c[:rubro],
					nivel: c[:nivel],
				}
				print "."
			end
			puts
		end
		productos.compact.uniq
	end

	def img(url)
		aux = Nokogiri::HTML(URI.open(url)).css(".woocommerce-product-gallery__image a")
		!aux.nil? && !aux.first.nil? ? aux.first["href"] : ""
	end

	def sku(url)
		Nokogiri::HTML(URI.open(url)).css(".sku_wrapper span").text
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
		page.css('#root li a').map do |x|
			{rubro: x.text, nivel: x["data-level"].to_i, url: x["href"].gsub(URL,"") }
		end	
	end

	def bajar_productos(clasificacion)
		productos = []
		clasificacion.each do |c|
			url = "#{URL}#{c[:url]}"
			print " - #{url}"
			page = Nokogiri::HTML(URI.open(url))

			page.css('.products-grid li').each do |x|
				img = x.css("img").first["src"].gsub(URL_Imagenes,"")
				productos << {
					nombre: x.css("h2 a").first["title"],
					precio: x.css(".price").last.text.to_money,
					url: "", 
					imagen: img,
					rubro: c[:rubro],
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

Jumbo.new.bajar_todo
Tatito.new.bajar_todo(1)
Maxiconsumo.new.bajar_todo(2)
