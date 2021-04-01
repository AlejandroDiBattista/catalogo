# Simulacion pobreza estructural

poblacion = Array.new(100,10)
poblacion.shuffle!

n = poblacion.size
i = n / 2
(0..i).each{|i|poblacion[i]+=1}
(i..n).each{|i|poblacion[i]-=1}
