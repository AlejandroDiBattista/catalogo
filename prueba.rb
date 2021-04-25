Origen = "C:/Users/administrator/Downloads/distritos_electorales_smt.kml"
Destino = "C:/Users/administrator/Downloads/distritos_electorales_smt_nuevo.kml"

Votos = {
    "0001" => {	pj: 16,	jxc: 55, fr: 6, votantes: 6400 },
    "001A" => {	pj: 17,	jxc: 55, fr: 6, votantes: 5300 },
    "0002" => {	pj: 18,	jxc: 54, fr: 5, votantes: 3700 },
    "002A" => {	pj: 18,	jxc: 52, fr: 5, votantes: 4200 },
    "0003" => {	pj: 18,	jxc: 53, fr: 6, votantes: 7000 },
    "0004" => {	pj: 20,	jxc: 52, fr: 5, votantes: 6400 },
    "0005" => {	pj: 13,	jxc: 62, fr: 6, votantes: 11000 },
    "0006" => {	pj: 17,	jxc: 57, fr: 4, votantes: 4900 },
    "0007" => {	pj: 24,	jxc: 46, fr: 4, votantes: 4800 },
    "007A" => {	pj: 23,	jxc: 48, fr: 5, votantes: 6300 },
    "0008" => {	pj: 23,	jxc: 47, fr: 4, votantes: 4700 },
    "008A" => {	pj: 25,	jxc: 44, fr: 5, votantes: 7500 },
    "0009" => {	pj: 34,	jxc: 36, fr: 6, votantes: 11500 },
    "009A" => {	pj: 36,	jxc: 33, fr: 5, votantes: 10700 },
    "0010" => {	pj: 43,	jxc: 27, fr: 4, votantes: 11800 },
    "010A" => {	pj: 52,	jxc: 20, fr: 7, votantes: 20700 },
    "0011" => {	pj: 21,	jxc: 51, fr: 4, votantes: 2100 },
    "011A" => {	pj: 50,	jxc: 22, fr: 5, votantes: 8900 },
    "0012" => {	pj: 25,	jxc: 45, fr: 5, votantes: 11800 },
    "012A" => {	pj: 36,	jxc: 34, fr: 6, votantes: 9200 },
    "0013" => {	pj: 33,	jxc: 37, fr: 5, votantes: 11000 },
    "013A" => {	pj: 30,	jxc: 37, fr: 6, votantes: 4500 },
    "0014" => {	pj: 35,	jxc: 36, fr: 5, votantes: 19100 },
    "014A" => {	pj: 46,	jxc: 24, fr: 5, votantes: 2900 },
    "014B" => {	pj: 55,	jxc: 18, fr: 7, votantes: 3200 },
    "014C" => {	pj: 52,	jxc: 23, fr: 7, votantes: 6000 },
    "014D" => {	pj: 50,	jxc: 19, fr: 5, votantes: 4500 },
    "0015" => {	pj: 37,	jxc: 31, fr: 5, votantes: 13800 },
    "015A" => {	pj: 43,	jxc: 29, fr: 6, votantes: 11700 },
    "015B" => {	pj: 41,	jxc: 32, fr: 5, votantes: 21600 },
    "0016" => {	pj: 24,	jxc: 48, fr: 5, votantes: 14100 },
    "016A" => {	pj: 30,	jxc: 43, fr: 5, votantes: 12500 },
    "0017" => {	pj: 30,	jxc: 41, fr: 5, votantes: 16100 },
    "017A" => {	pj: 25,	jxc: 51, fr: 5, votantes: 11700 },
    "0018" => {	pj: 31,	jxc: 39, fr: 5, votantes: 16900 },
    "018A" => {	pj: 40,	jxc: 31, fr: 7, votantes: 3800 },
    "018B" => {	pj: 40,	jxc: 32, fr: 8, votantes: 9700 },
    "018C" => {	pj: 47,	jxc: 24, fr: 7, votantes: 9800 },
    "018D" => {	pj: 42,	jxc: 32, fr: 6, votantes: 5700 },
    "018E" => {	pj: 44,	jxc: 28, fr: 7, votantes: 10100 },
    "018F" => {	pj: 48,	jxc: 22, fr: 8, votantes: 4500 },
    "018G" => {	pj: 48,	jxc: 24, fr: 7, votantes: 5000 },
    "0019" => {	pj: 39,	jxc: 33, fr: 6, votantes: 15200 },
    "019A" => {	pj: 51,	jxc: 20, fr: 7, votantes: 10600 },
    "0020" => {	pj: 47,	jxc: 24, fr: 6, votantes: 24700 },
    "0021" => {	pj: 52,	jxc: 19, fr: 7, votantes: 19800 },
    "0022" => {	pj: 38,	jxc: 36, fr: 8, votantes: 7100 }
}

i = 100

valores = {}
salida = open(Destino, "w+")

open(Origen).each do |linea|
    if linea.strip == "<Placemark>"
        i = 0
        puts
    end

    if i == 1
        nombre = linea.strip.gsub("<name>","").gsub("</name>","")
        puts "Nombre : #{nombre}"
        valores = Votos[nombre]
        puts valores
        unless valores
            puts "ERROR en #{nombre}"
            exit
        end
    end

    if i == 1 || i == 8 || i == 11 || i == 14 || i == 17
        print " #{i}) "
        puts linea
    end

    puts(linea = "            <value>#{valores[:pj]}</value>")          if i ==  9
    puts(linea = "            <value>#{valores[:jxc]}</value>")         if i == 12
    puts(linea = "            <value>#{valores[:fr]}</value>")          if i == 15
    puts(linea = "            <value>#{valores[:votantes]}</value>")    if i == 18

    i = i + 1
    salida.puts linea
end

salida.close