class Hash 
	alias :get []
	def [](campo)
		get(campo.to_s.to_sym)
	end

	alias :set []=
	def []=(campo, valor)
		set(campo.to_s.to_sym, valor)
	end

	def method_missing(meth, *args, &blk)
		if meth["="]
			self[meth[0..-2]] = args
		else
			self[meth]
		end
	end

	def valores(*campos)
		campos.flatten.map{|campo| get(campo)}
	end

	def normalizar
		Hash(keys, values)
	end

	def normalizar!
		keys.select{|key| !(Symbol === key)}.each{|key| self[key.to_sym] = self.delete(key) }
		self 
	end
end

class Object
	def normalizar
		self
	end
end

module Enumerable
	def normalizar
		map(&:normalizar)
	end
end

def Hash(campos, valores=nil)
	campos = campos.map(&:to_sym).zip(valores) if valores
	Hash[campos]
end

class String
	def to_money
		gsub(",",".").gsub(/[^0-9.]/,"").to_f 
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

	# pp (({"a" => 1 , {"b" => 2, "c" => [3, {"d" => 4}]}).normalizar)
end