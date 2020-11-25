class Algo
	attr_accessor :contador
	def siguiente
		self.contador ||= 100
		self.contador += 1
	end
end

a = Algo.new
b = Algo.new

p a.siguiente
p a.siguiente
p a.siguiente

p b.siguiente
p b.siguiente

p a.siguiente