CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_TB_LOGDBERRO (psNroTelefone NUMBER, psAPIKey VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);

    -- Criado por Giuliano em 10/09/2025
    -- Capta objetos invalidos e envia notificação pelo wts
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN
    FOR msg IN (

      SELECT Y.DTAHOREVENTO,
             Y.USERNAME,
             Y.NLSLANG,
             Y.IPCLIENT,
             Y.OSUSER,
             Y.TERMINAL,
             Y.MODULO,
             Y.IDENTIFIER,
             Y.MSGERRO,
             Y.ACTION,
             Y.SQLERRO 
        FROM MONITORPDV.TB_LOGDBERRO Y
    )
    LOOP
        -- Montar o texto da mensagem
        VTEXT := '%F0%9F%9A%A8%20*Report:%20Existem%20Erros%20na%20Carga%20Monitor:*%0A%0A' ||
                 '*Data Evento:*%20' || msg.DTAHOREVENTO || '%0A' ||
                 '*Username:*%20'    || msg.USERNAME     || '%0A' ||
                 '*NlsLang:*%20'     || msg.NLSLANG      || '%0A' ||
                 '*IpcClient:*%20'   || msg.IPCLIENT     || '%0A' ||
                 '*OsUser:*%20'      || msg.OSUSER       || '%0A' ||
                 '*Terminal:*%20'    || msg.TERMINAL     || '%0A' ||
                 '*Modulo:*%20'      || msg.MODULO       || '%0A' ||
                 '*Identifier:*%20'  || msg.IDENTIFIER   || '%0A' ||
                 '*MsgErro:*%20'     || msg.MSGERRO      || '%0A' ||
                 '*Action:*%20'      || msg.ACTION       || '%0A' ||
                 '*SqlErro:*%20'     || msg.SQLERRO;

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
