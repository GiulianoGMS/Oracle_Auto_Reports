CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_LOG_API_SEAL (
    psNroTelefone VARCHAR2,
    psAPIKey      VARCHAR2
)
AS
    vnLixo VARCHAR2(5000);
    vText  VARCHAR2(4000);
    vUrl   VARCHAR2(4000);

BEGIN

    FOR msg IN (
        SELECT ROWID rid,
               TO_CHAR(DTALOG, 'DD/MM/YY HH24:MI') DTALOG,
               ERRO
          FROM NAGT_LOG_API_SEAL
         WHERE INDLOGPROCESSADO = 'N'
         ORDER BY DTALOG
    )
    LOOP

        -- Monta a mensagem
        vText :=
            '%F0%9F%8F%B7%EF%B8%8F%20*Erro%20detectado%20na%20integracao%20com%20a%20API%20da%20SEAL%20-%20Pre%C3%A7os*%0A%0A' ||
            '*Data:*%20' ||msg.DTALOG || '%0A' ||
            '*Erro:*%20' || msg.ERRO;

        -- URL da API
        vUrl :=
            'http://api.textmebot.com/send.php?recipient=+' ||
            psNroTelefone ||
            '&text=' ||
            vText ||
            '&apikey=' ||
            psAPIKey;

        -- Envia WhatsApp
        SELECT UTL_HTTP.REQUEST(vUrl)
          INTO vnLixo
          FROM DUAL;

        COMMIT;

        -- Evita bloqueio da API
        DBMS_SESSION.SLEEP(5);

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
