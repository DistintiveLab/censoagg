#' Leitores e helpers internos do censoagg
#'
#' Purezas testaveis offline: coercao numerica dos agregados do
#' IBGE ("." e vazio significam NA/zero), escolha da coluna de
#' peso, chave territorial e o agregador generico em memoria.
#' @keywords internal
.para_numerico <- \(x) {
  x <- as.character(x)
  x[x %in% c(".", "", "X", "-")] <- NA_character_
  suppressWarnings(as.numeric(x))
}

#' Coluna de peso padrao por dataset de microdados
#' @keywords internal
.peso_padrao <- \(dataset) {
  switch(dataset,
         pessoas = "PESO_PES",
         domicilios = "PESO_DOM",
         familias = "PESO_FAM",
         NULL)
}

#' Resolve a coluna de peso: explicita, padrao do dataset ou
#' autodetectada (primeira coluna ^PESO)
#' @keywords internal
.resolver_peso <- \(dados, dataset, peso = NULL) {
  if (!is.null(peso)) return(peso)
  padrao <- .peso_padrao(dataset)
  if (!is.null(padrao) && padrao %in% names(dados)) return(padrao)
  candidata <- grep("^PESO", names(dados), value = TRUE, ignore.case = TRUE)
  if (length(candidata)) return(candidata[1])
  stop("censoagg: coluna de peso nao encontrada. Os microdados ",
       "publicos de 2022 nao incluem pesos: use funcao='soma'/'media' ",
       "ou importe o acesso controlado (censobr::import_microdata22) ",
       "e informe 'peso=' (PESO_PES/PESO_DOM/PESO_FAM)")
}

#' Chave territorial por nivel (NULL = Brasil inteiro)
#' @keywords internal
.chave_nivel <- \(nivel) {
  switch(nivel,
         municipio = "code_muni",
         area_ponderacao = "code_weighting",
         setor = "code_setor",
         brasil = NULL,
         stop("censoagg: nivel desconhecido: ", nivel))
}

#' Exige censobr instalado com mensagem clara
#' @keywords internal
.exigir_censobr <- \() {
  if (!requireNamespace("censobr", quietly = TRUE)) {
    stop("censoagg: instale o pacote censobr ",
         "(install.packages('censobr') ou ",
         "remotes::install_github('ipea/censobr'))")
  }
}

#' Agregador generico em memoria (testavel offline)
#'
#' Agrupa `dados` pela chave e calcula `funcao` para cada
#' variavel. Ponderadas pre-multiplicam x pelo peso e dividem a
#' soma dos pesos apenas nas linhas com x observado.
#' @keywords internal
.agregador <- \(dados, chave, variaveis, funcao, peso = NULL) {
  funcao <- match.arg(funcao, c("soma", "media", "soma_pond", "media_pond"))
  ponderada <- grepl("_pond$", funcao)
  if (ponderada && is.null(peso)) {
    stop("censoagg: funcao ponderada exige coluna de peso")
  }
  faltando <- setdiff(variaveis, names(dados))
  if (length(faltando)) {
    stop("censoagg: variaveis ausentes nos dados: ",
         paste(faltando, collapse = ", "))
  }
  grupo <- if (is.null(chave)) {
    dados$.local <- "Brasil"
    ".local"
  } else chave

  prep <- as.data.frame(dados)
  cols_xw <- cols_w <- character(0)
  if (ponderada) {
    w_base <- as.numeric(prep[[peso]])
    for (v in variaveis) {
      x <- .para_numerico(prep[[v]])
      prep[[paste0(v, "__xw")]] <- x * w_base
      w_limpo <- w_base
      w_limpo[is.na(x)] <- NA_real_
      prep[[paste0(v, "__w")]] <- w_limpo
    }
    cols_xw <- paste0(variaveis, "__xw")
    cols_w <- paste0(variaveis, "__w")
  } else {
    for (v in variaveis) prep[[v]] <- .para_numerico(prep[[v]])
  }

  saida <- prep |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grupo))) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(c(cols_xw, if (!ponderada) variaveis)),
                    \(x) sum(x, na.rm = TRUE)),
      dplyr::across(dplyr::all_of(cols_w), \(x) sum(x, na.rm = TRUE)),
      .groups = "drop")

  if (funcao == "media") {
    saida <- prep |>
      dplyr::group_by(dplyr::across(dplyr::all_of(grupo))) |>
      dplyr::summarise(dplyr::across(dplyr::all_of(variaveis),
                                     \(x) mean(x, na.rm = TRUE)),
                       .groups = "drop")
  } else if (funcao == "media_pond") {
    for (v in variaveis) {
      saida[[v]] <- saida[[paste0(v, "__xw")]] /
        pmax(saida[[paste0(v, "__w")]], 0)
    }
    saida <- saida[, c(grupo, variaveis), drop = FALSE]
  } else if (funcao == "soma_pond") {
    for (v in variaveis) saida[[v]] <- saida[[paste0(v, "__xw")]]
    saida <- saida[, c(grupo, variaveis), drop = FALSE]
  }

  if (is.null(chave)) names(saida)[1] <- "local"
  saida
}
