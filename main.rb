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

	def categoria
		rubro.split(">").first
	end

	def niveles
		rubro.from_rubro.count
	end

	def nivel(n)
		rubro.from_rubro[0...n]
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

	# def agrupar(lista)
	# 	valores = lista.map{|r, i| r.first }.compact.uniq 
	# 	return lista.map{|r,i| i } if valores.count == 0
	# 	valores.map do |valor|
	# 		items = lista.select{|r,_| r.first == valor }
	# 		items = items.map{|r,i| [ r[1..-1], i ] }
	# 		[valor, agrupar( items )].compact
	# 	end
	# end

	# i = 0
	# lista = map{|x| [x.nivel(10), i+=1] }
	# lista = agrupar(lista)
	# mostrar_grupo(lista)

	def resumir
		puts (" %-60s   %4i   $ %6.2f" % ["Resumen [#{@base.capitalize}]", count, precio_promedio]).green
		map{|x|x.nivel(1)}.uniq.each do |n1|
			d2 = filtrar{|x| x.nivel(1) == n1 }
			if d2.any?
				puts ("   %-60s   %4i   $ %6.2f" % [n1.last, d2.count, d2.precio_promedio]).yellow
				d2.map{|x|x.nivel(2)}.uniq.each do |n2|1
					d3 = filtrar{|x| x.nivel(2) == n2  && x.niveles >= 2}
					if d3.any?
						puts ("     %-60s   %4i   $ %6.2f" % [n2.last, d3.count, d3.precio_promedio]).cyan
						d3.map{|x|x.nivel(3)}.uniq.each do |n3|
							d4 = filtrar{|x| x.nivel(3) == n3 && x.niveles >= 3}
							if d4.count > 0 
								puts ("       %-60s   %4i   $ %6.2f" % [n3.last, d4.count, d4.precio_promedio]).white 
							end
						end
					end
				end
			end
		end
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
end


[:tatito, :maxiconsumo, :jumbo, :tuchanguito].each{|nombre|	Catalogo.analizar(nombre, 7) }

t = Catalogo.leer(:tuchanguito)
t.resumir 
pp t.map(&:niveles).ranking
