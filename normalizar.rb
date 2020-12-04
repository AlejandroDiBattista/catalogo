class String
	def terminacion
		%w{x pack botella bot cja paq}.each do |x| 
			puts x
			gsub!(/-\s*$/,"")
			gsub!(/\b#{x}\s*$/i, " #{x} ")
			gsub!(/-\s*$/,"")
		end
		espacios
	end

	def limpiar
		gsub!("unidades", " un ")
		gsub!(/\bu\b/i, " un ")
		%w{ml gr cc kg un lt}.each{|x| gsub!( /\b#{x}\.?-?/i, " #{x} ")}
		espacios
	end

	def separar_unidad
		tmp = limpiar
		if a = tmp.match(/^(.+?)(ml|cc|kg|gr|un|lt)\s([1-9][0-9.,]*)$/i)
			[a[1].terminacion, "#{a[3]} #{a[2]}" ] 
		elsif a = tmp.match(/^(.+?)([1-9][0-9.,]*.*)$/i)
			[a[1].terminacion, a[2]]
		# elsif a = tmp.match(/^(.+)\s(por|x)\s\b(kg|k|kilo|kilogramos)\b.*$/i)
		# 	[a[1], "1 kg"]
		else
			[tmp, nil]
		end

	end
end

# class String
# 	def separar
# 		strip.scan(/^(.{2,})\s(\d+.*)$/)
# 	end
	
# 	def unidad
# 		strip
# 			.gsub(/([a-zñ]+)\.\s*/i,"\\1 ")
# 			.gsub(/([0-9.]+)([^0-9]*)/, "\\1 \\2")
# 			.gsub(/\bG\b/,"GR")
# 			.gsub(/\bGRS\b/,"GR")
# 			.gsub(/\bL\b/,"LT")
# 			.gsub(/\s+/," ")
# 			.strip
# 	end
# end


a = "Cera Líquida Para Madera Suiza-roble Oscuro-tradicional-bot"

x = "bot"
p a.gsub( /\b#{x}\.?-?/i, " #{x} ")
p a.terminacion
return

n = Catalogo.leer(:jumbo).nombres
n = n.select{|x| /-/ === x}.map{|x| [x, x.separar_unidad ].flatten}
# n = n.select{|x| /^\d+$/ === x.last }
n.each{|x|puts "%-80s %-80s %-40s" % x}
puts "----"
return
n = n.map(&:separar_unidad)
n = n.select{|a, b| b }
n = n.uniq#.select {|x| x[/\d/]  }

pp n 
p n.size