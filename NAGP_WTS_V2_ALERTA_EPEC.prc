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
    vdEpecMaisAntiga DATE;
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

    IF vHora IN (8)
       AND vMin BETWEEN 0 AND 2
    THEN

    FOR MSG IN (
        WITH BASE AS (
            SELECT N.DTAEMISSAO,
                   N.NROEMPRESA
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
               AND N.DTAEMISSAO >= SYSDATE - 30
        ),
        RESUMO AS (
            SELECT COUNT(1) QTD_EPEC,
                   MIN(DTAEMISSAO) DTA_EPEC_MAIS_ANTIGA
              FROM BASE
        ),
        DETALHE AS (
            SELECT DTAEMISSAO,
                   NROEMPRESA,
                   COUNT(1) QTD
              FROM BASE
             GROUP BY DTAEMISSAO, NROEMPRESA
        )
        SELECT R.QTD_EPEC,
               R.DTA_EPEC_MAIS_ANTIGA,
               D.DTAEMISSAO,
               D.NROEMPRESA,
               D.QTD
          FROM RESUMO R
          LEFT JOIN DETALHE D ON 1 = 1
         ORDER BY D.DTAEMISSAO,
                  D.NROEMPRESA
    )
    LOOP

        vnQtdEpec := MSG.QTD_EPEC;
        vdEpecMaisAntiga := MSG.DTA_EPEC_MAIS_ANTIGA;

        IF vnQtdEpec > 300
           OR vdEpecMaisAntiga < SYSDATE - 3
        THEN

            IF VTEXT IS NULL THEN

                VTEXT :=
                    '%E2%8F%B3%20*Alerta%20EPEC%20Pendentes:*%0A%0A' ||
                    '%E2%80%A2%20*Pendentes:*%20' ||
                    vnQtdEpec ||
                    '%0A' ||
                    '%E2%80%A2%20*Mais%20antiga:*%20' ||
                    TO_CHAR(vdEpecMaisAntiga, 'DD/MM/YYYY');

                IF vdEpecMaisAntiga < SYSDATE - 3 THEN
                    VTEXT := VTEXT ||
                             '%0A' ||
                             '%E2%80%A2%20*Persistindo%20h%C3%A1:*%20' ||
                             TRUNC(SYSDATE - vdEpecMaisAntiga) ||
                             '%20dias';
                END IF;

                VTEXT := VTEXT ||
                         '%0A%0A*Detalhamento:*';

            END IF;

            IF MSG.DTAEMISSAO IS NOT NULL THEN

                VTEXT := VTEXT ||
                         '%0A%E2%80%A2%20' ||
                         TO_CHAR(MSG.DTAEMISSAO, 'DD/MM/YYYY') ||
                         '%20-%20*Loja%20' ||
                         TO_CHAR(MSG.NROEMPRESA) ||
                         ':*%20' ||
                         MSG.QTD;

            END IF;

        END IF;

    END LOOP;


    IF VTEXT IS NOT NULL THEN

        vUrl := 'http://api.textmebot.com/send.php?recipient=+'||psNroTelefone||'&text='||VTEXT ||'&apikey='||psAPIKey;

        SELECT UTL_HTTP.REQUEST(VURL)
          INTO vnLixo
          FROM DUAL;

        DBMS_SESSION.SLEEP(10);

    END IF;

    END IF;

END;
