require_relative '../code'

TiempoMinimoAtencion    = 2
TiempoMinimoObservacion = 5

def promedio(a, b)
    return 0 if b.cantidad == a.cantidad
    ((b.hora - a.hora) / (b.cantidad - a.cantidad).to_f).abs.round(2)
end

class Cola 
    attr_accessor :nombre, :reloj, :registros
    
    def initialize(nombre='Cola')
        self.nombre = nombre
        self.reloj  = nil 
        self.registros = []
    end

    def entrar
        registrar(+1) 
    end

    def salir
        registrar(-1)
    end

    def configurando?
        primero = entradas.first 
        !primero || (self.hora - primero.hora >= TiempoMinimoObservacion)
    end

    def editando?
        ultimo = entradas.last 
        !ultimo || (self.hora - ultimo.hora >= TiempoMinimoAtencion)
    end

    def hora 
        self.reloj || Time.new
    end

    def entradas
        permanentes = []
        reducir(self.registros) do | anterior, actual |
            if actual 
                permanentes << anterior if actual.hora - anterior.hora >= TiempoMinimoAtencion
            else 
                permanentes << anterior if self.hora - anterior.hora >= TiempoMinimoAtencion
            end
        end

        salida = []
        reducir(permanentes) do | anterior, actual |
            next unless actual
            if salida.count == 0
                salida << anterior if actual.hora - anterior.hora >= TiempoMinimoObservacion
            end 
            salida << actual   if actual.cantidad < anterior.cantidad 
        end
        salida 
    end

    def muestra(cantidad=1000)
        lista = self.entradas.clone
        cantidad.times.map do
            i = rand(lista.count)
            j = rand(lista.count)
            redo if i == j
            promedio(lista[i], lista[j])
        end
    end

    def registrar(cantidad)
        cantidad += registros.last ? registros.last.cantidad : 0
        self.registros << { cantidad: cantidad, hora: self.hora } if cantidad >= 0
    end

    def avanzar(tiempo=1)
        self.reloj ||= 0
        self.reloj += tiempo if tiempo > 0
    end

    def mostrar(lista, texto='')
        puts " #{nombre} (#{self.hora}s, #{lista.count}) [#{texto}] #{configurando? ? :configurando : ''} #{editando? ? :editando : ''} ".titulo do 
            lista.each{|e| puts ' • %2is > %2i ' % [e.hora, e.cantidad] }
        end
        puts ''
    end
    
    def reducir(lista)
        pares = lista.zip(lista[1..-1])
        pares.each{|anterior, actual| yield( anterior, actual ) }
    end
end

# ---

def Cola(nombre, cantidad=0, &bloque)
    tmp = Cola.new( nombre )
    tmp.avanzar(0)
    cantidad.times{ tmp.entrar }
    tmp.instance_eval( &bloque )
    tmp 
end

if __FILE__ == $0
    puts ' Simulacion '.pad(100).error
    Cola 'Polo Norte' do 
        entrar
        entrar
        entrar
        entrar
        entrar
        avanzar 10 #5 
        salir
        salir       
        avanzar 30  #3
        salir 
        avanzar 10  #2
        
        pp muestra(100).promedio.round(1)
    end
 end