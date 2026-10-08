# censoagg 0.0.1.9003

- Fix: `nivel = "setor"` usava a coluna `code_setor`, que nao existe
  nos parquets do censobr v1.0.0 (convencao geobr: `code_tract`);
  `agregar_setores()` agora funciona contra os dados reais.

# censoagg 0.0.1.9000

- `agregar_setores()` e `agregar_microdados()` devolvem lista
  nomeada variável -> long(local, periodo, valor), pronta para o
  `db_datawrite` do beep.
- Snapshots dos dicionários do Censo 2022 (3.508 variáveis de
  agregados por setor; 247 de microdados públicos) em `data/`.
- Validado contra o Censo 2022 real (soma BR = população oficial).
- Limitação documentada: microdado público 2022 sem code_muni/V/
  pesos — usar agregados por setor ou acesso controlado.
