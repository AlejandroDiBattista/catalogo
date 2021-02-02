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