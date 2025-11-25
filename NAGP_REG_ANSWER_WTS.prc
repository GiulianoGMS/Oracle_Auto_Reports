CREATE OR REPLACE PROCEDURE NAGP_REG_ANSWER_WTS (
    psNumeroFone NUMBER,
    psTexto      VARCHAR2
) AS
BEGIN
    INSERT INTO NAGT_ANSWERS_WTS (
        FONE,
        TEXT,
        DATE_LOG,
        INDPROCESSADO,
        INDRETURN
    )
    VALUES (
        psNumeroFone,
        psTexto,
        SYSDATE,
        'N',
        'N'
    );

    COMMIT;
END;
