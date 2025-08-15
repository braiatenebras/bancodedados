# Bryan Kauan Fagundes 3°D
## Tema: Gestão de Restaurante

---

## 📄 Descrição do Problema Modelado

O sistema modelado tem como objetivo gerenciar todas as operações de um restaurante, contemplando desde o atendimento ao cliente até o controle financeiro. Ele abrange:

* **Clientes:** cadastro e informações de contato, para registrar pedidos e reservas.
* **Mesas:** controle do status (livre, ocupada ou reservada) e quantidade de lugares.
* **Funcionários:** cadastro de garçons, caixas e chefes, com histórico de contratação.
* **Cardápio:** itens organizados por categorias (entradas, pratos principais, bebidas e sobremesas), incluindo preço e status de disponibilidade.
* **Pedidos e Itens:** registro detalhado de cada pedido feito, relacionando cliente, mesa e funcionário responsável, além dos itens consumidos.
* **Pagamentos:** registro dos meios de pagamento utilizados (dinheiro, débito, crédito, Pix) e valores recebidos.
* **Reservas:** agendamento de mesas por clientes, permitindo o controle de ocupação futura.

O sistema permite consultas detalhadas sobre vendas, itens mais consumidos, reservas próximas e clientes com maior gasto. Ele também facilita a tomada de decisões, como identificar mesas mais utilizadas, produtos mais vendidos e monitorar o desempenho financeiro do restaurante.

A modelagem garante integridade referencial entre entidades (por meio de chaves estrangeiras), normalização até a 3ª forma normal (3FN), e suporte a relatórios e análises por meio de views, funções e procedures.

---

## 📌 Explicação das Entidades e Relacionamentos

### 1. Clientes
- **Descrição:** Armazena informações dos clientes do restaurante, como nome, e-mail, telefone e data de cadastro.  
- **Relacionamentos:**  
  - Um cliente pode ter vários pedidos (`pedidos.cliente_id`) e várias reservas (`reservas.cliente_id`).  

### 2. Mesas
- **Descrição:** Representa as mesas do restaurante, com código, quantidade de lugares e status atual (livre, ocupada, reservada).  
- **Relacionamentos:**  
  - Uma mesa pode estar associada a vários pedidos (`pedidos.mesa_id`) e várias reservas (`reservas.mesa_id`).  

### 3. Funcionários
- **Descrição:** Armazena os dados dos funcionários, como nome, cargo (garçom, caixa, chefe) e data de contratação.  
- **Relacionamentos:**  
  - Um funcionário pode estar associado a vários pedidos como responsável (`pedidos.funcionario_id`).  

### 4. Categorias
- **Descrição:** Define categorias de itens do cardápio, como Entradas, Pratos Principais, Bebidas e Sobremesas.  
- **Relacionamentos:**  
  - Uma categoria pode conter vários itens do cardápio (`itens_cardapio.categoria_id`).  

### 5. Itens do Cardápio
- **Descrição:** Lista os produtos disponíveis no restaurante, com nome, preço, categoria e status de ativo/inativo.  
- **Relacionamentos:**  
  - Um item do cardápio pode aparecer em vários itens de pedidos (`pedido_itens.item_id`).  

### 6. Pedidos
- **Descrição:** Registra cada pedido feito no restaurante, com referência ao cliente (opcional), mesa e funcionário responsável, além de status, data de abertura e fechamento.  
- **Relacionamentos:**  
  - Um pedido pode ter vários itens (`pedido_itens.pedido_id`).  
  - Um pedido pode ter um ou mais pagamentos (`pagamentos.pedido_id`).  

### 7. Itens de Pedido
- **Descrição:** Detalha os produtos de cada pedido, com quantidade e preço unitário.  
- **Relacionamentos:**  
  - Cada registro está vinculado a um pedido e um item do cardápio.  

### 8. Meios de Pagamento
- **Descrição:** Lista os tipos de pagamento aceitos pelo restaurante, como Dinheiro, Débito, Crédito e Pix.  
- **Relacionamentos:**  
  - Um meio de pagamento pode ser usado em vários pagamentos (`pagamentos.meio_pagamento_id`).  

### 9. Pagamentos
- **Descrição:** Registra os pagamentos realizados pelos clientes, com valor, meio de pagamento e data de recebimento.  
- **Relacionamentos:**  
  - Cada pagamento está vinculado a um pedido e um meio de pagamento.  

### 10. Reservas
- **Descrição:** Armazena os agendamentos de mesas feitos pelos clientes, com data/hora e status (ativa, cumprida, cancelada).  
- **Relacionamentos:**  
  - Cada reserva está vinculada a um cliente e uma mesa.

---

## 🖼️ DER / Modelo

> O DER completo foi exportado do DBML do projeto para **PNG/PDF** e está disponível no repositório como `der_restaurante.png` ou `der_restaurante.pdf`.

---

## 🧱 Scripts SQL

> O script completo está disponível no arquivo `script_restaurante.sql` no repositório. Ele contém:
> - Criação de banco e tabelas
> - Inserção de dados fictícios
> - Views, consultas JOIN, subqueries, agregações
> - Procedure e função

Exemplos de consultas:

```sql
-- 1. Pedidos detalhados
SELECT * FROM vw_pedidos_detalhados;

-- 2. Reservas próximas 72h
SELECT r.id, c.nome AS cliente, m.codigo AS mesa, r.reservado_para, r.status
FROM reservas r
JOIN clientes c ON c.id = r.cliente_id
JOIN mesas m ON m.id = r.mesa_id
WHERE r.reservado_para BETWEEN NOW() AND NOW() + INTERVAL 72 HOUR
ORDER BY r.reservado_para;

-- 3. Itens mais vendidos
SELECT categoria, item, qtd_vendida, receita
FROM vw_itens_vendidos
ORDER BY receita DESC;

-- 4. Clientes com gasto acima da média
SELECT c.id, c.nome, COALESCE(SUM(pi.quantidade * pi.preco_unitario),0) AS gasto_total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id AND p.status <> 'CANCELADO'
LEFT JOIN pedido_itens pi ON pi.pedido_id = p.id
GROUP BY c.id
HAVING gasto_total > (
    SELECT AVG(SUM(pi2.quantidade * pi2.preco_unitario))
    FROM clientes c2
    LEFT JOIN pedidos p2 ON p2.cliente_id = c2.id AND p2.status <> 'CANCELADO'
    LEFT JOIN pedido_itens pi2 ON pi2.pedido_id = p2.id
    GROUP BY c2.id
);

-- 5. Mesa mais ocupada
SELECT mesa_id, COUNT(*) AS qtd_pedidos
FROM pedidos
GROUP BY mesa_id
HAVING qtd_pedidos = (
    SELECT MAX(qtd)
    FROM (SELECT mesa_id, COUNT(*) AS qtd FROM pedidos GROUP BY mesa_id) AS sub
);

-- 6. Procedure para total de vendas
CALL sp_total_vendas();

-- 7. Função para total gasto de um cliente específico
SELECT fn_total_cliente(1) AS total_gasto;
