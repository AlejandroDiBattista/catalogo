class Maxiconsumo < Web
	#imagen: 		'/catalog/product/view/id/',
	# http://maxiconsumo.com/sucursal_capital/catalog/product/view/id
	def get_url 
		{ 
			base:			'http://www.maxiconsumo.com/sucursal_capital', 
			clasificacion: 	'/', 
			productos: 		'/*', 
		  	producto: 		'http://maxiconsumo.com/sucursal_capital/catalog/product/view/id/*?product_list_limit=96', 
		  	imagen: 		'http://maxiconsumo.com/pub/media/catalog/product/cache/*'
		}
	end
	# http://maxiconsumo.com/sucursal_capital/catalog/product/view/
	def get_selector
		{ 
			productos: 		'.product-item-info', 
			nombre: 		'a.product-item-link', 
			precio: 		'.price', 
			producto: 		'a.product-item-link',
		}
	end

	def bajar_clasificaciones
		Archivo.abrir(ubicar(:clasificacion)) do |pagina|
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

	def imagen(item)
		extraer_img(item.css('.image'))
	end

	def incluir(item)
		validos = ['Perfumeria', 'Fiambreria', 'Comestibles', 'Bebidas Con Alcohol', 'Bebidas Sin Alcohol', 'Limpieza']
		departamento = item.rubro.split('>').first.strip
		validos.include?(departamento)	
	end

end