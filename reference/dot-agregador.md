# Agregador generico em memoria (testavel offline)

Agrupa `dados` pela chave e calcula `funcao` para cada variavel.
Ponderadas pre-multiplicam x pelo peso e dividem a soma dos pesos apenas
nas linhas com x observado.

## Usage

``` r
.agregador(dados, chave, variaveis, funcao, peso = NULL)
```

## Arguments

- dados:

  `data.frame` ja reduzido as colunas necessarias.

- chave:

  Coluna de agrupamento; `NULL` agrega tudo em `"Brasil"` (cria a coluna
  `local`).

- variaveis:

  Variaveis a agregar.

- funcao:

  `"soma"`, `"media"`, `"soma_pond"` ou `"media_pond"`; as variantes
  `_pond` exigem `peso`.

- peso:

  Coluna de peso, obrigatoria nas funcoes ponderadas e ignorada nas
  demais.

## Value

`data.frame` largo com a chave e uma coluna por variavel.

## NA e ponderacao

Valores textuais passam por
[`.para_numerico()`](https://distintivelab.github.io/censoagg/reference/dot-para_numerico.md)
(`"."`/`""` -\> NA); somas usam `na.rm` (NA equivale a zero) e medias
ponderadas excluem do denominador apenas as linhas com valor ausente.
