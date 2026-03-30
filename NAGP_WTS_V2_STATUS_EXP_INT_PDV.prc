CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_STATUS_EXP_INT_PDV (psNroTelefone NUMBER, psAPIKey VARCHAR2)

 AS
 
    vnLixo    VARCHAR2(5000);
    vText     VARCHAR2(4000);
    vUrl      VARCHAR2(4000);
    vDta      VARCHAR2(2);
    vFeriado  VARCHAR2(1);
    vValorDia VARCHAR2(1000);
    vValorBI  VARCHAR2(1000);

    -- Criado por Giuliano em 22/12/2025
    -- Valida se a ultima execucao de integracao de documentos do monitor foi à mais de 30 minutos
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN  
    
    SELECT TO_CHAR(SYSDATE, 'HH24') INTO vDta FROM DUAL;
    
    IF vDta BETWEEN 7 AND 21 THEN -- Se for entre 7hrs ate 23:59
    
    FOR msg IN (

    SELECT DISTINCT TO_CHAR((DTAHOREXPORTACAO), 'DD/MM/YYYY HH24:MI:SS') ULT_EXPORTACAO,
           ROUND((SYSDATE - (DTAHOREXPORTACAO)) * 24 * 60) COUNT_MIN,
           X.*, TO_CHAR(ULTCARGAPRECO, 'DD/MM/YYYY HH24:MI:SS') ULT_CARGAPRECO
      FROM NAGV_STATUS_EXP_INT_PDV_v2 X 
     WHERE ROUND((SYSDATE - (DTAHOREXPORTACAO)) * 24 * 60) >= 5
       AND TO_CHAR(DTAHOREXPORTACAO, 'DDMM') NOT IN ('2512', '0101') -- Tira Natal e Ano Novo, as lojas nao abrem
       -- AND (X.PENDENTEEXPORTACAO > 0 OR X.PENDENTEIMPORTACAO > 0)
               )
    LOOP
      
      SELECT TO_CHAR(NVL(SUM(A.VALOR),0), 
                     'FM999G999G990D90', 
                     'NLS_NUMERIC_CHARACTERS='',.''')
        INTO vValorDia
        FROM CONSINCO.VENDAS_PDV A
       WHERE A.DTAMOVIMENTO >= 
             CASE 
               WHEN TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) <= 3 -- PEga ate as 3 da manha considera o dia anterior para envio
               THEN TRUNC(SYSDATE) - 1
               ELSE TRUNC(SYSDATE)
             END;
             
      SELECT TO_CHAR(
       (SELECT NVL(SUM(F.VALOR), 0)
          FROM DWNAGT_VENDASDIAANTERIOR@BI F
         WHERE F.DTAMOVIMENTO = CASE 
                                WHEN TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) <= 3 -- PEga ate as 3 da manha considera o dia anterior para envio
                                THEN TRUNC(SYSDATE) - 1
                                ELSE TRUNC(SYSDATE)
                                END) -
       
       (SELECT NVL(SUM(-F.VALOR), 0)
          FROM DWNAGT_VENDASANTERIORDEV@BI F
         WHERE F.DTAMOVIMENTO = CASE 
                                WHEN TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) <= 3 -- PEga ate as 3 da manha considera o dia anterior para envio
                                THEN TRUNC(SYSDATE) - 1
                                ELSE TRUNC(SYSDATE)
                                END), 'FM999G999G990D90', 
                                      'NLS_NUMERIC_CHARACTERS='',.''')
          INTO vValorBI
          FROM DUAL;
       
        -- Montar o texto da mensagem
        VTEXT := '%F0%9F%9A%A8%20*Report:%20Ultima%20Exportacao%20de%20Documentos%20ha%20mais%20de%20'||msg.COUNT_MIN||'%20minutos.*%0A%0A' ||
                 '*Ultima Exportacao:*%20'         || msg.ULT_EXPORTACAO || '%0A' ||
                 '*Qtd Pendente Exportacao:*%20'   || msg.PENDENTEEXPORTACAO || '%0A' ||
                 '*Qtd Pendente Importacao:*%20'   || msg.PENDENTEIMPORTACAO || '%0A' ||
                 '*Sessoes:*%20'                   || msg.SESSOES || '%0A' ||
                 '*Qtd Docto Integrado:*%20'       || msg.DOCTOINTEGRADO || '%0A' ||
                 '*Ultima Carga de Preco:*%20'     || msg.ULT_CARGAPRECO || '%0A%0A' ||
                 '%F0%9F%92%B0%20*Valor Venda Atual PDV:*%20'|| vValorDia || '%0A' ||
                 '%F0%9F%93%8A%20*Valor Venda Atual BI:*%20' || vValorBI;
                

        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||psAPIKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
    
    END IF;
  
END;
