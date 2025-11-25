CREATE OR REPLACE PROCEDURE NAGP_EXEC_COMMAND_WTS AS

    vErro   VARCHAR2(4000);
    cm_rid VARCHAR2(4000);
    cm_vSQL VARCHAR2(4000);
    cm_ID NUMBER(38);
    
BEGIN
  
    FOR cm IN (SELECT FONE, REGEXP_SUBSTR(UPPER(TEXT), '([A-Z0-9_]+ *\([^)]*\))', 1, 1) vSQL, ROWID rid, ID
                 FROM NAGT_ANSWERS_WTS X
                WHERE TEXT IS NOT NULL
                ---------------------------------------------------------------------
                -- Seguranca basica - fiz pra executar somente o que mandar com NAGP_xxxxxx e nao dar merda
                ---------------------------------------------------------------------
                  AND UPPER(TEXT) LIKE '%NAGP%'      
                  AND X.INDPROCESSADO = 'N')
    LOOP
    ---------------------------------------------------------------------
    -- Roda o comando que encontrei anteriormente
    ---------------------------------------------------------------------
    -- variaveis para capturar possiveis erros
    cm_rid := cm.rid;
    cm_vSQL := cm.vSQL;
    cm_ID := cm.ID;
    --
    EXECUTE IMMEDIATE 'BEGIN ' || cm.vSQL || '; END;';
    INSERT INTO NAGT_ANSWERS_WTS_LOG VALUES ('BEGIN ' || cm.vSQL || '; END;', SYSDATE, 'OK', cm.ID);
    
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDPROCESSADO = 'S'
     WHERE X.ROWID = cm.rid;
          
    NAGP_WTS_V2_RETURN_CM(cm.ID);
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDRETURN = 'S'
     WHERE X.ROWID = cm.rid;
     
    COMMIT;   
     
    END LOOP;
    
    EXCEPTION

      WHEN OTHERS THEN
        vErro := SQLERRM;
    INSERT INTO NAGT_ANSWERS_WTS_LOG VALUES ('BEGIN ' || cm_vSQL ||  '; END;', SYSDATE, SUBSTR(vErro,0,2900), cm_ID);
    
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDPROCESSADO = 'E'
     WHERE X.ROWID = cm_rid;
    
    NAGP_WTS_V2_RETURN_CM(cm_ID);
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDRETURN = 'S'
     WHERE X.ROWID = cm_rid;
    COMMIT;
    
END;
