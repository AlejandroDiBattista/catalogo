#Install Packages
# install.packages("rvest")
# install.packages("rjson")
# install.packages("jsonlite")

library(tidyverse)
library(rvest)
library(jsonlite)

pagina <- function(texto) gsub("https://www.jumbo.com.ar/", "", texto)
precio <- function(texto) gsub(",", ".", gsub("[^0-9,.]+", "", texto)) %>% as.numeric()
id     <- function(texto) gsub(".*ids/([0-9]+).*", "\\1", texto)

extraer.pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_text()
extraer.marca  <- function(nodo) nodo %>% html_nodes('.product-item__brand') %>% html_text()
extraer.precio <- function(nodo) nodo %>% html_nodes('.product-prices__value--best-price') %>% html_text() %>% precio()
extraer.pagina <- function(nodo) nodo %>% html_nodes('.product-item__name a') %>% html_attr("href") %>% pagina()
extraer.imagen <- function(nodo) nodo %>% html_nodes('.product-item__image-link img') %>% html_attr("src") %>% id()

bajar.clasificacion <- function() {
  print("BAJANDO CLASIFICACION")
  
  departamentos <- fromJSON('https://www.jumbo.com.ar/api/catalog_system/pub/category/tree/3') %>% filter(hasChildren) %>% arrange(name)
  
  lista = list()
  for (d in 1:nrow(departamentos)) {
    departamento <- departamentos[d,]
    categorias   <- departamento$children[[1]]
    
    if(nrow(categorias) == 0) next
    
    for (c in 1:nrow(categorias)) {
      categoria <- categorias[c,]
      subcategorias <- categoria$children[[1]]
      
      if (!is.null(nrow(subcategorias)) & (nrow(subcategorias) > 0) ) {
        for (s in 1:nrow(subcategorias)) {
          subcategoria <- subcategorias[s,]
          
          item <- tibble(
            departamento = departamento$name,
            categoria    = categoria$name, 
            subcategoria = ifelse(is.null(subcategoria), "-" , subcategoria$name), 
            url          = ifelse(is.null(subcategoria), categoria$url, subcategoria$url) 
          )
          str(item)
          lista <- bind_rows(lista, item)
        }
      }
    }
  }
  lista
}

bajar.catalogo <- function(clasificacion) {
  print("BAJANDO CATALOGO")

    catalogo = list()
  for (i in 1:nrow(clasificacion)) {
    tmp <- clasificacion[i,]

    print(c(nrow(catalogo), tmp$url))
    
    productos = bajar.producto(tmp$url, tmp$departamento, tmp$categoria, tmp$subcategoria)
    if (nrow(productos) == 0) next
    
    str(productos)
    catalogo <- bind_rows(catalogo, productos)
    write.csv2(catalogo, "catalogo.csv")
  }
  catalogo
}

bajar.producto <- function(url, departamento = "", categoria = "", subcategoria = "") {
  url = paste0(url,"?PS=99")
  nodos <- read_html(url) %>% html_nodes('.product-shelf li')
  
  nodos <- nodos[ length(nodos %>% html_nodes('.product-item__no-stock')) == 0 ]
  str(nrow(nodos), url)
  
  tibble(
    nombre = nodos %>% extraer.pagina(),
    marca  = nodos %>% extraer.marca(),
    precio = nodos %>% extraer.precio(),
    pagina = nodos %>% extraer.pagina(),
    imagen = nodos %>% extraer.imagen()
    # ,
    # departamento = departamento,
    # categoria    = categoria,
    # subcategoria = subcategoria
  )
}

#setwd("GitHub/catalogo")

clasificacion <- bajar.clasificacion()
write.csv2(clasificacion, "clasificacion.csv")
#clasificacion = read.csv2("clasificacion.csv")
catalogo <- bajar.catalogo(clasificacion)
View(catalogo)

# url = "https://www.jumbo.com.ar/almacen/pastas-secas-y-salsas/salsas?PS=99"
# nodos <- read_html(url) %>% html_nodes('.product-shelf li')
# print(c(url,length(nodos %>% html_nodes('.product-item__no-stock'))))
