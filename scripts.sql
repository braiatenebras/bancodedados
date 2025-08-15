DROP DATABASE IF EXISTS restaurante_db;
CREATE DATABASE restaurante_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE restaurante_db;

CREATE TABLE clientes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE,
    telefone VARCHAR(20),
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mesas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    lugares INT NOT NULL,
    status VARCHAR(20) DEFAULT 'LIVRE'
);

CREATE TABLE funcionarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    contratado_em DATE NOT NULL
);

CREATE TABLE categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE itens_cardapio (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    categoria_id INT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_item_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

CREATE TABLE pedidos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cliente_id INT NULL,
    mesa_id INT NOT NULL,
    funcionario_id INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ABERTO',
    aberto_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fechado_em DATETIME NULL,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_pedido_mesa FOREIGN KEY (mesa_id) REFERENCES mesas(id),
    CONSTRAINT fk_pedido_func FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
);

CREATE TABLE pedido_itens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pedido_id INT NOT NULL,
    item_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_pi_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
    CONSTRAINT fk_pi_item FOREIGN KEY (item_id) REFERENCES itens_cardapio(id)
);

CREATE TABLE meios_pagamento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE pagamentos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pedido_id INT NOT NULL,
    meio_pagamento_id INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    recebido_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pg_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
    CONSTRAINT fk_pg_meio FOREIGN KEY (meio_pagamento_id) REFERENCES meios_pagamento(id)
);

CREATE TABLE reservas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    mesa_id INT NOT NULL,
    reservado_para DATETIME NOT NULL,
    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT fk_res_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_res_mesa FOREIGN KEY (mesa_id) REFERENCES mesas(id)
);

INSERT INTO clientes (nome, email, telefone) VALUES
('Ana Souza', 'ana@exemplo.com', '11999990001'),
('Bruno Lima', 'bruno@exemplo.com', '11999990002'),
('Carla Dias', 'carla@exemplo.com', '11999990003'),
('Diego Nunes', 'diego@exemplo.com', '11999990004'),
('Elaine Prado', 'elaine@exemplo.com', '11999990005');

INSERT INTO mesas (codigo, lugares, status) VALUES
('M01', 2, 'LIVRE'), ('M02', 4, 'LIVRE'), ('M03', 4, 'RESERVADA'), ('M04', 6, 'LIVRE');

INSERT INTO funcionarios (nome, cargo, contratado_em) VALUES
('Rafaela Costa', 'garcom', '2024-01-10'),
('João Pedro', 'garcom', '2023-10-02'),
('Marina Silva', 'caixa', '2022-08-15'),
('Paulo Henrique', 'chefe', '2020-05-20');

INSERT INTO categorias (nome) VALUES ('Entradas'), ('Pratos Principais'), ('Bebidas'), ('Sobremesas');

INSERT INTO itens_cardapio (nome, preco, categoria_id, ativo) VALUES
('Bruschetta', 22.90, 1, TRUE),
('Salada Caesar', 29.50, 1, TRUE),
('Filé à Parmegiana', 58.00, 2, TRUE),
('Lasanha Bolonhesa', 52.00, 2, TRUE),
('Refrigerante Lata', 8.00, 3, TRUE),
('Suco Natural', 12.00, 3, TRUE),
('Petit Gateau', 24.00, 4, TRUE);

INSERT INTO meios_pagamento (nome) VALUES ('Dinheiro'), ('Débito'), ('Crédito'), ('Pix');

INSERT INTO pedidos (cliente_id, mesa_id, funcionario_id, status, aberto_em) VALUES
(1,1,1,'ABERTO',NOW()),
(2,2,2,'FECHADO',NOW() - INTERVAL 1 DAY),
(NULL,2,1,'FECHADO',NOW() - INTERVAL 2 DAY),
(3,4,2,'ABERTO',NOW());

INSERT INTO pedido_itens (pedido_id, item_id, quantidade, preco_unitario) VALUES
(1,1,2,22.90),
(1,5,2,8.00),
(2,3,1,58.00),
(2,6,1,12.00),
(3,4,2,52.00),
(3,5,2,8.00),
(4,2,1,29.50),
(4,6,2,12.00);

INSERT INTO pagamentos (pedido_id, meio_pagamento_id, valor, recebido_em) VALUES
(2,4,70.00,NOW() - INTERVAL 1 DAY),
(3,2,120.00,NOW() - INTERVAL 2 DAY);

INSERT INTO reservas (cliente_id, mesa_id, reservado_para, status) VALUES
(5,3,NOW() + INTERVAL 2 DAY,'ATIVA'),
(1,4,NOW() + INTERVAL 1 DAY,'ATIVA');

CREATE OR REPLACE VIEW vw_pedidos_detalhados AS
SELECT p.id AS pedido_id,
       p.status,
       p.aberto_em,
       p.fechado_em,
       c.nome AS cliente,
       m.codigo AS mesa,
       f.nome AS garcom,
       SUM(pi.quantidade * pi.preco_unitario) AS total_itens
FROM pedidos p
LEFT JOIN clientes c ON c.id = p.cliente_id
JOIN mesas m ON m.id = p.mesa_id
JOIN funcionarios f ON f.id = p.funcionario_id
LEFT JOIN pedido_itens pi ON pi.pedido_id = p.id
GROUP BY p.id, p.status, p.aberto_em, p.fechado_em, c.nome, m.codigo, f.nome;

CREATE OR REPLACE VIEW vw_itens_vendidos AS
SELECT ic.id AS item_id, ic.nome AS item, cat.nome AS categoria,
       SUM(pi.quantidade) AS qtd_vendida,
       SUM(pi.quantidade * pi.preco_unitario) AS receita
FROM pedido_itens pi
JOIN itens_cardapio ic ON ic.id = pi.item_id
JOIN categorias cat ON cat.id = ic.categoria_id
GROUP BY ic.id, ic.nome, cat.nome;

SELECT * FROM vw_pedidos_detalhados;

SELECT r.id, c.nome AS cliente, m.codigo AS mesa, r.reservado_para, r.status
FROM reservas r
JOIN clientes c ON c.id = r.cliente_id
JOIN mesas m ON m.id = r.mesa_id
WHERE r.reservado_para BETWEEN NOW() AND NOW() + INTERVAL 72 HOUR
ORDER BY r.reservado_para;

SELECT categoria, item, qtd_vendida, receita
FROM vw_itens_vendidos
ORDER BY receita DESC;

SELECT c.id, c.nome, COALESCE(SUM(pi.quantidade * pi.preco_unitario),0) AS gasto_total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id AND p.status <> 'CANCELADO'
LEFT JOIN pedido_itens pi ON pi.pedido_id = p.id
GROUP BY c.id
HAVING gasto_total > (SELECT AVG(SUM(pi2.quantidade * pi2.preco_unitario))
                      FROM clientes c2
                      LEFT JOIN pedidos p2 ON p2.cliente_id = c2.id AND p2.status <> 'CANCELADO'
                      LEFT JOIN pedido_itens pi2 ON pi2.pedido_id = p2.id
                      GROUP BY c2.id);

SELECT mesa_id, COUNT(*) AS qtd_pedidos
FROM pedidos
GROUP BY mesa_id
HAVING qtd_pedidos = (SELECT MAX(qtd)
                      FROM (SELECT mesa_id, COUNT(*) AS qtd FROM pedidos GROUP BY mesa_id) AS sub);

DELIMITER //
CREATE PROCEDURE sp_total_vendas()
BEGIN
    SELECT SUM(pi.quantidade * pi.preco_unitario) AS total_vendas
    FROM pedido_itens pi;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION fn_total_cliente(cliente INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT COALESCE(SUM(pi.quantidade * pi.preco_unitario),0)
    INTO total
    FROM pedidos p
    JOIN pedido_itens pi ON pi.pedido_id = p.id
    WHERE p.cliente_id = cliente AND p.status <> 'CANCELADO';
    RETURN total;
END //
DELIMITER ;
