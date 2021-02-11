require_relative 'utils'

class Punto < Struct.new(:x , :y)
    def x(m=3)
        self[:x] * m 
        def precio(fecha: '1/1/2000', cantidad: 1)
            puts "#{fecha} > #{cantidad}"
        end
    end 
end 


a = Punto.new(10,20)
pp a 
puts a.x 
puts a.x(2) 
puts a[:x]

precio 
precio fecha: '2/2/2000'
precio cantidad: 10 
precio cantidad: 10 , fecha: '3/3/2000'