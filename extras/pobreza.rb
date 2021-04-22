# Simulacion pobreza estructural

def simular(poblacion, repeticiones)
    poblacion = poblacion.clone 
    repeticiones.times do |v|
        poblacion.select!{|x|x > 0 }                                    # Sin dinero no podes seguir
        break if poblacion.size < 2                                     # Evitar jugar solo
        m =  poblacion.size / 2
        
        poblacion.shuffle!                                              # Transacciones sin merito alguno, mezclados al azar
    
        impuesto = poblacion[0...m].sum * Impuesto 
        (0...m).each{|i| poblacion[i] *= (1-Impuesto) }                 # Sacarle a los que mas tienen en proporcion
        (-m..-1).each{|i|poblacion[i] += impuesto / m.to_f}             # Darle a los que menos tiene en forma igualiaria
        #(0...n).each{|i|poblacion[i] += impuesto / n.to_f}             # Darle a todos por igual

        (0...m).each{|i|poblacion[i] += Intercambio }                   # Los primeros ganan
        (-m..-1).each{|i|poblacion[i] -= Intercambio }                  # Los ultimos pierden

        # p poblacion.sort.reverse.first(50).map{|x|(100.0 * x / (Poblacion * Riqueza)).to_i}
    end
    return poblacion 
end

Poblacion   = 1000
Riqueza     = 10.0
Intercambio =  1.0
Impuesto    =  0.01 

poblacion = Array.new(Poblacion, Riqueza)   # Empezamos todo iguales

puts 
puts "Simulación de pobreza estructural (n = #{poblacion.count} x $#{poblacion.sum}) (Impuesto de %0.1f%%)" % [100*Impuesto]

for r in [1_000,10_000, 100_0000]
    poblacion = simular(poblacion, r)
    rico = poblacion.max / poblacion.sum.to_f
    concentracion = rico / (1.0 / Poblacion.to_f)
    inclusion     = 100.0*(poblacion.size / Poblacion.to_f)
    puts " - El mas rico se quedo con %3.0f%%,  Concentración %2.0f, Inclusión: %3.0f%% (en %8i repeticiones) " % [100.0*rico, concentracion, inclusion, r ]
end