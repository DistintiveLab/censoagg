# Agrega microdados do Censo por territorio

Le os microdados via censobr (Arrow), reduz as colunas necessarias ANTES
de trazer os dados para a memoria (microdados da amostra sao grandes) e
agrega cada variavel pedida pela funcao escolhida. Toda estatistica
analitica deve ser ponderada; dominios pequenos (bairro/setor) pertencem
aos agregados por setor, nao aos microdados.

## Usage

``` r
agregar_microdados(
  dataset = c("pessoas", "domicilios", "familias"),
  ano = 2022,
  variaveis,
  nivel = c("municipio", "area_ponderacao", "brasil"),
  funcao = c("soma_pond", "media_pond", "soma", "media"),
  peso = NULL,
  corte = NULL,
  show_progress = FALSE
)
```

## Arguments

- dataset:

  `"pessoas"`, `"domicilios"` ou `"familias"`.

- ano:

  Ano do censo (2022 publico; 2010...).

- variaveis:

  Vetor de variaveis do dicionario
  ([`censo_variaveis()`](https://distintivelab.github.io/censoagg/reference/censo_variaveis.md));
  colunas ausentes na base pedida param com erro listando o que faltou.

- nivel:

  `"municipio"` (default), `"area_ponderacao"` ou `"brasil"`, define a
  chave territorial: `code_muni`, `code_weighting` ou nenhuma (Brasil
  inteiro).

- funcao:

  `"soma_pond"` (default), `"media_pond"`, `"soma"` ou `"media"`. As
  variantes `_pond` multiplicam cada valor pelo peso e dividem pela soma
  dos pesos.

- peso:

  Coluna de peso; default resolve por dataset
  (PESO_PES/PESO_DOM/PESO_FAM ou autodeteccao por `^PESO`), com override
  explicito por este argumento.

- corte:

  Expressao de recorte (character, ex.: `"V1005 == 1"`), opcional; as
  colunas citadas entram na leitura e o filtro roda no Arrow, antes de
  trazer os dados para a memoria.

- show_progress:

  Repassado ao censobr (barra de download).

## Value

Lista nomeada por variavel, cada item um `data.frame` long com `local`,
`periodo` e `valor`; veja o contrato completo em
[censoagg-package](https://distintivelab.github.io/censoagg/reference/censoagg-package.md).

## Ponderacao

Somas ponderadas pre-multiplicam o valor pelo peso e somam com `na.rm`;
medias ponderadas excluem do denominador apenas as linhas com valor
ausente (soma dos pesos das linhas observadas).

## Limitacao do microdado publico de 2022

O microdado publico de 2022 distribuido pelo censobr vem reduzido pelo
IBGE: sem `code_muni`, sem codigos `V...` e sem pesos. Com ele, use
`funcao = "soma"`/`"media"`; para estatisticas ponderadas use o acesso
controlado
([`censobr::import_microdata22()`](https://ipea.github.io/censobr/reference/import_microdata22.html))
com `peso = "PESO_PES"`, ou prefira
[`agregar_setores()`](https://distintivelab.github.io/censoagg/reference/agregar_setores.md).
Os microdados de 2010 funcionam ponderados.

## See also

[`agregar_setores()`](https://distintivelab.github.io/censoagg/reference/agregar_setores.md)
para contagens por setor censitario e
[`censo_variaveis()`](https://distintivelab.github.io/censoagg/reference/censo_variaveis.md)
para descobrir os codigos das variaveis.

Other agregadores:
[`agregar_setores()`](https://distintivelab.github.io/censoagg/reference/agregar_setores.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# contagem de pessoas por municipio (ponderada)
agregar_microdados("pessoas", 2010, variaveis = c("V0001"),
                   nivel = "municipio", funcao = "soma_pond")
} # }
```
