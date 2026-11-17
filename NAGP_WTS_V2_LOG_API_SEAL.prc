CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_LOG_API_SEAL (
    psNroTelefone VARCHAR2,
    psAPIKey      VARCHAR2
)
AS
    vnLixo VARCHAR2(5000);
    vText  VARCHAR2(4000);
    vUrl   VARCHAR2(4000);
    vnCont NUMBER := 0;

BEGIN

    FOR msg IN (
        SELECT ROWID rid,
               TO_CHAR(DTALOG, 'DD/MM/YY HH24:MI') DTALOG,
               ERRO
          FROM NAGT_LOG_API_SEAL
         WHERE NVL(INDLOGPROCESSADO, 'N') = 'N'
         ORDER BY DTALOG
    )
    LOOP

        vnCont := vnCont + 1;

        BEGIN

            -- Emoji codificado + restante da mensagem
            vText :=
                '%F0%9F%8F%B7%EF%B8%8F%20' ||
                UTL_URL.ESCAPE(
                    '*Erro detectado na integracao com a API da SEAL - Preços*' ||
                    CHR(10) || CHR(10) ||
                    '*Data:* ' || msg.DTALOG ||
                    CHR(10) ||
                    '*Erro:* ' || msg.ERRO,
                    TRUE,
                    'UTF-8'
                );

            -- Monta URL
            vUrl :=
                'http://api.textmebot.com/send.php?recipient=+' ||
                psNroTelefone ||
                '&text=' || vText ||
                '&apikey=' || psAPIKey;

            -- Envia WhatsApp
            vnLixo := UTL_HTTP.REQUEST(vUrl);

            DBMS_OUTPUT.PUT_LINE('Retorno API: ' || vnLixo);
            DBMS_OUTPUT.PUT_LINE('Envio concluido: ' || vnCont);

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(
                    'FALHA NO REGISTRO ' || vnCont || ': ' || SQLERRM
                );
        END;

        DBMS_SESSION.SLEEP(5);

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('TOTAL DE REGISTROS: ' || vnCont);

END;
