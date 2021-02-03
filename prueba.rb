require 'date'
require_relative 'utils'


class Producto < Struct.new(:nombre, :rubro, :precio, :id)
    def key 
        "#{self.nombre}-#{self.rubro}".downcase.gsub(/[^a-z09-]/i,'')
    end

    @@proximo = "00001"
    @@claves  = {}

    def self.registrar(producto)
        if clave = producto.id 
            @@claves[producto.key] = clave 
            @@proximo = clave.succ if clave >= @@proximo 
        end
    end

    def self.identificar(producto)
        if !producto.id
            producto.id = @@claves[producto.key] || @@proximo
            registrar(producto)
        end
    end

    def self.mostrar
        pp @@claves
    end
end

pp (a=Object.const_get('Producto'))
pp Producto === a 
pp a.new("ale", "persona", 99)
pp Class === Producto
return
puts Date.new 
puts Date.today 
puts Date.new.to_fecha
return
p(d="2017-12-23".to_fecha)
p d.strftime('%d/%m/%Y')
p d.to_s
return 
l = [   
        Producto.new('Coca Cola',   :gaseosa,  100),
        Producto.new('Pepsi Cola',  :gaseosa,   90), 
        Producto.new('Gallo',       :arroz,     40), 
        Producto.new('Triunfador',  :arroz,     30),
    ]

10.times{puts}
puts "INICIAL"
Producto.mostrar 
pp l

l.each{|o| Producto.registrar(o)}
puts "\nREGISTRADO"
Producto.mostrar 
pp l

puts "\nIDENTIFICADO"
l.each{|o| Producto.identificar(o)}
Producto.mostrar 
pp l 

p [nil, nil, nil].max 
p [].max 