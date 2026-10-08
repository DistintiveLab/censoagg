# AGENTS.md — censoagg

Ponte censobr -> formato longo do DW beep. Textos em pt-BR;
MIT DistintiveLab.

## Comandos

```r
devtools::document()   # NAMESPACE + man/ (roxygen2 markdown)
devtools::test()       # 27 testes offline
source("data-raw/dicionarios.R")  # snapshots data/*.rda (requer censobr)
pkgdown::build_site()  # site local em docs/ (gitignored)
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
  existirem níveis submunicipais). Chaves territoriais seguem o
  censobr/geobr: `code_muni`, `code_weighting` e `code_tract`
  (setor — **não** existe `code_setor` nos parquets).
- `man/` é gerado por `devtools::document()` e versionado; função
  nova precisa de roxygen com `@param`/`@return` e de bump de
  versão no DESCRIPTION + entrada no NEWS.md.
- Nível "brasil": chave NULL, coluna `local` = "Brasil".

## Site (pkgdown)

- `_pkgdown.yml` define idioma (`lang: pt`), bootstrap 5 e as seções
  do índice de referência; ao criar função nova, inclua-a em
  `reference:`.
- `.github/workflows/pkgdown.yaml` publica o site na branch
  `gh-pages` (URL <https://distintivelab.github.io/censoagg/>) a
  cada push em `main`. `docs/` fica no `.gitignore`: o site só é
  gerado no CI (ou localmente para conferir).
- O pkgdown renderiza todo `.md` da raiz (`build_home_md`), então o
  workflow roda `mv -f AGENTS.md .AGENTS.md` antes do build para
  não publicar esta nota interna.
