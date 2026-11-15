workspace "EduHub - Plataforma de Ensino Online" "E-learning simples no estilo SOA (Arquitetura Orientada a Serviços)." {

    !identifiers hierarchical

    model {
        aluno = person "Aluno" "Se matricula em cursos, conclui aulas, vê o progresso, o ranking e os certificados, e dá feedback."
        instrutor = person "Instrutor" "Cadastra cursos e aulas."

        eduhub = softwareSystem "EduHub" "Cadastro de cursos, aulas e alunos, com progresso e feedback, composto por serviços independentes." {

            web = container "Aplicação Web" "Páginas simples para aluno e instrutor." "HTML + JavaScript" "Browser"

            academico = container "Serviço Acadêmico" "Serviço principal: cursos, aulas, alunos, matrículas, progresso e feedback. Orquestra as chamadas aos outros serviços." "Node.js + Express" {
                rotas = component "API REST Acadêmica" "Endpoints de cursos, aulas, alunos, matrículas, concluir aula e feedback. Documentada com OpenAPI/Swagger." "Express Router"
                cursoSvc = component "Serviço de Cursos" "Regras de cursos, aulas e alunos." "JavaScript"
                progressoSvc = component "Serviço de Progresso" "Registra aula concluída, calcula o % e aciona Ranking e Certificados." "JavaScript"
                feedbackSvc = component "Serviço de Feedback" "Registra notas e comentários." "JavaScript"
                repo = component "Repositório" "Acesso ao banco do Serviço Acadêmico." "SQLite driver"
                clienteCert = component "Cliente de Certificados" "Chama o Serviço de Certificados com Retry (3 tentativas) e Circuit Breaker." "axios + opossum" "Resiliencia"
                clienteRank = component "Cliente de Ranking" "Chama o Serviço de Ranking com Retry e Circuit Breaker." "axios + opossum" "Resiliencia"
                pendencias = component "Reprocessador de Pendências" "Se um serviço estiver fora, guarda a chamada como pendente e tenta de novo a cada minuto." "setInterval" "Resiliencia"
            }
            dbAcad = container "Banco Acadêmico" "Cursos, aulas, alunos, matrículas, progresso, feedback e pendências." "SQLite" "Database"

            certificados = container "Serviço de Certificados" "Serviço REUTILIZÁVEL e genérico: emite e valida certificados para qualquer sistema (não conhece cursos)." "Node.js + Express" "Reutilizavel" {
                certApi = component "API REST de Certificados" "POST /certificados, GET /certificados/{codigo}, GET /certificados?destinatario=. Documentada com OpenAPI/Swagger." "Express Router"
                emissao = component "Serviço de Emissão" "Valida os dados, gera o código de verificação único e registra o certificado." "JavaScript"
                certRepo = component "Repositório" "Acesso ao banco de certificados." "SQLite driver"
            }
            dbCert = container "Banco de Certificados" "Certificados emitidos e códigos de verificação." "SQLite" "Database"

            ranking = container "Serviço de Ranking" "Soma pontos por usuário e devolve o ranking." "Node.js + Express"
            dbRank = container "Banco de Ranking" "Pontuação por usuário." "SQLite" "Database"
        }

        # Contexto / containers
        aluno -> eduhub.web "Estuda, vê progresso, ranking e certificados" "HTTP"
        instrutor -> eduhub.web "Cadastra cursos e aulas" "HTTP"
        eduhub.web -> eduhub.academico.rotas "Chama" "REST/JSON"
        eduhub.web -> eduhub.ranking "Consulta o ranking" "REST/JSON"
        eduhub.web -> eduhub.certificados.certApi "Consulta e valida certificados" "REST/JSON"

        # Dentro do Serviço Acadêmico
        eduhub.academico.rotas -> eduhub.academico.cursoSvc "Usa"
        eduhub.academico.rotas -> eduhub.academico.progressoSvc "Usa"
        eduhub.academico.rotas -> eduhub.academico.feedbackSvc "Usa"
        eduhub.academico.cursoSvc -> eduhub.academico.repo "Usa"
        eduhub.academico.progressoSvc -> eduhub.academico.repo "Usa"
        eduhub.academico.feedbackSvc -> eduhub.academico.repo "Usa"
        eduhub.academico.progressoSvc -> eduhub.academico.clienteRank "Adicionar pontos"
        eduhub.academico.progressoSvc -> eduhub.academico.clienteCert "Emitir certificado"
        eduhub.academico.clienteCert -> eduhub.academico.pendencias "Registra pendência se falhar"
        eduhub.academico.clienteRank -> eduhub.academico.pendencias "Registra pendência se falhar"
        eduhub.academico.pendencias -> eduhub.academico.repo "Lê e grava pendências"
        eduhub.academico.repo -> eduhub.dbAcad "Lê e grava" "SQL"
        eduhub.academico.clienteCert -> eduhub.certificados.certApi "POST /certificados" "REST/JSON"
        eduhub.academico.clienteRank -> eduhub.ranking "POST /pontos" "REST/JSON"

        # Dentro do Serviço de Certificados
        eduhub.certificados.certApi -> eduhub.certificados.emissao "Usa"
        eduhub.certificados.emissao -> eduhub.certificados.certRepo "Usa"
        eduhub.certificados.certRepo -> eduhub.dbCert "Lê e grava" "SQL"

        eduhub.ranking -> eduhub.dbRank "Lê e grava" "SQL"
    }

    views {
        systemContext eduhub "Contexto" "Nível 1 - Contexto" {
            include *
            autoLayout lr
        }

        container eduhub "Containers" "Nível 2 - Serviços e bancos" {
            include *
            autoLayout lr
        }

        component eduhub.academico "ComponentesAcademico" "Nível 3 - Serviço Acadêmico (com padrões de resiliência)" {
            include *
            autoLayout tb
        }

        component eduhub.certificados "ComponentesCertificados" "Nível 3 - Serviço de Certificados (reutilizável)" {
            include *
            autoLayout tb
        }

        dynamic eduhub "FluxoPrincipal" "Aluno conclui a última aula do curso" {
            eduhub.web -> eduhub.academico "POST /matriculas/{id}/aulas/{aulaId}/concluir"
            eduhub.academico -> eduhub.dbAcad "Salva progresso (100%)"
            eduhub.academico -> eduhub.ranking "POST /pontos (+10) com Retry/Circuit Breaker"
            eduhub.academico -> eduhub.certificados "POST /certificados com Retry/Circuit Breaker"
            eduhub.certificados -> eduhub.dbCert "Grava certificado com código de verificação"
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Reutilizavel" {
                background #2e9e5b
                color #ffffff
            }
            element "Browser" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Resiliencia" {
                background #f5a623
                color #000000
            }
        }
    }
}
