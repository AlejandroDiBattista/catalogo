require_relative 'utils'

Unidades = {
	gramos: :gr, gramo: :gr, grs: :gr, gr: :gr, g: :gr, 
	kilogramos: :kg, kilogramo: :kg, kilo: :kg, kgs: :kg, kg: :kg, k: :kg,
	ml: :ml, 
	cc: :cc, 
	litros: :lt, litro: :lt, lt: :lt, l: :lt, 
	unidades: :un, uni: :un, und: :un, u: :un,
}
class String
	def limpiar_nombre
		tmp = espacios.split(' ').map(&:capitalize).join(' ')
			.limpiar_terminacion
			.limpiar_envase
			.limpiar_unidades
			.strip
	end

	def limpiar_envase
		tmp = self
		%w{pack botella bot cja caja paq}.each do |x| 
			tmp = tmp.gsub(/\b#{x}\s*$/i, " #{x}")
		end
		tmp = tmp.gsub(/ x\s*([0-9]+)/i, ' x \1')
		tmp = tmp.gsub(/ [xy] /i){|x|" #{x.downcase} "}
		tmp = tmp.gsub(/(\d+)\.(\d+)/i,'\1,\1')
		tmp.espacios
	end

	def limpiar_unidades
		tmp = self
		tmp = tmp.gsub("unidades", " un ")
		tmp = tmp.gsub(/\bu\b/i, " un ")
		Unidades.each do |origen, destino|
			tmp = tmp.gsub( /\b([0-9,]+)\s*(#{origen})\b/i, ' \1 \2 ')
			tmp = tmp.gsub( /\b#{origen}\b/i, " #{destino} ")
			tmp = tmp.gsub( /(\d+)\s+(#{destino})\b/i, '\1\2')
		end
		tmp.espacios
	end

	def limpiar_terminacion
		gsub(/\s*[.-]*$/, '')
	end

	def separar_unidad
		tmp = limpiar
		if a = tmp.match(/^(.+?)(ml|cc|kg|gr|un|lt)\s([1-9][0-9.,]*)$/i) then
			[a[1].terminacion, "#{a[3]} #{a[2]}" ] 
		elsif a = tmp.match(/^(.+?)([1-9][0-9.,]*.*)$/i) then
			[a[1].terminacion, a[2]]
		else
			[tmp, nil]
		end
	end
end

# puts "CAFE ARLISTAN X17.0G.-".limpiar_nombre
