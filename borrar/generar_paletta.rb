
require 'erb'

    # @include my-palette(primary, var(--primary-color-l), 5%, 98%);
    # @include my-palette(neutral, var(--neutral-color-l), 30%, 99%);


    # #{$name}: hsl(var(#{$base}-h), var(#{$base}-s), var(#{$name}-l));


primary  = { h: 198, s: 1.0, l: 0.53, min: 0.05, max: 0.98, tonos: (100..900).step(100).to_a + [850] }
neutral  = { h: 198, s: 0.8, l: 0.35, min: 0.30, max: 0.99, tonos: (100..900).step(100).to_a + [850] }
accents1 = { h: 122, s: 0.6, l: 0.53, min: 0.10, max: 0.90, tonos: [500] }
accents2 = { h:  24, s: 1.0, l: 0.50, min: 0.10, max: 0.90, tonos: [500] }
accents3 = { h:   1, s: 1.0, l: 0.56, min: 0.10, max: 0.90, tonos: [500] }

def calcular_luminancia(luminancia, tono, min, max)
    t = (tono - 100.0) / 800;

    initial = 2 * (max + min) * t * t - (max + 3 * min) * t + min
    return 4 * luminancia * t * (1 - t) + initial

    # $base: "--#{$pallete}-color";
    # $name: "--#{$pallete}-#{$tone}";

    #{$name}-h: var(#{$base}-h);
    #{$name}-s: var(#{$base}-s);
    #{$name}-l: #{$lum};
end

def listar_paleta(paleta)
    paleta[:tonos].sort.each do |tono|
        l = calcular_luminancia(paleta[:l], tono, paleta[:min], paleta[:max])
        puts "  %3i > %3i, %3i%%, %3i%% " % [tono, paleta[:h], 100*paleta[:s], 100*l]
    end
end

puts "Primary"
listar_paleta primary
puts "Neutral"
listar_paleta neutral
return 
class Color < Struct.new(:nombre, :variable, :paleta)

	def variables
		# self.tonos.map{|a, b| ["--#{self.variable}-#{a}", a, hsl_3(b)]}
        tonos = self.paleta[:tonos]
        min = self.paleta[:min]
        max = self.paleta[:max]

        self.tonos.map{|a, b| ["--#{self.variable}-#{a}", a, hsl_3(b)]}
	end

    def color
        self.paleta
    end

	def trio(s)
		h = color[:h]
		s ||= color[:s]
		l = color[:l]
		["%i" % h, "%0.0f%%" % (s * 100), "%0.0f%%" % (l * 100)]
	end

	def hsl(s=nil)
		"hsl(#{trio(s).join(", ")})".gsub(", 0%", ", Saturation")
	end

	def hsl_3(s)
		trio(s)[1]
	end
end

Paleta = [
	Color.new("Primary", :primary, primary),
	Color.new("Neutral", :neutral, neutral),
	Color.new("Accents 1", :accents1, accents1),
	Color.new("Accents 2", :accents2, accents2),
	Color.new("Accents 3", :accents3, accents3),
]


Pagina = <<EOF
<!DOCTYPE html>
<html>
	<head>
		<style>
			body {
		  		background-color: white;
			}

			span {
				display: inline-block;
			}

			.colores span div {
				width: 40px;
				height: 30px;
				margin: 2px;

				border-radius: 2px;
				box-shadow: 0 0 3px gray;

				text-shadow: 0 0 2px black, 0 0 2px black;
				font-size: 8px;
				color: white;
			}

			.colores b {
				font-size: 14px;
				padding: 0;
				margin: 0;
				padding-left: 5px;
			}

			.colores p {
				padding: 0;
				margin: 0;
				font-size: 12px;
				padding-left: 10px;
			}


			.convertir span {
				border-radius: 8px;
				box-shadow: 0 0 5px gray;
				padding: 4px;
				margin-bottom: 8px;
			}

			.convertir span div div {
				width: 100px;
				height: 32px;
				margin: 4px;

				border-radius: 4px;
				box-shadow: 0 0 3px gray;
				
				text-shadow: 0 0 4px black, 0 0 4px black;
				color: white;
			}

			p { padding: 2px; }
			h1, h2, h3 { margin: 0; padding: 0; }
			h2 {
				font-size: 20px;
				padding-top: 16px;
			}
			.borde {
				border: 4px solid gray;
				box-shadow: 0 0 6px black;
			}
			<%= Variables %>
		</style>
	</head>

	<body>
		<h1>AMIRA Palette v1</h1>
		<%= generar_cuerpo() %>
	</body>
</html>
EOF

Variables = <<EOF
:root {
    --primary-color-h: 198;
    --primary-color-s: 40%;
    --primary-color-l: 52%;

    --neutral-color-h: 198;
    --neutral-color-s: 10%;
    --neutral-color-l: 90%;

    --accents1-color-h: 145;
    --accents1-color-s: 80%;
    --accents1-color-l: 60%;

    --accents2-color-h: 45;
    --accents2-color-s: 80%;
    --accents2-color-l: 60%;

    --accents3-color-h: 5;
    --accents3-color-s: 80%;
    --accents3-color-l: 60%;

    --primary-color:  hsl( var(--primary-color-h ), var(--primary-color-s ), var(--primary-color-l ) );
    --neutral-color:  hsl( var(--neutral-color-h ), var(--neutral-color-s ), var(--neutral-color-l ) );
    --accents1-color: hsl( var(--accents1-color-h), var(--accents1-color-s), var(--accents1-color-l) );
    --accents2-color: hsl( var(--accents2-color-h), var(--accents2-color-s), var(--accents2-color-l) );
    --accents3-color: hsl( var(--accents3-color-h), var(--accents3-color-s), var(--accents3-color-l) );
}

:root {
    --primary-100: hsl(var(--primary-color-h), var(--primary-color-s), 5%);
    --primary-100-h: var(--primary-color-h);
    --primary-100-s: var(--primary-color-s);
    --primary-100-l: 5%;
    --primary-200: hsl(var(--primary-color-h), var(--primary-color-s), 16%);
    --primary-200-h: var(--primary-color-h);
    --primary-200-s: var(--primary-color-s);
    --primary-200-l: 16%;
    --primary-300: hsl(var(--primary-color-h), var(--primary-color-s), 28%);
    --primary-300-h: var(--primary-color-h);
    --primary-300-s: var(--primary-color-s);
    --primary-300-l: 28%;
    --primary-400: hsl(var(--primary-color-h), var(--primary-color-s), 40%);
    --primary-400-h: var(--primary-color-h);
    --primary-400-s: var(--primary-color-s);
    --primary-400-l: 40%;
    --primary-500: hsl(var(--primary-color-h), var(--primary-color-s), 51%);
    --primary-500-h: var(--primary-color-h);
    --primary-500-s: var(--primary-color-s);
    --primary-500-l: 51%;
    --primary-600: hsl(var(--primary-color-h), var(--primary-color-s), 63%);
    --primary-600-h: var(--primary-color-h);
    --primary-600-s: var(--primary-color-s);
    --primary-600-l: 63%;
    --primary-700: hsl(var(--primary-color-h), var(--primary-color-s), 74%);
    --primary-700-h: var(--primary-color-h);
    --primary-700-s: var(--primary-color-s);
    --primary-700-l: 74%;
    --primary-800: hsl(var(--primary-color-h), var(--primary-color-s), 86%);
    --primary-800-h: var(--primary-color-h);
    --primary-800-s: var(--primary-color-s);
    --primary-800-l: 86%;
    --primary-850: hsl(var(--primary-color-h), var(--primary-color-s), 92%);
    --primary-850-h: var(--primary-color-h);
    --primary-850-s: var(--primary-color-s);
    --primary-850-l: 92%;
    --primary-900: hsl(var(--primary-color-h), var(--primary-color-s), 98%);
    --primary-900-h: var(--primary-color-h);
    --primary-900-s: var(--primary-color-s);
    --primary-900-l: 98%;
    --neutral-100: hsl(var(--neutral-color-h), var(--neutral-color-s), 30%);
    --neutral-100-h: var(--neutral-color-h);
    --neutral-100-s: var(--neutral-color-s);
    --neutral-100-l: 30%;
    --neutral-200: hsl(var(--neutral-color-h), var(--neutral-color-s), 38%);
    --neutral-200-h: var(--neutral-color-h);
    --neutral-200-s: var(--neutral-color-s);
    --neutral-200-l: 38%;
    --neutral-300: hsl(var(--neutral-color-h), var(--neutral-color-s), 47%);
    --neutral-300-h: var(--neutral-color-h);
    --neutral-300-s: var(--neutral-color-s);
    --neutral-300-l: 47%;
    --neutral-400: hsl(var(--neutral-color-h), var(--neutral-color-s), 56%);
    --neutral-400-h: var(--neutral-color-h);
    --neutral-400-s: var(--neutral-color-s);
    --neutral-400-l: 56%;
    --neutral-500: hsl(var(--neutral-color-h), var(--neutral-color-s), 65%);
    --neutral-500-h: var(--neutral-color-h);
    --neutral-500-s: var(--neutral-color-s);
    --neutral-500-l: 65%;
    --neutral-600: hsl(var(--neutral-color-h), var(--neutral-color-s), 73%);
    --neutral-600-h: var(--neutral-color-h);
    --neutral-600-s: var(--neutral-color-s);
    --neutral-600-l: 73%;
    --neutral-700: hsl(var(--neutral-color-h), var(--neutral-color-s), 82%);
    --neutral-700-h: var(--neutral-color-h);
    --neutral-700-s: var(--neutral-color-s);
    --neutral-700-l: 82%;
    --neutral-800: hsl(var(--neutral-color-h), var(--neutral-color-s), 91%);
    --neutral-800-h: var(--neutral-color-h);
    --neutral-800-s: var(--neutral-color-s);
    --neutral-800-l: 91%;
    --neutral-900: hsl(var(--neutral-color-h), var(--neutral-color-s), 99%);
    --neutral-900-h: var(--neutral-color-h);
    --neutral-900-s: var(--neutral-color-s);
    --neutral-900-l: 99%;
    --accents1-100: hsl(var(--accents1-color-h), var(--accents1-color-s), 10%);
    --accents1-100-h: var(--accents1-color-h);
    --accents1-100-s: var(--accents1-color-s);
    --accents1-100-l: 10%;
    --accents1-200: hsl(var(--accents1-color-h), var(--accents1-color-s), 20%);
    --accents1-200-h: var(--accents1-color-h);
    --accents1-200-s: var(--accents1-color-s);
    --accents1-200-l: 20%;
    --accents1-300: hsl(var(--accents1-color-h), var(--accents1-color-s), 30%);
    --accents1-300-h: var(--accents1-color-h);
    --accents1-300-s: var(--accents1-color-s);
    --accents1-300-l: 30%;
    --accents1-400: hsl(var(--accents1-color-h), var(--accents1-color-s), 40%);
    --accents1-400-h: var(--accents1-color-h);
    --accents1-400-s: var(--accents1-color-s);
    --accents1-400-l: 40%;
    --accents1-500: hsl(var(--accents1-color-h), var(--accents1-color-s), 50%);
    --accents1-500-h: var(--accents1-color-h);
    --accents1-500-s: var(--accents1-color-s);
    --accents1-500-l: 50%;
    --accents1-600: hsl(var(--accents1-color-h), var(--accents1-color-s), 60%);
    --accents1-600-h: var(--accents1-color-h);
    --accents1-600-s: var(--accents1-color-s);
    --accents1-600-l: 60%;
    --accents1-700: hsl(var(--accents1-color-h), var(--accents1-color-s), 70%);
    --accents1-700-h: var(--accents1-color-h);
    --accents1-700-s: var(--accents1-color-s);
    --accents1-700-l: 70%;
    --accents1-800: hsl(var(--accents1-color-h), var(--accents1-color-s), 80%);
    --accents1-800-h: var(--accents1-color-h);
    --accents1-800-s: var(--accents1-color-s);
    --accents1-800-l: 80%;
    --accents1-900: hsl(var(--accents1-color-h), var(--accents1-color-s), 90%);
    --accents1-900-h: var(--accents1-color-h);
    --accents1-900-s: var(--accents1-color-s);
    --accents1-900-l: 90%;
    --accents2-100: hsl(var(--accents2-color-h), var(--accents2-color-s), 10%);
    --accents2-100-h: var(--accents2-color-h);
    --accents2-100-s: var(--accents2-color-s);
    --accents2-100-l: 10%;
    --accents2-200: hsl(var(--accents2-color-h), var(--accents2-color-s), 20%);
    --accents2-200-h: var(--accents2-color-h);
    --accents2-200-s: var(--accents2-color-s);
    --accents2-200-l: 20%;
    --accents2-300: hsl(var(--accents2-color-h), var(--accents2-color-s), 30%);
    --accents2-300-h: var(--accents2-color-h);
    --accents2-300-s: var(--accents2-color-s);
    --accents2-300-l: 30%;
    --accents2-400: hsl(var(--accents2-color-h), var(--accents2-color-s), 40%);
    --accents2-400-h: var(--accents2-color-h);
    --accents2-400-s: var(--accents2-color-s);
    --accents2-400-l: 40%;
    --accents2-500: hsl(var(--accents2-color-h), var(--accents2-color-s), 50%);
    --accents2-500-h: var(--accents2-color-h);
    --accents2-500-s: var(--accents2-color-s);
    --accents2-500-l: 50%;
    --accents2-600: hsl(var(--accents2-color-h), var(--accents2-color-s), 60%);
    --accents2-600-h: var(--accents2-color-h);
    --accents2-600-s: var(--accents2-color-s);
    --accents2-600-l: 60%;
    --accents2-700: hsl(var(--accents2-color-h), var(--accents2-color-s), 70%);
    --accents2-700-h: var(--accents2-color-h);
    --accents2-700-s: var(--accents2-color-s);
    --accents2-700-l: 70%;
    --accents2-800: hsl(var(--accents2-color-h), var(--accents2-color-s), 80%);
    --accents2-800-h: var(--accents2-color-h);
    --accents2-800-s: var(--accents2-color-s);
    --accents2-800-l: 80%;
    --accents2-900: hsl(var(--accents2-color-h), var(--accents2-color-s), 90%);
    --accents2-900-h: var(--accents2-color-h);
    --accents2-900-s: var(--accents2-color-s);
    --accents2-900-l: 90%;
    --accents3-100: hsl(var(--accents3-color-h), var(--accents3-color-s), 10%);
    --accents3-100-h: var(--accents3-color-h);
    --accents3-100-s: var(--accents3-color-s);
    --accents3-100-l: 10%;
    --accents3-200: hsl(var(--accents3-color-h), var(--accents3-color-s), 20%);
    --accents3-200-h: var(--accents3-color-h);
    --accents3-200-s: var(--accents3-color-s);
    --accents3-200-l: 20%;
    --accents3-300: hsl(var(--accents3-color-h), var(--accents3-color-s), 30%);
    --accents3-300-h: var(--accents3-color-h);
    --accents3-300-s: var(--accents3-color-s);
    --accents3-300-l: 30%;
    --accents3-400: hsl(var(--accents3-color-h), var(--accents3-color-s), 40%);
    --accents3-400-h: var(--accents3-color-h);
    --accents3-400-s: var(--accents3-color-s);
    --accents3-400-l: 40%;
    --accents3-500: hsl(var(--accents3-color-h), var(--accents3-color-s), 50%);
    --accents3-500-h: var(--accents3-color-h);
    --accents3-500-s: var(--accents3-color-s);
    --accents3-500-l: 50%;
    --accents3-600: hsl(var(--accents3-color-h), var(--accents3-color-s), 60%);
    --accents3-600-h: var(--accents3-color-h);
    --accents3-600-s: var(--accents3-color-s);
    --accents3-600-l: 60%;
    --accents3-700: hsl(var(--accents3-color-h), var(--accents3-color-s), 70%);
    --accents3-700-h: var(--accents3-color-h);
    --accents3-700-s: var(--accents3-color-s);
    --accents3-700-l: 70%;
    --accents3-800: hsl(var(--accents3-color-h), var(--accents3-color-s), 80%);
    --accents3-800-h: var(--accents3-color-h);
    --accents3-800-s: var(--accents3-color-s);
    --accents3-800-l: 80%;
    --accents3-900: hsl(var(--accents3-color-h), var(--accents3-color-s), 90%);
    --accents3-900-h: var(--accents3-color-h);
    --accents3-900-s: var(--accents3-color-s);
    --accents3-900-l: 90%;
}
EOF

Cuerpo = <<EOF
<% for a in Paleta %>
	<h2> <%= a.nombre %> = <%= a.hsl() %></h2>
	<div class="colores">
		<% for (variable, i,c) in a.variables %>
			<span>
				<div style="background-color:var(<%= variable %>);" class="<%= i.to_s=="500" ? "borde": "" %>" >
					<b><%= i %></b>
					<p><%= c %></p>
				</div>
			</span>
		<% end %>
	</div>
<% end %>
EOF

def generar_cuerpo()
	ERB.new(Cuerpo).result()
end

open("paleta.html", "w"){|f|f.puts ERB.new(Pagina).result() }
