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

	def nombres
		map(&:nombre).uniq.sort 
	end
end


class String
	def espacios
		strip.gsub(/\s+/," ")
	end

	def terminacion
		%w{x pack botella bot cja paq}.each do |x| 
			puts x
			gsub!(/-\s*$/,"")
			gsub!(/\b#{x}\s*$/i, " #{x} ")
			gsub!(/-\s*$/,"")
		end
		espacios
	end

	def limpiar
		gsub!("unidades", " un ")
		gsub!(/\bu\b/i, " un ")
		%w{ml gr cc kg un lt}.each{|x| gsub!( /\b#{x}\.?-?/i, " #{x} ")}
		espacios
	end

	def separar_unidad
		tmp = limpiar
		if a = tmp.match(/^(.+?)(ml|cc|kg|gr|un|lt)\s([1-9][0-9.,]*)$/i)
			[a[1].terminacion, "#{a[3]} #{a[2]}" ] 
		elsif a = tmp.match(/^(.+?)([1-9][0-9.,]*.*)$/i)
			[a[1].terminacion, a[2]]
		# elsif a = tmp.match(/^(.+)\s(por|x)\s\b(kg|k|kilo|kilogramos)\b.*$/i)
		# 	[a[1], "1 kg"]
		else
			[tmp, nil]
		end

	end
end

a = "Cera Líquida Para Madera Suiza-roble Oscuro-tradicional-bot"

x = "bot"
p a.gsub( /\b#{x}\.?-?/i, " #{x} ")
p a.terminacion
return

n = Catalogo.leer(:jumbo).nombres
n = n.select{|x| /-/ === x}.map{|x| [x, x.separar_unidad ].flatten}
# n = n.select{|x| /^\d+$/ === x.last }
n.each{|x|puts "%-80s %-80s %-40s" % x}
puts "----"
return
n = n.map(&:separar_unidad)
n = n.select{|a, b| b }
n = n.uniq#.select {|x| x[/\d/]  }

pp n 
p n.size