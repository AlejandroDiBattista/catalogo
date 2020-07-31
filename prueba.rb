require 'httparty'
o = "https://www.disco.com.ar/Login/PreHomeService.aspx/CategoriaSubcategoria"

class Disco
  include HTTParty
  base_uri 'http://www.disco.com.ar'

  # def initialize(service, page)
  #   @options = { query: { site: service, page: page } }
  # end

  def clasificacion
    self.class.get("/Login/PreHomeService.aspx/CategoriaSubcategoria")
  end

  def users
    self.class.get("/2.2/users", @options)
  end
end

d = Disco.new
p d.clasificacion