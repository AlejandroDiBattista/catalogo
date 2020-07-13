require 'open-uri'
require 'json'
require 'nokogiri'
require 'csv'

def bajar_clasificacion()
	clasificacion = JSON(URI.open('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3').read)

	clasificacion.map do |d|
		d["children"].map do |c|
			if c["children"].size > 0
				c["children"].map{|s|  {departamento: d["name"], categoria: c["name"], subcategoria: s["name"], url: s["url"]} }
			else
				{departamento: d["name"], categoria: c["name"],  subcategoria: "-", url: c["url"]}
			end
		end
	end.flatten
end

def bajar_productos(clasificacion)
	productos = []
	clasificacion.each do |c|
		print c[:url]
		page = Nokogiri::HTML(URI.open(c[:url]+"?PS=99"))
		page.css('.product-shelf li').each do |x|
			if x.css(".product-item__name a").text.strip.size > 0 
				productos << {
					nombre:  x.css(".product-item__name a").text,
					marca:   x.css(".product-item__brand").text,
					precio:  x.css(".product-prices__value--best-price").text,
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

def leer_productos
	datos = CSV.read("productos.dsv", :col_sep => "|")
	campos = datos.shift.map(&:to_sym)
	datos.map{|x| Hash[campos.zip(x)]}
end

def escribir_productos(productos)
	campos = productos.map(&:keys).uniq.flatten
	CSV.open("productos.dsv", "wb", :col_sep => "|") do |csv|
		csv << campos
		productos.each{|x| csv << campos.map{|c|x[c]} }
	end
end

def bajar_imagenes(imagenes,tamaño=512)
	imagenes.each do |imagen|
		origen  = "https://jumboargentina.vteximg.com.br/arquivos/ids/#{imagen}-#{tamaño}-#{tamaño}"
		destino = "fotos/#{imagen}.jpg"
		unless File.exist?(destino)
			print("*")
			URI.open(origen){|f|  File.open(destino, "wb"){|file| file.puts f.read }} 
		else 
			print "."
		end
	end
	puts "FIN"
end


imagenes = leer_productos.map{|x|x[:imagen]}.select{|x|x.size > 4}
bajar_imagenes(imagenes)