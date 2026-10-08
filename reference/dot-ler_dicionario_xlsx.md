# Parseia o xlsx do dicionario do censobr (v1.0.0) para long

Layouts: sheets de tracts tem colunas nomeadas (Variavel, Tema,
Descricao por categoria - descricoes repetidas com NA); sheets de
microdados sao posicionais (col 1 = codigo, col 2 = descricao com
categorias embutidas).

## Usage

``` r
.ler_dicionario_xlsx(path, dataset)
```

## Arguments

- path:

  Caminho do xlsx devolvido por
  [`censobr::data_dictionary()`](https://ipea.github.io/censobr/reference/data_dictionary.html).

- dataset:

  `"tracts"` ou `"microdata"`; define quais sheets entram (tracts ignora
  `Siglas`, microdados exigem `_publico`).

## Value

`data.frame` long (variavel, descricao, dataset, tema), ordenado por
subbase e codigo, com uma linha por variavel.
