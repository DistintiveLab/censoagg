# censoagg 0.0.1.9005

- Site de documentacao publicado com pkgdown (`_pkgdown.yml`, tema
  bootstrap 5, `lang: pt`) em <https://distintivelab.github.io/censoagg/>,
  servido da branch `gh-pages`.
- GitHub Actions (`.github/workflows/pkgdown.yaml`) reconstroi e
  publica o site a cada push em `main`, pull request, release ou
  disparo manual; o deploy cria a `gh-pages` automaticamente.
- `AGENTS.md` e nota interna: o workflow a esconde antes do build,
  porque o pkgdown renderiza todo `.md` da raiz do pacote.
- `docs/` continua fora do versionamento; a URL do site entra no
  campo `URL` do DESCRIPTION.

# censoagg 0.0.1.9004

- Documentacao completa: roxygen com `@param`/`@return`, secoes de
  ponderacao e da limitacao do microdado publico, `@seealso` e
  `@family` em todas as funcoes; as paginas `man/` passam a ser
  geradas por `devtools::document()` e versionadas.
- README com o contrato de saida, a tabela de niveis territoriais e o
  exemplo validado de homens/mulheres por setor censitario no DF;
  AGENTS.md registra que a chave de setor e `code_tract`.
- Removida a copia morta de `censo_variaveis()` em `R/agregar.R` (a
  versao viva esta em `R/dicionario.R`).
- Os snapshots `dict_tracts_2022` e `dict_microdata_2022` ganharam
  pagina propria (`?dict_2022`, com formato e fonte), eliminando o
  aviso de dados nao documentados.
- Dependencias declaradas direito: `rlang` em Imports e `readxl` em
  Suggests; `NAMESPACE` passa a ser inteiramente gerado por roxygen2
  (com `importFrom(utils, data)`, sem imports ociosos de dplyr).
- Empacotamento: `LICENSE` no formato reconhecido (YEAR/COPYRIGHT
  HOLDER) e `data-raw/`, `LICENSE.md` e `.crush` fora do build.

# censoagg 0.0.1.9003

- Fix: `nivel = "setor"` usava a coluna `code_setor`, que nao existe
  nos parquets do censobr v1.0.0 (convencao geobr: `code_tract`);
  `agregar_setores()` agora funciona contra os dados reais.

# censoagg 0.0.1.9000

- `agregar_setores()` e `agregar_microdados()` devolvem lista
  nomeada variável -> long(local, periodo, valor), pronta para o
  `db_datawrite` do beep.
- Snapshots dos dicionários do Censo 2022 (3.508 variáveis de
  agregados por setor; 247 de microdados públicos) em `data/`.
- Validado contra o Censo 2022 real (soma BR = população oficial).
- Limitação documentada: microdado público 2022 sem code_muni/V/
  pesos — usar agregados por setor ou acesso controlado.
