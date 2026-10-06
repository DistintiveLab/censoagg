#' Dicionario de variaveis do Censo (snapshot offline)
#'
#' Devolve o dicionario (variavel, descricao) para escolha no
#' painel beep SEM depender do censobr em runtime: usa o snapshot
#' lazy do pacote (gerado por `data-raw/dicionarios.R` a partir
#' dos xlsx do censobr v1.0.0); sem snapshot, tenta o censobr ao
#' vivo (requer readxl).
#'
#' @param ano Ano do censo (2022).
#' @param dataset `"microdata"` ou `"tracts"`.
#' @param dict Snapshot opcional (data.frame com colunas
#'   `variavel` e `descricao`; opcionalmente `dataset`) - para
#'   testes.
#' @return `data.frame` com variavel, descricao e `dataset`
#'   (subbase: Basico/Pessoas/... para tracts; pessoas/
#'   domicilios/familias para microdados).
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
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("censoagg: sem snapshot '", rda, "' o fallback ao vivo ",
         "precisa do pacote readxl")
  }
  .ler_dicionario_xlsx(censobr::data_dictionary(ano, dataset = dataset),
                       dataset)
}

#' Parseia o xlsx do dicionario do censobr (v1.0.0) para long
#'
#' Layouts: sheets de tracts tem colunas nomeadas (Variavel,
#' Tema, Descricao por categoria - descricoes repetidas com NA);
#' sheets de microdados sao posicionais (col 1 = codigo, col 2 =
#' descricao com categorias embutidas).
#' @keywords internal
.ler_dicionario_xlsx <- \(path, dataset) {
  sheets <- readxl::excel_sheets(path)
  saida <- lapply(sheets, \(s) {
    if (identical(dataset, "tracts") && grepl("^Siglas", s)) return(NULL)
    if (identical(dataset, "microdata") &&
        !grepl("_publico", s)) return(NULL)
    x <- as.data.frame(readxl::read_excel(path, sheet = s))
    if (nrow(x) < 2) return(NULL)

    if (identical(dataset, "tracts")) {
      col_var <- grep("Vari", names(x), ignore.case = TRUE)[1]
      col_desc <- grep("Desc", names(x), ignore.case = TRUE)[1]
      col_tema <- grep("Tema", names(x), ignore.case = TRUE)[1]
      if (is.na(col_var) || is.na(col_desc)) return(NULL)
      ds <- s
      tem <- if (!is.na(col_tema)) as.character(x[[col_tema]]) else
        NA_character_
      v <- as.character(x[[col_var]])
      d <- .limpa_desc(x[[col_desc]])
    } else {
      v <- as.character(x[[1]])
      d <- .limpa_desc(x[[2]])
      tem <- NA_character_
      ds <- .sheet_para_dataset(s)
    }
    ok <- !is.na(v) & grepl("^([a-z0-9]+_)?[A-Z]{1,6}[0-9]{3,}$|^PESO", v) &
      !is.na(d) & nzchar(d)
    if (!any(ok)) return(NULL)
    data.frame(variavel = v[ok], descricao = d[ok],
               dataset = ds, tema = tem[ok],
               stringsAsFactors = FALSE)
  })
  saida <- do.call(rbind, Filter(Negate(is.null), saida))
  saida <- saida[!is.na(saida$dataset), ]
  saida <- saida[!duplicated(saida[, c("dataset", "variavel")]), ]
  if (!nrow(saida)) {
    stop("censoagg: dicionario vazio para ", dataset)
  }
  saida[order(saida$dataset, saida$variavel), ]
}

#' Alias de sheet do xlsx para dataset do painel (microdados)
#' @keywords internal
.sheet_para_dataset <- \(sheet) {
  if (grepl("^PESS", sheet)) return("pessoas")
  if (grepl("^DOMI", sheet)) return("domicilios")
  if (grepl("^FAMI", sheet)) return("familias")
  NA_character_
}

#' Limpa quebras do texto do dicionario em uma linha legivel;
#' para descricoes por categoria (repetidas com NA em tracts),
#' o chamador ja mantem a primeira ocorrencia nao vazia por
#' variavel via deduplicacao
#' @keywords internal
.limpa_desc <- \(x) {
  x <- gsub("\r?\n\\s*", "; ", as.character(x))
  trimws(gsub(";\\s*;\\s*", "; ", x))
}
