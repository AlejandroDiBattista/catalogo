# require 'date'
# require_relative 'utils'


# class Producto < Struct.new(:nombre, :rubro, :precio, :id)
#     def key 
#         "#{self.nombre}-#{self.rubro}".downcase.gsub(/[^a-z09-]/i,'')
#     end

#     @@proximo = "00001"
#     @@claves  = {}

#     def self.registrar(producto)
#         if clave = producto.id 
#             @@claves[producto.key] = clave 
#             @@proximo = clave.succ if clave >= @@proximo 
#         end
#     end

#     def self.identificar(producto)
#         if !producto.id
#             producto.id = @@claves[producto.key] || @@proximo
#             registrar(producto)
#         end
#     end

#     def self.mostrar
#         pp @@claves
#     end
# end

# a = "2020-12-5".to_fecha
# b = a.to_fecha
# p a 
# p a.class.name
# p b 
# p b.class.name
require 'date'

class String
    def to_date 
        Date.parse(self)
    end
end

a = Date.today 
b = "2020-3-1".to_date 
p a 
p a.to_s

p b 
p b.to_s 

p a == a.to

