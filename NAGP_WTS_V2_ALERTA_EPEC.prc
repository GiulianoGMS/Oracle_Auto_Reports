CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTA_EPEC (
    psNroTelefone VARCHAR2,
    psAPIKey      VARCHAR2
)

AS
    vnLixo          VARCHAR2(5000);
    vText           VARCHAR2(4000);
    vUrl            VARCHAR2(4000);
    vnQtdEpec       NUMBER;
    vdEpecAntiga    DATE;
    vHora           NUMBER;
    vMin            NUMBER;
BEGIN

    /*
      Criado por Giuliano em 21/09/2026
      Alerta EPEC:
        - Mais de 300 EPECs pendentes
        - EPEC pendente há mais de 3 dias
      Considera EPECs dos últimos 20 dias.
    */

    SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
           TO_NUMBER(TO_CHAR(SYSDATE, 'MI'))
      INTO vHora,
           vMin
      FROM DUAL;

    IF vHora IN (8,15,16)
       AND vMin BETWEEN 0 AND 2
    THEN

        SELECT COUNT(1),
               MIN(N.DTAEMISSAO)
          INTO vnQtdEpec,
               vdEpecAntiga
          FROM MLFV_BASENFE N
         WHERE N.STATUSNFE NOT IN (4,7,8)
           AND EXISTS (
                SELECT 1
                  FROM MFL_NFELOG A
                 WHERE A.SEQNOTAFISCAL = N.SEQNOTAFISCAL
                   AND UPPER(A.DESCRICAO) LIKE '%EPEC%'
           )
           AND NOT EXISTS (
                SELECT 1
                  FROM MFL_NFELOG B
                 WHERE B.SEQNOTAFISCAL = N.SEQNOTAFISCAL
                   AND UPPER(B.DESCRICAO) LIKE '%AUTORIZ%'
           )
           AND N.DTAEMISSAO >= SYSDATE - 20;

        /*
          Envia se:
            - houver mais de 300 EPECs
            OU
            - o EPEC mais antigo tiver mais de 3 dias
        */
        IF vnQtdEpec > 300
           OR vdEpecAntiga < SYSDATE - 3
        THEN

          VTEXT := '%E2%9A%A0%EF%B8%8F%20*Alerta%20EPECs%20Pendentes:*%0A%0A' ||

         '%E2%80%A2%20*Pendentes:*%20' ||
         TO_CHAR(vnQtdEpec) ||
         '%0A' ||

         '%E2%80%A2%20*Mais%20antiga:*%20' ||
         TO_CHAR(vdEpecAntiga, 'DD/MM/YYYY') ||
         '%0A' ||

         '%E2%80%A2%20*Persistindo%20h%C3%A1:*%20' ||
         TO_CHAR(TRUNC(SYSDATE - vdEpecAntiga)) ||
         '%20dias';

            vUrl := 'http://api.textmebot.com/send.php?recipient=+' ||
                    psNroTelefone ||
                    '&text=' ||
                    VTEXT ||
                    '&apikey=' ||
                    psAPIKey;

            SELECT UTL_HTTP.REQUEST(VURL)
              INTO vnLixo
              FROM DUAL;

            DBMS_SESSION.SLEEP(10);

        END IF;

    END IF;

END;
