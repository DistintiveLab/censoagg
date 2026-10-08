# Leitores e helpers internos do censoagg

Purezas testaveis offline: coercao numerica dos agregados do IBGE ("." e
vazio significam NA/zero), escolha da coluna de peso, chave territorial
e o agregador generico em memoria.

## Usage

``` r
.para_numerico(x)
```

## Arguments

- x:

  Vetor de valores lidos do parquet (character ou numerico).

## Value

Vetor `numeric`; `NA` onde o valor nao e numerico.

## Details

Coercao dos valores textuais do IBGE para numero; `"."`, `""`, `"X"` e
`"-"` viram `NA` (que as somas tratam como zero).

## See also

[`.agregador()`](https://distintivelab.github.io/censoagg/reference/dot-agregador.md),
que aplica a coercao antes de somar.
