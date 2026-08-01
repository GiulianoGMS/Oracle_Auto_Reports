CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_RETURN_CM (psID NUMBER)

 AS
 
    vnLixo    VARCHAR2(5000);
    vText     VARCHAR2(4000);
    vUrl      VARCHAR2(4000);
    vGroupID  VARCHAR2(4000);
    vApiKey   VARCHAR2(300);

    -- Criado por Giuliano em 25/11/2025
    -- Envia mensagem de retorno apos executar o comando enviado pelo usuario
    -- Whats: Envia msg pelo whatsapp pela API TextMeBot
    
    BEGIN
    
    SELECT X.GROUP_ID, X.APIKEY
      INTO vGroupID, vApiKey
      FROM NAGT_API_CALL_NUMBERS X  
     WHERE X.TYPE = 'GERP';
    
    FOR msg IN (

      SELECT DISTINCT A.ID, A.FONE, A.TEXT FULL_COMMAND, B.COMMAND, B.DATE_LOG, SUBSTR(B.ST, 0,300) ST,
            (SELECT MAX(APELIDO) FROM NAGT_API_CALL_NUMBERS X WHERE X.NROTELEFONE = A.FONE) APELIDO
        FROM NAGT_ANSWERS_WTS A INNER JOIN NAGT_ANSWERS_WTS_LOG B ON A.ID = B.ID
                                WHERE a.ID = psID
                                  AND INDRETURN = 'N'
    )
    LOOP
        -- Montar o texto da mensagem
      VTEXT := '%E2%9C%94%EF%B8%8F%20*Comando%20Executado:*%0A%0A' ||
                 '*Por:*%20'        || msg.APELIDO  || '%0A' ||
                 '*Comando executado:*%20'        || msg.COMMAND  || '%0A' ||
                 '*Comando enviado:*%20'|| msg.FULL_COMMAND  || '%0A' ||
                 '*Data:*%20'           || msg.DATE_LOG || '%0A' ||
                 '*Output:*%20'         || msg.ST       || '%0A' ||
                 '*Request Number:*%20' || msg.FONE    ;


        -- Construir a URL
        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||vGroupID||'&text=' || REPLACE(vText, ' ','%20') || '&apikey='||vApiKey; -- Whatsapp 

        -- Enviar a mensagem
        SELECT UTL_HTTP.REQUEST(VURL)  INTO vnLixo  FROM DUAL;
        
        DBMS_SESSION.SLEEP(10); -- Segura 10 segundos pra nao dar pau na API (nao considerar spam)
      
    END LOOP;
  
END;
