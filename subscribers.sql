select /*+ parallel(a,8) */ a.account_status,count(1) from ( 
select /*+ parallel(acl,8) */ 
           acl.account_id,
           acl.service_class_id,
           acl.account_status,
           acl.account_group_id,
           acl.VALID_TO_UTC,
           acl.DWS_CREATION_DATE,
           acl.ACCOUNT_STATUS_CODE 
         from accounts_change_log acl
           where sysdate between acl.valid_from_utc and acl.valid_to_utc
           and acl.account_status ='A' 
	   and acl.service_class_id in ( 21,39,57)
           )a
          group by account_status


