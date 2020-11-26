Campos = [:nombre, :precio, :rubro, :unidad, :url_producto, :url_imagen, :id, :anterior, :texto, :precio_1, :precio_2, :precio_3, :historia]

class Producto < Struct.new(*Campos)
	attr_accessor :ofertas

	def self.cargar(datos)
		new.tap{|tmp| Campos.each{|campo| tmp[campo] = datos[campo]}}.normalizar
	end

	def to_hash
		Hash[Campos.map{|campo|[campo, self[campo]]}]
	end

	def normalizar
		self.nombre = self.nombre.limpiar_nombre
		self.rubro  = self.rubro.espacios
		self.precio = self.precio.to_money

		self.url_producto = nil if self.url_producto.vacio?
		self.url_imagen   = nil	if self.url_imagen.vacio?

		self.id =  nil 			if self.id.vacio?
		self.anterior = 0

		self.texto = [
			self.nombre, self.rubro, self.precio, self.unidad, 
			self.nombre.tag(:nombre), 
			# self.rubro.tag(:rubro), 
			self.precio.tag(:precio), self.url_imagen.tag(:foto), 
			self.error?.tag(:error),
			self.id,
		].map{|x|x.to_s.espacios}.join(' ')

		self.ofertas = [] 
		self.ofertas << [1, self.precio]
		self.ofertas << extraer_oferta(self.precio_1) unless self.precio_1.vacio?
		self.ofertas << extraer_oferta(self.precio_2) unless self.precio_2.vacio?
		self.ofertas << extraer_oferta(self.precio_3) unless self.precio_3.vacio? 

		self.historia ||= []
		self
	end

	def extraer_oferta(oferta)
		oferta = oferta.gsub(/[^\d.,]/,'')
		a, b = oferta.split(',')
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
			palabras = palabras.gsub(' y ', '')
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
		precio / (anterior.vacio? ? precio : anterior).to_f - 1
	end

	def aumento?
		variacion > 0 
	end

	def disminuyo?
		variacion < 0 
	end

	def vario?
		variacion.abs > 0 
	end

	def actualizar(fecha, precio = nil)
		if ultimo = self.historia.last 
			if precio 
				if ultimo.precio == precio 
					ultimo[:hasta] = fecha
					precio = nil 
				else
					ultimo[:hasta] = fecha - 1
					ultimo = nil 
				end
			elsif ultimo[:hasta] != fecha
				ultimo[:hasta] = fecha - 1
			end
		end 
		
		self.historia << { desde: fecha, hasta: fecha, precio: precio } if !ultimo && precio 
	end
end

if __FILE__ == $0

end