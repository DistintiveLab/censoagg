# Dicionario de variaveis do Censo (snapshot offline)

Devolve o dicionario para escolha de variaveis no painel beep SEM
depender do censobr em runtime: usa o snapshot lazy do pacote
(`data/dict_*.rda`, gerado por `data-raw/dicionarios.R` a partir dos
xlsx do censobr v1.0.0); sem snapshot, tenta o censobr ao vivo (requer
readxl).

## Usage

``` r
censo_variaveis(ano, dataset = c("microdata", "tracts"), dict = NULL)
```

## Arguments

- ano:

  Ano do censo (2022).

- dataset:

  `"microdata"` ou `"tracts"`.

- dict:

  Snapshot opcional (data.frame com colunas `variavel` e `descricao`;
  opcionalmente `dataset`) - para testes.

## Value

`data.frame` com as colunas `variavel` (codigo usado nas demais
funcoes), `descricao` (rotulo em pt-BR), `dataset` (subbase:
Basico/Pessoas/... para tracts; pessoas/domicilios/ familias para
microdados) e `tema`. Linhas sem codigo ou sem descricao sao
descartadas, o que mantem o resultado alinhado as colunas realmente
presentes nos parquets.

## See also

[`agregar_setores()`](https://distintivelab.github.io/censoagg/reference/agregar_setores.md)
e
[`agregar_microdados()`](https://distintivelab.github.io/censoagg/reference/agregar_microdados.md),
que recebem os codigos devolvidos aqui no argumento `variaveis`.

## Examples

``` r
if (FALSE) { # \dontrun{
d <- censo_variaveis(2022, "tracts")
d[d$variavel == "demografia_V01007", ]
} # }
```
