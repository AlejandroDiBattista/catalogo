require 'nokogiri'
require 'JSON'
require 'open-uri'
require_relative 'utils'
require_relative 'archivo'
require 'httparty'

require 'net/http'


Base = "https://boletas.yerbabuena.gob.ar/CISI"
URL = "https://boletas.yerbabuena.gob.ar/Inmueble/BuscarDatos"

def get_token()
	Nokogiri::HTML(HTTParty.get(Base).body).css('meta[name="csrf-token"]').to_s.scan(/content="(.*)">/).flatten.first
end

p token =  get_token()
 padron = "80029"

headers = { 
	"authority" => "boletas.yerbabuena.gob.ar",
	"method" 	=> "POST",
	"path" 		=> "/Inmueble/BuscarDatos",
	"scheme" 	=> "https",
	"accept" 	=> "application/json, text/javascript, */*; q=0.01",
	"accept-encoding" 	=> "gzip, deflate, br",
	"accept-language" 	=> "es-AR,es-419;q=0.9,es;q=0.8,en;q=0.7",
	"cache-control" 	=> "no-cache",
	"content-type" 		=> "application/x-www-form-urlencoded; charset=UTF-8",
	"x-csrf-token"		=> token 
}


p HTTParty.post(URL, body: {_token: token, Padron: padron}.to_json, headers: headers).body
