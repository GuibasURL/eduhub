# EduHub — Plataforma de Ensino Online

Projeto final da disciplina de **Arquitetura de Software** — Tema 4: Plataforma de Ensino Online (E-learning).

O EduHub permite cadastrar cursos, aulas e alunos, com progresso e feedback. Ao concluir aulas o aluno ganha pontos no ranking e, ao terminar o curso, recebe um certificado.

## Estilo arquitetural: SOA (Orientada a Serviços)

O sistema é dividido em serviços independentes, cada um com sua API REST documentada (OpenAPI/Swagger) e seu próprio banco.

| Serviço | Responsabilidade | Porta |
|---|---|---|
| **Acadêmico** | Cursos, aulas, alunos, matrículas, progresso e feedback. Orquestra os demais. | 3001 |
| **Certificados** ♻️ | Emite e valida certificados para **qualquer** sistema (serviço reutilizável) | 3002 |
| **Ranking** | Soma pontos por usuário e devolve o ranking | 3003 |

### Padrões de resiliência
- **Retry:** até 3 tentativas nas chamadas do Acadêmico para Certificados e Ranking.
- **Circuit Breaker:** interrompe as chamadas a um serviço que está falhando.
- **Pendências:** chamadas que falharam são reprocessadas a cada minuto; o progresso do aluno nunca se perde.

## Serviço reutilizável: Certificados

| Endpoint | O que faz |
|---|---|
| `POST /certificados` | Emite um certificado (destinatário, título, descrição, emissor) e devolve o código de verificação |
| `GET /certificados/{codigo}` | Valida um certificado pelo código |
| `GET /certificados?destinatario=` | Lista os certificados de uma pessoa |

Documentação interativa em `http://localhost:3002/docs`.

## Funcionalidades

| Serviço | Funcionalidade | Quem usa |
|---|---|---|
| Acadêmico | Cadastrar cursos e aulas | Instrutor |
| Acadêmico | Cadastrar aluno e matricular em curso | Aluno |
| Acadêmico | Marcar aula como concluída e ver o % de progresso | Aluno |
| Acadêmico | Dar feedback (nota 1–5 + comentário) | Aluno |
| Ranking | Somar pontos e mostrar o ranking | Aluno |
| Certificados | Emitir certificado ao concluir o curso e validar pelo código | Aluno / qualquer pessoa |

## Fluxo principal

1. O aluno conclui a última aula na aplicação web.
2. O Serviço Acadêmico salva o progresso (100%).
3. O Acadêmico chama o Ranking (`POST /pontos`) e os Certificados (`POST /certificados`), com Retry e Circuit Breaker.
4. Se algum estiver fora do ar, a chamada fica pendente e é reprocessada depois.

## Documentação

- Diagramas C4 (Structurizr DSL): [`docs/arquitetura/workspace.dsl`](docs/arquitetura/workspace.dsl) — para visualizar, cole em [https://structurizr.com/dsl](https://playground.structurizr.com)
- Decisões arquiteturais: [`docs/decisoes/DECISOES.md`](docs/decisoes/DECISOES.md)
- Resumo do projeto: [`docs/EduHub_Projeto.pdf`](docs/EduHub_Projeto.pdf)
- Divisão das atividades: [`DIVISAO_ATIVIDADES.md`](DIVISAO_ATIVIDADES.md)

## Tecnologias (previstas)

Node.js + Express · SQLite (um banco por serviço) · Swagger · opossum (Circuit Breaker) · HTML + JavaScript

## Estrutura

```
docs/                     # diagramas, decisões e PDF
servicos/
  academico/              # Serviço Acadêmico (porta 3001)
  certificados/           # Serviço de Certificados (porta 3002)
  ranking/                # Serviço de Ranking (porta 3003)
web/                      # páginas HTML
```

## Equipe

| Nome | Matrícula |
|---|---|
| Guilherme Sousa Barbosa | 565684 |
| Edivar Cruz Carvalho Filho | 565857 |
| João Gabriel Costa Leandro | 569466 |
| Paulo Sérgio Vieira de Oliveira | 566589 |
| Randson da Silva Alves | 568002 |
