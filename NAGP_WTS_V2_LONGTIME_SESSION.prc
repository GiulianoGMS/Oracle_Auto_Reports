CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_LONGTIME_SESSION (psNroTelefone NUMBER, psAPIKey VARCHAR2, psUserPDV VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);
    vHora   VARCHAR2(2);
    vMin    VARCHAR2(2);

    -- Criado por Giuliano em 10/09/2025
    -- Capta objetos invalidos e envia notificação pelo wts
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
  BEGIN
    
    SELECT TO_CHAR(SYSDATE, 'HH24') INTO vHora FROM DUAL;
    SELECT TO_CHAR(SYSDATE, 'MI') INTO vMin FROM DUAL;
    
    IF vHora BETWEEN 04 AND 21
        AND (vMin BETWEEN 00 AND 02 
          OR vMin BETWEEN 20 AND 22 
          OR vMin BETWEEN 40 AND 42) THEN
    
    FOR msg IN (
                   SELECT  REPLACE(SUBSTR(SESSION_TIME,0,2), ':','') HR,
                           AMBIENTE,
                           INST_ID,
                           SID,
                           SERIAL#,
                           SESSION_USERNAME,
                           STATUS,
                           USUARIO_OS,
                           TERMINAL_OS,
                           PROGRAMA,
                           SESSION_TIME,
                           LOGON_TIME,
                           CLIENT_INFO,
                           CLIENT_IDENTIFIER,
                           JOB_NAME,
                           ACTION,
                           PROCESS_DESC,
                           SPID
                FROM NAGV_DBMONITOR_WTS
                WHERE SESSION_TIME >= '3:00:00'
                  AND PROGRAMA NOT LIKE '%sqlplus%'
                  AND SESSION_USERNAME = CASE WHEN psUserPDV = 'Monitorpdv' THEN 'Monitorpdv' ELSE SESSION_USERNAME END
                ORDER BY SESSION_TIME DESC
  
    )
    LOOP
        -- Montar o texto da mensagem
        VTEXT :=
                '%E2%8F%B1%EF%B8%8F%20*Sess%C3%A3o%20ativa%20h%C3%A1%20mais%20de%20'||msg.HR||'%20horas*%0A%0A' ||

                '*Ambiente:*%20' || msg.AMBIENTE || '%0A' ||
                '*Usu%C3%A1rio:*%20' || msg.SESSION_USERNAME || '%0A' ||
                '*Sess%C3%A3o:*%20' || msg.SID || '%0A' ||
                '*Serial:*%20' || msg.SERIAL# || '%0A' ||
                '*Inst%C3%A2ncia:*%20' || msg.INST_ID || '%0A' ||
                '*Status:*%20' || msg.STATUS || '%0A' ||
                '*Dura%C3%A7%C3%A3o:*%20' || msg.SESSION_TIME || '%0A' ||
                '*Logon:*%20' || msg.LOGON_TIME || '%0A' ||
                '*SO:*%20' || msg.USUARIO_OS || '%0A' ||
                '*Terminal:*%20' || msg.TERMINAL_OS || '%0A' ||
                '*Programa:*%20' || msg.PROGRAMA || '%0A' ||
                '*PID:*%20' || msg.SPID || '%0A';

                IF msg.CLIENT_IDENTIFIER IS NOT NULL THEN
                   VTEXT := VTEXT || '*Client Identifier:*%20' ||
                            REPLACE(msg.CLIENT_IDENTIFIER,' ','%20') || '%0A';
                END IF;

                IF msg.CLIENT_INFO IS NOT NULL THEN
                   VTEXT := VTEXT || '*Client Info:*%20' ||
                            REPLACE(msg.CLIENT_INFO,' ','%20') || '%0A';
                END IF;

                IF msg.ACTION IS NOT NULL THEN
                   VTEXT := VTEXT || '*Action:*%20' ||
                            REPLACE(msg.ACTION,' ','%20') || '%0A';
                END IF;

                IF msg.JOB_NAME IS NOT NULL THEN
                   VTEXT := VTEXT || '*Job:*%20' ||
                            REPLACE(msg.JOB_NAME,' ','%20') || '%0A';
                END IF;

                VTEXT := VTEXT || '%0A*Para%20encerrar%20a%20sess%C3%A3o:*%0A' ||
                         'NAGP_KILL_SESSION(' ||
                         msg.SID || ',%20' ||
                         msg.SERIAL# || ',%20' ||
                         msg.INST_ID || ')';

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
    
    END IF;
  
END;
