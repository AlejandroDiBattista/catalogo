require 'open-uri'
require 'csv'
require_relative 'utils'
require 'fileutils'

module Archivo
	def ubicar(camino, diario = false)
		camino = [camino].flatten.map(&:to_s).join("/")
		camino = "#{camino}.dsv" unless camino["."]
		camino = camino.sub(".", Time.now.strftime("_%F")) if diario
		camino
	end

	def buscar(camino, condicion = base)
		camino = [camino].flatten.map(&:to_s).join("/")
		camino = "#{camino}*.*" unless camino["."]
		lista = Dir[camino].sort
		case condicion
		when :base
			lista.select{|x|!x["_"]}.first
		when :primero
			lista.select{|x|x["_"]}.first
		when :ultimo
			lista.select{|x|x["_"]}.last
		when :historia
			lista.select{|x|x["_"]}
		when :todo 
			lista
		else 
			lista.first 
		end
	end

	def leer(camino = :datos)
		datos  = CSV.open(ubicar(camino), :col_sep => "|")
		campos = datos.shift.map(&:to_key)
		datos.map{|x| Hash(campos, x)}.normalizar
	end

	def escribir(datos, camino = :datos, diario = false)
		campos = datos.map(&:keys).uniq.flatten
		CSV.open(ubicar(camino, diario), "wb", :col_sep => "|") do |csv|
			csv << campos.map(&:to_key).map(&:upcase)
			datos.each{|x| csv << campos.map{|c| x[c] } }
		end
		puts "  Escribir #{camino} (#{datos.count})"
	end

	 def bajar(origen, destino, forzar=false)
		begin
			if forzar || !File.exist?(destino)
				URI.open(origen){|f|  File.open(destino, "wb"){|file| file.puts f.read }} 
			end
			true
		rescue
			false
		end
	end

	def borrar(destino)
		puts destino
		begin
			File.delete(destino)
		rescue
			false				
		end
	end
	
	def siguiente(destino)
		Dir["*.*"].select{|x| File.base_name(x)[/$#{destino}/]}
	end

	def fotos
		Dir["fotos/*.jpg"]
	end

	def abrir(url)
		begin
			if block_given?
				URI.open(url){|f| yield(Nokogiri::HTML(f)) }
			else
				Nokogiri::HTML(URI.open(url))
			end
		rescue 
		end
	end
	
end
include Archivo

if __FILE__ == $0 
	pp buscar("jumbo/clasificacion", :base)
	pp buscar("jumbo/clasificacion", :primero)
	pp buscar("jumbo/clasificacion", :ultimo)
	pp buscar("jumbo/clasificacion", :historia)
	pp buscar("jumbo/clasificacion", :todo)
	pp buscar("jumbo/producto", :todo)
end