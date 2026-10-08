#' censoagg: agregacao de dados do Censo para o DW beep
#'
#' Ponte entre o pacote censobr (microdados e agregados por setor
#' do Censo IBGE, em Arrow/parquet) e o formato longo esperado
#' pelo painel beep: listas nomeadas de tibbles com colunas
#' local, periodo e valor, uma por variavel pedida.
#'
#' @section Contrato de saida:
#' [agregar_microdados()] e [agregar_setores()] devolvem a mesma
#' estrutura, pronta para o `db_datawrite` do beep:
#'
#' - lista nomeada pelo codigo da variavel (`"V0001"`,
#'   `"demografia_V01007"`...);
#' - cada item um long com `local`, `periodo` e `valor`;
#' - `local` e character com o codigo IBGE (7 digitos de municipio,
#'   15 de setor); no nivel `"brasil"` a chave e `NULL` e a coluna
#'   recebe `"Brasil"`;
#' - `periodo` e `Date` com 31/12 do ano do censo;
#' - `valor` e `numeric`, com `"."`, `""`, `"X"` e `"-"` do IBGE
#'   convertidos em `NA` e somas com `na.rm` (ou seja, valem zero).
#'
#' @section Ponderacao:
#' Estatisticas analiticas de microdados sao SEMPRE ponderadas
#' (`soma_pond`/`media_pond` com PESO_PES/PESO_DOM/PESO_FAM,
#' autodetectadas por `^PESO` e com override via `peso=`); dominios
#' pequenos (bairro/setor) pertencem aos agregados por setor
#' ([agregar_setores()]), que sao contagens do universo e nao se
#' ponderam.
#'
#' @section Dependencias opcionais:
#' O censobr e `Suggests`: sem ele instalado, o dicionario continua
#' disponivel pelo snapshot em `data/` ([censo_variaveis()]) e as
#' funcoes de leitura param com erro explicativo. Nenhum download
#' acontece em `.onLoad()`; a primeira execucao guarda os parquets no
#' cache do censobr.
#'
#' @seealso [agregar_microdados()], [agregar_setores()] e
#'   [censo_variaveis()].
#' @author DistintiveLab
#' @keywords internal
#' @docType package
"_PACKAGE"
