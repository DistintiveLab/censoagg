test_that("coercao numerica trata '.' e vazio como NA (soma ignora)", {
  expect_identical(censoagg:::.para_numerico(c("10", ".", "", "3", "X")),
                   c(10, NA, NA, 3, NA))
})

test_that("peso padrao e autodeteccao", {
  expect_identical(censoagg:::.peso_padrao("pessoas"), "PESO_PES")
  expect_null(censoagg:::.peso_padrao("quengas"))
  d <- data.frame(FOO = 1, PESO_QUALQUER = 2)
  expect_identical(censoagg:::.resolver_peso(d, "quengas"), "PESO_QUALQUER")
  expect_error(censoagg:::.resolver_peso(d[, 1, drop = FALSE], "quengas"),
               "peso")
})

test_that("chave por nivel e erros", {
  expect_identical(censoagg:::.chave_nivel("municipio"), "code_muni")
  expect_identical(censoagg:::.chave_nivel("setor"), "code_setor")
  expect_null(censoagg:::.chave_nivel("brasil"))
  expect_error(censoagg:::.chave_nivel("rua"), "desconhecido")
})

test_that("agregador: soma e soma ponderada por chave", {
  d <- data.frame(code_muni = c("A", "A", "B"),
                  V1 = c("10", ".", "4"),
                  w = c(1, 2, 3))
  soma <- censoagg:::.agregador(d, "code_muni", "V1", "soma")
  expect_identical(soma$V1[soma$code_muni == "A"], 10)
  somap <- censoagg:::.agregador(d, "code_muni", "V1", "soma_pond", "w")
  expect_identical(somap$V1[somap$code_muni == "A"], 10) # NA entra 0*2
  expect_identical(somap$V1[somap$code_muni == "B"], 12)
})

test_that("agregador: media ponderada exclui NA do denominador", {
  d <- data.frame(code_muni = c("A", "A", "A"),
                  V1 = c(10, ".", 20),
                  w = c(1, 2, 3))
  mp <- censoagg:::.agregador(d, "code_muni", "V1", "media_pond", "w")
  expect_equal(mp$V1, (10 * 1 + 20 * 3) / 4)
  me <- censoagg:::.agregador(d, "code_muni", "V1", "media")
  expect_equal(me$V1, 15)
})

test_that("agregador: brasil (sem chave) e erros", {
  d <- data.frame(V1 = c(1, 3))
  b <- censoagg:::.agregador(d, NULL, "V1", "soma")
  expect_identical(b$local[1], "Brasil")
  expect_identical(b$V1[1], 4)
  expect_error(censoagg:::.agregador(d, "code_muni", "V1", "soma_pond"),
               "peso")
  expect_error(censoagg:::.agregador(d, "code_muni", "VX", "soma"),
               "ausentes")
})

test_that("empacotar devolve lista long nomeada", {
  agg <- data.frame(code_muni = c("5300108"), V1 = 7)
  out <- censoagg:::empacotar(agg, "code_muni", 2022, "V1")
  expect_named(out, "V1")
  expect_named(out$V1, c("local", "periodo", "valor"))
  expect_s3_class(out$V1$periodo, "Date")
  expect_identical(as.Date(out$V1$periodo[1]), as.Date("2022-12-31"))
})

test_that("censo_variaveis usa dict informado e snapshot gerado", {
  fake <- data.frame(variavel = "V0001", descricao = "populacao")
  expect_identical(censo_variaveis(2022, "tracts", dict = fake), fake)
  out <- censo_variaveis(2022, "tracts")
  expect_s3_class(out, "data.frame")
  expect_true(all(c("variavel", "descricao", "dataset") %in%
                    names(out)))
  expect_true("V0001" %in% out$variavel[out$dataset == "Basico"])
  expect_true(nrow(out[out$dataset == "Pessoas", ]) > 100)
})
