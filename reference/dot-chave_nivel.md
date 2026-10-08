# Chave territorial por nivel (NULL = Brasil inteiro)

Os nomes seguem o censobr/geobr: `code_muni` (7 digitos),
`code_weighting` (area de ponderacao dos microdados) e `code_tract`
(setor censitario, 15 digitos - a coluna se chama `code_tract` nos
parquets de tracts, nao `code_setor`).

## Usage

``` r
.chave_nivel(nivel)
```

## Arguments

- nivel:

  `"municipio"`, `"area_ponderacao"`, `"setor"` ou `"brasil"`.

## Value

Nome da coluna chave (`character`) ou `NULL` no nivel Brasil, que agrega
tudo em uma linha `"Brasil"`.
