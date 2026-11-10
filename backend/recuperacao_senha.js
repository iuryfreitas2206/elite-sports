
const crypto = require("node:crypto");
const { rateLimit } = require("express-rate-limit");

// ==========================================
// RECUPERAÇÃO DE SENHA - ELITE SPORTS
// ==========================================

module.exports = function registrarRecuperacao(app, db, bcrypt) {
  const mensagemGenerica =
    "Se o e-mail estiver cadastrado, você receberá um código de recuperação.";

  // ==========================================
  // LIMITAR TENTATIVAS
  // ==========================================

  const limite = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: {
      mensagem:
        "Muitas tentativas. Tente novamente mais tarde.",
    },
  });

// ==========================================
// ENVIAR E-MAIL PELO RESEND
// ==========================================

function transporte() {
  if (
    !process.env.RESEND_API_KEY ||
    !process.env.RESET_CODE_SECRET
  ) {
    return null;
  }

  return {
    async sendMail({ to, subject, text }) {
      const resposta = await fetch(
        "https://api.resend.com/emails",
        {
          method: "POST",
          headers: {
            Authorization:
              `Bearer ${process.env.RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from:
              process.env.RESEND_FROM_EMAIL ||
              "Elite Sports <onboarding@resend.dev>",
            to: [to],
            subject: subject,
            text: text,
          }),
          signal: AbortSignal.timeout(15000),
        }
      );

      if (!resposta.ok) {
        throw new Error(
          `Falha no envio pelo Resend: HTTP ${resposta.status}`
        );
      }

      return await resposta.json();
    },
  };
}

  
  // ==========================================
  // PROTEGER O CÓDIGO DE RECUPERAÇÃO
  // ==========================================

  function hashCodigo(idUsuario, codigo) {
    return crypto
      .createHmac(
        "sha256",
        process.env.RESET_CODE_SECRET
      )
      .update(`${idUsuario}:${codigo}`)
      .digest("hex");
  }

  function emailValido(email) {
    return (
      typeof email === "string" &&
      email.length <= 254 &&
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    );
  }

  // ==========================================
  // SOLICITAR CÓDIGO POR E-MAIL
  // ==========================================

  app.post(
    "/api/recuperacao/solicitar",
    limite,
    async (req, res) => {
      const email =
        typeof req.body?.email === "string"
          ? req.body.email.trim().toLowerCase()
          : "";

      if (!emailValido(email)) {
        return res.status(400).json({
          mensagem: "Informe um e-mail válido.",
        });
      }

      const mailer = transporte();

      if (!mailer) {
        return res.status(503).json({
          mensagem:
            "Recuperação indisponível. O envio de e-mail não está configurado.",
        });
      }

      try {
        const [usuarios] = await db.query(
          "SELECT id_usuario, email FROM usuarios WHERE email = ? LIMIT 1",
          [email]
        );

        // Não revelar se o e-mail existe no banco.
        if (usuarios.length === 0) {
          return res.json({
            mensagem: mensagemGenerica,
          });
        }

        const idUsuario = String(
          usuarios[0].id_usuario
        );

        // Evitar vários envios em pouco tempo.
        const [anteriores] = await db.query(
          `SELECT
             enviado_em > DATE_SUB(
               NOW(3), INTERVAL 1 MINUTE
             ) AS recente
           FROM recuperacao_senha
           WHERE id_usuario = ?`,
          [idUsuario]
        );

        if (
          anteriores.length &&
          anteriores[0].recente
        ) {
          return res.json({
            mensagem: mensagemGenerica,
          });
        }

        // Gerar código aleatório de seis números.
        const codigo = crypto
          .randomInt(0, 1000000)
          .toString()
          .padStart(6, "0");

        const codigoHash = hashCodigo(
          idUsuario,
          codigo
        );

        // Salvar apenas o hash do código.
        await db.query(
          `INSERT INTO recuperacao_senha
            (
              id_usuario,
              codigo_hash,
              expira_em,
              enviado_em,
              tentativas
            )
           VALUES (
             ?, ?,
             DATE_ADD(NOW(3), INTERVAL 10 MINUTE),
             NOW(3),
             0
           )
           ON DUPLICATE KEY UPDATE
             codigo_hash = VALUES(codigo_hash),
             expira_em = VALUES(expira_em),
             enviado_em = VALUES(enviado_em),
             tentativas = 0`,
          [idUsuario, codigoHash]
        );

        // ==========================================
        // ENVIAR CÓDIGO POR E-MAIL
        // ==========================================

        try {
          await mailer.sendMail({
            from: process.env.SMTP_FROM,
            to: usuarios[0].email,
            subject:
              "Elite Sports - Recuperação de senha",
            text:
              `Seu código de recuperação é: ${codigo}\n\n` +
              "Ele expira em 10 minutos.\n" +
              "Se você não pediu a recuperação, ignore este e-mail.",
          });
        } catch (erroEmail) {
          console.error(
            "Falha no envio da recuperação:",
            erroEmail.message
          );

          await db.query(
            `DELETE FROM recuperacao_senha
             WHERE id_usuario = ?
               AND codigo_hash = ?`,
            [idUsuario, codigoHash]
          );
        }

        return res.json({
          mensagem: mensagemGenerica,
        });
      } catch (erro) {
        console.error(
          "Falha na solicitação de recuperação:",
          erro.message
        );

        return res.status(500).json({
          mensagem:
            "Não foi possível processar a solicitação.",
        });
      }
    }
  );

  // ==========================================
  // CONFIRMAR CÓDIGO E ALTERAR SENHA
  // ==========================================

  app.post(
    "/api/recuperacao/confirmar",
    limite,
    async (req, res) => {
      const email =
        typeof req.body?.email === "string"
          ? req.body.email.trim().toLowerCase()
          : "";

      const codigo = req.body?.codigo;
      const novaSenha = req.body?.novaSenha;

      // ==========================================
      // VALIDAR OS DADOS
      // ==========================================

      if (
        !emailValido(email) ||
        typeof codigo !== "string" ||
        !/^\d{6}$/.test(codigo) ||
        typeof novaSenha !== "string" ||
        novaSenha.length < 8 ||
        Buffer.byteLength(novaSenha, "utf8") > 72
      ) {
        return res.status(400).json({
          mensagem:
            "Confira o e-mail, o código e a senha. A senha deve ter pelo menos 8 caracteres.",
        });
      }

      if (!process.env.RESET_CODE_SECRET) {
        return res.status(503).json({
          mensagem: "Recuperação indisponível.",
        });
      }

      const conexao = await db.getConnection();

      try {
        await conexao.beginTransaction();

        // ==========================================
        // LOCALIZAR USUÁRIO
        // ==========================================

        const [usuarios] = await conexao.query(
          "SELECT id_usuario FROM usuarios WHERE email = ? LIMIT 1",
          [email]
        );

        if (!usuarios.length) {
          await conexao.rollback();

          return res.status(400).json({
            mensagem: "Código inválido ou expirado.",
          });
        }

        const idUsuario = String(
          usuarios[0].id_usuario
        );

        // ==========================================
        // CONSULTAR CÓDIGO E VALIDADE
        // ==========================================

        const [registros] = await conexao.query(
          `SELECT
             codigo_hash,
             tentativas,
             expira_em <= NOW(3) AS expirado
           FROM recuperacao_senha
           WHERE id_usuario = ?
           FOR UPDATE`,
          [idUsuario]
        );

        const registro = registros[0];

        if (
          !registro ||
          registro.expirado ||
          registro.tentativas >= 5
        ) {
          await conexao.commit();

          return res.status(400).json({
            mensagem:
              "Código inválido ou expirado. Solicite outro código.",
          });
        }

        // ==========================================
        // COMPARAR O CÓDIGO
        // ==========================================

        const recebido = Buffer.from(
          hashCodigo(idUsuario, codigo),
          "hex"
        );

        const esperado = Buffer.from(
          registro.codigo_hash,
          "hex"
        );

        const codigoCorreto =
          recebido.length === esperado.length &&
          crypto.timingSafeEqual(
            recebido,
            esperado
          );

        if (!codigoCorreto) {
          await conexao.query(
            `UPDATE recuperacao_senha
             SET tentativas = tentativas + 1
             WHERE id_usuario = ?`,
            [idUsuario]
          );

          await conexao.commit();

          return res.status(400).json({
            mensagem: "Código inválido ou expirado.",
          });
        }

        // ==========================================
        // CRIPTOGRAFAR A NOVA SENHA
        // ==========================================

        const senhaHash = await bcrypt.hash(
          novaSenha,
          12
        );

        // ==========================================
        // ATUALIZAR A SENHA DO USUÁRIO
        // ==========================================

        await conexao.query(
          `UPDATE usuarios
           SET senha_hash = ?
           WHERE id_usuario = ?`,
          [senhaHash, idUsuario]
        );

        // ==========================================
        // INVALIDAR O CÓDIGO APÓS O USO
        // ==========================================

        await conexao.query(
          `DELETE FROM recuperacao_senha
           WHERE id_usuario = ?`,
          [idUsuario]
        );

        await conexao.commit();

        return res.json({
          mensagem:
            "Senha atualizada com sucesso! Faça login novamente.",
        });
      } catch (erro) {
        await conexao.rollback();

        console.error(
          "Falha ao confirmar recuperação:",
          erro.message
        );

        return res.status(500).json({
          mensagem:
            "Não foi possível redefinir a senha.",
        });
      } finally {
        conexao.release();
      }
    }
  );
};
