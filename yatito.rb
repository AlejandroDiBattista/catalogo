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
		rubros = [nil, nil]
		Archivo.abrir("http://tatito.com.ar/tienda") do |pagina|
			return pagina.css('#checkbox_15_2 option').map do |x|
				rubro = x.text.strip
				nivel = rubro[0..0] == "-" ? 1 : 0
				rubros[nivel] = rubro.gsub(/^-\s*/,"").strip
				id = x["value"].to_i
				nivel == 1 ? { categoria: rubros[0].espacios, rubro: rubros[1].espacios, id: id } : nil 
			end.compact
		end
	end

	def bajar_rubro(rubro, pagina = 1)
		url = "http://tatito.com.ar/tienda/page/%i/?filters=product_cat[%i]" % [pagina, rubro]
		productos = []
		Archivo.abrir(url) do |page|
			if  hay_productos(page)
				productos = page.css(".item_tienda .titulo_producto a").map{|x| x[:href] } 
				productos += bajar_rubro(rubro, pagina + 1) if page.css(".pagination").count > 0  
			end
		end
		productos
	end

	def bajar_producto(item)
		Archivo.abrir(item[:producto]) do |page|
			item[:titulo]   = page.css(".product_title").text
			item[:detalle]  = page.css(".woocommerce-product-details__short-description p").map(&:text).join("/")
			item[:sku] 	    = page.css(".sku").text.to_sku
			item[:imagen]   = page.css(".woocommerce-product-gallery__image img").first["src"]

			precios = extraer_precios(page)

			item[:regla_1 ] = precios[0][0]   
			item[:precio_1] = precios[0][1].to_money
			
			if precios.size > 1
				item[:regla_2 ] = precios[1][0] 
				item[:precio_2] = precios[1][1].to_money 
			end
			if precios.size > 2
				item[:regla_3 ] = precios[2][0]
				item[:precio_3] = precios[2][1].to_money 
			end
		end
		item 
	end

	def bajar_imagenes(productos, forzar=false)
		puts "Bajando #{productos.count} imagenes"
		productos.procesar do |producto|
			origen  = producto[:imagen]
			destino = "#{carpeta}/fotos/#{producto[:sku]}.jpg"
			Archivo.bajar(origen, destino, forzar)
		end
	end

	def hay_productos(pagina)
		!pagina.css(".column_attr").last.text["No se encontraron productos"]
	end

	def extraer_precios(page)
		precios = page.css(".price-rules-table tbody tr").map{|x|[x.css("span").first.text, x.css(".woocommerce-Price-amount").text]}
		if precios.size == 0 
			["1+", page.css(".woocommerce-Price-amount").text]
		else
			precios
		end
	end

	def self.leer
		Archivo.leer([:yatito, :productos])
	end

end

y = Yatito.new
a = y.bajar_todo
# pp y.bajar_producto({producto: "http://tatito.com.ar/producto/alfajor-dolche-patagonia-negro-60-grs/"})
# a = Yatito.leer 
# p a.map(&:sku).repetidos