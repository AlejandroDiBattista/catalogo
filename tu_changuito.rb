class TuChanguito < Web
	def get_url
		{ base: 'https://www.tuchanguito.com.ar', clasificacion: '/', productos: '/*', producto: '/productos/*', imagen: 'http://d26lpennugtm8s.cloudfront.net/stores/001/219/229/products/*', }
	end

	def get_selector
		{ productos: '.js-item-product', nombre: 'div.item-name',precio: '.item-price', producto: '.item-image a', }
	end

	def incluir(item)
		!item[:rubro][/ver todo/i] && !item[:rubro][/ofertas/i]
	end

	def bajar_clasificaciones
		url = ubicar(:clasificacion)
		Archivo.abrir(url) do |pagina|
			rubros = {}
			pagina.css('.nav-desktop-list li.nav-item-desktop').each do |x|
				if y = x.at('.nav-item-container')
					rubro = y.text.espacios
					x.css('.desktop-dropdown a').each{|y| rubros[y.text.espacios] = rubro }
				end 
			end
			salida = pagina.css('.nav-item-desktop a').map do |y|
				subrubro = y.text.espacios
				{ rubro: [rubros[subrubro], subrubro].to_rubro, url: acortar(y[:href]) }
			end
			rubros = rubros.values.uniq 
			return salida.select{|x| incluir(x) && !rubros.include?(x.rubro) }
		end
	end

	def imagen(item)
		url = acortar('http:' + item.css('.item-image img')[0]['data-srcset'].split(' ')[-2])
		url[/no-foto/i] ? nil : url 
	end
end