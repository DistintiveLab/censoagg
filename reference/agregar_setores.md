# Agrega os agregados por setor censitario do Censo

Le
[`censobr::read_tracts()`](https://ipea.github.io/censobr/reference/read_tracts.html)
e soma as variaveis pedidas por setor censitario, municipio ou Brasil.
Sao contagens do universo, logo nao se ponderam; valores `"."`, `""`,
`"X"` e `"-"` do IBGE viram `NA` e entram como zero na soma.

## Usage

``` r
agregar_setores(
  dataset = "Basico",
  ano = 2022,
  variaveis,
  nivel = c("municipio", "setor", "brasil"),
  corte = NULL,
  show_progress = FALSE
)
```

## Arguments

- dataset:

  Subbase do `read_tracts`. Para 2022: `"Basico"`, `"Domicilio"`,
  `"Pessoas"`, `"Indigenas"`, `"Quilombolas"`, `"ResponsavelRenda"`,
  `"Entorno"`, `"Obitos"` ou `"Preliminares"` (2010: `"Basico"`,
  `"Domicilio"`, `"DomicilioRenda"`, `"Responsavel"`,
  `"ResponsavelRenda"`, `"Pessoa"`, `"PessoaRenda"`, `"Entorno"`). Use
  [`censo_variaveis()`](https://distintivelab.github.io/censoagg/reference/censo_variaveis.md)
  para ver qual subbase tem cada codigo.

- ano:

  Ano do censo (2022 publico).

- variaveis:

  Vetor de variaveis de contagem, no formato `tema_V00xxx` (ex.:
  `"demografia_V01007"`), como saem do dicionario.

- nivel:

  `"municipio"` (default), `"setor"` ou `"brasil"`; a chave e
  `code_muni`, `code_tract` (convencao geobr do censobr; o codigo de
  setor tem 15 digitos e ainda nao encaixa nos niveis do DW do beep) ou
  nenhuma, respectivamente.

- corte:

  Expressao de recorte (character), opcional, ex.:
  `"code_muni == 5300108"` para o Distrito Federal; roda no Arrow, antes
  de trazer os dados para a memoria.

- show_progress:

  Repassado ao censobr (barra de download).

## Value

Lista nomeada por variavel, cada item um `data.frame` long com `local`,
`periodo` e `valor`; veja o contrato completo em
[censoagg-package](https://distintivelab.github.io/censoagg/reference/censoagg-package.md).

## See also

[`agregar_microdados()`](https://distintivelab.github.io/censoagg/reference/agregar_microdados.md)
para estatisticas ponderadas de microdados e
[`censo_variaveis()`](https://distintivelab.github.io/censoagg/reference/censo_variaveis.md)
para descobrir os codigos das variaveis.

Other agregadores:
[`agregar_microdados()`](https://distintivelab.github.io/censoagg/reference/agregar_microdados.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# populacao por municipio
agregar_setores("Basico", 2022, variaveis = c("V0001"),
                nivel = "municipio")

# homens e mulheres por setor censitario no DF
agregar_setores("Pessoas", 2022,
                variaveis = c("demografia_V01007",
                              "demografia_V01008"),
                nivel = "setor", corte = "code_muni == 5300108")
} # }
```
