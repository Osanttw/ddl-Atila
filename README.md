# Relatório de Queries – Hospital Vida & Saúde

Por Eduardo Santos Lima

Neste relatório mostramos as 15 consultas (DQL) que fizemos no banco `hospital_db` para responder às perguntas da diretoria. Todas foram testadas no MySQL/MariaDB com os dados de teste (10 registros por tabela).

## Arquivos do repositório

| Arquivo | Conteúdo |
| --- | --- |
| `01_ddl_hospital.sql` | Criação do banco, tabelas, relacionamentos e regras (DDL) |
| `02_dml_popular_hospital.sql` | Carga de dados de teste (DML) |
| `03_dql_consultas.sql` | As 15 consultas (DQL) |
| `README.md` | Este relatório |

## Como executar

Execute os scripts nesta ordem:

```bash
mysql -u root -p < 01_ddl_hospital.sql
mysql -u root -p < 02_dml_popular_hospital.sql
mysql -u root -p < 03_dql_consultas.sql
```

## Banco utilizado

Usamos 6 tabelas ligadas por chaves estrangeiras:

| Tabela | O que guarda | Relacionamento |
| --- | --- | --- |
| pacientes | dados e convênio do paciente | 1 paciente tem várias consultas e internações |
| medicos | nome, CRM e especialidade | 1 médico faz várias consultas |
| quartos | número, andar e tipo | 1 quarto recebe várias internações |
| consultas | paciente, médico, data e valor | liga pacientes e medicos (N:N) |
| internacoes | paciente, quarto, datas e diária | liga pacientes e quartos (N:N) |
| prescricoes | remédio, dosagem e quantidade | 1 consulta tem várias prescrições |

## Consultas 1 a 8

**1) Farmácia:** relatório com paciente, médico, data da consulta, medicamento e quantidade.

```sql
SELECT p.nome_paciente, m.nome_medico, c.data_consulta, pr.medicamento, pr.quantidade
FROM prescricoes pr
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
ORDER BY c.data_consulta;
```

Resultado: 10 prescrições. Exemplo: Ana Silva, Dr. Marcos Andrade, 10/01/2026, Dipirona 500mg, 20 unidades.

**2) Auditoria:** histórico de internações com paciente, quarto, andar, entrada e diária.

```sql
SELECT p.nome_paciente, q.numero_quarto, q.andar, i.data_entrada, i.valor_diaria
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos q ON i.id_quarto = q.id_quarto
ORDER BY i.data_entrada;
```

Resultado: 10 internações. A primeira é João Pedro Silva, quarto 102, 1º andar, entrada em 15/01/2026, diária de R$ 200,00.

**3) Recepção:** pacientes, convênios, médicos que atenderam e especialidades.

```sql
SELECT p.nome_paciente, p.convenio, m.nome_medico, m.especialidade
FROM pacientes p
INNER JOIN consultas c ON p.id_paciente = c.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
ORDER BY p.nome_paciente;
```

Resultado: 10 linhas. Exemplo: Ana Silva (Unimed) foi atendida pelo Dr. Marcos Andrade, de Cardiologia. Beatriz Lima não aparece porque nunca fez consulta.

**4) Coordenação médica:** prescrições com médico, especialidade, paciente e remédio.

```sql
SELECT m.nome_medico, m.especialidade, p.nome_paciente, pr.medicamento
FROM prescricoes pr
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN medicos m ON c.id_medico = m.id_medico
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
ORDER BY m.nome_medico;
```

Resultado: 10 prescrições. O Dr. Marcos Andrade (Cardiologia) fez 3, para Ana Silva (2) e Roberto Almeida (1).

**5) Diretoria médica:** pacientes internados que também tiveram consulta, sem duplicidade.

```sql
SELECT DISTINCT p.nome_paciente, q.numero_quarto, m.nome_medico, c.data_consulta
FROM pacientes p
INNER JOIN internacoes i ON p.id_paciente = i.id_paciente
INNER JOIN quartos q ON i.id_quarto = q.id_quarto
INNER JOIN consultas c ON p.id_paciente = c.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
ORDER BY p.nome_paciente, c.data_consulta;
```

Resultado: 11 linhas. O DISTINCT tira as repetidas. Carlos Oliveira aparece duas vezes porque ficou em dois quartos (101 e 201).

**6) Todas as consultas, das mais recentes para as mais antigas.**

```sql
SELECT p.nome_paciente, m.nome_medico, c.data_consulta
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
ORDER BY c.data_consulta DESC;
```

Resultado: 10 consultas. A mais recente é de Ana Silva com a Dra. Camila Rocha, em 01/07/2026.

**7) Financeiro:** paciente, quarto e diária, da menor para a maior.

```sql
SELECT p.nome_paciente, q.numero_quarto, i.valor_diaria
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos q ON i.id_quarto = q.id_quarto
ORDER BY i.valor_diaria ASC;
```

Resultado: a menor diária é R$ 200,00 (João Pedro Silva, quarto 102) e a maior é R$ 600,00 (Beatriz Lima, quarto 401).

**8) Valor médio das consultas.**

```sql
SELECT ROUND(AVG(valor_consulta), 2) AS valor_medio_consulta
FROM consultas;
```

Resultado: R$ 415,00.

## Consultas 9 a 15

**9) Total arrecadado com consultas agendadas ou realizadas.**

```sql
SELECT SUM(valor_consulta) AS total_arrecadado
FROM consultas
WHERE status_consulta IN ('Agendada', 'Realizada');
```

Resultado: R$ 4.150,00.

**10) Consultas de pacientes com a família "Silva" no nome.**

```sql
SELECT p.nome_paciente, m.nome_medico, c.data_consulta
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
WHERE p.nome_paciente LIKE '%Silva%'
ORDER BY c.data_consulta;
```

Resultado: 4 consultas. Ana Silva teve 3 e João Pedro Silva teve 1. O médico Roberto Silva não entra porque o filtro é no nome do paciente.

**11) Consultas com médicos de Cardiologia.**

```sql
SELECT p.nome_paciente, m.nome_medico, m.especialidade
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos m ON c.id_medico = m.id_medico
WHERE m.especialidade LIKE '%Cardio%';
```

Resultado: 3 consultas: Ana Silva e Roberto Almeida com o Dr. Marcos Andrade (Cardiologia) e Carlos Oliveira com o Dr. Roberto Silva (Cardiologia Pediátrica).

**12) Internações do 1º semestre de 2026 (01/01 a 30/06).**

```sql
SELECT p.nome_paciente, q.numero_quarto, i.data_entrada
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos q ON i.id_quarto = q.id_quarto
WHERE i.data_entrada BETWEEN '2026-01-01' AND '2026-06-30'
ORDER BY i.data_entrada;
```

Resultado: 8 internações, de João Pedro Silva (15/01) até Fernanda Costa (10/06). As de julho e agosto ficam de fora.

**13) Total gasto em consultas por pacientes Unimed, do maior para o menor.**

```sql
SELECT p.nome_paciente, p.convenio, SUM(c.valor_consulta) AS total_gasto
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
WHERE p.convenio LIKE '%Unimed%'
GROUP BY p.id_paciente, p.nome_paciente, p.convenio
ORDER BY total_gasto DESC;
```

| Paciente | Convênio | Total gasto |
| --- | --- | --- |
| Ana Silva | Unimed | R$ 1.350,00 |
| Juliana Oliveira | Unimed Pleno | R$ 600,00 |
| Maria Santos | Unimed | R$ 280,00 |

**14) Custo das diárias por andar, só de pacientes "Oliveira".**

```sql
SELECT q.andar, SUM(i.valor_diaria) AS custo_total_diarias
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos q ON i.id_quarto = q.id_quarto
WHERE p.nome_paciente LIKE '%Oliveira%'
GROUP BY q.andar
ORDER BY q.andar ASC;
```

| Andar | Custo total das diárias |
| --- | --- |
| 1 | R$ 450,00 |
| 2 | R$ 300,00 |
| 3 | R$ 250,00 |

**15) Faturamento em consultas das especialidades de Cirurgia.**

```sql
SELECT m.especialidade, SUM(c.valor_consulta) AS total_arrecadado
FROM consultas c
INNER JOIN medicos m ON c.id_medico = m.id_medico
WHERE m.especialidade LIKE '%Cirurgia%'
GROUP BY m.especialidade
ORDER BY total_arrecadado DESC;
```

| Especialidade | Total arrecadado |
| --- | --- |
| Cirurgia Geral | R$ 1.000,00 |
| Cirurgia Plástica | R$ 600,00 |
| Cirurgia Vascular | R$ 550,00 |

## Conclusão

Com os JOINs, GROUP BY, LIKE, BETWEEN e funções como SUM e AVG, o banco respondeu às 15 perguntas da diretoria. Esses dados antes ficavam em planilhas e papel, e agora saem em segundos.
