# Alias de sheet do xlsx para dataset do painel (microdados)

Alias de sheet do xlsx para dataset do painel (microdados)

## Usage

``` r
.sheet_para_dataset(sheet)
```

## Arguments

- sheet:

  Nome da sheet do xlsx (`PESS...`, `DOMI...` ou `FAMI...`).

## Value

`"pessoas"`, `"domicilios"` ou `"familias"`; `NA` para sheets fora
desses prefixos.
