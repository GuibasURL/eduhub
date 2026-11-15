# Registro de Decisões Arquiteturais

| # | Decisão | Justificativa |
|---|---|---|
| 1 | Usar **SOA** | O tema indica SOA; separar em serviços permite reutilizar o de Certificados em outros sistemas. |
| 2 | **3 serviços** (Acadêmico, Certificados, Ranking) | Mantém o escopo pequeno: cada serviço corresponde a uma capacidade do sistema. |
| 3 | Comunicação **REST/JSON síncrona** | Simples de implementar, testar (Postman/Swagger) e documentar. |
| 4 | **Um banco por serviço** | Cada serviço é dono dos seus dados; nenhum acessa o banco do outro. |
| 5 | Serviço de Certificados **genérico** | Não conhece cursos: recebe destinatário, título e emissor. Assim serve para qualquer sistema. |
| 6 | **Retry + Circuit Breaker + pendências** | Falha em um serviço secundário não derruba o fluxo principal. |
| 7 | **Sem ESB/API Gateway** | Para 3 serviços, um barramento só adicionaria complexidade. |
| 8 | **SQLite** | Um arquivo por serviço, sem instalar servidor. |
