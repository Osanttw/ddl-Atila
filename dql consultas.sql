-- =====================================================
-- Hospital Vida & Saúde - DQL: 15 consultas estratégicas
-- =====================================================
USE hospital_db;

-- 1) Farmácia: paciente, médico, data da consulta, medicamento e quantidade
SELECT p.nome_paciente, m.nome_medico, c.data_consulta, pr.medicamento, pr.quantidade
FROM prescricoes pr
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos   m ON c.id_medico   = m.id_medico
ORDER BY c.data_consulta;

-- 2) Auditoria: histórico de internações (paciente, quarto, andar, entrada, diária)
SELECT p.nome_paciente, q.numero_quarto, q.andar, i.data_entrada, i.valor_diaria
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos   q ON i.id_quarto   = q.id_quarto
ORDER BY i.data_entrada;

-- 3) Recepção: pacientes, convênios, médicos que os atenderam e especialidades
SELECT p.nome_paciente, p.convenio, m.nome_medico, m.especialidade
FROM pacientes p
INNER JOIN consultas c ON p.id_paciente = c.id_paciente
INNER JOIN medicos   m ON c.id_medico   = m.id_medico
ORDER BY p.nome_paciente;

-- 4) Coordenação médica: prescrições com médico, especialidade, paciente e remédio
SELECT m.nome_medico, m.especialidade, p.nome_paciente, pr.medicamento
FROM prescricoes pr
INNER JOIN consultas c ON pr.id_consulta = c.id_consulta
INNER JOIN medicos   m ON c.id_medico    = m.id_medico
INNER JOIN pacientes p ON c.id_paciente  = p.id_paciente
ORDER BY m.nome_medico;

-- 5) Diretoria médica: pacientes internados que também tiveram consulta (sem duplicidade)
SELECT DISTINCT p.nome_paciente, q.numero_quarto, m.nome_medico, c.data_consulta
FROM pacientes p
INNER JOIN internacoes i ON p.id_paciente = i.id_paciente
INNER JOIN quartos     q ON i.id_quarto   = q.id_quarto
INNER JOIN consultas   c ON p.id_paciente = c.id_paciente
INNER JOIN medicos     m ON c.id_medico   = m.id_medico
ORDER BY p.nome_paciente, c.data_consulta;

-- 6) Todas as consultas, das mais recentes para as mais antigas
SELECT p.nome_paciente, m.nome_medico, c.data_consulta
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos   m ON c.id_medico   = m.id_medico
ORDER BY c.data_consulta DESC;

-- 7) Financeiro: paciente, quarto e diária, da menor para a maior
SELECT p.nome_paciente, q.numero_quarto, i.valor_diaria
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos   q ON i.id_quarto   = q.id_quarto
ORDER BY i.valor_diaria ASC;

-- 8) Valor médio das consultas registradas
SELECT ROUND(AVG(valor_consulta), 2) AS valor_medio_consulta
FROM consultas;

-- 9) Total arrecadado com consultas agendadas/realizadas
SELECT SUM(valor_consulta) AS total_arrecadado
FROM consultas
WHERE status_consulta IN ('Agendada', 'Realizada');

-- 10) Consultas de pacientes da família "Silva"
SELECT p.nome_paciente, m.nome_medico, c.data_consulta
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos   m ON c.id_medico   = m.id_medico
WHERE p.nome_paciente LIKE '%Silva%'
ORDER BY c.data_consulta;

-- 11) Consultas com médicos de áreas ligadas à Cardiologia
SELECT p.nome_paciente, m.nome_medico, m.especialidade
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
INNER JOIN medicos   m ON c.id_medico   = m.id_medico
WHERE m.especialidade LIKE '%Cardio%';

-- 12) Internações com entrada no 1º semestre de 2026
SELECT p.nome_paciente, q.numero_quarto, i.data_entrada
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos   q ON i.id_quarto   = q.id_quarto
WHERE i.data_entrada BETWEEN '2026-01-01' AND '2026-06-30'
ORDER BY i.data_entrada;

-- 13) Convênios: total gasto em consultas por paciente Unimed (qualquer variação)
SELECT p.nome_paciente, p.convenio, SUM(c.valor_consulta) AS total_gasto
FROM consultas c
INNER JOIN pacientes p ON c.id_paciente = p.id_paciente
WHERE p.convenio LIKE '%Unimed%'
GROUP BY p.id_paciente, p.nome_paciente, p.convenio
ORDER BY total_gasto DESC;

-- 14) Custo total das diárias por andar, apenas pacientes "Oliveira"
SELECT q.andar, SUM(i.valor_diaria) AS custo_total_diarias
FROM internacoes i
INNER JOIN pacientes p ON i.id_paciente = p.id_paciente
INNER JOIN quartos   q ON i.id_quarto   = q.id_quarto
WHERE p.nome_paciente LIKE '%Oliveira%'
GROUP BY q.andar
ORDER BY q.andar ASC;

-- 15) Faturamento em consultas por especialidade cirúrgica
SELECT m.especialidade, SUM(c.valor_consulta) AS total_arrecadado
FROM consultas c
INNER JOIN medicos m ON c.id_medico = m.id_medico
WHERE m.especialidade LIKE '%Cirurgia%'
GROUP BY m.especialidade
ORDER BY total_arrecadado DESC;