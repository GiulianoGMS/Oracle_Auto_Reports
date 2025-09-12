CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_TB_LOGFALHACARGAMONITOR (psNroTelefone NUMBER, psAPIKey VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);

    -- Criado por Giuliano em 10/09/2025
    -- Capta objetos invalidos e envia notificação pelo wts
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN
    FOR msg IN (

      SELECT DISTINCT X.SEQLOG,
             X.TABELA,
             TO_CHAR(X.DTAHOREMISSAO, 'DD/MM/YYYY') DTAHOREMISSAO,
             X.TIPOCARGA,
             X.MENSAGEM,
             X.REPLICACAO
        FROM MONITORPDV.TB_LOGFALHACARGAMONITOR X
    )
    LOOP
        -- Montar o texto da mensagem
        VTEXT := '%F0%9F%9A%A8%20*Report:%20Existem%20Erros%20na%20Carga%20Monitor:*%0A%0A' ||
                 '*SeqLog:*%20'     || msg.SEQLOG        || '%0A' ||
                 '*Tabela:*%20'     || msg.TABELA        || '%0A' ||
                 '*Data:*%20'       || msg.DTAHOREMISSAO || '%0A' ||
                 '*TipoCarga:*%20'  || msg.TIPOCARGA     || '%0A' ||
                 '*Mensagem:*%20'   || msg.MENSAGEM      || '%0A' ||
                 '*Replicacao:*%20' || msg.REPLICACAO    || '%0A' ||
                 '*Erro em:*%20TB_LOGFALHACARGAMONITOR';

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
