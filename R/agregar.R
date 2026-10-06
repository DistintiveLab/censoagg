#' Dicionario de variaveis do Censo (snapshot offline)
#'
#' Devolve o dicionario (variavel, descricao) para escolha no
#' painel beep SEM depender do censobr em runtime: usa o snapshot
#' lazy do pacote; sem snapshot, tenta o censobr ao vivo.
#'
#' @param ano Ano do censo (2022, 2010...).
#' @param dataset `"microdata"` ou `"tracts"`.
#' @param dict Snapshot opcional (data.frame com colunas
#'   `variavel` e `descricao`) - para testes.
#' @return `data.frame` com variavel e descricao.
#' @examples
#' \dontrun{
#' censo_variaveis(2022, "tracts")
#' }
#' @export
censo_variaveis <- \(ano, dataset = c("microdata", "tracts"),
                     dict = NULL) {
  dataset <- match.arg(dataset)
  if (!is.null(dict)) return(dict)
  rda <- paste0("dict_", dataset, "_", ano)
  if (rda %in% data(package = "censoagg")[["results"]][, "Item"]) {
    return(get(rda, envir = asNamespace("censoagg")))
  }
  .exigir_censobr()
  d <- censobr::data_dictionary(ano, dataset = dataset)
  colunas <- intersect(c("variable_name", "name", "code", "var_name"),
                       names(d))[1]
  desc <- intersect(c("description", "label", "descricao", "desc"),
                    names(d))[1]
  if (is.na(colunas) || is.na(desc)) {
    stop("censoagg: dicionario ", ano, "/", dataset,
         " com colunas inesperadas: ", paste(names(d), collapse = ", "))
  }
  tibble::tibble(variavel = as.character(d[[colunas]]),
                 descricao = as.character(d[[desc]]))
}

#' Agrega microdados do Censo por territorio
#'
#' Le microdados via censobr (Arrow), reduz as colunas necessarias
#' ANTES do collect (microdados da amostra sao grandes) e agrega
#' cada variavel pedida pela funcao escolhida. Toda estatistica
#' analitica deve ser ponderada; domínios pequenos (bairro/setor)
#' pertencem aos agregados por setor, nao aos microdados.
#'
#' @param dataset `"pessoas"`, `"domicilios"` ou `"familias"`.
#' @param ano Ano do censo (2022 publico; 2010...).
#' @param variaveis Vetor de variaveis do dicionario.
#' @param nivel `"municipio"` (default), `"area_ponderacao"` ou
#'   `"brasil"`.
#' @param funcao `"soma_pond"` (default), `"media_pond"`, `"soma"`
#'   ou `"media"`.
#' @param peso Coluna de peso; default resolve por dataset
#'   (PESO_PES/PESO_DOM/PESO_FAM ou autodeteccao ^PESO). Os
#'   microdados publicos de 2022 NAO incluem pesos: com eles, use
#'   `funcao='soma'`/`'media'` ou dados controlados.
#' @param corte Expressao de recorte (character, ex.:
#'   `"V1005 == 1"`), opcional.
#' @param show_progress Propagar para o censobr.
#' @return Lista nomeada por variavel, cada item um `data.frame`
#'   long: local, periodo, valor.
#' @examples
#' \dontrun{
#' agregar_microdados("pessoas", 2022,
#'                    variaveis = c("V0001"),
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

#' Agrega os agregados por setor censitario do Censo 2022
#'
#' Le `censobr::read_tracts()` e soma as variaveis pedidas por
#' setor ou municipio (contagens; nao ponderar). Valores `"."`
#' do IBGE viram NA e entram como zero na soma.
#'
#' @param dataset Base do read_tracts (ex.: `"Basico"`,
#'   `"Domicilio"`, `"Pessoas"`, `"Instrucao"`, `"Morador"`,
#'   `"DomicilioRenda"`).
#' @param ano Ano do censo.
#' @param variaveis Vetor de variaveis de contagem.
#' @param nivel `"setor"`, `"municipio"` ou `"brasil"`.
#' @param corte Expressao de recorte (character), opcional.
#' @return Lista nomeada por variavel, cada item long:
#'   local, periodo, valor.
#' @examples
#' \dontrun{
#' agregar_setores("Basico", 2022, variaveis = c("V0001"),
#'                 nivel = "municipio")
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
