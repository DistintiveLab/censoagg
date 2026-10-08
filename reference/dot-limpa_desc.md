# Limpa quebras do texto do dicionario em uma linha legivel; para descricoes por categoria (repetidas com NA em tracts), o chamador ja mantem a primeira ocorrencia nao vazia por variavel via deduplicacao

Quebras de linha viram `"; "` para que a descricao inteira caiba em uma
celula do painel, sem espacos duplicados nas emendas.

## Usage

``` r
.limpa_desc(x)
```

## Arguments

- x:

  Vetor de descricoes lido do xlsx.

## Value

`character` do mesmo comprimento de `x`, ja aparado.
