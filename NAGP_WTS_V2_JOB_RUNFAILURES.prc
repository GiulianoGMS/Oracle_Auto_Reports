CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_JOB_RUNFAILURES (psNroTelefone NUMBER, psAPIKey VARCHAR2) 

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);

    -- Criado por Giuliano em 10/09/2025
    -- Capta objetos invalidos e envia notificação pelo wts
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN
    FOR msg IN (
      
    SELECT DISTINCT
           REPLACE(TO_CHAR(XP.LOG_DATE, 'DD-MON-YYYY'), ' ', '%20') AS DATA,
           REPLACE(SUBSTR(XP.JOB_NAME, 1, 100), ' ', '%20') AS JOB_NAME,
           SUBSTR(REPLACE(REGEXP_REPLACE(REPLACE(XP.ERRORS, '-','x'), '[^a-zA-Z0-9\-]', ' '), ' ', '%20'),0,1700)||'...' AS ERROR,
           REPLACE(TO_CHAR(XP.INSTANCE_ID), ' ', '%20') AS INSTANCE
        
      FROM ALL_SCHEDULER_JOB_RUN_DETAILS XP
     WHERE TO_DATE(TO_CHAR(LOG_DATE, 'DD/MM/YYYY HH24:MI'), 'DD/MM/YYYY HH24:MI') 
        >=  SYSDATE - (10/1440)  AND STATUS = 'FAILED' ORDER BY 1 DESC
    )
    LOOP
      
        -- Montar o texto da mensagem
        vText := '%F0%9F%9A%A8%20*Report:%20Houve%20falha%20de%20execucao%20na(s)%20rotina(s)%20abaixo:*%0A%0A' ||
                 '*Log_Date:*%20'    || msg.DATA || '%0A' ||
                 '*Job_Name:*%20'    || msg.JOB_NAME || '%0A' ||
                 '*Error:*%20'       || msg.ERROR || '%0A' ||
                 '*Instance_ID:*%20' || msg.INSTANCE;

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
