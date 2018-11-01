select msisdn,journal_type_id,cash_account_id,charged_amount,credit_amount
from( 
 SELECT /*+ USE_HASH(sdp,air) PARALLEL (sdp,6) PARALLEL(air,6) */
sdp.account_event_id,
ms.msisdn,
sdp.cash_account_id,
NVL (air.air_journal_type_id, sdp.journal_type_id) journal_type_id,
sdp.service_class_id,
sdp.account_id,
NVL (sdp.currency_type, 0),
NVL (air.amount, sdp.amount) amount,
CASE
   WHEN jt.normalisation_factor = -1
      THEN NVL (air.amount, sdp.amount)
ELSE 0
END charged_amount,
CASE
   WHEN jt.normalisation_factor = 1
      THEN NVL (air.amount, sdp.amount)
   ELSE 0
END credit_amount,
sdp.campaign_id,
sdp.subscriber_fee,
sdp.debt,
sdp.account_credit_cleared_reason,
sdp.account_id,
sdp.account_start_date start_date,
nvl(sdp.DED_ACC_UNIT_TYPE,1) unit_type    
 FROM sdp_journal_entries sdp,
      air_journal_entries air,
      journal_types jt,
      msisdn_allocations ms,
      msisdn_rfill_1033 ccl
WHERE    sdp.time_hour_id >= 20140818160
  AND sdp.time_hour_id < 20140820160
  AND air.time_hour_id(+) >= 20140818160
  AND air.time_hour_id(+) < 20140820160
and sdp.account_event_id = air.account_event_id(+)
  AND sdp.cash_account_id = air.cash_account_id(+)
  AND sdp.journal_type_id = air.sdp_journal_type_id(+)
  and sdp.ACCOUNT_ID = ms.ACCOUNT_ID
  and ms.msisdn=ccl.msisdn
  AND nvl(sdp.DED_ACC_CATG,0) <> 1
  AND nvl(air.DED_ACC_CATG,0) <> 1
  AND sdp.amount IS NOT NULL
  and sdp.cash_account_id=0
  AND jt.journal_type_id = NVL (air.air_journal_type_id, sdp.journal_type_id)
) where journal_type_id = 5 order by 1;