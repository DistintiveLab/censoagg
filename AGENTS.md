# AGENTS.md — censoagg

Ponte censobr -> formato longo do DW beep. Textos em pt-BR;
MIT DistintiveLab.

## Comandos

```r
devtools::document()   # NAMESPACE + man/ (roxygen2 markdown)
devtools::test()       # 24 testes offline
source("data-raw/dicionarios.R")  # snapshots data/*.rda (requer censobr)
```

## Contratos

- Funções runtime (`agregar_microdados`, `agregar_setores`) devolvem
  **lista nomeada variável -> long(local, periodo, valor)**;
  `periodo` = 31/12 do ano do censo.
- Estatística analítica de microdados **sempre ponderada**
  (PESO_PES/PESO_DOM/PESO_FAM, autodetectadas por `^PESO` com
  override); bairro/setor => agregados por setor, nunca microdados.
- `"."`, `""`, `"X"`, `"-"` viram NA (`.para_numerico`); somas com
  `na.rm` => equivalente a zero, médias ponderadas excluem o NA do
  denominador.
- Sem censobr instalado: erro explicativo (`.exigir_censobr`); nada
  de download em `.onLoad`.
- `local` sai como character do código IBGE (7 dígitos município,
  15 dígitos setor — setor não encaixa no DW atual do beep até
  existirem níveis submunicipais).
- Nível "brasil": chave NULL, coluna `local` = "Brasil".
