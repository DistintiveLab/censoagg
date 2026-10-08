# Exige censobr instalado com mensagem clara

O censobr e `Suggests`, entao o pacote carrega e o dicionario funciona
offline; apenas as leituras de dados o exigem. Nenhum download acontece
em `.onLoad()`.

## Usage

``` r
.exigir_censobr()
```

## Value

`NULL` invisivel quando o censobr esta instalado.
