require_relative 'utils'
require_relative 'archivo'
require_relative 'web'

Campos = [:nombre, :precio, :rubro, :unidad, :url_producto, :url_imagen, :id, :anterior, :texto, :precio_1, :precio_2]

class Producto < Struct.new(*Campos)
	
	def self.cargar(datos)
		new.tap{|tmp| Campos.each{|campo| tmp[campo] = datos[campo]}}.normalizar
	end

	def to_hash
		Hash[Campos.map{|campo|[campo, self[campo]]}]
	end

	def normalizar
		self.nombre = (self.nombre||"").espacios
		self.rubro  = (self.rubro||"").espacios
		self.precio = self.precio.to_f

		self.url_producto = nil if self.url_producto.vacio?
		self.url_imagen = nil 	if self.url_imagen.vacio?

		self.id =  nil 			if self.id.vacio?
		self.anterior = 0

		self.texto ||=  [
			self.nombre, self.rubro, self.precio, self.unidad, 
			self.nombre.tag(:nombre), self.rubro.tag(:rubro), self.precio.tag(:precio), self.url_imagen.tag(:foto), 
			self.error?.tag(:error),
			self.id,
		].map{|x|x.to_s.espacios}.join(' ')

		self
	end

	def categoria
		rubro.from_rubro.first
	end

	def niveles
		rubro.from_rubro.count
	end

	def nivel(n)
		n <= niveles ? rubro.from_rubro[0...n] : nil
	end

	def error?
		self.nombre.vacio? || self.rubro.vacio? || self.precio.vacio? || self.url_imagen.vacio? 
	end

	def contiene(condicion)
		alternativas = condicion.espacios.split(' o ')
		alternativas.any? do |palabras|
			palabras = palabras.gsub(' y ', '')
			palabras.split(' ').all? do |palabra|
				operador, valor = palabra.scan(/([-+:<>\/])?(.*)/).first
				case operador 
					when '-' then !contiene(valor)
					when '<' then self.precio <= valor.to_f
					when '>' then self.precio >= valor.to_f
					when '/' then /\b#{valor}/i === self.rubro
					when ':' then /\b#{valor}\b/i === self.texto
					else  /\b#{palabra}/i === self.texto 
				end
			end
		end
	end

	def precio_n(cantidad=1)
		return self.precio if cantidad == 1 
	end
end

class Catalogo
	attr_accessor :base 
	include Enumerable 
	
	def initialize(base, productos=[])
		@base, @datos = base, {}
		agregar(productos)
	end

	def datos()
		@datos ||= {}
	end

	def self.leer(base, posicion=nil)
		if posicion 
			origen = listar(base, :productos)[posicion]
		else
			origen = [base, :productos]
		end
		lista = Archivo.leer(origen).sort_by(&:rubro)
		new(base, lista)
	end

	def escribir(tipo = :dsv)
		datos = filtrar{|x|!x.error?}.datos.values.sort_by(&:rubro)
		Archivo.escribir(datos, [@base, "productos.#{tipo}"])
	end
	

	def agregar(*productos)
		[productos].flatten.each do |producto|
			producto = Hash === producto ? Producto.cargar(producto) : producto
			@datos[producto.id] = producto
		end
		self 
	end

	def each()
		datos.values.each{|producto| yield(producto) }
	end

	def buscar(producto)
		id = Producto === producto ? producto.id : producto
		find{|x| x.id == id }
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

	def precio_promedio
		sum(&:precio) / count
	end

	def categorias
		map(&:categoria).uniq.sort 
	end
	
	def rubros
		map(&:rubro).uniq.sort 
	end
	
	def comparar(otro, verboso)
		altas = self - otro
		bajas = otro - self
		igual = self - bajas - altas 

		igual.each{|n| n.anterior = otro.buscar(n.id).precio }
		cambios = igual.filtrar{|n| (n.anterior - n.precio).abs > 1.0}
	
		t = igual.sum(&:precio)
		v = cambios.sum(&:precio)
		n = cambios.sum(&:anterior)

		inf = 100.0 * (n - v) / t 

		puts "%-20s A: %5i  B: %5i  M: %5i  T: %5i >  Inf: %6.2f%%" % [base, altas.count, bajas.count, cambios.count, count, inf]
		if verboso
			puts "ALTAS"
			altas.listar

			puts "\nCAMBIOS"
			cambios.listar

			puts "\nBAJAS"
			bajas.listar
		end
	end

	def self.analizar(base, dias=1, verboso=false)
		for d in 2..dias
			nuevo = Catalogo.leer(base, -d+1)
			viejo = Catalogo.leer(base, -d)
			print "#{d} dia  "
			nuevo.comparar(viejo, verboso)
		end
		nuevo = Catalogo.leer(base, -1)
		viejo = Catalogo.leer(base, -dias)
		print "Semana:"
		nuevo.comparar(viejo, verboso)
		puts
	end

	def resumir(nivel=nil, n=1)
		if !nivel 
			puts "  RESUMEN [#{@base.capitalize}]                                                                          ".yellow.on_red
			nivel, n = "Productos", 1
		end
		puts ("%s%-88s   %4i   $ %6.2f" % ["  " * n, nivel, count, precio_promedio]).colorize([:green, :yellow, :cyan, :white][n-1])

		map{|x| x.nivel(n) }.compact.uniq.each do |nivel|
			filtrar{|x| x.nivel(n) == nivel}.resumir(nivel.last, n + 1)
		end
	end


	def listar_productos(*busqueda)
		busqueda = [busqueda].flatten.map(&:to_s).join(' ').espacios
		datos = filtrar{|x| x.contiene(busqueda) }
		puts 

		puts (" %-85s %4i  %6.2f " % ["Productos para '#{busqueda}'", datos.count, datos.precio_promedio]).on_blue.white

		anterior = []
		datos.each do |x|
			actual = x.rubro.from_rubro
			if actual != anterior
				# pp actual
				mostrar = false 
				actual.each_with_index do |valor, nivel|
					mostrar ||= valor != anterior[nivel]
					puts (" %s  %s " % ["  " * nivel, valor]).colorize([:green, :yellow, :cyan][nivel]) if mostrar 
				end
			end
			puts " %s  %-80s    %6.2f %s" % ["  " * actual.count, x.nombre, x.precio, (x.error? ? '*' : ' ').red]
			anterior = actual
		end
	end

end

# [:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre|	Catalogo.analizar(nombre, 7) }
[:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre| Catalogo.leer(nombre).filtrar{|x| !x.error? }.escribir}

t = Catalogo.leer(:tatito)
a = t.first 
pp a 
return 
# t -= t.filtrar{|x|x.error?}
# t.escribir(:json)
# t.escribir(:dsv)
# t.resumir 
t.listar_productos 'mermelada'

