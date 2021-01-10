
def azar(min = -2, max = 2)
    (rand * (max-min) + min).round(0)
end 

def generar_pesos(pesos)
    pesos.map{azar}
end

def activar(z)
    z < 0 ? 0 : 1 
end

def evaluar(entrada, pesos)
    suma = entrada.zip(pesos).map{|e,p|e*p}.sum
    activar(suma)
end

def ejecutar(entradas, pesos)
    activar( evaluar(entradas + [1], pesos) )
end

def buscar(entradas, salidas, intentos = 1000)
    n = entradas.first.size 
    pesos = Array.new(n,0)
    intentos.times do |i|
        pesos = generar_pesos(pesos)
        evaluaciones = entradas.map{|entrada| evaluar(entrada, pesos) }
        ok = evaluaciones.zip(salidas).all?{|v, s| v == s }
        return pesos if ok 
    end
    nil 
end

datos = [
    [[0, 0], 0], 
    [[0, 1], 0], 
    [[1, 0], 0], 
    [[1, 1], 1],
]

entradas = datos.map{|e, _| e + [1] }
salidas  = datos.map{|_, s| s }


if pesos = buscar(entradas, salidas)
    puts "La solucion es #{pesos}"
    datos.each do |entrada, salida|
        puts " #{entrada} = #{salida} >> #{evaluar(entrada+[1], pesos)}"
    end
else
    puts "No hay solucion"
end 