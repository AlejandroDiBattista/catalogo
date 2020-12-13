require_relative 'code'

TiempoMinimoAtencion = 2
TiempoMinimoObservacion = 5

class Entrada < Struct.new(:cantidad, :hora, :temporal)
    def mostrar
        puts "%2i > %3i  %s" % [hora, cantidad, temporal ? "?" : " "]
    end
end

class Cola 
    attr_accessor :nombre, :reloj, :entradas, :proximo, :configuracion
    
    def initialize(nombre='Cola')
        self.nombre = nombre
        self.configuracion = true
        self.reloj = 0

        self.entradas = [] << Entrada.new(0,0,true)
    end

    def avanzar(tiempo = 1)
        self.reloj += tiempo if tiempo > 0
        revisar_estado
    end

    def entra()
        registrar(ultimo.cantidad + 1) 
    end

    def sale() 
        registrar(ultimo.cantidad - 1)
    end

private 

    def registrar(cantidad)
        return if cantidad < 0

        if ultimo.temporal
            ultimo.cantidad = cantidad 
            ultimo.hora = reloj
        else
            self.entradas << Entrada.new(cantidad, reloj, true)
        end
       
        revisar_estado
    end

    def revisar_estado
        ultimo.temporal = false if tiempo_actual >= TiempoMinimoAtencion    # rapido

        if tiempo_actual >= TiempoMinimoObservacion                         # lento
            
            self.configuracion = false
            if anterior && ultimo.cantidad > anterior.cantidad 
                puts "Reiniciar!"
                self.entradas = [] << ultimo
            end
        end 
    end

    def tiempo_actual
        reloj - ultimo.hora
    end

    def anterior
        entradas[-2]
    end

    def ultimo
        entradas[-1]
    end

    def mostrar(tmp="")
        puts " #{nombre} reloj: #{reloj}s (#{entradas.first.cantidad} #{ self.configuracion ? 'Configurando' : 'Ejecutando' }) t:#{tmp} ".titulo do 
            entradas.each( &:mostrar )
        end
    end

    def estimar
        puts " #{nombre} reloj: #{reloj}s (#{entradas.first.cantidad} #{ self.configuracion ? 'Configurando' : 'Ejecutando' }) ESTIMAR ".error do 
            i = 0 
            (0..entradas.first.cantidad).to_a.reverse.each do |e|
                print e  
                aux = entradas[i]
                if  aux && aux.cantidad == e 
                    puts " + #{aux.hora} #{aux.temporal ? "?" : ""}"
                    i += 1
                else
                    puts " -"
                end
            end
        end
    end
end

def Cola(nombre, cantidad=0, &bloque)
    tmp = Cola.new(nombre)
    cantidad.times{tmp.entra}
    tmp.instance_eval(&bloque)
end


if __FILE__ == $0

    puts "Simulacion".pad(100).error
    Cola :polo_norte do 
        10.times{ entra } 
        # mostrar 0 #10!
        avanzar 20
        3.times{ sale }
        # mostrar 1 #7*
        avanzar 10
        # mostrar 2 #7
        2.times{ avanzar 10; sale }
        avanzar 8
        # mostrar 3 #5
        sale
        # mostrar 4 #4* 
        entra 
        entra 
        # mostrar 5 #6*
        avanzar 10
        # mostrar 6 #6!
        sale 
        # mostrar 7 #5*
        avanzar 3
        # mostrar 8 #5
        2.times{sale}
        mostrar 9 #3

        estimar
    end

end