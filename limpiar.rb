class String
	def separar
		strip.scan(/^(.{2,})\s(\d+.*)$/)
	end
	def unidad
		strip
			.gsub(/([a-zñ]+)\.\s*/i,"\\1 ")
			.gsub(/([0-9.]+)([^0-9]*)/, "\\1 \\2")
			.gsub(/\bG\b/,"GR")
			.gsub(/\bGRS\b/,"GR")
			.gsub(/\bL\b/,"LT")
			.gsub(/\s+/," ")
			.strip
	end
end
lista = Archivo.leer("productos_01.dsv")
pp lista.first(3)
nombres = lista.map(&:nombre).uniq.map(&:upcase).sort.map(&:separar).map(&:last).compact.map(&:last).uniq.sort.map(&:unidad).uniq.sort
pp nombres

cantidad = ""