require "fileutils"
def nombre(camino)
    File.basename(camino,".docx")
end

def normalizar(expediente)
    lista = expediente.split(",")

    lista.map do |e|
        a = e.split("-")
        orden = a.first.to_i 
        año = a.last.to_i % 100
        "%03i-%02i" % [orden,año]
    end.join(", ")
end

Base = "C:/Users/gogo/Documents/GitHub/OSP/dictamenes"
lista = Dir["#{Base}/***/*.docx"].sort.reverse

nombres = lista.map{|x|nombre(x)}
normalizados = nombres.map{|nombre|normalizar(nombre)}

puts lista.count
lista.each do |origen|    
    p [nombre(origen), destino=normalizar(nombre(origen))]
    destino = "#{Base}/#{destino}.docx"
    FileUtils.cp origen, destino
end

