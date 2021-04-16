Muestra = { 1 => 36, 2 => 44, 3 => 8 }
Total = Muestra.values.sum
module Enumerable
    def contar
        uniq.map{|i|[i, count(i)]}.sort_by(&:first)
    end
end

def generar
    i = rand(Total)
    suma = 0 
    Muestra.each do |personas, frecuencia| 
        suma += frecuencia 
        return personas if suma > i 
    end
end

veces = 1_000_000
puts "\nSimulación Descongelacion Anticipada"
for dosis in  [5, 10, 15, 20, 25]
    for autos in 1..dosis 
        casos = 0
        veces.times do 
            personas = autos.times.map{generar}.sum 
            casos += 1 if personas >= dosis 
        end
        probabilidad = 100.0 * (casos / veces.to_f)
        if probabilidad >= 99.9
            puts "  Para #{dosis} dosis debe haber #{autos} autos (Seguridad %4.1f%%)" % probabilidad
            break 
        end
    end
end
total = Muestra.values.sum


# Simulación Descongelacion Anticipada (90%)
#   Para  5 dosis debe haber  4 autos (Seguridad  97.2%)
#   Para 10 dosis debe haber  7 autos (Seguridad  91.9%)
#   Para 15 dosis debe haber 11 autos (Seguridad  97.7%)
#   Para 20 dosis debe haber 14 autos (Seguridad  96.1%)
#   Para 25 dosis debe haber 17 autos (Seguridad  94.6%)

# Simulación Descongelacion Anticipada (95%)
#   Para  5 dosis debe haber  4 autos (Seguridad  97.2%)
#   Para 10 dosis debe haber  8 autos (Seguridad  99.2%)
#   Para 15 dosis debe haber 11 autos (Seguridad  97.7%)
#   Para 20 dosis debe haber 14 autos (Seguridad  96.1%)
#   Para 25 dosis debe haber 18 autos (Seguridad  98.7%)

# Simulación Descongelacion Anticipada (99%)
#   Para  5 dosis debe haber  5 autos (Seguridad 100.0%)
#   Para 10 dosis debe haber  8 autos (Seguridad  99.2%)
#   Para 15 dosis debe haber 12 autos (Seguridad  99.7%)
#   Para 20 dosis debe haber 15 autos (Seguridad  99.3%)
#   Para 25 dosis debe haber 19 autos (Seguridad  99.8%)

# Simulación Descongelacion Anticipada (99.9%)
#   Para  5 dosis debe haber  5 autos (Seguridad 100.0%)
#   Para 10 dosis debe haber  9 autos (Seguridad 100.0%)
#   Para 15 dosis debe haber 13 autos (Seguridad 100.0%)
#   Para 20 dosis debe haber 16 autos (Seguridad  99.9%)
#   Para 25 dosis debe haber 20 autos (Seguridad 100.0%)