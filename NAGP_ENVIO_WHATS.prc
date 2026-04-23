CREATE OR REPLACE PROCEDURE NAGP_ENVIO_WHATS AS

BEGIN
  FOR bs_all IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE = 'ALL')
    LOOP
      NAGP_WTS_V2_INVALIDOBJECTS          (bs_all.NROTELEFONE, bs_all.APIKEY);
      NAGP_WTS_V2_JOB_RUNFAILURES         (bs_all.NROTELEFONE, bs_all.APIKEY);
      NAGP_WTS_V2_LOCKS                   (bs_all.NROTELEFONE, bs_all.APIKEY);
      NAGP_WTS_V2_TB_LOGDBERRO            (bs_all.NROTELEFONE, bs_all.APIKEY);
      NAGP_WTS_V2_TB_LOGFALHACARGAMONITOR (bs_all.NROTELEFONE, bs_all.APIKEY);
      NAGP_WTS_V2_TB_ULTCARGAMONITOR      (bs_all.Nrotelefone, bs_all.APIKEY);
      NAGP_WTS_V2_STATUS_EXP_INT_PDV      (bs_all.Nrotelefone, bs_all.APIKEY);
      NAGP_WTS_V2_ALERTAS_BOT_DOWN        (bs_all.Nrotelefone, bs_all.APIKEY);
    END LOOP;

  FOR bs_pdv IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE = 'PDV')
    LOOP
      NAGP_WTS_V2_TB_LOGDBERRO            (bs_pdv.NROTELEFONE, bs_pdv.APIKEY);
      NAGP_WTS_V2_TB_LOGFALHACARGAMONITOR (bs_pdv.NROTELEFONE, bs_pdv.APIKEY);
      NAGP_WTS_V2_TB_ULTCARGAMONITOR      (bs_pdv.NROTELEFONE, bs_pdv.APIKEY);
     -- NAGP_WTS_V2_STATUS_EXP_INT_PDV      (bs_pdv.Nrotelefone, bs_pdv.APIKEY); Agora esta indo para o grupo GSD
    END LOOP;
    
  FOR bs_esp IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE IN ('ESP', 'SD'))
    LOOP
     -- NAGP_WTS_V2_STATUS_EXP_INT_PDV      (bs_esp.Nrotelefone, bs_esp.APIKEY);
      NAGP_WTS_V2_JOB_RUNFAILURES_ESP     (bs_esp.Nrotelefone, bs_esp.APIKEY);
    END LOOP;
    
  FOR bs_BI IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE = 'BI')
     LOOP
       NAGP_WTS_V2_ALERTAS_BI             (bs_BI.Nrotelefone, bs_BI.APIKEY);
     END LOOP;
    
  FOR bs_groups_SD IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE = 'GSD')
     LOOP
       NAGP_WTS_V2_CONTROLECARGA_PDV      (bs_groups_SD.Group_Id, bs_groups_SD.Apikey);
       NAGP_WTS_V2_STATUS_EXP_INT_PDV     (bs_groups_SD.Group_Id, bs_groups_SD.Apikey);
       NAGP_WTS_V2_ALERTAS_BI             (bs_groups_SD.Group_Id, bs_groups_SD.Apikey);
     END LOOP;
     
   FOR bs_bot_down IN (SELECT * FROM NAGT_API_CALL_NUMBERS X WHERE STATUS = 'A' AND TYPE = 'CFG')
     LOOP
       NAGP_WTS_V2_ALERTAS_BOT_DOWN       (bs_bot_down.NROTELEFONE, bs_bot_down.Apikey);       
     END LOOP;   
END;
