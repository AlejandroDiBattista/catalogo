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
				URI.open(origen){|f|  Archivo.open(destino, "wb"){|file| file.puts f.read }} 
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

class Web
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
		
		def imagenes(imagenes,tamaño=512)
			imagenes.each.with_index do |imagen, i|
				origen  = "https://jumboargentina.vteximg.com.br/arquivos/ids/#{imagen}-#{tamaño}-#{tamaño}"
				destino = "fotos/#{imagen}.jpg"
				unless File.exist?(destino)
					print(".")
					puts if i % 100 == 0
					puts origen if ! File.download(origen, destino)
				end
			end
			puts "FIN"
		end
	end
end

# pp Web.clasificacion.map(&:departamento).uniq.sort
# Archivo.escribir( Web.clasificacion(), :clasificacion)
# pp File.read(:productos).map{|x|x[:departamento]}.uniq
a = Archivo.fotos.map(&:to_num).sort
productos = Archivo.leer(:productos).select{|x|incluir(x)}
b = productos.map{|x|x.imagen}.sort
p a.first(10)
p b.first(10)
p (a.first(10) - b.first(10))
(a.first(10) - b.first(10)).each{|imagen| Archivo.borrar("fotos/#{imagen}.jpg")}
return

clasificacion =  Web.clasificacion()
productos = Web.productos(clasificacion)
Archivo.escribir(productos, :productos)
imagenes = productos.map{|x|x[:imagen]}
p Web.imagenes(imagenes)

