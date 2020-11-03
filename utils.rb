$stdout.sync = true

require 'parallel'
require 'colorize'

def Hash(campos, valores=nil)
	campos = campos.map(&:to_sym).zip(valores) if valores
	Hash[campos]
end

class Hash 
	def method_missing(meth, *args, &blk)
		if meth["="]
			self[meth[0..-2]] = args
		else
			self[meth]
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
		puts ("▶  "+campos.zip(anchos).map{|campo, ancho| (campo.to_s.upcase + " " * ancho)[0...ancho]}.join("  ")).yellow
		each do |x|
			puts " • ".green + x.values.zip(anchos).map{|valor, ancho| (valor.to_s + " " * ancho)[0...ancho]}.join("  ")
		end
		puts "■"
	end

	def listar(titulo="Listado", maximo=10)
		return if count == 0
		maximo ||= count
		puts "#{titulo} (#{count})"
		puts "▶ %-60s %7s | %-80s" % ["Nombre", "Precio", "Rubro"]
		a = first(1)
		first(maximo).each{|x| puts " • %-60s %7.2f | %-80s | %s | %s %s" % [x.nombre[0...60], x.precio.to_f, x.rubro, x.id, (x.anterior > 0 ? ("%7.2f" % x.anterior) : ""), (x.anterior > 0 ? ("%7.2f" % (x.precio - x.anterior)) : "")]}
		puts "■"
	end

	def to_rubro
		compact.map(&:strip).select{|x| x.size > 1 }.join(" > ")
	end
end

class Object
	def normalizar
		self
	end

	def to_key
		to_s.strip.gsub(" ","_").downcase.to_sym
	end

	def vacio?
		to_s.strip.size < 3
	end

	def to_sku
		to_s.gsub(/\W/,"")
	end

	def tag(nombre)
		"#{self.vacio? ? 'sin' : 'con'}_#{nombre}".to_sym
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
end 

class Float 
	def vacio?
		abs < 0.1 
	end
end

module Enumerable
	def normalizar
		map(&:normalizar)
	end

	def ranking
		suma = Hash.new
		suma.default = 0
		each{ |valor| suma[valor] += 1  }
		suma.to_a.sort_by(&:last).reverse
	end

	def repetidos
		suma = Hash.new
		suma.default = 0
		each{ |valor| suma[yield(valor)] += 1  }
		suma.select{|valor| suma[yield(valor)] > 2}
	end

	def procesar(hilos=50)
		salida = []
		progreso = Progreso.new 
		Parallel.each(to_a, in_threads: hilos) do |item|
			resultado = yield(item)
			progreso.avanzar(resultado)
			salida << resultado
		end
		progreso.finalizar
		salida
	end

	def vacio?
		count == 0 
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
end

$semaphore = Mutex.new
class Progreso
	attr_accessor :cuenta , :inicio

	def initialize
		self.cuenta = 0 
		self.inicio = Time.new
		print "  ► "
	end

	def avanzar(correcto=true)
		$semaphore.synchronize  do 
			print correcto.nil? ? "●".yellow : (correcto ? "●".green : "●".red) #○
			self.cuenta += 1 
			print " " if self.cuenta % 10 == 0 
			print "  " if self.cuenta % 50 == 0
			puts if self.cuenta %  100 == 0
			puts if self.cuenta %  500 == 0
			puts if self.cuenta % 1000 == 0
			puts if self.cuenta % 5000 == 0
			print "    " if self.cuenta % 100 == 0
		end
	end

	def finalizar
		puts unless self.cuenta % 100 == 0
		puts "  ◄ %4.1f" % (Time.new - inicio) 
	end
end

if __FILE__ == $0 
	puts nil
	puts nil.class 
	puts nil.vacio?
    return 
	a,b ="algo".scan(/([-+:<>|])?(.*)/).first
	p a
	p b 
	return 
	a = Hash([:x, "y", "z"], [10, 20, 40])
	b = Hash([[:a, 100], [:b, 200]])

	c = {"m" => 1000, "n" => 2000}
	p a 
	p b 

	p c 
	p c.normalizar
	p c 

	p a.valores(:x, :y)

	p "$12,23".to_money

	p [1,2,3].include?(2)
	p [1,2,3].include?(5)
	# pp (({"a" => 1 , {"b" => 2, "c" => [3, {"d" => 4}]}).normalizar)
	puts "as/12121.jpg".to_num
	
	a = "$ 62,80"
	p a.to_money
	p [1,2].class
	# p [{x:10, y:"0000"},{x:"100000", y: 2}].tabular
	a = [1, 1, 2, 2, 5, 6, 7, 8].sort
	p a
	# p a.select{|x| a.count(x) > 1}
	p a.repetidos{|x|x}
	p "c0.-1212a  ".to_sku
	
	p '-'*100
	pp
	( a="Almacén > Aceites y Vinagres")
	pp( b = a.from_rubro )
	pp( b.to_rubro)
	
end

