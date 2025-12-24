CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_CONTROLECARGA_PDV (psNroTelefone NUMBER, psAPIKey VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);
    vDta    VARCHAR2(2);
    vFeriado      VARCHAR2(1);

    -- Criado por Giuliano em 22/12/2025
    -- Valida se a ultima execucao de integracao de documentos do monitor foi à mais de 30 minutos
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN  
    
    SELECT TO_CHAR(SYSDATE, 'HH24') INTO vDta FROM DUAL;
    
    IF 1=1 THEN --vDta BETWEEN 8 AND 23 THEN -- Se for entre 7hrs ate 23:59
    
    FOR msg IN (

    SELECT CASE WHEN ROW_NUMBER() OVER (ORDER BY 1) > 1 AND ROW_NUMBER() OVER (PARTITION BY TABELA ORDER BY TABELA, NROEMPRESA) = 1 THEN '%0A'||'*Tabela:*%20'||TABELA||'%0A'
           ELSE CASE WHEN ROW_NUMBER() OVER (PARTITION BY TABELA ORDER BY TABELA, NROEMPRESA) = 1 THEN '*Tabela:*%20'||TABELA||'%0A' ELSE '%20' END END TB,
         CASE WHEN ROW_NUMBER() OVER (PARTITION BY TABELA ORDER BY TABELA, NROEMPRESA) = 1 
           THEN '*Status:*%20'||DECODE(A.STATUS,3, 'Falha no envio do pacote', 4, 'Falha ao tentar carregar o pacote', 'Teste')||'%0A%0A' ELSE '%20' END STATUS,
         CASE WHEN ROW_NUMBER() OVER (PARTITION BY TABELA ORDER BY TABELA, NROEMPRESA) = 1 THEN '%20%20' END||
           '*Loja:*%20'||A.NROEMPRESA||'%20*Checkouts:*%20'||LISTAGG(DISTINCT A.NROCHECKOUT, ', ') WITHIN GROUP (ORDER BY A.NROEMPRESA, A.NROCHECKOUT)||'%0A' INFO
       
      FROM MONITORPDV.TB_CONTROLECARGAPDV A
     WHERE A.TIPOCARGA = 'P'
       AND A.STATUS IN (3, 4)
       AND A.TABELA LIKE '%TB_PRODPRECO%'
       AND A.DTAHOREMISSAO >= TRUNC(SYSDATE) - 1
       AND A.DTAHOREMISSAO < TRUNC(SYSDATE + 1)
       
     GROUP BY A.NROEMPRESA, A.STATUS, A.TABELA
     ORDER BY A.TABELA, A.NROEMPRESA
    
               )
    LOOP
        -- Montar o texto da mensagem
        VTEXT := VTEXT||msg.TB||msg.STATUS||RTRIM(msg.INFO, '%0A');
      
    END LOOP;
    
    -- Construir a URL
    
     vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE('%F0%9F%9A%A8%20*Report:%20Falhas%20Registradas%20No%20Controle%20De%20Carga%20Do%20PDV:*%0A%0A'||
                                                                                         vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
    
    END IF;
  
END;
