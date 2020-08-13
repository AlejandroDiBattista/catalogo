require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'

class Yatito
	def carpeta
		self.class.to_s.downcase
	end

	def bajar_todo
		clasificaciones = bajar_clasificacion()
		clasificaciones.procesar{|clasificacion| clasificacion[:productos] = bajar_rubro(clasificacion[:id]) }
		productos = clasificaciones.map do |clasificacion|
			clasificacion[:productos].map do |item|
				{ categoria: clasificacion[:categoria], rubro: clasificacion[:rubro], id: clasificacion[:id], producto: item}
			end
		end.flatten
		productos.procesar(50){|producto| bajar_producto(producto) }
		Archivo.escribir(productos, [:yatito, :productos])
		bajar_imagenes(productos)
	end

	def bajar_clasificacion
		url = ubicar(:clasificacion)
		rubros = [nil, nil]
		Archivo.abrir(url) do |pagina|
			return pagina.css('#checkbox_15_2 option').map do |x|
				rubro = x.text.strip
				nivel = rubro[0..0] == "-" ? 1 : 0
				rubros[nivel] = rubro.gsub(/^-\s*/,"").strip
				id = x["value"].to_i
				nivel == 1 ? { categoria: rubros[0], rubro: rubros[1], id: id } : nil 
			end.compact
		end
	end

	def bajar_rubro(rubro)
		productos, paginas = *extraer_productos(rubro, 1)
		productos << extraer_productos(rubro, 2).first if paginas 
		productos.flatten
	end

	def bajar_producto(item)
		Archivo.abrir(item[:producto]) do |page|

			item[:titulo]   = page.css(".product_title").text
			item[:detalle]  = page.css(".woocommerce-product-details__short-description p").map(&:text).join("/")
			item[:sku] 	    = page.css(".sku").text
			item[:imagen]  = page.css(".woocommerce-product-gallery__image img").first["src"]

			precios = extraer_precios(page)

			item[:regla_1]  = precios[0][0]   
			item[:precio_1] = precios[0][1] 
			
			if precios.size > 1
				item[:regla_2]  = precios[1][0] 
				item[:precio_2] = precios[1][1] 
			end
			if precios.size > 2
				item[:regla_3]  = precios[2][0]
				item[:precio_3] = precios[2][1] 
			end
		end
	end

	def bajar_imagenes(productos, forzar=false)
		puts "Bajando #{productos.count} imagenes"
		productos.procesar do |producto|
			origen  = producto[:imagen]
			destino = "#{carpeta}/fotos/#{producto[:sku]}.jpg"
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def extraer_precios(page)
		precios = page.css(".price-rules-table tbody tr").map{|x|[x.css("span").first.text, x.css(".woocommerce-Price-amount").text]}
		if precios.size == 0 
			["1+", page.css(".woocommerce-Price-amount").text]
		else
			precios
		end
	end

	def key(producto)
		"#{producto.nombre.to_key}-#{producto.url_producto.to_key}-#{producto.url_imagen.to_key}-#{producto.rubro.to_key}"
	end

	def self.muestra(breve=true)
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

	def self.leer
		base = new.carpeta 
		Archivo.leer("#{base}/productos.dsv")
	end


	def href(item)
		!item.nil? && !item.first.nil? && item.first[:href] || ""
	end

	def src(item)
		item && item.first && item.first[:src] || ""
	end
	
	URL = "http://tatito.com.ar/tienda"
	URL_Rubro  = "http://tatito.com.ar/tienda/page/%i/?filters=product_cat[%i]"
	URL_Productos = "http://tatito.com.ar/producto"

	URL_Imagenes  = "http://tatito.com.ar/wp-content/uploads"

	def ubicar(modo = :clasificacion, valor = nil, pagina=1)
		case modo
		when :clasificacion
			URL
		when :rubro
			URL_Rubro % [pagina, valor]
		when :producto
			"#{URL_Producto}#{valor}"
		when :imagen 
			"#{URL_Imagenes}#{valor}"
		end
	end
		
	def varias_paginas(pagina)
		pagina.css(".pagination").count > 0 
	end

	def hay_productos(pagina)
		!pagina.css(".column_attr").last.text["No se encontraron productos"]
	end

	def extraer_productos(rubro, pagina)
		Archivo.abrir( ubicar(:rubro, rubro, pagina) ) do |page|
			return [ [], false ] unless hay_productos(page)
			begin
				[ page.css(".item_tienda .titulo_producto a").map{|x| x[:href] }, varias_paginas(page) ]
			rescue Exception => e
				puts "ERROR #{e}"			
				[ [], false ]
			end
		end
	end

	
end

puts "COMENZANDO"
y = Yatito.new
a = y.bajar_todo