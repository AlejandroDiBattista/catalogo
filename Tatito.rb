class Tatito < Web
	def get_url
		{ base: 'http://tatito.com.ar', clasificacion: '/tienda', productos: '/tienda/?filters=product_cat*', producto: '/producto/*', imagen: '/wp-content/uploads/*',}
	end

	def get_selector
		{ productos: '.item_tienda', nombre: '.titulo_producto a', precio: '.amount', producto: '.pad15 a',}
	end

	def bajar_clasificaciones 
		url = ubicar(:clasificacion)
		rubros = [nil, nil]
		Archivo.abrir(url) do |pagina|
			return pagina.css('select option').map do |x|
				rubro = x.text.gsub("\u00A0", ' ').gsub("\u00E9", 'é').strip 

				nivel = rubro[0..0] == '-' ? 1 : 0
				rubros[nivel] = rubro.gsub(/^-\s*/, '')
				id = x['value']
				nivel == 1 ?  { rubro: rubros.to_rubro, url: "[#{id}]" } : nil 
			end.compact
		end
	end

	def oferta(item, indice)
		item.css('.precio_mayor_cont').each_with_index do |x, i|
			if i + 1 == indice then
				cantidad, precio = *x.text.split('$')
				return '%s,%1.2f' % [cantidad.gsub(/\D/,'').to_i, precio.to_money]
			end
		end
		return nil 
	end
	
	def imagen(item)
		url = extraer_url(item.css('.pad15 a'), false)
		Archivo.abrir(url) do |pagina|
			aux = pagina.css('.woocommerce-product-gallery__image a')
			return extraer_url(aux)
		end
	end
end