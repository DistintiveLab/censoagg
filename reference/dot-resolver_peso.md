# Resolve a coluna de peso: explicita, padrao do dataset ou autodetectada (primeira coluna ^PESO)

Resolve a coluna de peso: explicita, padrao do dataset ou autodetectada
(primeira coluna ^PESO)

## Usage

``` r
.resolver_peso(dados, dataset, peso = NULL)
```

## Arguments

- dados:

  Base (ou apenas o schema) onde procurar a coluna.

- dataset:

  `"pessoas"`, `"domicilios"` ou `"familias"`.

- peso:

  Coluna explicita; quando informada, vence as demais regras.

## Value

Nome da coluna de peso.

## Erro

Sem peso explicito, sem padrao do dataset e sem coluna `^PESO`, para com
erro explicativo lembrando que os microdados publicos de 2022 nao trazem
pesos (usar `soma`/`media` ou o acesso controlado).

## See also

[`.peso_padrao()`](https://distintivelab.github.io/censoagg/reference/dot-peso_padrao.md)
