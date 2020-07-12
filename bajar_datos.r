#Install Packages
# install.packages("rvest")
# install.packages("rjson")
# install.packages("jsonlite")

library(tidyverse)
library(rvest)
library(jsonlite)

pagina <- function(texto) gsub("https://www.jumbo.com.ar/", "", texto)
precio <- function(texto) gsub(",", ".", gsub("[^0-9,]+", "", texto)) %>% as.numeric()
id     <- function(texto) gsub(".*ids/([0-9]+).*", "\\1", texto)
is.error <- function(x) inherits(x, "try-error")

incluir  <- function(clasificacion) clasificacion  %in% list("Almacén", "Bebidas", "Carnes", "Congelados", "Frutas y Verduras", "Lácteos", "Limpieza", "Panadería y Repostería",  "Perfumería", "Quesos y Fiambres")  

imagen.file <- function(imagen) paste0("fotos/",imagen,".jpg")
imagen.url  <- function(imagen, tamaño=512) paste0("https://jumboargentina.vteximg.com.br/arquivos/ids/",imagen,"-", tamaño,"-",tamaño)

extraer.pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_text()
extraer.marca  <- function(nodo) nodo %>% html_nodes('.product-item__brand') %>% html_text()
extraer.precio <- function(nodo) nodo %>% html_nodes('.product-prices__value--best-price') %>% html_text() %>% precio()
extraer.pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_attr("href") %>% pagina()
extraer.imagen <- function(nodo) nodo %>% html_nodes('.product-item__image-link img') %>% html_attr("src") %>% id()

bajar.clasificacion <- function() {
  print("BAJANDO CLASIFICACION")
  
  departamentos <- fromJSON('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3') %>% filter(hasChildren) %>% arrange(name)
  
  clasificacion = list()
  for (d in 1:nrow(departamentos)) {
    departamento <- departamentos[d,]
    categorias   <- departamento$children[[1]]
    
    for (c in 1:nrow(categorias)) {
      if(c > 0 ){
        categoria <- categorias[c,]
        subcategorias <- categoria$children[[1]]
        
        if (is.null(nrow(subcategorias))) next
        
        for (s in 1:nrow(subcategorias)) {
          if( s == 0) next
          subcategoria <- subcategorias[s,]
          
          if(is.null(subcategoria$name)){
            nombre = "-"
            url    = categoria$url
          } else {
            nombre = subcategoria$name
            url    = subcategoria$url
          }
          
          item <- tibble(departamento = departamento$name, categoria = categoria$name, subcategoria = nombre, url = url )
          str(item)
          clasificacion <- bind_rows(clasificacion, item)
        }
        
      }
    }
  }
  print("CLASIFICACION BAJADA")
  return(clasificacion)
}

bajar.producto <- function(url, departamento = "", categoria = "", subcategoria = "") {
  url = paste0(url,"?PS=99")
  nodos <- read_html(url) %>% html_nodes('.product-shelf li')
  
  nodos <- nodos[ length(nodos %>% html_nodes('.product-item__no-stock')) == 0 ]
  str(c( url, length(nodos %>% extraer.marca()), length(nodos)))
  
  productos = tibble(
    nombre = nodos %>% extraer.pagina(),
    marca  = nodos %>% extraer.marca(),
    precio = nodos %>% extraer.precio(),
    pagina = nodos %>% extraer.pagina(),
    imagen = nodos %>% extraer.imagen()
  )
  
  productos$departamento = departamento
  productos$categoria    = categoria
  productos$subcategoria = subcategoria
  
  return(productos)
}

bajar.catalogo <- function(clasificacion) {
  print("BAJANDO CATALOGO")
  
  catalogo = list()
  for (i in 1:nrow(clasificacion)) {
    tmp <- clasificacion[i,]
    productos = try(bajar.producto(tmp$url, tmp$departamento, tmp$categoria, tmp$subcategoria))
    if (is.error(productos) ) next
  
    str(productos)
    catalogo <- bind_rows(catalogo, productos)
    write.csv2(catalogo, "catalogo.csv")
  }
  print("CATALOGO BAJADO")
  return(catalogo)
}

bajar.imagenes <- function(catalogo, tamaño=256) {
  print("BAJANDO IMAGENES")
  for(c in 1:nrow(catalogo)){ 
    id <- catalogo[c,]$imagen
    origen  = imagen.url(id, tamaño)
    destino = imagen.file(id)
    print(c(c,destino))
    if(!file.exists(destino)){
      try(download.file(origen , destino, mode = 'wb', quiet = TRUE))
    }
  }
  print("IMAGENES BAJADAS")
}

setwd("GitHub/catalogo")
# 
# 
# clasificacion <- bajar.clasificacion()
# write.csv2(clasificacion, "clasificacion.csv")
# 
# # clasificacion = read.csv2("clasificacion.csv")
# clasificacion <- clasificacion %>% filter(categoria != "Panaderia")
# 
# catalogo <- bajar.catalogo(clasificacion)
#   # View(catalogo)

catalogo <- read.csv2("catalogo.csv") 
catalogo <- as.tibble(catalogo) %>% filter(incluir( departamento ))
bajar.imagenes(catalogo)