class Jumbo < Web
	Tamaño = 512

	def get_url
		{ 
			base: 			'https://www.jumbo.com.ar', 
			clasificacion: 	'/api/catalog_system/pub/category/tree/3', 
			productos: 		'/*?PS=199', 
			producto: 		'/*/p', 
			imagen: 		'https://jumboargentina.vteximg.com.br/arquivos/ids/*', 
		}
	end

	def get_selector
		{ 
			productos: 		'.product-shelf li', 
			nombre: 		'.product-item__name > a', 
			marca: 			'.product-item__brand',
			precio: 		'.product-prices__value--best-price', 
			precio_unitario:'.product-prices__price--price-per-unit',
			producto: 		'.product-item__name a'
		}
	end

	def bajar_clasificaciones()
		datos = JSON(URI.open(ubicar(:clasificacion)).read).normalizar
		# datos = Archivo.leer_json(:clasificacion).normalizar
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

	def imagen(item)
		if item = item.css('.product-item__image-link img')
			if url = extraer_img(item)
				url = url.split('/').first if url
				url = url.split('-').first if url 
				url && "#{url}-#{Tamaño}-#{Tamaño}" 
			end
		end
	end

	def incluir(item)
		validos = ['Almacén', 'Bebidas', 'Pescados y Mariscos', 'Quesos y Fiambres', 'Lácteos', 'Congelados', 'Panadería y Repostería', 'Comidas Preparadas', 'Perfumería', 'Limpieza']
		departamento = item.rubro.split(">").first.strip
		validos.include?(departamento)	
	end

end