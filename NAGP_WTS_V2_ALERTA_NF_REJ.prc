CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTA_NF_REJ (
    psNroTelefone VARCHAR2,
    psAPIKey VARCHAR2
)
AS
    vnLixo VARCHAR2(5000);
    vText VARCHAR2(4000);
    vUrl VARCHAR2(4000);
    vnQtd NUMBER := 0;
BEGIN

    -- Criado por Giuliano em 07/10/2026
    -- Alerta de notas rejeitadas de clientes PJ.
    -- Considera notas das últimas 24 horas.
    -- Não envia novamente notas já registradas em NAGT_CONTROLE_ENVIO_WTS_NF_REJ.

    SELECT COUNT(1)
      INTO vnQtd
      FROM MFL_DOCTOFISCAL X
     WHERE X.CODGERALOPER = 48
       AND STATUSNFE = 5
       AND STATUSDF = 'V'
       AND X.DTAMOVIMENTO >= SYSDATE - 1
       AND NOT EXISTS (
           SELECT 1
             FROM NAGT_CONTROLE_ENVIO_WTS_NF_REJ Y
            WHERE Y.SEQNF = X.SEQNF
       );

    IF vnQtd > 0 THEN

        vText :=
            '%F0%9F%9A%AB%20*Alerta%20NF%20Rejeitada%20-%20Cliente%20PJ*' ||
            '%0A%0A' ||
            '*Pendentes:*%20' ||
            vnQtd ||
            '%0A%0A*Detalhamento:*';

        FOR X IN (
            SELECT X.SEQNF,
                   X.DTAHOREMISSAO,
                   X.NROEMPRESA LOJA,
                   X.NUMERODF NUMERO_DOCUMENTO,
                   X.SEQPESSOA COD_CLIENTE,
                   X.CODGERALOPER CGO, X.NFECHAVEACESSO
              FROM MFL_DOCTOFISCAL X
             WHERE X.CODGERALOPER = 48
               AND STATUSNFE = 5
               AND STATUSDF = 'V'
               AND X.DTAMOVIMENTO >= SYSDATE - 1
               AND NOT EXISTS (
                   SELECT 1
                     FROM NAGT_CONTROLE_ENVIO_WTS_NF_REJ Y
                    WHERE Y.SEQNF = X.SEQNF
               )
             ORDER BY X.NROEMPRESA,
                      X.DTAHOREMISSAO
        )
        LOOP

            vText := vText ||
                     '%0A%E2%80%A2%20Emissao:%20' ||
                     TO_CHAR(X.DTAHOREMISSAO,'DD/MM/YYYY HH24:MI') ||
                     '%20-%20*Loja%20' ||
                     TO_CHAR(X.LOJA) ||
                     '*%20-%20NF%20' ||
                     TO_CHAR(X.NUMERO_DOCUMENTO) ||
                     '%20-%20Cliente%20' ||
                     TO_CHAR(X.COD_CLIENTE);

            INSERT INTO NAGT_CONTROLE_ENVIO_WTS_NF_REJ (
                SEQNF
            )
            VALUES (
                X.SEQNF
            );
        
        UPDATE MFL_DOCTOFISCAL Y SET Y.SEQVENDEDOR = Y.NROEMPRESA
                               WHERE Y.NFECHAVEACESSO = X.NFECHAVEACESSO
                                 AND Y.SEQVENDEDOR IS NULL;
        END LOOP;

        COMMIT;

        vUrl := 'http://api.textmebot.com/send.php?recipient=+' ||
                psNroTelefone ||
                '&text=' ||
                vText ||
                '&apikey=' ||
                psAPIKey;

        SELECT UTL_HTTP.REQUEST(vUrl)
          INTO vnLixo
          FROM DUAL;

        DBMS_SESSION.SLEEP(10);

    END IF;

END;
