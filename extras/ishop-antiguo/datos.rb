require 'json'
require 'pp'


#Usar +"/db" si lo corro desde bundle rails

Base = Dir.pwd

def traer_datos
  JSON.parse(open("#{Base}/inventario-29-10-2012.json").read).map{|x|[x['codigo'], x['gondola']]}
end

def traer_rotaciones(minimo=1)
  # rotaciones  = open('rotaciones.csv'){|x|x.split(';')}[1..-1].map{|codigo,descripcion,pesos,unidades,utilidad|codigo}
  open("#{Base}/rotaciones.csv").map{|x|x.split(';')}[1..-1].select{|u| u[4].to_i >= minimo}.map{|x|x[0]}.uniq
end

def traer_originales
  JSON.parse(open("#{Base}/productos.json").read).map{|x|x['codigo']}.uniq.sort
end

def traer_verificados
  traer_datos.map(&:first).uniq.sort
end

def traer_gondolas
  gondolas = Hash.new{[]}
  for codigo, gondola in traer_datos
    if corregir?(codigo)
      partir(limpiar(codigo)).each{|x| gondolas[gondola] <<= x}
    elsif valido?(codigo)
      gondolas[gondola] <<= codigo
    end
  end
  gondolas
end

def separar(codigos, separador)
  codigos.map do |codigo|
    if codigo[separador]
      codigo.split(separador).map{|x|"#{separador}#{x}"}[1..-1]
    else
      codigo
    end
  end.flatten
end


def limpiar(codigo)
  codigo = codigo.gsub(/^000/,'')
  codigo = codigo.gsub(/^790150696491/,  '')
  codigo = codigo.gsub(/5000292001001$/, '')
  codigo.strip
end

def partir(codigo)
  codigo = [codigo]
  codigo = separar(codigo, '779')
  codigo = separar(codigo, '03700')
  codigo = separar(codigo, '750')
  codigo = separar(codigo, '7590')
end

def corregir?(codigo)
  codigo.size >= 16
end

def valido?(codigo)
  [8, 12, 13].include?(codigo.size)
end

def limpiar_gondolas(gondolas)
  gondolas.each do |gondola|
    productos =  Producto.en_gondola(gondola[0]).where("codigo not in (?)", gondola[1])
    puts "Borrando Codigos erroneos en gondola #{gondola[0]}"
    productos.destroy_all
  end
end

rotacion_minima = 10

activas     = traer_rotaciones(rotacion_minima)
gondolas    = traer_gondolas()


originales  = traer_originales()
verificados = traer_verificados()


vinos  = %w{1052 1053 1083 1084 1085}.map{|x|gondolas[x]}.flatten.uniq

altas  = verificados - originales
bajas  = gondolas['0'].uniq

disponible         = verificados - altas - bajas
disponible_quietas = disponible - activas
disponible_activas = disponible - disponible_quietas

actuales           = verificados - bajas
actuales_quietas   = actuales - activas
actuales_activas   = actuales - actuales_quietas

fotos_sacar   = altas - vinos
fotos_quietas = fotos_sacar - activas
fotos_activas = fotos_sacar - fotos_quietas

vinos_quietos = vinos - activas
vinos_activo  = vinos - vinos_quietos

puts "---| INFORME |---"
puts "  %5i : Inicial"     % originales.size
puts "  %5i : + Altas"     % altas.size
puts "  %5i : - Bajas"     % bajas.size
puts "  %5i : Final"  % actuales.size
puts
puts "  %5i : Rotaron (Agosto - Minimo de #{rotacion_minima}) " % activas.size
puts
puts "  %5i : Disponible" % disponible.size
puts "  %5i :   Activas"  % disponible_activas.size
puts "  %5i :   Quietas"  % disponible_quietas.size
puts
puts "  %5i : Actuales"  % actuales.size
puts "  %5i :   Activas" % actuales_activas.size
puts "  %5i :   Quietas" % actuales_quietas.size
puts

puts "---| FOTOS |---"
puts "  %5i : Listas"      % originales.size
puts "  %5i : Para sacar"  % fotos_sacar.size
puts "  %5i :   Activas"   % fotos_activas.size
puts "  %5i :   Quietas"   % fotos_quietas.size
puts "  %5i : Vinos"       % vinos.size
puts "  %5i :   Activos"   % vinos_activo.size
puts "  %5i :   Quietos"   % vinos_quietos.size
puts

puts "\n---| DETALLE |---"

# limpiar_gondolas(gondolas.to_a)

