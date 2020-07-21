$stdout.sync = true

require 'open-uri'
require 'json'
require 'nokogiri'
require 'csv'
require_relative 'utils'

class Archivo
	class << self
		def leer(origen = :datos)
			origen = "#{origen}.dsv" if Symbol === origen
			datos  = CSV.open(origen, :col_sep => "|")
			campos = datos.shift
			datos.map{|x| Hash(campos, x)}.normalizar
		end

		def escribir(datos, destino = :datos)
			destino = "#{destino}.dsv" if Symbol === destino
			campos = datos.map(&:keys).uniq.flatten
			CSV.open(destino, "wb", :col_sep => "|") do |csv|
				csv << campos
				datos.each{|x| csv << campos.map{|c| x[c] } }
			end
		end

		 def bajar(origen, destino, forzar=false)
			begin
				if forzar || !File.exist?(destino)
					URI.open(origen){|f|  File.open(destino, "wb"){|file| file.puts f.read }} 
				end
				true
			rescue
				false
			end
		end

		def borrar(destino)
			puts destino
			begin
				File.delete(destino)
			rescue
				false				
			end
		end
		
		def fotos
			Dir["fotos/*.jpg"]
		end
	end
end

def incluir(item)
	departamento = ["Almacén", "Bebidas", "Pescados y Mariscos", "Quesos y Fiambres", "Lácteos", "Congelados", "Panadería y Repostería", "Comidas Preparadas", "Perfumería", "Limpieza"]
	departamento.include?(item.departamento)	
end

class Jumbo
	class << self
		URL = 'https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3'
		URL_Imagenes = "https://jumboargentina.vteximg.com.br/arquivos/ids"

		def clasificacion()
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

		def productos(clasificacion)
			productos = []
			clasificacion.each do |c|
				url = "#{URL}/#{c[:url]}?PS=99"
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
			productos
		end
		
		def imagenes(productos, carpeta=:fotos, tamaño=512)
			productos.each{|x| x[:imagen] = "#{x[:imagen]}-#{tamaño}-#{tamaño}"} if tamaño
			
			productos.each.with_index do |producto, i|
				origen  = "#{URL_Imagenes}/#{producto[:imagen]}"
				destino = "#{carpeta}/#{producto[:id]}.jpg"
				unless File.exist?(destino)
					print "."
					puts if i % 100 == 0
					puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino)
				end
			end
		end

		def bajar_todo
			puts "BAJANDO todos los datos de JUMBO"
			Dir.chdir "jumbo" do 
				clasificacion =  Jumbo.clasificacion()
				Archivo.escribir(clasificacion, :clasificacion)

				productos = Jumbo.productos(clasificacion)
				Archivo.escribir(productos, :productos)

				Jumbo.imagenes(productos)
			end
			puts "FIN."
		end
	end
end

class Tatito
	class << self
		URL = "http://tatito.com.ar/tienda"
		URL_Imagenes = "http://tatito.com.ar/wp-content/uploads"

		def clasificacion
			page = Nokogiri::HTML(URI.open(URL))
			page.css('#checkbox_15_2 option').map do |x|
				rubro = x.text.gsub("\u00A0"," ").gsub("\u00E9","é").strip 
				nivel = rubro[0..0] == "-" ? 1 : 0
				url   = "?filters=product_cat[#{x["value"]}]"
				{ rubro: rubro.gsub(/^-\s*/,""), nivel: nivel, url: url }
			end	
		end
	
		def productos(clasificacion)
			productos = []
			clasificacion.each do |c|
				url = "#{URL}/#{c[:url]}"
				page = Nokogiri::HTML(URI.open(url))
				print url
				page.css('.item_tienda').each do |x|
					img = x.css("img").first
					productos << {
						nombre:  x.css(".titulo_producto a").text,
						precio:  x.css(".amount").text.to_money,
						imagen: img.nil? ? "" : img["src"].gsub(URL_Imagenes,""),
						rubro: c[:rubro],
						nivel: c[:nivel],
						id: "%04i" % (productos.size + 1)
					}
					print "."
				end
				puts
			end
			productos.compact
		end

		def imagenes(productos, carpeta=:fotos)
			productos.each.with_index do |producto, i|
				origen  = "#{URL_Imagenes}#{producto[:imagen]}"
				destino = "#{carpeta}/#{producto[:id]}.jpg"
				unless origen.size == 0 || File.exist?(destino) 
					print(".")
					puts if i % 100 == 0
					puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino)
				end
			end
		end

		def bajar_todo
			puts "BAJANDO todos los datos de TATITO"
			Dir.chdir "tatito" do 
				clasificacion = clasificacion().first(3)
				Archivo.escribir(clasificacion, :clasificacion)
				productos = Tatito.productos(clasificacion)
				Archivo.escribir(productos, :productos)
				Tatito.imagenes(productos, :fotos)
			end
			puts "FIN."
		end
	end
end

class Maxiconsumo
	class << self
		URL = "http://www.maxiconsumo.com/sucursal_capital/"
		URL_Imagenes = "http://www.maxiconsumo.com/media/catalog/product/cache/29/small_image/115x115/9df78eab33525d08d6e5fb8d27136e95"

		def clasificacion
			page = Nokogiri::HTML(URI.open(URL))
			page.css('#root li a').map do |x|
				{rubro: x.text, nivel: x["data-level"].to_i, url: x["href"].gsub(URL,"") }
			end	
		end
	
		def productos(clasificacion)
			productos = []
			clasificacion.each do |c|
				url = "#{URL}#{c[:url]}"
				print url
				page = Nokogiri::HTML(URI.open(url))

				page.css('.products-grid li').each do |x|
					img = x.css("img").first["src"].gsub(URL_Imagenes,"").gsub("small_image/115x115", "image/300x")
					productos << {
						nombre:  x.css("h2 a").first["title"],
						precio:  x.css(".price").last.text.to_money,
						imagen: img,
						rubro: c[:rubro],
						nivel: c[:nivel],
						id: x.css(".sku").text.gsub(/\D/,""),
					}
					print "."
				end
				puts
			end
			productos.compact
		end

		def imagenes(productos, carpeta=:fotos)
			productos.each.with_index do |producto, i|
				origen  = "#{URL_Imagenes}#{producto[:imagen]}"
				destino = "#{carpeta}/#{producto[:id]}.jpg"
				unless origen.size == 0 || File.exist?(destino) 
					print(".")
					puts if i % 100 == 0
					puts "#{origen} => #{destino}" if ! Archivo.bajar(origen, destino, true)
				end
			end
		end

		def bajar_todo
			puts "BAJANDO todos los datos de MAXICONSUMO"
			Dir.chdir "maxiconsumo" do 
				clasificacion = Maxiconsumo.clasificacion()
				Archivo.escribir(clasificacion, :clasificacion)
				productos = Maxiconsumo.productos(clasificacion.select{|x|x[:nivel]==2})
				Archivo.escribir(productos, :productos)
				Maxiconsumo.imagenes(productos)
			end
			puts "FIN."
		end
	end
end


# Jumbo.bajar_todo
# Tatito.bajar_todo
# Maxiconsumo.bajar_todo
