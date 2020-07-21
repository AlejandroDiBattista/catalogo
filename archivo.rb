require 'open-uri'
require 'csv'
require_relative 'utils'

module Archivo
	def leer(origen = :datos)
		origen = "#{origen}.dsv" if Symbol === origen
		datos  = CSV.open(origen, :col_sep => "|")
		campos = datos.shift
		datos.map{|x| Hash(campos, x)}.normalizar
	end

	def escribir(datos, destino = :datos)
		destino = "#{destino}.dsv" if Symbol === destino
		campos = datos.map(&:keys).uniq.flatten
		CSV.open(destino, "wb", :col_sep => "|") do |csv|
			csv << campos
			datos.each{|x| csv << campos.map{|c| x[c] } }
		end
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
	
	def fotos
		Dir["fotos/*.jpg"]
	end
end
include Archivo
