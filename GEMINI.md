# nomadtrip — regras de trabalho

- Antes de alterar código, leia `docs/PROJECT_SPECIFICATION.md` e todos os documentos relevantes em `docs/`, especialmente `docs/📅 RoteiroFloridaV909.md`.
- Preserve o comportamento existente e a compatibilidade do JSON/SQLite ao adicionar features.
- Para cada regra de negócio nova ou alterada, crie testes unitários significativos; não gaste testes em getters/trivialidades.
- Execute `dart format`, `flutter analyze` e os testes afetados antes de concluir.
- Ao mudar o schema local, implemente migração e teste de importação/exportação.
- O nome oficial do produto é `nomadtrip`; não reintroduza `florida_trip` em novos arquivos ou identificadores.
