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

	def listar(titulo="Listado")
		return if count == 0
		puts titulo if titulo
		puts " > %-60s %6s | %s" % ["Nombre", "Precio", "Rubro"]
		each{|x| puts " • %-60s %6.2f | %s" % [x.nombre[0...60], x.precio.to_f, x.rubro]}
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

	def repetidos
		contar = Hash.new
		contar.default = 0
		each{ |valor| contar[yield(valor)] += 1  }

		select{|valor| contar[yield(valor)] > 2}
	end

	def procesar(hilos=50)
		progreso = Progreso.new 
		Parallel.each(to_a, in_threads: hilos) do |item|
			yeild(item)
			progreso.avanzar
		end
		progreso.finalizar
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
	attr_accessor :cuenta 

	def initialize
		self.cuenta = 0 
	end
	def avanzar
		print "●" 
		self.cuenta += 1 
		print " " if self.cuenta % 10 == 0 
		print " " if self.cuenta % 50 == 0
		puts if self.cuenta % 100 == 0
		puts if self.cuenta % 500 == 0
	end

	def finalizar
		print " " unless self.cuenta % 100 == 0 
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

class String
	def separar_unidad
		if a = match(/\s*(\w.*)\s+x?([0-9.,]+.*)\s*$/i)
			return [a[1], a[2]]
		end
		[self, nil]

	end
end
