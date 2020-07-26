require_relative 'utils'
require_relative 'archivo'
require_relative 'web'

Campos = [:nombre, :precio, :rubro, :unidad, :url_producto, :url_imagen, :id]

class Producto < Struct.new(*Campos)
	def self.cargar(datos)
		new.tap{|tmp| Campos.each{|campo| tmp[campo] = datos[campo]}}.normalizar
	end

	def to_hash
		Hash[Campos.map{|campo|[campo, self[campo]]}]
	end

	def normalizar
		self.precio = self.precio.to_f
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
		@base  = base
		@datos = []
		agregar(productos)
		self
	end

	def agregar(*productos)
		[productos].flatten.each do |producto|
			@datos << (Hash === producto ? Producto.cargar(producto) : producto)
		end
	end

	def datos()
		@datos ||= []
	end

	def each()
		datos.each{|producto| yield(producto) }
	end

	def filtrar()
		self.class.new(@base, select{|x|yield x})
	end

	def sumar(otro)
		new(@base, (datos + otro.datos).uniq)
	end

	def restar(otro)
		new(@base, (datos - otro.datos).uniq)
	end

	def listar
		map{|x|{nombre: x.nombre, precio: x.precio, rubro: x.rubro, id: x.id}}.sort_by(&:nombre).listar("Listado #{@base}")
	end

	def nombres
		map(&:nombre).uniq.sort 
	end

	def buscar(id)
		find{|x|x.id == id}
	end

	def comparar(otro)
		puts "ALTAS"
		filtrar{|x| !otro.buscar(x.id)}.listar 

		puts "\nBAJAS"
		otro.filtrar{|x| !buscar(x.id)}.listar 

		puts "\nCAMBIOS"
		datos = filtrar{|x| otro.buscar(x.id)}
		datos.each{|x| x.precio -= otro.buscar(x.id).precio}
		datos.filtrar{|x| x.precio != 0}.listar 

	end
	def self.analizar(base)
		viejo = Catalogo.leer(base, -2)
		nuevo = Catalogo.leer(base, -1)
		nuevo.comparar(viejo)
	end
end


# Catalogo.analizar(:maxiconsumo)
a = Catalogo.leer(:maxiconsumo).filtrar{|x|x.id == "00181"}
a.escribir

