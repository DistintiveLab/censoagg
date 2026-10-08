#' Snapshots dos dicionarios do Censo 2022
#'
#' Dicionarios de variaveis embarcados no pacote para que o painel
#' escolha variaveis sem depender do censobr em runtime
#' ([censo_variaveis()]). Sao o resultado de `data-raw/dicionarios.R`
#' sobre `censobr::data_dictionary()` (censobr v1.0.0).
#'
#' @format `data.frame` com quatro colunas:
#' \describe{
#'   \item{variavel}{codigo da variavel, aceito no argumento
#'     `variaveis` das funcoes de agregacao (ex.: `"V0001"`,
#'     `"demografia_V01007"`).}
#'   \item{descricao}{rotulo em pt-BR vindo do dicionario do IBGE.}
#'   \item{dataset}{subbase a que a variavel pertence (`Basico`,
#'     `Pessoas`, `Domicilios`, ...; no microdado, `pessoas`,
#'     `domicilios` ou `familias`).}
#'   \item{tema}{tema do IBGE (ex.: `"Caracteristicas do Setor"`,
#'     `"Demografia"`) ou `NA`.}
#' }
#' `dict_tracts_2022` tem 3.508 linhas (agregados por setor) e
#' `dict_microdata_2022` tem 247 linhas (microdado publico de 2022).
#' @source <https://ftp.ibge.gov.br/Censos/> via
#'   `censobr::data_dictionary(2022, dataset = c("tracts", "microdata"))`.
#' @seealso [censo_variaveis()], [agregar_setores()] e
#'   [agregar_microdados()].
#' @name dict_2022
#' @keywords datasets
#' @examples
#' \dontrun{
#' d <- censo_variaveis(2022, "tracts")
#' table(d$dataset)
#' }
NULL

#' @rdname dict_2022
"dict_tracts_2022"

#' @rdname dict_2022
"dict_microdata_2022"
