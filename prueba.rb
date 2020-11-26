require_relative 'utils'
def prueba(*lista, fecha: nil)
	puts lista
	puts fecha
end

# prueba 10, 20, 30
# prueba 10, 20, 30, fecha: 'hoy'

origen = "productos_2020-07-24.dsv"
pp origen.to_fecha
p Date.today