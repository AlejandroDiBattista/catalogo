$stdout.sync = true

require 'open-uri'
require 'json'
require 'nokogiri'
require 'csv'
require_relative 'utils'

class Archivo
	class << self
		def leer(origen="productos.dsv")
			origen = "#{origen}.dsv" if Symbol === origen
			datos  = CSV.open(origen, :col_sep => "|")
			campos = datos.shift
			datos.map{|x| Hash(campos, x)}.normalizar
		end

		def escribir(datos, destino="datos.dsv")
			destino = "#{destino}.dsv" if Symbol === destino
			campos = datos.map(&:keys).uniq.flatten
			CSV.open(destino, "wb", :col_sep => "|") do |csv|
				csv << campos
				datos.each{|x| csv << campos.map{|c| x[c] } }
			end
		end

		 def bajar(origen, destino)
			begin
				URI.open(origen){|f|  File.open(destino, "wb"){|file| file.puts f.read }} 
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
		def clasificacion()
			datos = JSON(URI.open('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3').read)
			datos.map do |d|
				d["children"].map do |c|
					if c["children"].size > 0
						c["children"].map{|s|  {departamento: d["name"], categoria: c["name"], subcategoria: s["name"], url: s["url"]} }
					else
						{departamento: d["name"], categoria: c["name"],  subcategoria: "-", url: c["url"]}
					end
				end
			end.flatten.select{|x|incluir(x)}
		end

		def productos(clasificacion)
			productos = []
			clasificacion.each do |c|
				print c[:url]
				page = Nokogiri::HTML(URI.open(c[:url]+"?PS=99"))
				page.css('.product-shelf li').each do |x|
					if x.css(".product-item__name a").text.strip.size > 0 
						productos << {
							nombre:  x.css(".product-item__name a").text,
							marca:   x.css(".product-item__brand").text,
							precio:  x.css(".product-prices__value--best-price").text.to_money,
							link:    x.css(".product-item__name a").first["href"].split("/")[3],
							imagen:  x.css(".product-item__image-link img").first["src"][/.*\/(\d+)-.*/, 1],
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
		
		def imagenes(productos,tamaño=512)
			imagenes = productos.map{|x|x[:imagen]}

			imagenes.each.with_index do |imagen, i|
				origen  = "https://jumboargentina.vteximg.com.br/arquivos/ids/#{imagen}-#{tamaño}-#{tamaño}"
				destino = "fotos/#{imagen}.jpg"
				unless File.exist?(destino)
					print(".")
					puts if i % 100 == 0
					puts origen if ! Archivo.bajar(origen, destino)
				end
			end
			puts "FIN"
		end
	end
end

class Tatito
	class << self

		def clasificacion
			page = Nokogiri::HTML(URI.open("http://tatito.com.ar/tienda/"))
			page.css('#checkbox_15_2 option').map do |x|
				{rubro: x.text.gsub("\u00A0"," ").gsub("\u00E9","é"), id: x["value"]}
			end	
		end
	
		def productos(clasificacion)
			productos = []
			clasificacion.each do |c|
				c[:url] = "http://tatito.com.ar/tienda/?filters=product_cat[#{c[:id]}]"
				print c[:url]
				page = Nokogiri::HTML(URI.open(c[:url]))

				page.css('.item_tienda').each do |x|
					img = x.css("img").first
					productos << {
						nombre:  x.css(".titulo_producto a").text,
						#marca:   x.css(".product-item__brand").text,
						precio:  x.css(".amount").text.to_money,
						#link:    x.css(".product-item__name a").first["href"].split("/")[3],
						imagen: img.nil? ? "" : img["src"].gsub(/-\d+x\d+\./,"."),
						rubro: c[:rubro],
						id: "%04i" % (productos.size + 1)
						#categoria:    c[:categoria],
						#subcategoria: c[:subcategoria],
					}
					print "."
				end
				puts
			end
			productos.compact
		end

		def imagenes(imagenes)
			imagenes.each.with_index do |imagen, i|
				origen  = imagen[:imagen]
				destino = "fotos-tatito/#{imagen[:id]}.jpg"
				unless origen.size == 0 || File.exist?(destino) 
					print(".")
					puts if i % 100 == 0
					puts origen if ! Archivo.bajar(origen, destino)
				end
			end
			puts "FIN"
		end
	end
end

puts "INICIO"
clasificacion = Tatito.clasificacion()
Archivo.escribir(clasificacion, :clasificacion_tatito)
productos = Tatito.productos(clasificacion)
Archivo.escribir(productos, :tatito_productos)
Tatito.imagenes(productos)

puts "FIN"
return 
clasificacion =  Jumbo.clasificacion()
Archivo.escribir(clasificacion, :clasificacion_01)

productos = Jumbo.productos(clasificacion)
Archivo.escribir(productos, :productos_01)

Jumbo.imagenes(productos)

