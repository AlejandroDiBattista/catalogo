require 'pp'
def convertir(lista)
  lista.map{|c,d,i|[c.to_i, d, i.gsub(',', '.').to_f, 0, 0]}
end

def leer(origen)
  lista = open("#{origen}.csv").map{|x|x.split(';')[0..2]}[1..-1]
  convertir(lista)
end

unidades = leer(:rotacion_unidades)
importes = leer(:rotacion_importes)
munecas  = leer(:rotacion_unidades_munecas)

def pareto(lista)
  total = lista.map{|x|x[2]}.inject(&:+)
  acumulado = 0
  lista.map do |codigo, descripcion, valor, _, _|
    porcentaje = valor / total
    acumulado += porcentaje
    [codigo, descripcion, valor, 100*porcentaje.round(3), 100*acumulado.round(3)]
  end
end

def filtar(lista)
  lista.select{|c, d, v, p, a| yield(d)}
end

def mostrar(lista, mensaje='Ranking de productos', umbral=100)
  umbral = umbral * 100 if umbral <= 1
  puts
  puts "#{mensaje.upcase} (#{umbral}%)"
  puts "\nOrden | Código | Descripción                              | Unid. | Porc. | Acum."
  unidades, porcentaje = 0, 0
  lista.each_with_index do |(c,d,v,p,a), i|
    puts "  %3i | %6i | %-30s | %5.0f |  %4.1f | %5.1f " % [i, c, d, v, p, a] if a <= umbral
    unidades   += v
    porcentaje += p
  end
  puts "  %3i   %6s   %-40s   %5.0f |  %4.1f  " % [lista.count, "", "", unidades, porcentaje]
  puts
end
def analizar(lista, condicion, texto='Productos', umbral=1)
  tmp = filtar(lista){|x|x[condicion]}
  mostrar pareto(tmp), "Ranking de #{texto.upcase}", umbral
end

ranking = pareto(unidades)


# analizar ranking, /^arroz/i, "Arroz"
# analizar ranking, /harina/i, "Harina"
#
# analizar ranking, /jugo/i, "Jugo"
# analizar ranking, /jugo inca bc/i, "Jugos Inca BC"
# analizar ranking, /jugo baggio/i,   "Jugos Baggio"
# analizar ranking, /jugo.*ades/i, "Jugos ADES"
# analizar ranking, //, "Global"

def clasificar(base, clasificacion)
  salida = []
  for condicion in clasificacion.map(&:first)
    salida << filtar(base){|x|x[condicion]}
  end
  base - salida.flatten(1)
end

Clasificacion = [
  [/^arroz/i,               "Arroz"],
  [/harina/i,               "Harina"],
  [/azucar/i,               "Azucar"],
  [/vino/i,                 "Vino"],
  [/detergente/i,           "Detergentes"],
  [/jabon.*polvo/i,         "Jabón en Polvo"],
  [/jugo/i,                 "Jugo"],
  [/yogur/i,                "Yogur"],
  [/dulce.*leche/i,         "Dulce de Leche"],
  [/^merm/i,                "Mermelada"],
  [/^gelatina/i,            "Gelatina"],
  [/Crema.*leche/i,         "Crema de Leche"],
  [/^leche/i,               "Leche"],
  [/mayonesa/i,             "Mayonesa"],
  [/mostaza/i,              "Mostaza"],
  [/lavandina/i,            "Lavandina"],
  [/Espiral/i,              "Espiral"],
  [/Caldo/i,                "Caldo"],
  [/^Sopa/i,                "Sopa"],
  [/papel.*hig/i,           "Panel Higienico"],
  [/Toall/i,                "Toallitas"],
  [/^Rollo/i,               "Rollo de cocina"],
  [/^Salchi/i,              "Salchica"],
  [/jabon.*toc/i,           "Jabón de Tocador"],
  [/jabon.*pan/i,           "Jabón en Pan"],
  [/SHAMPOO/i,              "Shampoo"],
  [/^Acon/i,                "Acondicionador"],
  [/^Suavi/i,               "Suavisante"],
  [/^Fideo/i,               "Fideos"],
  [/^Post/i,                "Postre"],
  [/^Yerba/i,               "Yerba Mate"],
  [/^Te/i,                  "Te"],
  [/Velas/i,                "Velas"],
  [/^Pica/i,                "Picadillo"],
  [/^Sal /i,                "Sal"],
  [/^Pure.*tom/i,           "Pure de tomate"],
  [/^Tomat/i,               "Tomate"],
  [/^PAÐAL/i,               "Pañales"],
  [/^Meda/i,                "Medallon"],
  [/^Soda/i,                "Soda"],
  [/^Meda/i,                "Medallon"],
  [/^Hambu/i,               "Hamburguesa"],
  [/^Sardina/i,             "Sardina"],
  [/^Atun/i,                "Atun"],
  [/^Queso/i,               "Queso"],
  [/^Marga/i,               "Margarina"],
  [/^Pimien/i,              "Pimienta"],
  [/^Insect/i,              "Insecticida"],
  [/^Fibra/i,               "Fibra Esponja"],
  [/^Polenta/i,             "Polenta"],
  [/galleta/i,              "Galletas"],
  [/^Caballa/i,             "Caballa"],
  [/^Caf./i,                "Café"],
  [/^Flan/i,                "Flan"],
  [/^Avena/i,               "Avena"],
  [/^Lampara/i,             "Lampara"],
  [/^Crem.*dent/i,          "Crema Dental"],
  [/^Raviol/i,              "Raviol"],
  [/^Prepi/i,               "Prepizas"],
  [/^Vainill/i,             "Vainilla"],
  [/^Lim.*liq/i,            "Limpiador Liquido"],
  [/^Cerea/i,               "Cereal"],
  [/^Servi/i,               "Servilleta"],
  [/^Lustram/i,             "Lustramueble"],
  [/^Burgo/i,               "Burgol"],
  [/^Aceite/i,              "Aceite"],
  [/^Vinag/i,               "Vinagre"],
  [/^Mortadela/i,           "Mortadela"],
  [/^Caca/i,                "Cacao"],
  [/^Trap.*pi/i,            "Trapo de piso"],
  [/^Talco/i,               "Talco"],
  [/^Manteca/i,             "Manteca"],
  [/^Espon/i,               "Esponja"],
  [/^Salam/i,               "Salamen"],
  [/^Levad/i,               "Levadura"],
  [/^Rejilla/i,             "Rejilla"],
  [/^Pan\s/i,               "Pan"],
  [/^Ferne/i,               "Fernet"],
  [/^Arvej/i,               "Arveja"],
  [/^Fecula/i,              "Fecula"],
  [/^Comino/i,              "Comino"],
  [/^Turro/i,               "Turrón"],
  [/^PAÐUELO/i,             "Pañuelo Descartable"],
  [/^Deso.*Amb/i,           "Desodorante de Ambiente"],
  [/^DESOD...[^b]/i,        "Desodorante"],
  [/^Salsa/i,               "Salsa"],
  [/^Ket/i,                 "Ketchup"],
  [/^Fosfo/i,               "Fosforo"],
  [/^Tableta/i,             "Tableta para Mosquito"],
  [/^Bica/i,                "Bicarbonato"],
  [/^Polv/i,                "Polvo"],
  [/^Adi/i,                 "Aditivo"],
  [/^Lico/i,                "Licor"],
  [/^Fiamb/i,               "Fiambre"],
  [/^Desi/i,                "Desifectante"],
  [/^Prote/i,               "Protector"],
  [/^Vaso/i,                "Vaso"],
  [/^Amargo/i,              "Terma"],
  [/^Maiz/i,                "Maiz"],
  [/^Pastilla/i,            "Pastilla para inodoho"],
  [/^Extra.*tom/i,          "Extracto"],
  [/^talla/i,               "Tallarin"],
  [/^grasa/i,               "Grasa"],
  [/^Limpia/i,              "Limpiador"],
  [/^Pate/i,                "Pate"],
  [/^Acti/i,                "Actimel"],
  [/^Cepil/i,               "Cepillo"],
  [/^Preme/i,               "Premezcla"],
  [/^Anti/i,                "Antiedad"],
  [/^Oble/i,                "Oblea"],
  [/^Lana/i,                "Lana de Acero"],
  [/^Tapa/i,                "Tapa para empanada"],
  [/^Seca/i,                "Secador de goma"],
  [/^Pimen/i,               "Pimenton"],
  [/^Condi/i,               "Condimento"],
  [/^Pila/i,                "Pila"],
  [/^Orega/i,               "Oregano"],
  [/^Dulce.*mem/i,          "Dulce Membrillo"],
  [/^Dulce.*bat/i,          "Dulce Batata"],
  [/^Jab.*liq/i,            "Jabon Liquido"],  
  [/^Edul|^Endul/i,         "Edulcorante"],
  [/^Aceitu/i,              "Aceituna"],
  [/^Autob/i,               "Autobrillo"],
  [/^Repele/i,              "Repelente"],
  [/^duraz/i,               "Durazno"],
  [/^Gaseo/i,               "Gaseosa"],
  [/^vidaco/i,              "Vidacol"],
  [/^capel/i,               "Capelettini"],
  [/^Alimen.*perr/i,        "Alimento para perro"],
  [/^Brillo/i,              "Brillo"],
  [/^Coctel/i,              "Coctel"],
  [/^Aperitivo/i,           "Aperitivo"],
  [/^Carame/i,              "Caramelo"],
  [/^Anana/i,               "Ananá"],
  [/^Maq.*af*|^Repue/i,     "Máquina de Afeitar"],
  [/^rebo/i,                "Rebozador"],
  [/^Frane/i,               "Franela"],
  [/^Lenteja/i,             "Lenteja"],
  [/^Algo/i,                "Algodon"],
  [/^Crema h/i,             "Crema Hinds"],
  [/^Semol/i,               "Semola"],
  [/Papa/i,                 "Papa"],
  [/^Bizco/i,               "Biscochuelo"],
  [/^Alco*/i,               "Alcohol"]
]

base = pareto(munecas)
mostrar clasificar(base, Clasificacion), "Sin Clasificar"

analizar base, *Clasificacion[-2]

puts "Falta clasificar #{clasificar(base, Clasificacion).size} productos. \n (Hay #{Clasificacion.size} clasificaciones)"