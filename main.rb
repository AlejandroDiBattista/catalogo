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

	def comparar(otro)
		puts "\nCAMBIOS"

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

		# pp( {total:t, nuevo:n, viejo:v, altas:altas.count, igual: igual.count, bajas: bajas.count, cambios:cambios.count, precio_promedio: t / igual.count })

		puts "Variacion > N: %7.2f  (V: %7.2f + %3.1f%%) (T: %7.2f * %3.1f%%  >> %3.1f%%)" % [n, v , 100*(n/v-1), t, 100 * (n / t), 100 * ((n - v) / t)]
		cambios.listar 

		puts "ALTAS"
		altas.listar 

		puts "\nBAJAS"
		bajas.listar 
	end

	def self.analizar(base)
		nuevo = Catalogo.leer(base, -1)
		viejo = Catalogo.leer(base, -4)
		nuevo.comparar(viejo)
	end
end

p Catalogo.leer(:jumbo).precio_promedio
p Catalogo.leer(:tatito).precio_promedio
p Catalogo.leer(:maxiconsumo).precio_promedio

p Catalogo.analizar(:tatito)