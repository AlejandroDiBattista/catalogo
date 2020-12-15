require_relative 'code'

TiempoMinimoAtencion = 2
TiempoMinimoObservacion = 5


def promedio(a, b)
    return 0 if b.cantidad == a.cantidad
    ((b.hora - a.hora) / (b.cantidad - a.cantidad).to_f).abs.round(2)
end

class Cola 
    attr_accessor :nombre, :reloj, :registros
    
    def initialize(nombre='Cola')
        self.nombre = nombre
        self.reloj  = 0
        self.registros = []
    end

    def avanzar(tiempo=1)
        self.reloj += tiempo if tiempo > 0
    end

    def cantidad
        registros.last ? registros.last.cantidad : 0
    end

    def entrar
        registrar(+1) 
    end

    def salir
        registrar(-1)
    end

    def registrar(cantidad)
        cantidad += registros.last ? registros.last.cantidad : 0
        self.registros << { cantidad: cantidad, hora: reloj } if cantidad >= 0
    end

    def permanentes
        salida = []
        anterior, *lista = self.registros
        lista.each do |actual|
            salida << anterior if actual.hora - anterior.hora >= TiempoMinimoAtencion
            anterior = actual
        end
        salida << anterior if reloj - anterior.hora >= TiempoMinimoAtencion
        salida
    end

    def entradas
        salida = []
        anterior, *lista = self.permanentes
        lista.each do |actual|
            salida << anterior if actual.hora - anterior.hora >= TiempoMinimoObservacion && salida.count == 0
            salida << actual   if actual.cantidad < anterior.cantidad
            anterior = actual
        end
        salida
    end

    def muestra(cantidad=1000)
        lista = entradas.clone
        cantidad.times.map do
            i = rand(lista.count)
            j = rand(lista.count)
            redo if i == j
            promedio(lista[i], lista[j])
        end.promedio.round(1)
    end

    def mostrar(lista, texto='')
        puts " #{nombre} (#{reloj}s, #{lista.count}) [#{texto}] ".titulo do 
            lista.each{|e| puts ' %2is > %2i ' % [e.hora, e.cantidad] }
        end
        puts ""
    end

end

def Cola(nombre, cantidad=0, &bloque)
    tmp = Cola.new(nombre)
    cantidad.times{tmp.entrar}
    tmp.instance_eval(&bloque)
end

if __FILE__ == $0
    
    puts "Simulacion".pad(100).error
    Cola 'Polo Norte' do 
        10.times{entrar}

        avanzar 20
        3.times{salir}
        
        avanzar 30
        salir 

        avanzar 10
        salir 

        avanzar 8
        2.times{salir}
        
        avanzar 10
        salir 

        2.times{entrar}

        avanzar 3
        2.times{salir}
        
        avanzar 10

        mostrar registros,   'Registros Brutos'
        mostrar permanentes, 'Permanentes'
        mostrar entradas,    'Entradas'

        # mostrar entradas,    "Entradas" 
   
        pp muestra(1000)

        # puts "Promedios" do 
        #     puts "Loco   10  #{promedio(10)}"
        #     puts "Loco  100  #{promedio(100)}"
        #     puts "Loco   1k  #{promedio(1000)}"
        #     puts "Loco  10k  #{promedio(10000)}"
        #     puts "Loco 100k  #{promedio(100000)}"
        #     puts "Loco   1M  #{promedio(1000000)}"
        # end
    end
 end
   