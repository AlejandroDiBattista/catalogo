#Install Packages
# install.packages("rvest")
# install.packages("rjson")
# install.packages("jsonlite")

library(tidyverse)
library(rvest)
library(jsonlite)

is_error <- function(x) inherits(x, "try-error")

pagina <- function(texto) gsub("https://www.jumbo.com.ar/", "", texto)
precio <- function(texto) gsub(",", ".", gsub("[^0-9,]+", "", texto)) %>% as.numeric()
id     <- function(texto) gsub(".*ids/([0-9]+).*", "\\1", texto)

departamento_incluir <- function(clasificacion) clasificacion %in% list("Almac�n", "Bebidas", "Carnes", "Congelados", "Frutas y Verduras", "L�cteos", "Limpieza", "Panader�a y Reposter�a",  "Perfumer�a", "Quesos y Fiambres")  

imagen_file   <- function(imagen) paste0("fotos/",imagen,".jpg")
imagen_url    <- function(imagen, tama�o=512) paste0("https://jumboargentina.vteximg.com.br/arquivos/ids/",imagen,"-", tama�o,"-",tama�o)
imagen_existe <- function(imagen) file.exists(imagen_file(imagen))
imagen_bajar  <- function(imagen, tama�o=512) try( download.file(imagen_url(imagen, tama�o), imagen_file(imagen), mode = 'wb', quiet=TRUE), silent = TRUE) 

extraer_nombre <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_text()
extraer_marca  <- function(nodo) nodo %>% html_nodes('.product-item__brand') %>% html_text()
extraer_precio <- function(nodo) nodo %>% html_nodes('.product-prices__value--best-price') %>% html_text() %>% precio()
extraer_pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_attr("href") %>% pagina()
extraer_imagen <- function(nodo) nodo %>% html_nodes('.product-item__image-link img') %>% html_attr("src") %>% id()

recorrer <- function(dato,funcion){
  if(nrow(dato) > 0) {
    for(c in 1:nrow( dato )) {
      funcion( dato[c,] )
    }
  }
  dato
}

clasificacion_bajar <- function() {
  print("BAJANDO CLASIFICACION")
  
  departamentos clasificacion = list()
  departamentos %>% recorrer( function(departamento) {
    categorias <- departamento$children[[1]]
    
    categorias %>% recorrer( function(categoria) {  
      subcategorias <- categoria$children[[1]]
      
      subcategorias %>% recorrer( function(subcategoria) {
        if(is.null(subcategoria$name)){
          subcategoria = tibble(name = "-", url  = categoria$url)
        }
        
        item <- tibble(departamento = departamento$name, categoria = categoria$name, subcategoria = subcategoria$name, url = subcategoria$url )
        str(item)
        clasificacion <- bind_rows(clasificacion, item)
      })
    })
  })
  <- fromJSON('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3') %>% 
    filter(hasChildren) %>% 
    arrange(name)
  
  
  print("CLASIFICACION BAJADA")
  clasificacion
}

clasificacion_escribir <- function(clasificacion) {
  write.csv2(clasificacion, "clasificacion.csv")
  clasificacion
}

clasificacion_leer <- function(con_imagen = FALSE) {
  clasificacion <- read.csv2("clasificacion.csv") %>% as_tibble() %>% filter(departamento_incluir( departamento ) )
  if(con_imagen){ clasificacion <- clasificacion %>% filter( !imagen_existe(imagen) ) }                                                 
  clasificacion
}

producto_bajar <- function(url, departamento = "", categoria = "", subcategoria = "") {
  url = paste0(url,"?PS=99")
  
  nodos <- read_html(url) %>% html_nodes('.product-shelf li')
  nodos <- nodos[ length(nodos %>% html_nodes('.product-item__no-stock')) == 0 ]

  productos = tibble(
    nombre = nodos %>% extraer_nombre(),
    marca  = nodos %>% extraer_marca(),
    precio = nodos %>% extraer_precio(),
    pagina = nodos %>% extraer_pagina(),
    imagen = nodos %>% extraer_imagen()
  )
  
  productos$departamento = departamento
  productos$categoria    = categoria
  productos$subcategoria = subcategoria
  
  productos
}

catalogo_bajar <- function(clasificacion) {
  print("BAJANDO CATALOGO")
  
  catalogo = list()
  clasificacion %>% recorrer( function(producto) {
    productos = try(producto_bajar(producto$url, producto$departamento, producto$categoria, producto$subcategoria))
    if (!is_error(productos) ) {
      str(productos)
      catalogo <- bind_rows(catalogo, productos)
      catalogo %>% catalogo_escribir()
    }
  })
  
  print("CATALOGO BAJADO")
  catalogo
}

catalogo_escribir <- function(catalogo){
  write.csv2(catalogo, "catalogo.csv")
  catalogo
}

catalogo_leer <- function(con_imagen=NA) {
  catalogo <- read.csv2("catalogo.csv") %>% as_tibble() %>% filter(departamento_incluir( departamento ))
  if( isTRUE(con_imagen)  ) { catalogo <- catalogo %>% filter(imagen_existe(imagen))  }
  if( isFALSE(con_imagen) ) { catalogo <- catalogo %>% filter(!imagen_existe(imagen)) }
  catalogo
}

imagenes_bajar <- function(catalogo,tama�o = 512, optimizar = FALSE) {
  print("BAJANDO IMAGENES")
  if(optimizar) { catalogo <- catalogo %>% filter(!imagen_existe(imagen)) }
  catalogo %>% recorrer( function(item){
    imagen_bajar(item, tama�o ) 
    str(item)
  })
  print("IMAGENES BAJADAS")
  catalogo
}

try(setwd("GitHub/catalogo"), silent = TRUE)

catalogo_leer() %>% imagenes_bajar()
View(catalogo)


clasificacion_bajar() %>% clasificacion_escribir() %>% 
  catalogo_bajar() %>% catalogo_escribir() %>% 
    imagenes_bajar()
  