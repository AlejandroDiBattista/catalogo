require_relative 'code'

TiempoMinimoAtencion = 2
TiempoMinimoObservacion = 5

class Entrada < Struct.new(:cantidad, :hora, :temporal)
    def mostrar
        puts "%2i > %3i  %s" % [hora, cantidad, temporal ? "?" : " "]
    end

    def promedio(otro)
        ((self.hora - otro.hora) / (self.cantidad - otro.cantidad).to_f).abs
    end

    def estimar(otro, n)
        offset = n - otro.cantidad
        otro.hora + offset * self.promedio(otro)
    end
end

class Cola 
    attr_accessor :nombre, :reloj, :entradas, :proximo, :configuracion
    
    def initialize(nombre='Cola')
        self.nombre = nombre
        comenzar(0)
    end

    def comenzar(cantidad)
        self.configuracion = true
        self.reloj = 0
        self.entradas = [] << Entrada.new(cantidad, 0, true)
    end

    def avanzar(tiempo = 1)
        self.reloj += tiempo if tiempo > 0
        revisar_estado
    end

    def entrar()
        registrar(ultimo.cantidad + 1) 
    end

    def salir() 
        registrar(ultimo.cantidad - 1)
    end

    def registrar(cantidad)
        return if cantidad < 0
        self.entradas.pop if ultimo.temporal
        self.entradas << Entrada.new(cantidad, reloj, true)
        revisar_estado
    end

    def revisar_estado
        ultimo.temporal &&= !(tiempo_actual >= TiempoMinimoAtencion)    # rapido

        if tiempo_actual >= TiempoMinimoObservacion                     # lento
            self.configuracion = false
            if anterior && ultimo.cantidad > anterior.cantidad 
                comenzar ultimo.cantidad
            end
        end 
    end

    def tiempo_actual
        reloj - ultimo.hora
    end

    def primero
        entradas.first
    end

    def anterior
        entradas[-2]
    end

    def ultimo
        entradas.last
    end

    def mostrar(tmp="")
        puts " #{nombre} reloj: #{reloj}s (#{primero.cantidad} #{ self.configuracion ? 'Configurando' : 'Ejecutando' }) t:#{tmp} ".titulo do 
            entradas.each( &:mostrar )
        end
    end

    def promedio_simple
        primero && ultimo ? ultimo.promedio(primero) : 0
    end

    def promedio_multiple
        n = entradas.count 
        promedios = [] << promedio_simple
        (0...n-1).each do |i|
            (i+1...n).each do |j|
                promedios << entradas[j].promedio(entradas[i])
            end
        end
        promedios.promedio
    end

    def promedio_loco
        promedios = []
        1000.times do 
            i = rand(entradas.count)
            j = rand(entradas.count)
            promedios << entradas[i].promedio(entradas[j]) if i != j 
        end
        promedios.promedio
    end

    def estimar
        if entradas.count == 1 || self.configuracion 
            puts "No hay datos suficientes".error
            return 
        end

        puts " #{nombre} reloj: #{reloj}s (#{primero.cantidad} #{ self.configuracion ? 'Configurando' : 'Ejecutando' }) ESTIMAR ".error do 
            i, anterior, actual = 0, nil, primero 

            (0..primero.cantidad).to_a.reverse.each do |e|
                if actual && e == actual.cantidad 
                    anterior, actual = actual, entradas[i+=1] 
                end

                print " %2i)" % e

                if e >= ultimo.cantidad
                    if anterior.cantidad == e 
                        puts " + %2i #{anterior.temporal ? "?" : ""}".green % anterior.hora
                    else
                        puts " ~ %2i".yellow % anterior.estimar(actual, e)
                    end
                else
                    puts " ~ %2i".red % primero.estimar(ultimo, e)
                end
            end
        end
    end
end

def Cola(nombre, cantidad=0, &bloque)
    tmp = Cola.new(nombre)
    cantidad.times{tmp.entrar}
    tmp.instance_eval(&bloque)
end

if __FILE__ == $0
    puts "Simulacion".pad(100).error
    Cola :polo_norte do 
        # 10.times{ entrar } 
        # # mostrar 0 #10!
        # avanzar 20
        # 3.times{ salir }
        # # mostrar 1 #7*
        # avanzar 10
        # # mostrar 2 #7
        # 2.times{ avanzar 10; salir }
        # avanzar 8
        # # mostrar 3 #5
        # salir
        # # mostrar 4 #4* 
        # entrar 
        # entrar 
        # # mostrar 5 #6*
        # avanzar 10
        # # mostrar 6 #6!
        # salir 
        # # mostrar 7 #5*
        # avanzar 3
        # # mostrar 8 #5
        # 2.times{salir}
        # mostrar 9 #3

        10.times{entrar}
        avanzar 21
        3.times{salir}
        avanzar 10
        3.times{salir}
        avanzar 18
        mostrar
        salir
        avanzar 10
        estimar
   
        puts "Promedios" do 
            puts "Simple   #{promedio_simple}"
            puts "Multiple #{promedio_multiple}"
            puts "Loco     #{promedio_loco}"
        end
    end
 end
   