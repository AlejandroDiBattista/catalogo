require 'parallel'
require 'colorize'
require 'date'

$stdout.sync = true
$semaphore = Mutex.new

class Hash 
	def method_missing(meth, *args, &blk)
		if meth['=']
			self[meth.to_key] = args
		else
			self[meth.to_key]
		end
	end

	def valores(*campos)
		campos.flatten.map{|campo| self[campo]}
	end

	def normalizar
		Hash[keys.map(&:to_key).zip(values.normalizar)]
	end

	def normalizar!
		keys.select{|key| !(Symbol === key)}.each{|key| self[key.to_key] = self.delete(key).normalizar }
		self 
	end

	def to_struct
		Struct.new(*keys).new(*values)
	end

	def to_hash
		to_h
	end
end

class Struct
	def to_hash
		to_h
	end
end

class Array
	def normalizar
		map(&:normalizar)
	end

	def tabular
		return if count == 0
		campos = first.keys
		anchos = campos.map{|campo| map{|x| x[campo].to_s.size }.max}
		puts ('▶  '+campos.zip(anchos).map{|campo, ancho| (campo.to_s.upcase + ' ' * ancho)[0...ancho]}.join('  ')).yellow
		each.with_index do |x, i|
			puts ' • '.blue + ('%3i' % (i+1)) + x.values.zip(anchos).map{|valor, ancho| (valor.to_s + ' ' * ancho)[0...ancho]}.join('  ')
		end
		puts '■'
	end

	def listar(titulo: 'Listado', maximo: 10)
		return if count == 0
		maximo ||= count
		puts "#{titulo} (#{count})" do 
			puts '▶ %-60s %7s | %-80s' % ['Nombre', 'Precio', 'Rubro']
			first(maximo).each do |x|
				anterior  = x.anterior
				variacion = x.anterior.vacio? ? 0 : x.precio - x.anterior 
					
				puts ' • %-60s %7.2f | %-80s | %s | %s %s' % [x.nombre.pad(60), x.precio.to_f, x.rubro, x.id, anterior.to_precio(false), variacion.to_precio(false)]
			end
			puts '■'
		end
	end

	def to_rubro
		compact.map(&:strip).select{|x| x.size > 1 }.join(' > ')
	end
end

class Class
	def to_class
		self 
	end
end

class Object
	def normalizar
		self
	end

	def to_key
		to_s.gsub(/([a-z])([A-Z])/,'\1 \2').gsub(/[^a-z0-9]/i,' ').espacios.gsub(' ','_').downcase.to_sym
	end

	def to_class_name 
		to_s.gsub('_',' ').espacios.split.map(&:capitalize).join 
	end

	def to_class 
		Object.const_get(to_class_name)
	end

	def vacio?
		to_s.strip.size < 3
	end

	def existe?
		!vacio?
	end 

	def to_sku
		to_s.gsub(/\W/,'')
	end

	def tag(nombre)
		"#{self.vacio? ? 'sin' : 'con'}_#{nombre}".to_sym
	end

	def limpiar_nombre
		to_s.limpiar_nombre
	end

	def espacios
		to_s.espacios
	end
end

class NilClass 
	def vacio?
		true
	end
end

class TrueClass
	def vacio?
		false 
	end
end 

class FalseClass
	def vacio?
		true 
	end
end 

class Integer
	def vacio?
		self == 0
	end

	def to_porcentaje
		(self / 100.0).to_f.to_porcentaje
	end
	
	def to_precio(vacio: true)
		to_f.to_precio(vacio)
	end

	def to_money
		to_f.to_money 
	end
end 

class Float 
	def vacio?
		abs < 0.1 
	end

	def to_porcentaje
		'%3.0f%%' % [100.0 * self]
	end

	def to_precio(vacio: true)
		return '' if !vacio && vacio?
		'%7.2f' % self 
	end

	def to_money
		self
	end
end

module Enumerable
	def vacio?
		compact.count == 0 
	end

	def to_key
		map(&:to_key).join('-')
	end

	def normalizar
		map(&:normalizar)
	end

	def contar
		return map{|x| yield x}.contar    if block_given?
		suma = Hash.new{0}
		each{|valor| suma[valor] += 1 }
		suma
	end

	def ranking
		return map{|x| yield x}.ranking   if block_given?
		contar.to_a.sort_by(&:last).reverse
	end

	def repetidos
		return map{|x| yield x}.repetidos if block_given?
		contar.select{|_, value| value > 1 }
	end

	def promedio(&b)
		return 0 if (n = count) == 0
		
		if block_given?
			sum(&b) / n 
		else
			sum / n
		end
	end

	def procesar(hilos = 20)
		salida = []
		Progreso.new do |progreso| 
			Parallel.each(to_a, in_threads: hilos) do |item|
				resultado = yield(item)
				progreso.avanzar(resultado)
				salida << resultado
			end
		end
		salida
	end

end

class String

	def espacios
		strip.gsub(/\s+/, ' ').strip
	end

	def to_money
		begin
			gsub(',', '.').gsub(/[^0-9.]/,'').to_f 
		rescue 
			0		
		end
	end

	def to_num
		gsub(/\D/,'')
	end

	def from_rubro(separador='>')
		split(separador).map(&:espacios)
	end

	def limpiar_nombre
		espacios.
			gsub(/\(\w+\)/,'').
			gsub(/[()]/,'').
			split(' ').
			map(&:capitalize).
			join(' ')
	end

	def pad(ancho)
		"#{self[0...ancho]}#{' ' * (ancho - self.size)}" 
	end

	def vacio?
		strip.size == 0
	end
end

class Progreso
	attr_accessor :inicio, :cuenta

	def initialize
		self.cuenta = 0 
		self.inicio = Time.new
		indent true 
		print '▶   '
		if block_given?
			yield self 
			finalizar
		end
	end

	def avanzar(correcto=true)
		$semaphore.synchronize  do 
			self.cuenta += 1

			print correcto.nil? ? '●'.yellow : (correcto ? '●'.green : '●'.red)
			print ' '  if self.cuenta % 10 == 0 
			print '  ' if self.cuenta % 50 == 0
			puts if self.cuenta %  100 == 0
			puts if self.cuenta %  500 == 0
			puts if self.cuenta % 1000 == 0
			puts if self.cuenta % 5000 == 0
			print '    ' if self.cuenta % 100 == 0
		end
	end

	def finalizar
		puts unless self.cuenta % 100 == 0
		puts '■ %4.1fs ' % (Time.new - inicio) 
		indent false 
	end
end

class String #Gestion de colores
	def titulo
		black.on_green
	end
	
	def subtitulo
		black.on_cyan
	end
	
	def error
		yellow.on_red
	end

	def debug
		red.on_yellow
	end
end

module Kernel
	alias :puts_  :puts
	alias :print_ :print

	$tab   = '  '
	$nivel = 0
	$continuar  = false 
	$mediciones = []

	def avanzar(correcto=true)
		$mediciones.last.avanzar(correcto)
	end

	def medir(titulo)
		puts " #{titulo} ".pad(100).white.on_blue do 
			$mediciones << Progreso.new
			yield $mediciones.last 
			$mediciones.pop.finalizar
		end
	end

	def indent(aumentar)
		$nivel += aumentar ? +1 : -1
	end

	def print(*valores)
		print_( $tab * $nivel ) unless $continuar 
		print_( *valores )
		$continuar = true 
	end
	
	def puts(*valores)
		print_( $tab * $nivel ) unless $continuar 
		puts_( valores.join(' ') )
		if block_given?
			indent true
			yield
			indent false 
		end
		$continuar = false 
	end
end

class String
	def to_date
		Date.parse(self)
	end
end

class Date
	def to_date
		self 
	end 

	def dia
		"%02i/%02i/%04i" % [self.day, self.month, self.year]
	end

	def hora 
		"%02i:%02i:%04i" % [self.hour, self.minute, self.seconds]
	end
end

class Object
	def compactar
		self 
	end
end

class Hash
	def compactar
		campos = keys.select{|key| self[key] }
		tmp = {}
		campos.each{|campo| tmp[campo] = self[campo].compactar}
		tmp 
	end
end

class Struct
	def compactar
		to_hash.compactar
	end 
end

module Enumerable
	def compactar
		map(&:compactar).compact
	end
end

if __FILE__ == $0

	puts " TuChanGui to".to_key
	puts :tu_chanquito.to_class_name
	return 
	puts "Esto es muy bueno"
	puts "Hola Mundo" do 
		puts "Algo" do 
			puts "va a"
			puts "pasar", "Dos"
			print "nuevo"
			print " intento", "doble"
			puts " a"
		end
		puts "Lindo"
	end
	a = {a: nil, "b" => "hola", c: [10,nil, {d: nil, "e" => 10}]}
	pp a 
	pp a.normalizar

	
end
