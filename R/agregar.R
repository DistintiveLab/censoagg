#' Agrega microdados do Censo por territorio
#'
#' Le os microdados via censobr (Arrow), reduz as colunas necessarias
#' ANTES de trazer os dados para a memoria (microdados da amostra sao
#' grandes) e agrega cada variavel pedida pela funcao escolhida. Toda
#' estatistica analitica deve ser ponderada; dominios pequenos
#' (bairro/setor) pertencem aos agregados por setor, nao aos
#' microdados.
#'
#' @param dataset `"pessoas"`, `"domicilios"` ou `"familias"`.
#' @param ano Ano do censo (2022 publico; 2010...).
#' @param variaveis Vetor de variaveis do dicionario
#'   ([censo_variaveis()]); colunas ausentes na base pedida param com
#'   erro listando o que faltou.
#' @param nivel `"municipio"` (default), `"area_ponderacao"` ou
#'   `"brasil"`, define a chave territorial: `code_muni`,
#'   `code_weighting` ou nenhuma (Brasil inteiro).
#' @param funcao `"soma_pond"` (default), `"media_pond"`, `"soma"` ou
#'   `"media"`. As variantes `_pond` multiplicam cada valor pelo peso
#'   e dividem pela soma dos pesos.
#' @param peso Coluna de peso; default resolve por dataset
#'   (PESO_PES/PESO_DOM/PESO_FAM ou autodeteccao por `^PESO`), com
#'   override explicito por este argumento.
#' @param corte Expressao de recorte (character, ex.: `"V1005 == 1"`),
#'   opcional; as colunas citadas entram na leitura e o filtro roda no
#'   Arrow, antes de trazer os dados para a memoria.
#' @param show_progress Repassado ao censobr (barra de download).
#' @return Lista nomeada por variavel, cada item um `data.frame` long
#'   com `local`, `periodo` e `valor`; veja o contrato completo em
#'   [censoagg-package].
#' @section Ponderacao:
#' Somas ponderadas pre-multiplicam o valor pelo peso e somam com
#' `na.rm`; medias ponderadas excluem do denominador apenas as linhas
#' com valor ausente (soma dos pesos das linhas observadas).
#' @section Limitacao do microdado publico de 2022:
#' O microdado publico de 2022 distribuido pelo censobr vem reduzido
#' pelo IBGE: sem `code_muni`, sem codigos `V...` e sem pesos. Com ele,
#' use `funcao = "soma"`/`"media"`; para estatisticas ponderadas use o
#' acesso controlado (`censobr::import_microdata22()`) com
#' `peso = "PESO_PES"`, ou prefira [agregar_setores()]. Os microdados
#' de 2010 funcionam ponderados.
#' @seealso [agregar_setores()] para contagens por setor censitario e
#'   [censo_variaveis()] para descobrir os codigos das variaveis.
#' @family agregadores
#' @examples
#' \dontrun{
#' # contagem de pessoas por municipio (ponderada)
#' agregar_microdados("pessoas", 2010, variaveis = c("V0001"),
#'                    nivel = "municipio", funcao = "soma_pond")
#' }
#' @export
agregar_microdados <- \(dataset = c("pessoas", "domicilios", "familias"),
                        ano = 2022, variaveis,
                        nivel = c("municipio", "area_ponderacao", "brasil"),
                        funcao = c("soma_pond", "media_pond", "soma", "media"),
                        peso = NULL, corte = NULL,
                        show_progress = FALSE) {
  .exigir_censobr()
  dataset <- match.arg(dataset)
  nivel <- match.arg(nivel)
  funcao <- match.arg(funcao)
  chave <- .chave_nivel(nivel)

  leitor <- switch(dataset,
                   pessoas = censobr::read_population,
                   domicilios = censobr::read_households,
                   familias = censobr::read_families)

  # leitura lazy (arrow): nomes via schema, sem baixar dados
  dados <- leitor(year = ano, showProgress = show_progress)

  colunas <- c(chave, variaveis)
  if (funcao %in% c("soma_pond", "media_pond")) {
    peso <- .resolver_peso(dados, dataset, peso)
    colunas <- c(colunas, peso)
  }
  if (!is.null(corte)) colunas <- unique(c(colunas, all.vars(parse(text = corte))))
  faltando <- setdiff(colunas, names(dados))
  if (length(faltando)) {
    stop("censoagg: colunas ausentes em ", dataset, "/", ano, ": ",
         paste(faltando, collapse = ", "))
  }

  reduzido <- dados |>
    dplyr::select(dplyr::all_of(colunas))
  if (!is.null(corte)) {
    reduzido <- reduzido |>
      dplyr::filter(!!rlang::parse_expr(corte))
  }
  reduzido <- as.data.frame(reduzido)
  if (funcao %in% c("soma_pond", "media_pond")) {
    peso_ok <- peso
  } else peso_ok <- NULL

  agg <- .agregador(reduzido, chave, variaveis, funcao, peso_ok)
  empacotar(agg, chave, ano, variaveis)
}

#' Agrega os agregados por setor censitario do Censo
#'
#' Le `censobr::read_tracts()` e soma as variaveis pedidas por setor
#' censitario, municipio ou Brasil. Sao contagens do universo, logo nao
#' se ponderam; valores `"."`, `""`, `"X"` e `"-"` do IBGE viram `NA` e
#' entram como zero na soma.
#'
#' @param dataset Subbase do `read_tracts`. Para 2022: `"Basico"`,
#'   `"Domicilio"`, `"Pessoas"`, `"Indigenas"`, `"Quilombolas"`,
#'   `"ResponsavelRenda"`, `"Entorno"`, `"Obitos"` ou
#'   `"Preliminares"` (2010: `"Basico"`, `"Domicilio"`,
#'   `"DomicilioRenda"`, `"Responsavel"`, `"ResponsavelRenda"`,
#'   `"Pessoa"`, `"PessoaRenda"`, `"Entorno"`). Use
#'   [censo_variaveis()] para ver qual subbase tem cada codigo.
#' @param ano Ano do censo (2022 publico).
#' @param variaveis Vetor de variaveis de contagem, no formato
#'   `tema_V00xxx` (ex.: `"demografia_V01007"`), como saem do
#'   dicionario.
#' @param nivel `"municipio"` (default), `"setor"` ou `"brasil"`; a
#'   chave e `code_muni`, `code_tract` (convencao geobr do censobr; o
#'   codigo de setor tem 15 digitos e ainda nao encaixa nos niveis do
#'   DW do beep) ou nenhuma, respectivamente.
#' @param corte Expressao de recorte (character), opcional, ex.:
#'   `"code_muni == 5300108"` para o Distrito Federal; roda no Arrow,
#'   antes de trazer os dados para a memoria.
#' @param show_progress Repassado ao censobr (barra de download).
#' @return Lista nomeada por variavel, cada item um `data.frame` long
#'   com `local`, `periodo` e `valor`; veja o contrato completo em
#'   [censoagg-package].
#' @seealso [agregar_microdados()] para estatisticas ponderadas de
#'   microdados e [censo_variaveis()] para descobrir os codigos das
#'   variaveis.
#' @family agregadores
#' @examples
#' \dontrun{
#' # populacao por municipio
#' agregar_setores("Basico", 2022, variaveis = c("V0001"),
#'                 nivel = "municipio")
#'
#' # homens e mulheres por setor censitario no DF
#' agregar_setores("Pessoas", 2022,
#'                 variaveis = c("demografia_V01007",
#'                               "demografia_V01008"),
#'                 nivel = "setor", corte = "code_muni == 5300108")
#' }
#' @export
agregar_setores <- \(dataset = "Basico", ano = 2022, variaveis,
                     nivel = c("municipio", "setor", "brasil"),
                     corte = NULL, show_progress = FALSE) {
  .exigir_censobr()
  nivel <- match.arg(nivel)
  chave <- .chave_nivel(nivel)
  colunas <- c(chave, variaveis)
  if (!is.null(corte)) colunas <- unique(c(colunas, all.vars(parse(text = corte))))
  dados <- censobr::read_tracts(year = ano, dataset = dataset,
                                showProgress = show_progress)
  faltando <- setdiff(colunas, names(dados))
  if (length(faltando)) {
    stop("censoagg: colunas ausentes em tracts/", dataset, ": ",
         paste(faltando, collapse = ", "))
  }
  reduzido <- dplyr::select(dados, dplyr::all_of(colunas))
  if (!is.null(corte)) {
    reduzido <- reduzido |>
      dplyr::filter(!!rlang::parse_expr(corte))
  }
  agg <- .agregador(as.data.frame(reduzido), chave, variaveis,
                    "soma", peso = NULL)
  empacotar(agg, chave, ano, variaveis)
}

#' Empacota o agregado largo em lista long (local, periodo, valor)
#' por variavel
#'
#' Fecha o contrato de saida do pacote: converte o `data.frame` largo
#' do agregador (uma linha por chave) na lista nomeada consumida pelo
#' DW, com `periodo` fixado em 31/12 do ano do censo e `local` sempre
#' character (codigo IBGE) ou `"Brasil"` no nivel nacional.
#'
#' @param agg `data.frame` largo devolvido por [.agregador()].
#' @param chave Nome da coluna territorial de `agg`; `NULL` no nivel
#'   Brasil.
#' @param ano Ano do censo, usado para montar `periodo`.
#' @param variaveis Vetor de variaveis que virao a ser as entradas da
#'   lista de saida.
#' @return Lista nomeada por variavel; cada item e um `tibble` com
#'   `local` (character), `periodo` (`Date`) e `valor` (`numeric`).
#' @keywords internal
empacotar <- \(agg, chave, ano, variaveis) {
  periodo <- as.Date(paste0(ano, "-12-31"))
  out <- lapply(variaveis, \(v) {
    tibble::tibble(
      local = if (is.null(chave)) "Brasil" else as.character(agg[[chave]]),
      periodo = periodo,
      valor = as.numeric(agg[[v]]))
  })
  names(out) <- variaveis
  out
}
