CREATE SCHEMA bd_dw;

-- Dimensão: Usuário
CREATE TABLE bd_dw.dim_usuario (
    id_usuario INT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    nome_usuario VARCHAR(100),
    cpf varchar(11),
    endereco varchar(300),
    bairro varchar(100),
    cidade varchar(100)
);

-- Dimensão: Produto
CREATE TABLE bd_dw.dim_produto (
    id_produto INT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    nome_produto VARCHAR(100)
);

-- Dimensão: Tempo
CREATE TABLE bd_dw.dim_tempo (
    id_data INT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    data DATE,
    ano INT,
    mes INT,
    dia INT
);

-- Tabela fato
CREATE TABLE bd_dw.fato_vendas (
    id_fato  int PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    id_usuario INT,
    id_produto INT,
    id_data INT,
    quantidade INT,
    preco_unitario DECIMAL(10,2),
    valor_total DECIMAL(10,2),
    FOREIGN KEY (id_usuario) REFERENCES bd_dw.dim_usuario(id_usuario),
    FOREIGN KEY (id_produto) REFERENCES bd_dw.dim_produto(id_produto),
    FOREIGN KEY (id_data) REFERENCES bd_dw.dim_tempo(id_data)
);


--insert USUARIO

INSERT INTO bd_dw.dim_usuario (nome_usuario, cpf, endereco, bairro, cidade)
SELECT DISTINCT vw.nm_usuario, vw.cpf, vw.logradouro, vw.bairro, vw.cidade
FROM public.vw_vendas vw
WHERE NOT EXISTS (
    SELECT 1 FROM bd_dw.dim_usuario d WHERE d.nome_usuario = vw.nm_usuario
);


--insert PRODUTO

INSERT INTO bd_dw.dim_produto (nome_produto)
SELECT DISTINCT vw.nm_produto
FROM public.vw_vendas vw
WHERE NOT EXISTS (
    SELECT 1 FROM bd_dw.dim_produto d WHERE d.nome_produto = vw.nm_produto
);


--insert TEMPO

INSERT INTO bd_dw.dim_tempo (data, ano, mes, dia)
SELECT DISTINCT 
    vw.data_venda,
    EXTRACT(YEAR FROM vw.data_venda)::INT,
    EXTRACT(MONTH FROM vw.data_venda)::INT,
    EXTRACT(DAY FROM vw.data_venda)::INT
FROM public.vw_vendas vw
WHERE NOT EXISTS (
    SELECT 1 FROM bd_dw.dim_tempo d WHERE d.data = vw.data_venda
);


--inserir na FATO

INSERT INTO bd_dw.fato_vendas (
    id_usuario,
    id_produto,
    id_data,
    quantidade,
    preco_unitario,
    valor_total
)
SELECT 
    u.id_usuario,
    p.id_produto,
    t.id_data,
    vw.quantidade,
    vw.preco_unitario,
    vw.total_venda
FROM public.vw_vendas vw
JOIN bd_dw.dim_usuario u ON u.nome_usuario = vw.nm_usuario
JOIN bd_dw.dim_produto p ON p.nome_produto = vw.nm_produto
JOIN bd_dw.dim_tempo t ON t.data = vw.data_venda;


--select para retornar os dados do dw

SELECT u.nome_usuario,
	   u.cpf,
	   u.bairro,
	   u.cidade,
	   u.endereco,
	   p.nome_produto,
	   t."data",
	   ft.quantidade,
	   ft.preco_unitario,
	   ft.valor_total 
	FROM bd_dw.fato_vendas ft
	JOIN bd_dw.dim_usuario u ON u.id_usuario = ft.id_usuario
	JOIN bd_dw.dim_produto p ON p.id_produto = ft.id_produto
	JOIN bd_dw.dim_tempo t ON t.id_data = ft.id_data;
