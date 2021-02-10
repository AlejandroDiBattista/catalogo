require_relative 'utils'
require_relative 'archivo'
require_relative 'web'
require_relative 'producto'

class Catalogo
	include Enumerable 
	attr_accessor :base, :datos, :productos, :ordenados
	
	def initialize(base, productos=[])
		@base, @datos, @productos, @ordenados = base, {}, [], false 
		agregar(productos)
	end

	def escribir(tipo: :dsv)
		Archivo.escribir(self, [base, "productos.#{tipo}"])
	end

	def guardar()
		ordenar!
		Archivo.escribir(compactar, [base, 'catalogo.json'])
	end
	
	def agregar(*items, fecha: nil)
		fecha ||= Date.today 
		[items].flatten.each do |producto|
			if producto = Producto.cargar(producto) 
				producto.id = nil
				if anterior = datos[producto.key]
					producto.id = anterior.id 
					producto.historia = anterior.historia
				end
				producto.actualizar(fecha, producto.precio)
				datos[producto.key] = producto
			end
			ordenados = false
		end
		self
	end

	def completar_id(regenerar=false)
		aux = datos.values 
		aux.each{|producto|producto.id = nil} if regenerar 
		ultimo = aux.map(&:id).compact.max || '00000'
		aux.select{|producto| producto.id.nil? }.sort_by(&:key).each do |producto|
			producto.id = (ultimo = ultimo.succ)
			self.ordenados = false 
		end
	end

	def ordenar!(regenerar=false)
		completar_id(regenerar)
		n = datos.values.count{|producto|producto.id.nil?}
		puts "Hay #{n} productos sin ID" if n > 0 
		return if ordenados 
		self.productos = datos.values.sort_by(&:id)
		self.ordenados = true
	end

	def each
		ordenar!
		productos.each{|producto| yield(producto) }
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

	def listar
		map{|x|{nombre: x.nombre, precio: x.precio, rubro: x.rubro, id: x.id, anterior: x.anterior}}.sort_by(&:nombre).listar("Listado #{@base}", 1000)
		self 
	end

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

	def analizar_cambios(otro, verboso)
		altas = self - otro
		bajas = otro - self
		igual = self - bajas - altas 

		igual.each{|n| n.anterior = otro.buscar(n.id).precio }
		cambios = igual.filtrar{|n| (n.anterior - n.precio).abs > 1.0}
	
		t = igual.sum(&:precio)
		v = cambios.sum(&:precio)
		n = cambios.sum(&:anterior)

		inf = 100.0 * (n - v) / t 

		puts "%-20s A: %5i  B: %5i  M: %5i  T: %5i > Inf: %6.2f%%" % [base, altas.count, bajas.count, cambios.count, count, inf]
		if verboso
			puts "ALTAS"
			altas.listar

			puts "\nCAMBIOS"
			cambios.listar

			puts "\nBAJAS"
			bajas.listar
		end
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
      salida = []
		anterior = []
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

	def ultima_actualizacion
		map{|x|x.historia.last}.compact.map(&:hasta).max 
	end

	def activos
		fecha = ultima_actualizacion
		filtrar{|x|x.historia.last[:hasta] == fecha}
	end

	
	class << self 
		def cargar(base)
			base = base.name if Class === base 
			new(base, Archivo.leer_json([base, 'catalogo.json']))
		end

		def leer(base, posicion=0)
			base = base.name if Class === base
			origen = listar(base, 'productos*.dsv')[posicion]
        	tmp  = new(base, Archivo.leer(origen))
        	tmp -= tmp.filtrar(&:error?)
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
			base = base.name if Class === base
			tmp = new(base)
			Archivo.listar(base, 'productos_*.dsv').sort.each do |origen|
				fecha = Archivo.extraer_fecha(origen)
				tmp.each{|producto| producto.actualizar(fecha) }
				
				nuevos = Archivo.leer(origen)
				nuevos.each{|producto| producto.id = nil}

				tmp.agregar(nuevos, fecha: fecha)
				tmp.ordenar!

				puts " > #{fecha} x #{nuevos.count} > #{tmp.count}"
			end
			tmp
		end
		
		def actualizar(base)
			t = Catalogo.cargar(base)
			t.agregar(base.bajar)
			t.guardar
			t 
		end
	end
end

if __FILE__ == $0
	medir "Cargando [Tatito]" do 
		[Tatito, TuChanguito, Jumbo, Maxiconsumo].each{|base| Catalogo.cargar_todo(base).guardar }
	end
	# [Tatito, TuChanguito, Jumbo, Maxiconsumo].each{|base| Catalogo.actualizar(base)}
end