require_relative 'utils'
Campos = [:id, :nombre, :precio, :rubro, :url_imagen, :url_producto, :marca, :unidad, :precio_unitario, :precio_1, :precio_2, :precio_3, :historia]

class Producto < Struct.new(*Campos)
	attr_accessor :ofertas, :texto, :anterior, :key#, :historia
	attr_accessor :tiene_foto 

	def self.cargar(datos)
		return datos if Producto === datos
		return nil unless Hash === datos || Struct === datos

		datos = datos.to_hash if Struct === datos 
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

		self.texto = [
			self.nombre, self.rubro,
			self.precio, self.unidad,
			self.marca, 
			self.nombre.tag(:nombre),
			self.precio.tag(:precio), self.url_imagen.tag(:foto),
			self.error?.tag(:error),
			self.id,
		].compact.map{|x|x.to_s.espacios}.join(' ')

		self.ofertas = [] 
		self.ofertas << [1, self.precio]
		self.ofertas << extraer_oferta(self.precio_1) unless self.precio_1.vacio?
		self.ofertas << extraer_oferta(self.precio_2) unless self.precio_2.vacio?
		self.ofertas << extraer_oferta(self.precio_3) unless self.precio_3.vacio?

		self.key = [self.nombre, self.url_producto, self.url_imagen].to_key
		self.historia ||= []
		self.historia.each{|h| h[:fecha] = h[:fecha].to_date }
		self
	end

	def actualizar(fecha, precio = nil)
		fecha = fecha.to_date 
		self.historia = historia.select{|h| h.fecha < fecha }
		ultimo = historia.last
		self.historia << { fecha: fecha, precio: precio }  if !ultimo || ultimo.precio != precio
	end

	def imagen?
		self.url_imagen
	end

	def activo?
		historia.count > 1 && ! historia.last.precio.vacio?
	end

	def extraer_oferta(oferta)
		cantidad, precio = oferta.gsub(/[^\d.,]/,'').split(',')
		[cantidad.to_num, precio.to_money]
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

	def precio(fecha= nil)
		return self[:precio] unless fecha 
		fecha = fecha.to_date 
		if item = historia.select{|h| h.fecha <= fecha}.last
			item.precio 
		end
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
		tmp = Hash[ Campos.map{|campo| [campo, self[campo]] } ]
		tmp[:historia] = self.historia.map{|h|{fecha: h.fecha.dia, precio: h.precio}} 
		tmp.compactar
	end

	def mostrar(verboso=true)
		puts " ID: #{id}" do
			puts " Nombre : %s" % nombre 
			puts " Rubro  : %s" % rubro 
			puts " URL    : #{url_imagen} | #{url_producto} > #{key}" if verboso 
			puts " Precio : $%7.2f (%s)" % [precio, [precio_1, precio_2, precio_3].compact.join(", ")]
			if verboso 
				precio_anterior = nil 
				historia.each do |h|
					accion = precio_anterior.vacio? ? :alta : (h[:precio].vacio? ? :baja : :cambio)
					puts "   #{h.fecha.dia} : #{h.precio ? "%6.2f" % h.precio : "      "} > #{accion}" 
					precio_anterior = h.precio
				end
			end
			puts 
		end
	end
end

if __FILE__ == $0
	puts " Probar PRODUCTOS ".pad(100).error
	b = Producto.cargar({id: '000', nombre: 'Cola Cola Zero', precio: 120.00, rubro: 'Gaseosa', url_imagen: '/i1', url_producto: '/p1', marca: 'Coca Cola', unidad: 'lt', precio_1: '3,99.0', precio_2: '6,89.0'})
	c = Producto.cargar(b)
	b.mostrar(true) 
	b.actualizar('2020/02/01', 100)
	b.actualizar('2020/02/02')
	b.actualizar('2020/02/02', 120)
	b.actualizar('2020/02/03')
	b.actualizar('2020/02/04', 120)
	b.actualizar('2020/02/05', 120)
	b.actualizar('2020/02/06', 130)
	b.mostrar(true)
	c.mostrar(true)
	pp b.compactar
end