# censoagg

**Ponte entre o [censobr](https://ipea.github.io/censobr/) e o painel
[beep](https://github.com/DistintiveLab/beep)**: agrega microdados da
amostra e agregados por setor censitário do Censo IBGE (Arrow/parquet)
no formato longo que o data warehouse do beep consome
(`local`, `periodo`, `valor`) — uma série por variável.

```r
remotes::install_github("DistintiveLab/censoagg")

# microdados SEMPRE ponderados (domínios pequenos: usar agregados)
censoagg::agregar_microdados("pessoas", 2022,
  variaveis = c("V0001"), nivel = "municipio", funcao = "soma_pond")

# agregados por setor -> município (contagens; "." vira NA)
censoagg::agregar_setores("Basico", 2022,
  variaveis = c("V0001"), nivel = "municipio")
```

- `agregar_microdados()`: reduz as colunas **antes** do `collect()`,
  recorte via expressão (`corte =`), níveis município/área de
  ponderação/Brasil.
- `agregar_setores()`: níveis setor/município/Brasil (não ponderar:
  são contagens do universo).
- `censo_variaveis()`: dicionário de variáveis para o painel,
  com snapshot lazy (`data-raw/dicionarios.R`) e fallback ao censobr.

Primeira execução baixa os parquets para o cache do censobr.
Microdados 2022 de acesso controlado: usar `censobr::import_microdata22()`.

MIT © 2026 DistintiveLab.
