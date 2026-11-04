-- =====================================================
-- Sistema de Gestão Hospitalar "Vida & Saúde"
-- DDL: criação do banco, tabelas, relacionamentos e regras
-- SGBD: MySQL 8+ / MariaDB 10.5+
-- =====================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hospital_db;

-- ---------- PACIENTES ----------
CREATE TABLE pacientes (
    id_paciente       INT AUTO_INCREMENT PRIMARY KEY,
    nome_paciente     VARCHAR(100) NOT NULL,
    cpf               VARCHAR(14)  NOT NULL UNIQUE,
    data_nascimento   DATE         NOT NULL,
    telefone_paciente VARCHAR(15),
    convenio          VARCHAR(50)  NOT NULL DEFAULT 'Particular'
) ENGINE=InnoDB;

-- ---------- MÉDICOS ----------
CREATE TABLE medicos (
    id_medico     INT AUTO_INCREMENT PRIMARY KEY,
    nome_medico   VARCHAR(100) NOT NULL,
    crm           VARCHAR(20)  NOT NULL UNIQUE,
    especialidade VARCHAR(60)  NOT NULL
) ENGINE=InnoDB;

-- ---------- QUARTOS (leitos) ----------
CREATE TABLE quartos (
    id_quarto     INT AUTO_INCREMENT PRIMARY KEY,
    numero_quarto INT         NOT NULL UNIQUE,
    andar         INT         NOT NULL,
    tipo_quarto   VARCHAR(30) NOT NULL,
    status_quarto VARCHAR(20) NOT NULL DEFAULT 'Livre'
) ENGINE=InnoDB;

-- ---------- INTERNAÇÕES (paciente N:N quarto) ----------
-- ON DELETE RESTRICT: não permite apagar paciente/quarto com histórico.
CREATE TABLE internacoes (
    id_internacao INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente   INT           NOT NULL,
    id_quarto     INT           NOT NULL,
    data_entrada  DATE          NOT NULL,
    data_saida    DATE          NULL,
    valor_diaria  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_int_paciente FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_int_quarto FOREIGN KEY (id_quarto) REFERENCES quartos(id_quarto)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_int_datas CHECK (data_saida IS NULL OR data_saida >= data_entrada),
    CONSTRAINT ck_int_valor CHECK (valor_diaria > 0)
) ENGINE=InnoDB;

-- ---------- CONSULTAS (paciente N:N médico) ----------
-- UNIQUE (id_medico, data_consulta): o mesmo médico não pode ter dois
-- atendimentos no mesmo horário (fim da sobreposição de agenda).
CREATE TABLE consultas (
    id_consulta     INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente     INT           NOT NULL,
    id_medico       INT           NOT NULL,
    data_consulta   DATETIME      NOT NULL,
    status_consulta VARCHAR(20)   NOT NULL DEFAULT 'Agendada',
    valor_consulta  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_con_paciente FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_con_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_medico)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_medico_horario UNIQUE (id_medico, data_consulta),
    CONSTRAINT ck_con_valor CHECK (valor_consulta >= 0)
) ENGINE=InnoDB;

-- ---------- PRESCRIÇÕES (1 consulta : N prescrições) ----------
CREATE TABLE prescricoes (
    id_prescricao INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta   INT          NOT NULL,
    medicamento   VARCHAR(100) NOT NULL,
    dosagem       VARCHAR(100) NOT NULL,
    quantidade    INT          NOT NULL,
    CONSTRAINT fk_pre_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_pre_qtd CHECK (quantidade > 0)
) ENGINE=InnoDB;

-- ---------- TRIGGERS: leito não pode ter internações sobrepostas ----------
DELIMITER $$

CREATE TRIGGER trg_internacao_sem_sobreposicao_ins
BEFORE INSERT ON internacoes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM internacoes i
        WHERE i.id_quarto = NEW.id_quarto
          AND NEW.data_entrada <= COALESCE(i.data_saida, '9999-12-31')
          AND COALESCE(NEW.data_saida, '9999-12-31') >= i.data_entrada
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Quarto ja ocupado no periodo informado';
    END IF;
END$$

CREATE TRIGGER trg_internacao_sem_sobreposicao_upd
BEFORE UPDATE ON internacoes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM internacoes i
        WHERE i.id_quarto = NEW.id_quarto
          AND i.id_internacao <> OLD.id_internacao
          AND NEW.data_entrada <= COALESCE(i.data_saida, '9999-12-31')
          AND COALESCE(NEW.data_saida, '9999-12-31') >= i.data_entrada
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Quarto ja ocupado no periodo informado';
    END IF;
END$$

DELIMITER ;