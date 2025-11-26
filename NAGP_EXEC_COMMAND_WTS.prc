CREATE OR REPLACE PROCEDURE NAGP_EXEC_COMMAND_WTS AS

    vErro     VARCHAR2(4000);
    cm_rid    VARCHAR2(4000);
    cm_vSQL   VARCHAR2(4000);
    cm_ID     NUMBER(38);
    v_comando VARCHAR2(4000);
    
BEGIN
  
    FOR cm IN (SELECT FONE, REGEXP_SUBSTR(UPPER(TEXT),'(NAGP_[A-Z0-9_]+ *\([^)]*\))|(NAGJ_[A-Z0-9_]+)', 1, 1) vSQL, X.ROWID rid, ID
                 FROM NAGT_ANSWERS_WTS X INNER JOIN NAGT_API_CALL_NUMBERS C ON C.NROTELEFONE = X.FONE
                WHERE TEXT IS NOT NULL
                ---------------------------------------------------------------------
                -- Seguranca basica - fiz pra executar somente o que mandar com NAGP_xxxxxx e nao dar merda
                ---------------------------------------------------------------------
                  AND UPPER(TEXT) LIKE '%NAG%'      
                  AND X.INDPROCESSADO = 'N'
                  -- Valida se permite que o nro realize acoes
                  AND C.PERM_CMD = 'S'
                  )
    LOOP
    ---------------------------------------------------------------------
    -- Roda o comando que encontrei anteriormente
    ---------------------------------------------------------------------
    -- variaveis para capturar possiveis erros
    cm_rid := cm.rid;
    cm_vSQL := cm.vSQL;
    cm_ID := cm.ID;
    --
    -- Trata o tipo de comando ( roda proc ou job )
    IF REGEXP_LIKE(cm.vSQL, '^NAGJ_') THEN
       v_comando := 'BEGIN DBMS_SCHEDULER.RUN_JOB(''' || cm.vSQL || '''); END;';
    ELSE
       v_comando := 'BEGIN ' || cm.vSQL || '; END;';
    END IF;
    --
    
    EXECUTE IMMEDIATE v_comando;
    INSERT INTO NAGT_ANSWERS_WTS_LOG VALUES (v_comando, SYSDATE, 'Executado', cm.ID);
    
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDPROCESSADO = 'S'
     WHERE X.ROWID = cm.rid;
          
    NAGP_WTS_V2_RETURN_CM(cm.ID);  
     
    END LOOP;
    
    EXCEPTION

      WHEN OTHERS THEN
        vErro := SQLERRM;
    INSERT INTO NAGT_ANSWERS_WTS_LOG VALUES (v_comando, SYSDATE, SUBSTR(vErro,0,2900), cm_ID);
    
    UPDATE NAGT_ANSWERS_WTS X
       SET X.INDPROCESSADO = 'E'
     WHERE X.ROWID = cm_rid;
    
    NAGP_WTS_V2_RETURN_CM(cm_ID);
    
END;
