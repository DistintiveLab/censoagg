#' censoagg: agregacao de dados do Censo para o DW beep
#'
#' Ponte entre o pacote censobr (microdados e agregados por setor
#' do Censo IBGE, em Arrow/parquet) e o formato longo esperado
#' pelo painel beep: listas nomeadas de tibbles com colunas
#' local, periodo e valor, uma por variavel pedida.
#'
#' As estatisticas de microdados sao SEMPRE ponderadas por
#' padrao (soma/media com a coluna de peso); domínios pequenos
#' (bairro/setor) devem usar os agregados por setor, nao os
#' microdados.
#'
#' @keywords internal
#' @docType package
"_PACKAGE"
