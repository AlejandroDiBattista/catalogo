require_relative 'utils'
require_relative 'archivo'
require_relative 'web'

Campos = [:nombre, :precio, :rubro, :unidad, :url_producto, :url_imagen, :id, :anterior]

class Producto < Struct.new(*Campos)
	def self.cargar(datos)
		new.tap{|tmp| Campos.each{|campo| tmp[campo] = datos[campo]}}.normalizar
	end

	def to_hash
		Hash[Campos.map{|campo|[campo, self[campo]]}]
	end

	def normalizar
		self.precio = self.precio.to_f
		self.anterior = 0
		self.url_producto = nil if self.url_producto.vacio?
		self.url_imagen = nil 	if self.url_imagen.vacio?
		self.id =  nil 			if self.id.vacio?
		self
	end
end

class Catalogo
	include Enumerable 

	attr_accessor :base 

	def self.leer(base, posicion=nil)
		if posicion 
			origen = listar(base, :productos)[posicion]
		else
			origen = [base, :productos]
		end
		lista = Archivo.leer(origen)
		new(base, lista)
	end

	def escribir()
		Archivo.escribir(self.datos.map(&:to_hash), [@base, :productos])
	end
	
	def initialize(base, productos=[])
		@base, @datos = base, {}
		agregar(productos)
	end

	def agregar(*productos)
		[productos].flatten.each do |producto|
			producto = Hash === producto ? Producto.cargar(producto) : producto
			@datos[producto.id] = producto
		end
		self 
	end

	def datos()
		@datos ||= {}
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
		map{|x|{nombre: x.nombre, precio: x.precio, rubro: x.rubro, id: x.id, anterior: x.anterior}}.sort_by(&:nombre).listar("Listado #{@base}",1000)
		self 
	end

	def nombres
		map(&:nombre).uniq.sort 
	end

	def precio_promedio
		sum(&:precio) / count
	end

	def comparar(otro,verboso)

		altas = self - otro
		bajas = otro - self
		igual = self - bajas - altas 

		cambios = igual.filtrar do |n| 
			v = otro.buscar(n.id) 
			n.anterior = v.precio
			(n.anterior - n.precio).abs > 1
		end
	
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
end

# p Catalogo.leer(:jumbo).precio_promedio
# p Catalogo.leer(:tatito).precio_promedio
# p Catalogo.leer(:maxiconsumo).precio_promedio

# Catalogo.analizar(:tatito, 7)
# Catalogo.analizar(:maxiconsumo, 7)
# Catalogo.analizar(:jumbo, 7)
# puts Archivo.listar(:tatito, :productos)[1..-1]

Web.new.cuando 