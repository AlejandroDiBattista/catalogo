# encoding: utf-8
require 'json'

Base  = File.dirname(File.expand_path(__FILE__))
productos = JSON.parse(open("#{Base}/productos.json").read)

productos.each do |p|
  descripcion = "#{p['tipo']} #{p['marca']}"
  descripcion += " - #{p['variante']}" if p['variante']

  hash = { 
            codigo:      p['codigo'],
            descripcion: descripcion,
            precio:      p['precio'].to_f,
            gondola:     0,
            activo:      true,
            disponible:  true,
            con_foto:    true
         }
  Producto.create(hash)
end