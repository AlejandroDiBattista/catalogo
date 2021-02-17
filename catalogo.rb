require_relative 'utils'
require_relative 'archivo'
require_relative 'web'
require_relative 'producto'

class Catalogo
	include Enumerable 
	attr_accessor :base, :datos, :productos, :ordenados
	
	def initialize(base, productos=[])
		@base, @datos, @productos, @ordenados = base, {}, [], false 
		productos.each do |producto|
			producto = Producto.cargar(producto)
			self.datos[producto.key] = producto
		end
		ordenar!
	end

	def escribir(tipo: :dsv)
		Archivo.escribir(self, [base, "productos.#{tipo}"])
		self
	end

	def guardar()
		ordenar!
		Archivo.escribir(self, [base, 'catalogo.json'])
		self
	end
	
	def agregar(*items, fecha: nil)
		fecha ||= Date.today 
		items = [items].flatten
		items.each do |producto|
			if producto = Producto.cargar(producto) 
				producto.id = nil
				if anterior = self.datos[producto.key]
					producto.id = anterior.id
					producto.historia = anterior.historia
				end
				producto.actualizar(fecha, producto.precio)
				# puts "> #{producto.key} > #{producto.id}"
				self.datos[producto.key] = producto
			end
			ordenados = false
		end
		self
	end

	def completar_id(regenerar=false)
		lista = datos.values 
		lista.each{|producto|producto.id = nil} if regenerar 
		return if lista.all?(&:id)
		ultimo = lista.map(&:id).compact.max || '00000'
		lista.select{|producto| producto.id.nil? }.sort_by(&:key).each do |producto|
			producto.id = (ultimo = ultimo.succ)
		end
		self.ordenados = false 
	end

	def ordenar!(regenerar=false)
		completar_id(regenerar)
		return if ordenados

		self.productos = self.datos.values.sort_by(&:id)
		self.ordenados = true
	end

	def each
		ordenar!
		self.productos.each{|producto| yield(producto) }
	end

	def buscar(producto)
		id = producto.is_a?(Producto) ? producto.id : producto
		datos[id]
	end

	def filtrar()
		self.class.new(@base, select{|producto| yield(producto) })
	end
	
	def +(otro)
		self.class.new(@base, datos.values).agregar(otro.values)
	end
	alias :sumar :+ 

	def -(otro)
		self.class.new(@base, select{|x| !otro.buscar(x) })
	end
	alias :restar :-

	def nombres
		map(&:nombre).uniq.sort 
	end

	def categorias
		map(&:categoria).uniq.sort 
	end
	
	def rubros
		map(&:rubro).uniq.sort 
	end

	def precio_promedio
		promedio(&:precio)
	end

	def precio_promedio_oferta
		promedio(&:precio_oferta) 
	end

	def variacion_promedio
		promedio(&:variacion)
	end

	def resumir(nivel=nil, n=1)
		if !nivel 
			puts " RESUMEN [#{@base.capitalize}]                                                                          ".yellow.on_red
			nivel, n = "Productos", 1
		end
		puts("%s%-88s   %4i   $ %6.2f" % ["  " * n, nivel, count, precio_promedio]).colorize([:green, :yellow, :cyan, :white][n-1])

		map{|x| x.nivel(n) }.compact.uniq.each do |nivel|
			filtrar{|x| x.nivel(n) == nivel}.resumir(nivel.last, n + 1)
		end
	end

	def listar_productos(busqueda, verboso=false)
		datos = filtrar{|x| x.contiene(busqueda) }
		
		puts (" %-12s | %-66s | %4i  %6.2f   %6.2f %s  " % [datos.base.upcase, verboso ? "Productos para '#{busqueda}'" : '', datos.count, datos.precio_promedio, datos.precio_promedio_oferta, datos.variacion_promedio.to_porcentaje]).on_green.black

		anterior = []
		datos.sort_by(&:nombre).each do |x|
			actual = x.rubro.from_rubro
			if actual != anterior
				mostrar = false 
				actual.each_with_index do |valor, nivel|
					mostrar ||= valor != anterior[nivel]
					puts (" %s  %s " % ["  " * nivel, valor.upcase]).colorize([:green, :yellow, :cyan][nivel]) if mostrar 
				end
			end
			oferta = x.precio_oferta < x.precio ?  x.precio_oferta.to_precio : "      "
			cambio = x.variacion.abs > 0.01 && x.variacion.abs < 0.5 ? x.variacion.to_porcentaje : ""
			cambio = cambio.colorize(x.variacion < 0 ? :green : :red)
			puts " %s  %-80s    %6.2f %s %s %s" % ["  " * actual.count, x.nombre, x.precio, (x.error? ? '*' : ' ').red, oferta.cyan, cambio]
			anterior = actual
		end
	end

    def generar_datos
		anterior = []
      	salida = []
		sort_by{|x|[x.rubro, x.nombre]}.each do |x|
			actual = x.rubro.from_rubro
			if actual != anterior
				if salida.last
					salida.last.titulos.last.titulo += " (#{salida.last.productos.count} unidades)" 
				end
				salida << { titulos: [], productos: [] }
				mostrar = false
				actual.each_with_index do |valor, nivel|
					mostrar ||= valor != anterior[nivel]
					salida.last.titulos << { nivel: nivel + 1, titulo: valor } if mostrar
				end
			end
			anterior = actual
			salida.last.productos << { id: x.id, nombre: x.nombre, precio: x.precio, oferta: x.precio_oferta, variacion: x.variacion , url_imagen: "fotos/#{x.id}.jpg" }
		end
    	salida
	end

	def comparar(dias = 7)
		referencia = Catalogo.leer(base, -dias)
		each do |actual|
			if anterior = referencia.buscar(actual)
				actual.anterior = anterior.precio 
			else
				actual.anterior = nil 
			end
		end
	end

	def con_imagenes
		filtrar(&:tiene_foto)
	end

	def activos
		filtrar(&:activo?)
	end

	def bajar_imagenes
		lista = select{|producto| producto.id && !producto.url_imagen.vacio?}
		lista.procesar do |producto|
			origen  = Web.ubicar(:imagen, producto.url_imagen)
			destino = Web.nombre_foto(producto.id)
			Archivo.bajar(origen, destino, forzar)
		end

	end

	class << self 
		def cargar(base)
			new(base, Archivo.leer_json([base, 'catalogo.json']))
		end

		def leer(base, posicion=0)
			origen = listar(base, 'productos_*.dsv').sort()[posicion]
        	catalogo  = new(base, Archivo.leer(origen))
        	catalogo -= catalogo.filtrar(&:error?)
		end

		def analizar(base, dias=1, verboso=false)
			for d in 2..dias
				nuevo = Catalogo.leer(base, -d + 1)
				viejo = Catalogo.leer(base, -d)
				print "#{d} dia "
				nuevo.comparar(viejo, verboso)
			end
			nuevo = Catalogo.leer(base, -1)
			viejo = Catalogo.leer(base, -dias)
			print "Semana:"
			nuevo.analizar_cambios(viejo, verboso)
			puts
		end

		def cargar_todo(base)
			catalogo = new(base)
			Archivo.listar(base, 'productos_*.dsv').sort.each do |origen|
				fecha = Archivo.extraer_fecha(origen)
				catalogo.each{|producto| producto.actualizar(fecha) }
				
				nuevos = Archivo.leer(origen)
				nuevos.each{|producto| producto.id = nil}

				catalogo.agregar(nuevos, fecha: fecha)
				catalogo.ordenar!

				puts " > #{fecha} x #{nuevos.count} > #{catalogo.count} | #{origen}"
			end
			catalogo
		end

		def bajar_fotos(base)
			catalogo = Catalogo.cargar(base)
			puts "Hay #{catalogo.count} productos en #{base.name}"
			web = Web.crear(base)
			catalogo.activos.procesar do |producto| 
				web.bajar_foto(producto) 
				producto.tiene_foto = web.existe_foto?(producto)
			end	
			catalogo 
		end

		DestinoSitio = 'C:/Users/gogo/Documents/GitHub/mitienda/tienda'
		def generar_sitio(base=:tatito)
			 
			destino_seed = "#{DestinoSitio}/db/seeds.rb"
			destino_img  = "#{DestinoSitio}/app/assets/images"

			catalogo = Catalogo.bajar_fotos(base)
			catalogo = catalogo.activos.con_imagenes

			lineas = catalogo.map{|a| "Producto.create!(id: #{a.id.to_i}, nombre: '#{a.nombre}', clasificacion: '#{a.rubro}', precio: #{a.precio}, imagen_url: '#{a.id}.jpg')"}

			lineas.unshift "Productos.delette_all"

			puts lineas.first(3).join("\n")
			Archivo.escribir(lineas.join("\n"), destino_seed)
			Archivo.borrar([destino_img, '.'])
			Archivo.copiar("#{base}/fotos/*.jpg", destino_img)
		end

		def actualizar(base)
			catalogo = Catalogo.cargar(base)
			web = Web.crear(base) 
			catalogo.agregar(web.bajar)
			catalogo.guardar
			catalogo 
		end
	end
end

if __FILE__ == $0
	medir "Cargando TODO" do 
		bases = [ :tatito, :tu_changuito, :jumbo, :maxiconsumo]
		bases.each{|base| Catalogo.actualizar(base)}
		bases.each{|base| Catalogo.bajar_fotos(base)}
		Catalogo.generar_sitio :tatito
	end
end