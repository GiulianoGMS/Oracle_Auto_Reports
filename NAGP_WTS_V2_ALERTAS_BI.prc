CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTAS_BI (psNroTelefone NUMBER, psAPIKey VARCHAR2)

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
             DTAREGISTRO,
             TO_CHAR(DTAATUALIZACAO_BI, 'DD/MM/YYYY HH24:MI:SS') DTAATUALIZACAO_BI,
             ROUND((SYSDATE - DTAATUALIZACAO_BI) * 1440) MIN_ATRASO
        FROM NAGT_CONTROLE_ATUALIZACAO_BI X
       WHERE DTAREGISTRO >= SYSDATE - (10/1440)   -- registro recente (10 min)
         AND X.DTAATUALIZACAO_BI <= SYSDATE - (30/1440) -- atualização defasada 30 min
         AND X.STATUS_ALERTA = 'A'
        
    ORDER BY 1 DESC
    )
    LOOP
      
        -- Montar o texto da mensagem
        vText := '%F0%9F%9A%A8%20*Report:%20Qlik%20Sense%20Alert*%20%F0%9F%93%8A%0A%0A' ||
                 '*Visao:*%20' || msg.VISAO || '%0A' ||
                 '*Ultima%20Atualizacao:*%20' || msg.DTAATUALIZACAO_BI || '%0A' ||
                 '*Atraso:*%20' || msg.MIN_ATRASO || '%20min';

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
