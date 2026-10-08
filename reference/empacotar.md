# Empacota o agregado largo em lista long (local, periodo, valor) por variavel

Fecha o contrato de saida do pacote: converte o `data.frame` largo do
agregador (uma linha por chave) na lista nomeada consumida pelo DW, com
`periodo` fixado em 31/12 do ano do censo e `local` sempre character
(codigo IBGE) ou `"Brasil"` no nivel nacional.

## Usage

``` r
empacotar(agg, chave, ano, variaveis)
```

## Arguments

- agg:

  `data.frame` largo devolvido por
  [`.agregador()`](https://distintivelab.github.io/censoagg/reference/dot-agregador.md).

- chave:

  Nome da coluna territorial de `agg`; `NULL` no nivel Brasil.

- ano:

  Ano do censo, usado para montar `periodo`.

- variaveis:

  Vetor de variaveis que virao a ser as entradas da lista de saida.

## Value

Lista nomeada por variavel; cada item e um `tibble` com `local`
(character), `periodo` (`Date`) e `valor` (`numeric`).
