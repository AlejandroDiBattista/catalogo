$stdout.sync = true

require 'nokogiri'
require 'JSON'
require 'open-uri'
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

	def self.leer(base)
		lista = Archivo.leer([base, :productos])
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
		new(@base, select{|x|yield x})
	end

	def sumar(otro)
		new(@base, (datos + otro.datos).uniq)
	end

	def restar(otro)
		new(@base, (datos - otro.datos).uniq)
	end

	def listar
		map{|x|{nombre: x.nombre, precio: x.precio, rubro: x.rubro}}.sort_by(&:nombre).listar("Listado #{@base}")
	end
end


if true
	# Jumbo.muestra
	# Tatito.muestra
	# Maxiconsumo.muestra
	return 
end

if true
	a = Catalogo.leer(:maxiconsumo).map{|x|x.nombre}
	b = a.map(&:separar_unidad).sort_by(&:first)
	b.select{|x|x.last}.map(&:last).uniq.sort.each{|x|pp x}
	return
end


j = Jumbo.new

puts "REGISTRANDO"
Archivo.buscar("jumbo/producto", :todo).each do |origen|
	productos = Archivo.leer(origen)
	j.registrar(productos)
	puts " > #{origen} #{productos.count{|x|x[:id].vacio?}}"
end
puts "Hay #{j.registrados}"
puts "COMPLETANDO"

Archivo.buscar("jumbo/producto", :todo).reverse.each do |origen|
	productos = Archivo.leer(origen)
	vacios = productos.select{|x|x[:id].vacio?}
	vacios.each_slice(10) do |lista|
		j.completar(lista)
		Archivo.escribir(productos, origen)
	end
end
return 

n = Jumbo.leer.map(&:nombre).uniq
n = n.select{|x| !separar(x).last }
n = n.select{|x| /d/ === x }

# pp n.map{|x|separar(x).first}.first(20)
puts n.first(20)
