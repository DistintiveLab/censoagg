# Gera os snapshots de dicionario do censoagg (data/*.rda).
#
# Requer censobr instalado (a 1a execucao baixa os dicionarios
# para o cache do usuario). Rodar de dentro da raiz do pacote:
#   source("data-raw/dicionarios.R")
#
# Sem censobr/ambiente offline, o pacote segue funcionando: o
# snapshot fica ausente e censo_variaveis() tenta o censobr ao
# vivo, com erro explicativo.

if (!requireNamespace("censobr", quietly = TRUE)) {
  stop("data-raw/dicionarios.R: censobr ausente - instale antes de gerar ",
       "os snapshots")
}
dir.create("data", showWarnings = FALSE)

gerar <- \(ano, dataset) {
  d <- censobr::data_dictionary(ano, dataset = dataset)
  colunas <- intersect(c("variable_name", "name", "code", "var_name"),
                       names(d))[1]
  desc <- intersect(c("description", "label", "descricao", "desc"),
                    names(d))[1]
  snap <- tibble::tibble(
    variavel = as.character(d[[colunas]]),
    descricao = as.character(d[[desc]]))
  assign(paste0("dict_", dataset, "_", ano), snap)
  usethis::use_data(get(paste0("dict_", dataset, "_", ano)),
                    overwrite = TRUE)
  message("snapshot: dict_", dataset, "_", ano, " (", nrow(snap),
          " variaveis)")
}

gerar(2022, "microdata")
gerar(2022, "tracts")
gerar(2010, "microdata")
gerar(2010, "tracts")
