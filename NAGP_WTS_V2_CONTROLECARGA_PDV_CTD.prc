CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_CONTROLECARGA_PDV_CTD (psNroTelefone VARCHAR2, psAPIKey VARCHAR2)

 AS -- Versao com contador
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);
    vHora   VARCHAR2(2);
    vMin    VARCHAR2(2);
    vFeriado      VARCHAR2(1);

    -- Criado por Giuliano em 22/12/2025
    -- Valida se a ultima execucao de integracao de documentos do monitor foi à mais de 30 minutos
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN  
    
    SELECT TO_CHAR(SYSDATE, 'HH24') INTO vHora FROM DUAL;
    SELECT TO_CHAR(SYSDATE, 'MI') INTO vMin FROM DUAL;
    
    IF 1=1 AND vHora BETWEEN 8 AND 20 /*IN (8,10,12,14,16,18,20)*/ AND vMin IN ('00','20','40') THEN-- Se for entre 7hrs ate 20h
      
    INSERT INTO NAGT_CONTROLECARGAPDV
    
     SELECT DISTINCT A.*   
      FROM MONITORPDV.TB_CONTROLECARGAPDV A
     WHERE A.TIPOCARGA = 'P'
       AND A.STATUS IN (3,4)
       AND (A.TABELA IN ('TB_PRODPRECO','TB_FAMILIA','TB_FAMDIVISAO','TB_TRIBUTACAOUF', 'TB_CODGERALOPER',' TB_CODGERALOPERCFOP') 
        OR A.TABELA LIKE '%CCT%' AND TRUNC(SYSDATE) >= DATE '2026-06-01')
       AND TRUNC(A.DTAHOREMISSAO) = TRUNC(SYSDATE)
       AND TO_CHAR(SYSDATE, 'DDMM') NOT IN ('2512', '0101') -- Tira Natal e Ano Novo, as lojas nao abrem
       
     ORDER BY A.TABELA, A.NROEMPRESA;
    
    FOR msg IN (

    SELECT CASE WHEN ROW_NUMBER() OVER (ORDER BY 1) > 1 AND ROW_NUMBER() OVER (PARTITION BY A.TABELA ORDER BY A.TABELA, A.NROEMPRESA) = 1 THEN '%0A%0A'||'*Tabela:*%20'||A.TABELA||'%0A'
           ELSE CASE WHEN ROW_NUMBER() OVER (PARTITION BY A.TABELA ORDER BY A.TABELA, A.NROEMPRESA) = 1 THEN '*Tabela:*%20'||A.TABELA||'%0A' ELSE '%20' END END TB,
         CASE WHEN ROW_NUMBER() OVER (PARTITION BY A.TABELA ORDER BY A.TABELA, A.NROEMPRESA) = 1 
           THEN '*Status:*%20'||A.STATUS||' - '||DECODE(A.STATUS,3, 'Falha no envio do pacote', 4, 'Falha ao tentar carregar o pacote', 'Falha')||'%0A' ELSE '%20' END STATUS,
         CASE WHEN ROW_NUMBER() OVER (PARTITION BY A.TABELA ORDER BY A.TABELA, A.NROEMPRESA) = 1 THEN '%20%20' END||'%0A%20'||
          CASE
              WHEN MAX(B.QTD_DIA) = 1 THEN
                  '%E2%96%B1%E2%96%B1%E2%96%B1%E2%96%B1' -- ▱▱▱▱

              WHEN MAX(B.QTD_DIA) BETWEEN 2 AND 3 THEN
                  '%E2%96%B0%E2%96%B1%E2%96%B1%E2%96%B1' -- ▰▱▱▱

              WHEN MAX(B.QTD_DIA) BETWEEN 4 AND 6 THEN
                  '%E2%96%B0%E2%96%B0%E2%96%B1%E2%96%B1' -- ▰▰▱▱

              WHEN MAX(B.QTD_DIA) BETWEEN 7 AND 10 THEN
                  '%E2%96%B0%E2%96%B0%E2%96%B0%E2%96%B1' -- ▰▰▰▱

              ELSE
                  '%E2%96%B0%E2%96%B0%E2%96%B0%E2%96%B0' -- ▰▰▰▰
          END
          ||
            '%20*Loja:*%20'||LPAD(A.NROEMPRESA,2,0)||
           '%20*| Checkouts:*%20'||
            LISTAGG(DISTINCT TO_CHAR(A.NROCHECKOUT), ', ')
            WITHIN GROUP (ORDER BY A.NROCHECKOUT)||'.' INFO
       
      FROM MONITORPDV.TB_CONTROLECARGAPDV A LEFT JOIN NAGV_CONTROLECARGAPDV_CTD B ON A.NROEMPRESA = B.NROEMPRESA AND A.TABELA = B.TABELA
     WHERE A.TIPOCARGA = 'P'
       AND A.STATUS IN (3,4)
       AND (A.TABELA IN ('TB_PRODPRECO','TB_FAMILIA','TB_FAMDIVISAO','TB_TRIBUTACAOUF', 'TB_CODGERALOPER',' TB_CODGERALOPERCFOP') 
        OR A.TABELA LIKE '%CCT%' AND TRUNC(SYSDATE) >= DATE '2026-06-01')
       AND TRUNC(A.DTAHOREMISSAO) = TRUNC(SYSDATE)
       AND TO_CHAR(SYSDATE, 'DDMM') NOT IN ('2512', '0101') -- Tira Natal e Ano Novo, as lojas nao abrem
       
     GROUP BY A.NROEMPRESA, A.STATUS, A.TABELA
     ORDER BY A.TABELA, A.NROEMPRESA
    
               )
    LOOP
        -- Montar o texto da mensagem
        VTEXT := VTEXT||msg.TB||msg.STATUS||RTRIM(msg.INFO, '%0A');
      
    END LOOP;
    
     IF vText IS NOT NULL THEN
    
    -- Construir a URL
    
     vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE('%F0%9F%9A%A8%20*Report:%20Falhas%20Registradas%20No%20Controle%20De%20Carga%20Do%20PDV:*%0A%0A'||
                                                                                         vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
    
    END IF;
    END IF;
    COMMIT;
  
END;
