require_relative 'utils'
Campos = [:id, :nombre, :precio, :rubro, :url_imagen, :url_producto, :marca, :unidad, :precio_unitario, :precio_1, :precio_2, :precio_3]

class Producto < Struct.new(*Campos)
	attr_accessor :ofertas, :historia, :texto, :anterior

	def self.cargar(datos)
		datos = datos.normalizar
		tmp = new 
		Campos.each{|campo| tmp[campo] = datos[campo] }
		tmp.historia = datos[:historia]	
		tmp.normalizar
		tmp 
	end

	def normalizar
		self.nombre = self.nombre.limpiar_nombre
		self.rubro  = self.rubro.espacios
		self.precio = self.precio.to_money

		self.url_producto = nil if self.url_producto.vacio?
		self.url_imagen   = nil	if self.url_imagen.vacio?

		self.id           = nil if self.id.vacio?
		self.anterior = 0

		self.texto = [
			self.nombre, self.rubro,
			self.precio, self.unidad,
			self.marca, 
			self.nombre.tag(:nombre),
			# self.rubro.tag(:rubro),
			self.precio.tag(:precio), self.url_imagen.tag(:foto),
			self.error?.tag(:error),
			self.id,
		].compact.map{|x|x.to_s.espacios}.join(' ')

		self.ofertas = [] 
		self.ofertas << [1, self.precio]
		self.ofertas << extraer_oferta(self.precio_1) unless self.precio_1.vacio?
		self.ofertas << extraer_oferta(self.precio_2) unless self.precio_2.vacio?
		self.ofertas << extraer_oferta(self.precio_3) unless self.precio_3.vacio?

		normalizar_historia
		self
	end

	def normalizar_historia
		self.historia ||= []
		self.historia.each{|h| h[:fecha] = h[:fecha].to_date }
		self
	end

	def actualizar(fecha, precio = nil)
		fecha = fecha.to_date 
		self.historia ||= []
		self.historia = self.historia.select{|h| h.fecha < fecha }
		ultimo = self.historia.last
		self.historia << { fecha: fecha, precio: precio }  if !ultimo || ultimo.precio != precio

		normalizar_historia
	end

	def key 
		[:nombre, :url_producto, :url_imagen].map{|campo| self[campo]}.to_key
	end

	def extraer_oferta(oferta)
		a, b = oferta.gsub(/[^\d.,]/,'').split(',')
		[a.to_num, b.to_money]
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
		self.nombre.vacio? || self.precio.vacio? || self.rubro.vacio? || self.url_imagen.vacio? 
	end

    def contiene(condicion)
        condicion = condicion.espacios
        return true if condicion.vacio?
        
		alternativas = condicion.split(' o ')
		alternativas.any? do |palabras|
			palabras = palabras.gsub(' y ', ' ')
			return true if palabras.vacio?
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

	def oferta(cantidad=1)
		self.ofertas.select{|maximo, precio| cantidad >= maximo }.last.last
	end

	def precio_oferta
		ofertas.last.last
	end

	def variacion
		precio / (anterior.vacio? ? precio : anterior).to_f - 1.0
	end

	def aumento?
		variacion > +0.01 
	end

	def disminuyo?
		variacion < -0.01 
	end

	def vario?
		variacion.abs > 0.01 
	end

	def to_hash
		Hash[ Campos.map{|campo| [campo, self[campo]] } ]
	end

	def to_hash
		tmp = to_h.compact 
		tmp[:historia] = self.historia.map{|h|[fecha: h.fecha.dia, precio: h.precio]} 
		tmp 
	end

	# [:id, :nombre, :precio, :rubro, :url_imagen, :url_producto, :marca, :unidad, :anterior, :precio_unitario, :precio_1, :precio_2, :precio_3]
	def mostrar(verboso=true)
		puts "ID: #{id}" do
			puts "Nombre: %s" % self.nombre 
			puts "Rubro : %s" % self.rubro 
			puts "URL   : #{self.url_imagen} | #{self.url_producto}" if verboso 
			puts "Precio: $%7.2f (%s)" % [self.precio, [self.precio_1, self.precio_2, self.precio_3].compact.join(", ")]
			if verboso 
				precio_anterior = nil 
				self.historia.each do |h|
					accion = precio_anterior.vacio? ? :alta : (h[:precio].vacio? ? :baja : :cambio)
					puts "   #{h.fecha.dia}  => #{h.precio ? "%6.2f" % h.precio : "      "} > #{accion}" 
					precio_anterior = h.precio
				end
			end
			puts 
		end
	end
end

if __FILE__ == $0
	a = [:id, :nombre, :precio, :rubro, :url_imagen, :url_producto, :marca, :unidad, :anterior, :precio_unitario, :precio_1, :precio_2, :precio_3].zip(['0', 'Cola Cola Zero', 12.34, 'gaseosa', '/i1','/p1','Coca Cola', 'lt', nil, nil, nil, nil, nil])
	a = Hash[a]
	b = Producto.cargar(a)
	b.mostrar(true) 
	b.actualizar('2020/02/01', 100)
	b.actualizar('2020/02/02', nil)
	b.actualizar('2020/02/02', 120)
	b.actualizar('2020/02/03', nil)
	b.actualizar('2020/02/04', 120)
	b.actualizar('2020/02/05', 120)
	b.actualizar('2020/02/06', 130)
	b.mostrar(true)
	pp b.to_hash
end