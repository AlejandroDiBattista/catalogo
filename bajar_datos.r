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

departamento_incluir <- function(clasificacion) clasificacion %in% list("Almacén", "Bebidas", "Carnes", "Congelados", "Frutas y Verduras", "Lácteos", "Limpieza", "Panadería y Repostería",  "Perfumería", "Quesos y Fiambres")  

imagen_file   <- function(imagen) paste0("fotos/",imagen,".jpg")
imagen_url    <- function(imagen, tamaño=512) paste0("https://jumboargentina.vteximg.com.br/arquivos/ids/",imagen,"-", tamaño,"-",tamaño)
imagen_existe <- function(imagen) file.exists(imagen_file(imagen))
imagen_bajar  <- function(imagen, tamaño=512) try( download.file(imagen_url(imagen, tamaño), imagen_file(imagen), mode = 'wb', quiet=TRUE), silent = TRUE) 

extraer_nombre <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_text()
extraer_marca  <- function(nodo) nodo %>% html_nodes('.product-item__brand') %>% html_text()
extraer_precio <- function(nodo) nodo %>% html_nodes('.product-prices__value--best-price') %>% html_text() %>% precio()
extraer_pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_attr("href") %>% pagina()
extraer_imagen <- function(nodo) nodo %>% html_nodes('.product-item__image-link img') %>% html_attr("src") %>% id()


recorrer <- function(dato, funcion) {
  if( is(dato, "tbl") && isTRUE(nrow(dato) > 0)) {
    for(c in 1:nrow( dato )) {
      funcion( dato[c,] )
    }
  }
  dato
}

clasificacion_bajar <- function() {
  print("BAJANDO CLASIFICACION")
  
  departamentos <- fromJSON('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3') %>% filter(hasChildren) %>% arrange(name)
  
  clasificacion = list()
  for (d in 1:nrow(departamentos)) {
    departamento <- departamentos[d,]
    categorias   <- departamento$children[[1]]
    
    for (c in 1:nrow(categorias)) {
      if(c > 0 ) next
 
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
  print("CLASIFICACION BAJADA")
  return(clasificacion)
}

clasificacion_escribir <- function(clasificacion) {
  write.csv2(clasificacion, "clasificacion.csv")
  clasificacion
}

clasificacion_leer <- function() {
  read.csv2("clasificacion.csv") %>% as_tibble() %>% filter(departamento_incluir( departamento ) )
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

imagenes_bajar <- function(catalogo, tamaño = 512, optimizar = FALSE) {
  print("BAJANDO IMAGENES")
  if(optimizar) { catalogo <- catalogo %>% filter(!imagen_existe(imagen)) }
  catalogo %>% recorrer( function(item){
    imagen_bajar(item, tamaño ) 
    str(item)
  })
  print("IMAGENES BAJADAS")
  catalogo
}

try(setwd("GitHub/catalogo"), silent = TRUE)

clasificacion_bajar() %>% clasificacion_escribir() %>% 
   catalogo_bajar() %>% catalogo_escribir() %>% 
     imagenes_bajar()
   