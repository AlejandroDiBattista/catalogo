require 'json'
require 'open-uri'
require 'rest-client'

#URL = "http://localhost:3000"
URL = "http://approductos.herokuapp.com"


def valido?(codigo)
  [8, 12, 13].include?(codigo.size)
end

def traer_rotaciones_total
  open('rotaciones.csv').map{|x|x.split(';')}[1..-1]
end


def cargar(producto)
  # puts "Guardando Producto #{producto['descripcion']}"
  p RestClient.post "#{URL}/cargar_rotacion", producto.to_json, :content_type => :json, :accept => :json
end


def borrar(codigo)
  if codigo != ""
    p RestClient.delete "#{URL}/borrar", params: { codigo: codigo}
  end
end


traer_rotaciones_total.each do |producto|
  prod = {codigo: producto[0], descripcion: producto[1], rotacion: producto[3]}
  valido?(prod[:codigo]) ? cargar(prod) : borrar(prod[:codigo])
end