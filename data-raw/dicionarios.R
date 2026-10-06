# Gera os snapshots de dicionario do censoagg (data/*.rda).
#
# Requer censobr + readxl. Rodar de dentro da raiz do pacote:
#   source("data-raw/dicionarios.R")
# Os xlsx baixam para o cache do censobr na 1a execucao.

dir.create("data", showWarnings = FALSE)

gerar <- function(ano, dataset) {
  path <- censobr::data_dictionary(ano, dataset = dataset)
  snap <- censoagg:::.ler_dicionario_xlsx(path, dataset)
  nm <- paste0("dict_", dataset, "_", ano)
  assign(nm, snap)
  save(list = nm, file = file.path("data", paste0(nm, ".rda")),
       compress = "bzip2")
  message(nm, ": ", nrow(snap), " variaveis (",
          length(unique(snap$dataset)), " subbases)")
}

gerar(2022, "tracts")
gerar(2022, "microdata")
