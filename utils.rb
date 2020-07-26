$stdout.sync = true
require 'parallel'

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
end

class Array
	def normalizar
		map(&:normalizar)
	end

	def tabular
		return if count == 0
		campos = first.keys
		anchos = campos.map{|campo| map{|x| x[campo].to_s.size }.max}
		puts "►  "+campos.zip(anchos).map{|campo, ancho| (campo.to_s.upcase + " " * ancho)[0...ancho]}.join("  ")
		each do |x|
			puts " • "+x.values.zip(anchos).map{|valor, ancho| (valor.to_s + " " * ancho)[0...ancho]}.join("  ")
		end
		puts ""
	end

	def listar(titulo="Listado", maximo=10)
		return if count == 0
		maximo ||= count
		puts "#{titulo} (#{count})" if titulo
		puts " > %-60s %7s | %-80s" % ["Nombre", "Precio", "Rubro"]
		first(maximo).each{|x| puts " • %-60s %7.2f | %-80s | %s" % [x.nombre[0...60], x.precio.to_f, x.rubro, x.id]}
		puts 
	end

	def to_rubro
		map(&:strip).select{|x|x.size > 1}.join(" > ")
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
end

def Hash(campos, valores=nil)
	campos = campos.map(&:to_sym).zip(valores) if valores
	Hash[campos]
end

class String
	def to_money
		begin
			gsub(",",".").gsub(/[^0-9.]/,"").to_f 
		rescue 
			0		
		end
	end

	def to_num
		gsub(/\D/,"")
	end
end


class Progreso
	attr_accessor :cuenta , :inicio

	def initialize
		self.cuenta = 0 
		self.inicio = Time.new
		print "  ► "
	end

	def avanzar(correcto=true)
		print correcto ? "●" : "○"
		self.cuenta += 1 
		print " " if self.cuenta % 10 == 0 
		print " " if self.cuenta % 50 == 0
		puts if self.cuenta %  100 == 0
		puts if self.cuenta %  500 == 0
		puts if self.cuenta % 1000 == 0
		print "    " if self.cuenta % 100 == 0
	end

	def finalizar
		puts unless self.cuenta % 100 == 0
		puts "  ◄ %4.1f" % (Time.new - inicio) 
	end
end


if __FILE__ == $0 
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
	p [{x:10, y:"0000"},{x:"100000", y: 2}].tabular
	a = [1, 1, 2, 2, 5, 6, 7, 8].sort
	p a
	# p a.select{|x| a.count(x) > 1}
	p a.repetidos{|x|x}
end