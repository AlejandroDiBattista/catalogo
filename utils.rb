require 'parallel'
require 'colorize'
require 'date'

$stdout.sync = true
$semaphore = Mutex.new

def Hash(campos, valores=nil)
	campos = campos.map(&:to_key).zip(valores) if valores
	Hash[campos]
end

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
		Hash(keys.map(&:to_key), values.normalizar)
	end

	def normalizar!
		keys.select{|key| !(Symbol === key)}.each{|key| self[key.to_key] = self.delete(key).normalizar }
		self 
	end

	def compact 
		borrar = keys.select{|key| self[key].nil? }
		borrar.each{|key| self.delete(key)}
		self 
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
		each do |x|
			puts ' • '.green + x.values.zip(anchos).map{|valor, ancho| (valor.to_s + ' ' * ancho)[0...ancho]}.join('  ')
		end
		puts '■'
	end

	def listar(titulo: 'Listado', maximo: 10)
		return if count == 0
		maximo ||= count
		puts "#{titulo} (#{count})"
		puts '▶ %-60s %7s | %-80s' % ['Nombre', 'Precio', 'Rubro']
		first(maximo).each do |x|
			anterior  = x.anterior
			variacion = x.anterior.vacio? ? 0 : x.precio - x.anterior 
				   
			puts ' • %-60s %7.2f | %-80s | %s | %s %s' % [x.nombre.pad(60), x.precio.to_f, x.rubro, x.id, anterior.to_precio(false), variacion.to_precio(false)]
		end
		puts '■'
	end

	def to_rubro
		compact.map(&:strip).select{|x| x.size > 1 }.join(' > ')
	end
end

class Object
	def normalizar
		self
	end

	def to_key
		to_s.gsub(/[^a-z0-9]/i,' ').espacios.gsub(' ','_').downcase.to_sym
	end

	def vacio?
		to_s.strip.size < 3
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
end

module Enumerable
	def vacio?
		compact.count == 0 
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

	def procesar(hilos = 50)
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

	def to_fecha
		Date.parse(self.scan(/(\d{2,4}-\d{1,2}-\d{1,2})/).flatten.first)
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
end

class Progreso
	attr_accessor :inicio, :cuenta

	def initialize
		self.cuenta = 0 
		self.inicio = Time.new
		indent true 
		print ' ►  '
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
		puts ' ◄ %4.1f ' % (Time.new - inicio) 
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
end

module Kernel
	alias :puts_  :puts
	alias :print_ :print

	$tab   = '·   '
	$nivel = 0
	$continuar = false 

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

if __FILE__ == $0
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
end
