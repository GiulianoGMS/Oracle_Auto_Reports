CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_STATUS_EXP_INT_PDV (psNroTelefone NUMBER, psAPIKey VARCHAR2)

 AS
 
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);
    --vDta    VARCHAR2(2);

    -- Criado por Giuliano em 22/12/2025
    -- Valida se a ultima execucao de integracao de documentos do monitor foi à mais de 30 minutos
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN  
    
    FOR msg IN (

    SELECT CASE WHEN (SYSDATE - (DTAHOREXPORTACAO)) * 24 * 60 >= 30 THEN 1 ELSE 0 END VALIDADOR,
           TO_CHAR((DTAHOREXPORTACAO), 'DD/MM/YYYY HH24:MI:SS') ULT_EXPORTACAO,
           ROUND((SYSDATE - (DTAHOREXPORTACAO)) * 24 * 60) COUNT_MIN,
           X.*, TO_CHAR(ULTCARGAPRECO, 'DD/MM/YYYY HH24:MI:SS') ULT_CARGAPRECO
      FROM NAGV_STATUS_EXP_INT_PDV X
     WHERE ROUND((SYSDATE - (DTAHOREXPORTACAO)) * 24 * 60) >= 30
   --  AND (TO_CHAR(DTAHOREXPORTACAO, 'MI') BETWEEN 30 AND 40 OR TO_CHAR(DTAHOREXPORTACAO, 'MI') BETWEEN 0 AND 10 AND TO_CHAR(DTAHOREXPORTACAO, 'HH24') >= 1)
    
    )
    LOOP
        -- Montar o texto da mensagem
        VTEXT := '%F0%9F%9A%A8%20*Report:%20Ultima%20Exportacao%20de%20Documentos%20ha%20mais%20de%20'||msg.COUNT_MIN||'%20minutos.*%0A%0A' ||
                 '*Ultima Exportacao:*%20'         || msg.ULT_EXPORTACAO || '%0A' ||
                 '*Qtd Pendente Exportacao:*%20'   || msg.PENDENTEEXPORTACAO || '%0A' ||
                 '*Qtd Pendente Importacao:*%20'   || msg.PENDENTEIMPORTACAO || '%0A' ||
                 '*Sessoes:*%20'                   || msg.SESSOES || '%0A' ||
                 '*Qtd Docto Integrado:*%20'       || msg.DOCTOINTEGRADO || '%0A' ||
                 '*Ultima Carga de Preco:*%20'     || msg.ULT_CARGAPRECO;
                

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
