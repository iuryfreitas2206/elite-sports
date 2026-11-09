
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const db = require("./db");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());


// ==========================================
// TESTE DA API
// ==========================================
app.get("/api/teste", (req, res) => {
    res.json({
        mensagem: "API Elite Sports funcionando!"
    });
});


// ==========================================
// TESTE DO BANCO
// ==========================================
app.get("/api/banco-teste", async (req, res) => {
    try {
        const [resultado] = await db.query(
            "SELECT DATABASE() AS banco"
        );

        res.json({
            mensagem: "MySQL conectado com sucesso!",
            banco: resultado[0].banco
        });

    } catch (erro) {
        console.error(erro);

        res.status(500).json({
            mensagem: "Erro ao conectar ao banco de dados"
        });
    }
});


// ==========================================
// CADASTRAR USUÁRIO
// ==========================================
app.post("/api/usuarios", async (req, res) => {

    try {

        const {
            nome,
            email,
            cpf,
            telefone,
            senha
        } = req.body;


        // Verifica campos obrigatórios
        if (!nome || !email || !cpf || !senha) {
            return res.status(400).json({
                mensagem: "Preencha nome, e-mail, CPF e senha."
            });
        }


        // Verifica se já existe e-mail ou CPF
        const [usuariosExistentes] = await db.query(
            `
            SELECT id_usuario
            FROM usuarios
            WHERE email = ? OR cpf = ?
            `,
            [email, cpf]
        );


        if (usuariosExistentes.length > 0) {
            return res.status(409).json({
                mensagem: "E-mail ou CPF já cadastrado."
            });
        }


        // Protege a senha
        const senhaHash = await bcrypt.hash(senha, 10);


        // Salva no banco
        const [resultado] = await db.query(
            `
            INSERT INTO usuarios
            (
                nome,
                email,
                cpf,
                telefone,
                senha_hash
            )
            VALUES (?, ?, ?, ?, ?)
            `,
            [
                nome,
                email,
                cpf,
                telefone || null,
                senhaHash
            ]
        );


        res.status(201).json({
            mensagem: "Usuário cadastrado com sucesso!",
            id_usuario: resultado.insertId
        });


    } catch (erro) {

        console.error("Erro ao cadastrar usuário:", erro);

        res.status(500).json({
            mensagem: "Erro interno ao cadastrar usuário."
        });
    }

});

// ==========================================
// LOGIN
// ==========================================
app.post("/api/login", async (req, res) => {

    try {

        const { email, senha } = req.body;

        if (!email || !senha) {
            return res.status(400).json({
                mensagem: "Informe e-mail e senha."
            });
        }

        const [usuarios] = await db.query(
            `
            SELECT
                id_usuario,
                nome,
                email,
                cpf,
                telefone,
                senha_hash
            FROM usuarios
            WHERE email = ?
            `,
            [email.toLowerCase()]
        );

        if (usuarios.length === 0) {
            return res.status(401).json({
                mensagem: "E-mail ou senha incorretos."
            });
        }

        const usuario = usuarios[0];

        const senhaCorreta = await bcrypt.compare(
            senha,
            usuario.senha_hash
        );

        if (!senhaCorreta) {
            return res.status(401).json({
                mensagem: "E-mail ou senha incorretos."
            });
        }

        res.json({
            mensagem: "Login realizado com sucesso!",
            usuario: {
                id_usuario: usuario.id_usuario,
                nome: usuario.nome,
                email: usuario.email,
                cpf: usuario.cpf,
                telefone: usuario.telefone || ""
            }
        });

    } catch (erro) {

        console.error("Erro no login:", erro);

        res.status(500).json({
            mensagem: "Erro interno ao realizar login."
        });
    }
});

// ==========================================
// BUSCAR USUÁRIO POR ID
// ==========================================
app.get("/api/usuarios/:id", async (req, res) => {

    try {

        const id = req.params.id;

        const [usuarios] = await db.query(
            `
            SELECT
                id_usuario,
                nome,
                email,
                cpf,
                telefone
            FROM usuarios
            WHERE id_usuario = ?
            `,
            [id]
        );

        if (usuarios.length === 0) {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }

        res.json(usuarios[0]);

    } catch (erro) {

        console.error("Erro ao buscar usuário:", erro);

        res.status(500).json({
            mensagem: "Erro interno ao buscar usuário."
        });
    }

});


// ==========================================
// ATUALIZAR USUÁRIO
// ==========================================
app.put("/api/usuarios/:id", async (req, res) => {

    try {

        const id = req.params.id;

        const {
            nome,
            telefone
        } = req.body;

        if (!nome) {
            return res.status(400).json({
                mensagem: "Informe o nome."
            });
        }

        const [resultado] = await db.query(
            `
            UPDATE usuarios
            SET
                nome = ?,
                telefone = ?
            WHERE id_usuario = ?
            `,
            [
                nome,
                telefone || null,
                id
            ]
        );

        if (resultado.affectedRows === 0) {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }

        res.json({
            mensagem: "Dados atualizados com sucesso!"
        });

    } catch (erro) {

        console.error("Erro ao atualizar usuário:", erro);

        res.status(500).json({
            mensagem: "Erro interno ao atualizar usuário."
        });
    }

});

// ==========================================
// CRIAR PEDIDO
// ==========================================
app.post("/api/pedidos", async (req, res) => {

    const conexao = await db.getConnection();

    try {

        const {
            id_usuario,
            itens
        } = req.body;


        if (
            !id_usuario ||
            !Array.isArray(itens) ||
            itens.length === 0
        ) {

            return res.status(400).json({
                mensagem: "Usuário e itens do pedido são obrigatórios."
            });
        }


        await conexao.beginTransaction();


        // Cria o pedido inicialmente zerado
        const [pedidoCriado] = await conexao.query(
            `
            INSERT INTO pedidos
            (
                id_usuario,
                status,
                valor_produtos,
                valor_frete,
                valor_total
            )
            VALUES (?, ?, ?, ?, ?)
            `,
            [
                id_usuario,
                "Pedido realizado",
                0,
                0,
                0
            ]
        );


        const idPedido =
            pedidoCriado.insertId;


        let valorProdutos = 0;


        // ==========================================
        // ITENS DO CARRINHO
        // ==========================================

        for (const item of itens) {

            const quantidade =
                Number(item.qtd) || 1;


            const cor =
                item.cor || "Única";


            const tamanho =
                item.tamanho === "Único"
                    ? null
                    : item.tamanho;


            // Procura a variação correta no banco
            const [variacoes] = await conexao.query(
                `
                SELECT
                    pv.id_variacao,
                    pv.estoque,
                    p.nome,
                    p.preco
                FROM produto_variacoes pv

                INNER JOIN produtos p
                    ON p.id_produto = pv.id_produto

                WHERE
                    p.nome = ?
                    AND pv.cor = ?
                    AND (
                        (? IS NULL AND pv.tamanho IS NULL)
                        OR pv.tamanho = ?
                    )
                    AND p.ativo = TRUE

                LIMIT 1
                `,
                [
                    item.nome,
                    cor,
                    tamanho,
                    tamanho
                ]
            );


            if (variacoes.length === 0) {

                throw new Error(
                    `Variação não encontrada para: ${item.nome} - ${cor} - ${item.tamanho}`
                );
            }


            const variacao =
                variacoes[0];


            if (variacao.estoque < quantidade) {

                throw new Error(
                    `Estoque insuficiente para ${item.nome}.`
                );
            }


            const precoUnitario =
                Number(variacao.preco);


            const subtotal =
                precoUnitario * quantidade;


            valorProdutos += subtotal;


            // Salva item do pedido
            await conexao.query(
                `
                INSERT INTO itens_pedido
                (
                    id_pedido,
                    id_variacao,
                    nome_produto,
                    preco_unitario,
                    quantidade
                )
                VALUES (?, ?, ?, ?, ?)
                `,
                [
                    idPedido,
                    variacao.id_variacao,
                    variacao.nome,
                    precoUnitario,
                    quantidade
                ]
            );


            // Diminui o estoque
            await conexao.query(
                `
                UPDATE produto_variacoes
                SET estoque = estoque - ?
                WHERE id_variacao = ?
                `,
                [
                    quantidade,
                    variacao.id_variacao
                ]
            );

        }


        const valorFrete = 0;

        const valorTotal =
            valorProdutos + valorFrete;


        // Atualiza totais
        await conexao.query(
            `
            UPDATE pedidos
            SET
                valor_produtos = ?,
                valor_frete = ?,
                valor_total = ?
            WHERE id_pedido = ?
            `,
            [
                valorProdutos,
                valorFrete,
                valorTotal,
                idPedido
            ]
        );


        await conexao.commit();


        res.status(201).json({
            mensagem: "Pedido realizado com sucesso!",
            id_pedido: idPedido,
            valor_total: valorTotal
        });


    } catch (erro) {

        await conexao.rollback();

        console.error(
            "Erro ao criar pedido:",
            erro
        );


        res.status(500).json({
            mensagem:
                erro.message ||
                "Erro interno ao criar pedido."
        });


    } finally {

        conexao.release();

    }

});


// ==========================================
// LISTAR PEDIDOS DO USUÁRIO
// ==========================================
app.get("/api/pedidos/usuario/:id_usuario", async (req, res) => {

    try {

        const idUsuario =
            req.params.id_usuario;


        const [pedidos] = await db.query(
            `
            SELECT
                id_pedido,
                data_pedido,
                status,
                valor_produtos,
                valor_frete,
                valor_total
            FROM pedidos
            WHERE id_usuario = ?
            ORDER BY data_pedido DESC
            `,
            [idUsuario]
        );


        for (const pedido of pedidos) {

            const [itens] = await db.query(
                `
                SELECT
                    ip.id_item,
                    ip.id_variacao,
                    ip.nome_produto,
                    ip.preco_unitario,
                    ip.quantidade,
                    pv.cor,
                    pv.tamanho,
                    pv.imagem
                FROM itens_pedido ip

                INNER JOIN produto_variacoes pv
                    ON pv.id_variacao = ip.id_variacao

                WHERE ip.id_pedido = ?
                `,
                [pedido.id_pedido]
            );


            pedido.itens = itens;

        }


        res.json(pedidos);


    } catch (erro) {

        console.error(
            "Erro ao listar pedidos:",
            erro
        );


        res.status(500).json({
            mensagem:
                "Erro interno ao listar pedidos."
        });

    }

});

// ==========================================
// VERIFICAR E-MAIL PARA REDEFINIR SENHA
// ==========================================
app.post("/api/verificar-email", async (req, res) => {

    try {

        const { email } = req.body;


        if (!email) {
            return res.status(400).json({
                mensagem: "Informe o e-mail."
            });
        }


        const [usuarios] = await db.query(
            `
            SELECT id_usuario, email
            FROM usuarios
            WHERE email = ?
            `,
            [email.toLowerCase()]
        );


        if (usuarios.length === 0) {
            return res.status(404).json({
                mensagem: "E-mail não cadastrado."
            });
        }


        res.json({
            mensagem: "E-mail encontrado."
        });


    } catch (erro) {

        console.error(
            "Erro ao verificar e-mail:",
            erro
        );


        res.status(500).json({
            mensagem:
                "Erro interno ao verificar e-mail."
        });

    }

});


// ==========================================
// REDEFINIR SENHA
// ==========================================
app.put("/api/redefinir-senha", async (req, res) => {

    try {

        const {
            email,
            novaSenha
        } = req.body;


        if (!email || !novaSenha) {
            return res.status(400).json({
                mensagem:
                    "Informe o e-mail e a nova senha."
            });
        }


        if (novaSenha.length < 6) {
            return res.status(400).json({
                mensagem:
                    "A senha precisa ter pelo menos 6 caracteres."
            });
        }


        const [usuarios] = await db.query(
            `
            SELECT id_usuario
            FROM usuarios
            WHERE email = ?
            `,
            [email.toLowerCase()]
        );


        if (usuarios.length === 0) {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }


        // Criptografa a nova senha
        const senhaHash =
            await bcrypt.hash(
                novaSenha,
                10
            );


        await db.query(
            `
            UPDATE usuarios
            SET senha_hash = ?
            WHERE email = ?
            `,
            [
                senhaHash,
                email.toLowerCase()
            ]
        );


        res.json({
            mensagem:
                "Senha redefinida com sucesso!"
        });


    } catch (erro) {

        console.error(
            "Erro ao redefinir senha:",
            erro
        );


        res.status(500).json({
            mensagem:
                "Erro interno ao redefinir senha."
        });

    }

});

// ==========================================
// LISTAR PRODUTOS E ESTOQUE
// ==========================================
app.get("/api/produtos", async (req, res) => {

    try {

        const [produtos] = await db.query(`
            SELECT
                id_produto,
                nome,
                preco,
                ativo
            FROM produtos
            WHERE ativo = TRUE
            ORDER BY id_produto
        `);


        for (const produto of produtos) {

            const [variacoes] = await db.query(
                `
                SELECT
                    id_variacao,
                    cor,
                    tamanho,
                    estoque,
                    imagem
                FROM produto_variacoes
                WHERE id_produto = ?
                ORDER BY id_variacao
                `,
                [produto.id_produto]
            );


            produto.variacoes = variacoes;

        }


        res.json(produtos);


    } catch (erro) {

        console.error(
            "Erro ao listar produtos:",
            erro
        );


        res.status(500).json({
            mensagem:
                "Erro interno ao listar produtos."
        });

    }

});

// ==========================================
// INICIA O SERVIDOR
// ==========================================
app.listen(PORT, () => {
    console.log(
        `API Elite Sports rodando em http://localhost:${PORT}`
    );
});