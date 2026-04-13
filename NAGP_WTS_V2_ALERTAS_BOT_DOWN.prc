CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTAS_BOT_DOWN (psNroTelefone VARCHAR2, psAPIKey VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);

    -- Criado por Giuliano em 10/09/2025
    -- Capta visoes do BI com datas defasadas
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN
    FOR msg IN (
      
      SELECT VISAO,
             TO_CHAR(DTAREGISTRO, 'DD/MM/YYYY HH24:MI:SS') DTAREGISTRO,
             TO_CHAR(DTAATUALIZACAO_BI, 'DD/MM/YYYY HH24:MI:SS') DTAATUALIZACAO_BI,
             ROUND((SYSDATE - DTAREGISTRO) * 1440) MIN_ATRASO
        FROM NAGT_CONTROLE_ATUALIZACAO_BI X
       WHERE DTAREGISTRO <= SYSDATE - (X.MIN_TMP_REGISTRO/1440)   
         AND X.STATUS_ALERTA = 'A'
        
    ORDER BY 1 DESC
    )
    LOOP
      
        -- Montar o texto da mensagem
        vText := '%E2%9B%94%20*Report:%20Servico%20Interrompido%20(Captura%20de%20dados)*%0A%0A' ||
                 '*Visao:*%20' || msg.VISAO || '%0A' ||
                 '*Ultimo%20Registro:*%20' || msg.Dtaregistro || '%0A' ||
                 '*Atraso:*%20' || msg.MIN_ATRASO || '%20min';

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
