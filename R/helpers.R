#' Leitores e helpers internos do censoagg
#'
#' Purezas testaveis offline: coercao numerica dos agregados do
#' IBGE ("." e vazio significam NA/zero), escolha da coluna de
#' peso, chave territorial e o agregador generico em memoria.
#'
#' Coercao dos valores textuais do IBGE para numero; `"."`, `""`,
#' `"X"` e `"-"` viram `NA` (que as somas tratam como zero).
#'
#' @param x Vetor de valores lidos do parquet (character ou numerico).
#' @return Vetor `numeric`; `NA` onde o valor nao e numerico.
#' @seealso [.agregador()], que aplica a coercao antes de somar.
#' @keywords internal
.para_numerico <- \(x) {
  x <- as.character(x)
  x[x %in% c(".", "", "X", "-")] <- NA_character_
  suppressWarnings(as.numeric(x))
}

#' Coluna de peso padrao por dataset de microdados
#'
#' @param dataset `"pessoas"`, `"domicilios"` ou `"familias"`.
#' @return Nome da coluna de peso (PESO_PES/PESO_DOM/PESO_FAM) ou
#'   `NULL` para dataset desconhecido (a autodeteccao cuida do resto).
#' @seealso [.resolver_peso()]
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
#'
#' @param dados Base (ou apenas o schema) onde procurar a coluna.
#' @param dataset `"pessoas"`, `"domicilios"` ou `"familias"`.
#' @param peso Coluna explicita; quando informada, vence as demais
#'   regras.
#' @return Nome da coluna de peso.
#' @section Erro:
#' Sem peso explicito, sem padrao do dataset e sem coluna `^PESO`,
#' para com erro explicativo lembrando que os microdados publicos de
#' 2022 nao trazem pesos (usar `soma`/`media` ou o acesso controlado).
#' @seealso [.peso_padrao()]
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
#'
#' Os nomes seguem o censobr/geobr: `code_muni` (7 digitos),
#' `code_weighting` (area de ponderacao dos microdados) e
#' `code_tract` (setor censitario, 15 digitos - a coluna se chama
#' `code_tract` nos parquets de tracts, nao `code_setor`).
#'
#' @param nivel `"municipio"`, `"area_ponderacao"`, `"setor"` ou
#'   `"brasil"`.
#' @return Nome da coluna chave (`character`) ou `NULL` no nivel
#'   Brasil, que agrega tudo em uma linha `"Brasil"`.
#' @keywords internal
.chave_nivel <- \(nivel) {
  switch(nivel,
         municipio = "code_muni",
         area_ponderacao = "code_weighting",
         setor = "code_tract",
         brasil = NULL,
         stop("censoagg: nivel desconhecido: ", nivel))
}

#' Exige censobr instalado com mensagem clara
#'
#' O censobr e `Suggests`, entao o pacote carrega e o dicionario
#' funciona offline; apenas as leituras de dados o exigem. Nenhum
#' download acontece em `.onLoad()`.
#'
#' @return `NULL` invisivel quando o censobr esta instalado.
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
#'
#' @param dados `data.frame` ja reduzido as colunas necessarias.
#' @param chave Coluna de agrupamento; `NULL` agrega tudo em
#'   `"Brasil"` (cria a coluna `local`).
#' @param variaveis Variaveis a agregar.
#' @param funcao `"soma"`, `"media"`, `"soma_pond"` ou
#'   `"media_pond"`; as variantes `_pond` exigem `peso`.
#' @param peso Coluna de peso, obrigatoria nas funcoes ponderadas e
#'   ignorada nas demais.
#' @return `data.frame` largo com a chave e uma coluna por variavel.
#' @section NA e ponderacao:
#' Valores textuais passam por [.para_numerico()] (`"."`/`""` -> NA);
#' somas usam `na.rm` (NA equivale a zero) e medias ponderadas
#' excluem do denominador apenas as linhas com valor ausente.
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
