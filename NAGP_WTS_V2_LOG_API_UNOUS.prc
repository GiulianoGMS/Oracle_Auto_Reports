CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_LOG_API_UNOUS (
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
               DTALOG,
               ERRO
          FROM NAGT_LOG_API_UNOUS
         WHERE INDLOGPROCESSADO = 'N'
         ORDER BY DTALOG
    )
    LOOP

        -- Monta a mensagem
        vText :=
            '%F0%9F%8C%90%20*Erro detectado na API Unous*%0A%0A' ||
            '*Data:* ' || TO_CHAR(msg.DTALOG,'DD/MM/YYYY HH24:MI:SS') || '%0A' ||
            '*Erro:* ' || REPLACE(msg.ERRO,' ','%20');

        -- URL da API
        vUrl :=
            'http://api.textmebot.com/send.php?recipient=+' ||
            psNroTelefone ||
            '&text=' || REPLACE(vText,' ','%20') ||
            '&apikey=' || psAPIKey;

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
