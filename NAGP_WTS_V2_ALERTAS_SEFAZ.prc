CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTAS_SEFAZ (
    psNroTelefone VARCHAR2,
    psAPIKey      VARCHAR2
)
AS
    vnLixo  VARCHAR2(5000);
    vText   VARCHAR2(4000);
    vUrl    VARCHAR2(4000);
    vHora   VARCHAR2(2);
    vMin    VARCHAR2(2);

BEGIN
  
    SELECT TO_CHAR(SYSDATE, 'HH24') INTO vHora FROM DUAL;
    SELECT TO_CHAR(SYSDATE, 'MI') INTO vMin FROM DUAL;
    
    IF 1=1 AND vHora BETWEEN 7 AND 20 /*IN (8,10,12,14,16,18,20)*/ AND vMin IN ('00', '02','30', '32') THEN-- Se for entre 7hrs ate 20h
      
  FOR msg IN (
    SELECT LISTAGG(DISTINCT UF, ', ') WITHIN GROUP (ORDER BY UF) UFS,
           LISTAGG(DISTINCT TIPO, '/') WITHIN GROUP (ORDER BY TIPO) TIPOS
    FROM (
    SELECT DISTINCT X.SIGLA UF, X.TIPO
     FROM ERP_INTEGRATION.NAGT_NFE_STATUS_UFS X
    WHERE X.ATUALIZADO_EM >= SYSDATE - (25/1440)
      AND ( X.TEMPO_RESPOSTA > 3
       OR X.SVC = 'Sim'
    )
    )
    )
  LOOP

  -- Somente envia se existir alguma indisponibilidade
  IF msg.UFS IS NOT NULL THEN

     -- Montar o texto da mensagem
     vText :=
          '%F0%9F%A7%BE%20*'||
          REPLACE(msg.TIPOS, ' ', '%20') ||
          '%20-%20Alerta%20SEFAZ%20Intermitente!*%0A%0A' ||
          '*UFs:*%20' || REPLACE(msg.UFS, ' ', '%20') || '%0A' ||
          '*Tipos:*%20' || REPLACE(msg.TIPOS, ' ', '%20')||'%0A%0A' ||
           CASE
               WHEN INSTR('/' || msg.TIPOS || '/', '/NFE/') > 0
               THEN '%F0%9F%94%B8%20Notas%20Fiscais%20(NFE)%20devem%20apresentar%20lentid%C3%A3o%20nas%20emiss%C3%B5es!%0A'
               ELSE ''
           END ||

           CASE
               WHEN INSTR('/' || msg.TIPOS || '/', '/NFCE/') > 0
               THEN '%F0%9F%94%B8%20Notas%20Fiscais%20(NFCE)%20devem%20apresentar%20lentid%C3%A3o%20nas%20emiss%C3%B5es!'
               ELSE ''
           END;

     -- Construir a URL
     vUrl :=
          'http://api.textmebot.com/send.php?recipient=+' ||
          psNroTelefone ||
          '&text=' || vText ||
          '&apikey=' || psAPIKey;

     -- Enviar a mensagem
     SELECT UTL_HTTP.REQUEST(vUrl)
       INTO vnLixo
       FROM DUAL;

     DBMS_SESSION.SLEEP(10);

  END IF;

END LOOP;
  END IF;

END;
