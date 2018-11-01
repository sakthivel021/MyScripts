 Database Information:
******************************************************************************************************************************************************************
Track OS Reboot Time:
net statistics server
systeminfo | find "Up Time"  -- to find system last uptime
systeminfo | find "System Boot Time"  -- to find system boot time
net statistics workstation | find "Statistics" Workstation Statistics for \\A5541TAG-WKS   --perticular workstation statistics
Database and Instance Last start time:
SELECT to_char(startup_time,'DD-MON-YYYY HH24:MI:SS') "DB Startup Time"
FROM   sys.v_$instance;
SELECT SYSDATE-logon_time "Days", (SYSDATE-logon_time)*24 "Hours"
from  sys.v_$session where  sid=1;
Track Database Version:
SELECT * from v$version;
Track Database Name and ID information:
SELECT DBID, NAME FROM V$DATABASE;‎
Track Database Global Name information:
SELECT * FROM GLOBAL_NAME;‎
Track Database Instance name:
SELECT INSTANCE_NAME FROM V$INSTANCE;‎
Track Database Host Details:
SELECT UTL_INADDR.GET_HOST_ADDRESS, UTL_INADDR.GET_HOST_NAME FROM DUAL;
Track Database Present Status:
SELECT created, RESETLOGS_TIME, Log_mode FROM V$DATABASE;
DB Character Set Information:
Select * from nls_database_parameters;
Track Database default information:
Select username, profile, default_tablespace, temporary_tablespace from dba_users;
Track Total Size of Database:
select a.data_size+b.temp_size+c.redo_size "Total_Size (GB)"
from ( select sum(bytes/1024/1024/1024) data_size
         from dba_data_files ) a, ( select nvl(sum(bytes/1024/1024/1024),0) temp_size
         from dba_temp_files ) b, ( select sum(bytes/1024/1024/1024) redo_size
         from sys.v_$log ) c;
Total Size of Database with free space:
Select round(sum(used.bytes) / 1024 / 1024/1024 ) || ' GB' "Database Size",round(free.p / 1024 / 1024/1024) || ' GB' "Free space"
from (select bytes from v$datafile
      union all
      select bytes from v$tempfile
      union all
      select bytes from v$log) used, (select sum(bytes) as p from dba_free_space) free group by free.p;
Track Database Structure:
select name from   sys.v_$controlfile
/
select group#,member from   sys.v_$logfile
/
Select F.file_id Id, F.file_name name, F.bytes/(1024*1024) Mbyte,
       decode(F.status,'AVAILABLE','OK',F.status) status, F.tablespace_name Tspace
from   sys.dba_data_files F
order by tablespace_name;
Tablespace/Datafile/Temp/UNDO Information:
******************************************************************************************************************************************************************
Track Tablespace Used/Free Space:
SELECT /* + RULE */  df.tablespace_name "Tablespace",  df.bytes / (1024 * 1024) "Size (MB)",
       SUM(fs.bytes) / (1024 * 1024) "Free (MB)", Nvl(Round(SUM(fs.bytes) * 100 / df.bytes),1) "% Free", Round((df.bytes - SUM(fs.bytes)) * 100 / df.bytes) "% Used"
  FROM dba_free_space fs, (SELECT tablespace_name,SUM(bytes) bytes
          FROM dba_data_files
         GROUP BY tablespace_name) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,df.bytes
UNION ALL
SELECT /* + RULE */ df.tablespace_name tspace,
       fs.bytes / (1024 * 1024), SUM(df.bytes_free) / (1024 * 1024), Nvl(Round((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1), Round((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes)
  FROM dba_temp_files fs, (SELECT tablespace_name,bytes_free,bytes_used
          FROM v$temp_space_header
         GROUP BY tablespace_name,bytes_free,bytes_used) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
 ORDER BY 4 DESC;
Track all Tablespaces with free space < 10%
Select a.tablespace_name,sum(a.tots/1048576) Tot_Size, sum(a.sumb/1024) Tot_Free, sum(a.sumb)*100/sum(a.tots) Pct_Free, ceil((((sum(a.tots) * 15) - (sum(a.sumb)*100))/85 )/1048576) Min_Add
from (select tablespace_name,0 tots,sum(bytes) sumb
from dba_free_space a
group by tablespace_name
union
Select tablespace_name,sum(bytes) tots,0 from dba_data_files
group by tablespace_name) a group by a.tablespace_name
having sum(a.sumb)*100/sum(a.tots) < 10
order by pct_free;
Track Tablespace Fragmentation Details:
Select a.tablespace_name,sum(a.tots/1048576) Tot_Size,
     sum(a.sumb/1048576) Tot_Free, sum(a.sumb)*100/sum(a.tots) Pct_Free,
     sum(a.largest/1024) Max_Free,sum(a.chunks) Chunks_Free
     from  ( select tablespace_name,0 tots,sum(bytes) sumb,
     max(bytes) largest,count(*) chunks
     from dba_free_space a
     group by tablespace_name
     union
     select tablespace_name,sum(bytes) tots,0,0,0 from dba_data_files
     group by tablespace_name) a  group by a.tablespace_name
order by pct_free;
Track Non-Sys owned tables in SYSTEM Tablespace:
SELECT owner, table_name, tablespace_name FROM dba_tables WHERE tablespace_name = 'SYSTEM' AND owner NOT IN ('SYSTEM', 'SYS', 'OUTLN');
Track Default and Temporary Tablespace:
SELECT * FROM DATABASE_PROPERTIES where PROPERTY_NAME like '%DEFAULT%';
select username,temporary_tablespace,default_tablespace from dba_users where username='HRMS';  --for Particular User
Select default_tablespace,temporary_tablespace,username from dba_users;   --for All Users
Track DB datafile used and free space:
SELECT SUBSTR (df.NAME, 1, 40) file_name,dfs.tablespace_name, df.bytes / 1024 / 1024 allocated_mb, ((df.bytes / 1024 / 1024) -  NVL (SUM (dfs.bytes) / 1024 / 1024, 0)) used_mb,
NVL (SUM (dfs.bytes) / 1024 / 1024, 0) free_space_mb
FROM v$datafile df, dba_free_space dfs
WHERE df.file# = dfs.file_id(+)
GROUP BY dfs.file_id, df.NAME, df.file#, df.bytes,dfs.tablespace_name
ORDER BY file_name;
Track Datafile with Archive Details:
SELECT NAME, a.status, DECODE (b.status, 'Active', 'Backup', 'Normal') arc, enabled, bytes, change#, TIME ARCHIVE FROM sys.v_$datafile a, sys.v_$backup b WHERE a.file# = b.file#;
Track Datafiles with highest I/O activity:
Select * from (select name,phyrds, phywrts,readtim,writetim
from v$filestat a, v$datafile b
where a.file#=b.file#
order by readtim desc) where rownum <6;
Track Datafile as per the Physical Read/Write Percentage:
WITH totreadwrite AS (SELECT SUM (phyrds) phys_reads, SUM (phywrts) phys_wrts FROM v$filestat)
SELECT   NAME, phyrds, phyrds * 100 / trw.phys_reads read_pct, phywrts, phywrts * 100 / trw.phys_wrts write_pct FROM totreadwrite trw, v$datafile df, v$filestat fs WHERE df.file# = fs.file# ORDER BY phyrds DESC;
Checking  Autoextend ON/OFF for Datafile:
select substr(file_name,1,50), AUTOEXTENSIBLE from dba_data_files
‎select tablespace_name,AUTOEXTENSIBLE from dba_data_files;
More on Tablespace/Datafile size click on the link: DB Tablespace/Datafile Details
Temp Segment:
Track Temp Segment Free space:
SELECT tablespace_name, SUM(bytes_used/1024/1024) USED, SUM(bytes_free/1024/1024) FREE
FROM   V$temp_space_header
GROUP  BY tablespace_name;
SELECT   A.tablespace_name tablespace, D.mb_total,
         SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
         D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM  v$sort_segment A, (SELECT   B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
         FROM     v$tablespace B, v$tempfile C
         WHERE    B.ts#= C.ts#
         GROUP BY B.name, C.block_size ) D
WHERE    A.tablespace_name = D.name
GROUP by A.tablespace_name, D.mb_total;
Track Who is Currently using the Temp:
SELECT b.tablespace, ROUND(((b.blocks*p.value)/1024/1024),2)||'M' "SIZE",
a.sid||','||a.serial# SID_SERIAL, a.username, a.program
FROM sys.v_$session a, sys.v_$sort_usage b, sys.v_$parameter p
WHERE p.name  = 'db_block_size' AND a.saddr = b.session_addr
ORDER BY b.tablespace, b.blocks;
Undo & Rollback Segment:
Monitor UNDO information:
select to_char(begin_time,'hh24:mi:ss'),to_char(end_time,'hh24:mi:ss'), maxquerylen,ssolderrcnt,nospaceerrcnt,undoblks,txncount from v$undostat
order by undoblks;
Track Active Rollback Segment:
SELECT   r.NAME, l.sid, p.spid, NVL (p.username, 'no transaction') "Transaction",
p.terminal "Terminal" FROM v$lock l, v$process p, v$rollname r
WHERE l.sid = p.pid(+) AND TRUNC (l.id1(+) / 65536) = r.usn AND l.TYPE(+) = 'TX' AND l.lmode(+) = 6 ORDER BY R.NAME;
Track Currently Who is using UNDO and TEMP:
SELECT TO_CHAR(s.sid)||','||TO_CHAR(s.serial#) sid_serial,
 NVL(s.username, 'None') orauser, s.program, r.name undoseg,
t.used_ublk * TO_NUMBER(x.value)/1024||'K' "Undo"
FROM sys.v_$rollname    r, sys.v_$session s, sys.v_$transaction t, sys.v_$parameter   x
 WHERE s.taddr = t.addr AND r.usn   = t.xidusn(+) AND x.name  = 'db_block_size';
Redolog Information:
******************************************************************************************************************************************************************
Track Redo Generation by Calender Year:
select to_char(first_time,'mm.DD.rrrr') day,
to_char(sum(decode(to_char(first_time,'HH24'),'00',1,0)),'99') "00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',1,0)),'99') "01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',1,0)),'99') "02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',1,0)),'99') "03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',1,0)),'99') "04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',1,0)),'99') "05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',1,0)),'99') "06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',1,0)),'99') "07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',1,0)),'99') "08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',1,0)),'99') "09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',1,0)),'99') "10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',1,0)),'99') "11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',1,0)),'99') "12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',1,0)),'99') "13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',1,0)),'99') "14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',1,0)),'99') "15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',1,0)),'99') "16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',1,0)),'99') "17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',1,0)),'99') "18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',1,0)),'99') "19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',1,0)),'99') "20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',1,0)),'99') "21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',1,0)),'99') "22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',1,0)),'99') "23"
from v$log_history group by to_char(first_time,'mm.DD.rrrr')
order by day;
Track Redo generation by day:
select trunc(completion_time) logdate, count(*) logswitch, round((sum(blocks*block_size)/1024/1024)) "REDO PER DAY (MB)" from v$archived_log
group by trunc(completion_time) order by 1;
Track How much full is the current redo log file:
SELECT le.leseq   "Current log sequence No", 100*cp.cpodr_bno/le.lesiz "Percent Full",
 cp.cpodr_bno   "Current Block No", le.lesiz   "Size of Log in Blocks"
FROM x$kcccp cp, x$kccle le
WHERE le.leseq =CP.cpodr_seq
AND bitand(le.leflg,24) = 8;
Monitor Running Jobs:
******************************************************************************************************************************************************************
Long Jobs:
Select username,to_char(start_time, 'hh24:mi:ss dd/mm/yy') started, time_remaining remaining, message
from v$session_longops
where time_remaining = 0 order by time_remaining desc;
Monitor Long running Job:
SELECT SID, SERIAL#, opname, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) COMPLETE
FROM   V$SESSION_LONGOPS
WHERE TOTALWORK != 0 AND SOFAR != TOTALWORK order by 1;
Track Long Query Progress in database:
SELECT a.sid, a.serial#, b.username , opname OPERATION, target OBJECT,
TRUNC(elapsed_seconds, 5) "ET (s)", TO_CHAR(start_time, 'HH24:MI:SS') start_time,
ROUND((sofar/totalwork)*100, 2) "COMPLETE (%)"
FROM v$session_longops a, v$session b
WHERE a.sid = b.sid AND b.username not IN ('SYS', 'SYSTEM') AND totalwork > 0
ORDER BY elapsed_seconds;
Track Running RMAN backup status:
SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%'  AND OPNAME NOT LIKE '%aggregate%'
  AND TOTALWORK != 0 AND SOFAR  != TOTALWORK;
Monitor Import Rate:
Oracle Import Utility usually takes hours for very large tables and we need to track the execution of Oracle Import Process. Below option can help you monitor the rate at which rows are being imported from a running import job.
select   substr(sql_text,instr(sql_text,'into "'),30) table_name,
   rows_processed, round((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60,1) minutes,
   trunc(rows_processed/((sysdate-to_date(first_load_time,'yyyy-mm-dd hh24:mi:ss'))*24*60)) rows_per_minute
from   sys.v_$sqlarea
where   sql_text like 'insert %into "%' and command_type = 2 and open_versions > 0;
Database SGA Report:
******************************************************************************************************************************************************************
Monitor SGA Information:
SELECT SUM(VALUE)/1024/1024 "Size in MB" from SYS.v_$sga;
select     NAME,   BYTES from     v$sgastat  order by NAME;
Monitor Shared Pool Information:
select to_number(value) shared_pool_size, sum_obj_size, sum_sql_size, sum_user_size,
(sum_obj_size + sum_sql_size+sum_user_size)* 1.3 min_shared_pool
  from (select sum(sharable_mem) sum_obj_size
  from v$db_object_cache where type <> 'CURSOR'),
 (select sum(sharable_mem) sum_sql_size from v$sqlarea),
 (select sum(250 * users_opening) sum_user_size from v$sqlarea), v$parameter
 where name = 'shared_pool_size';
Monitor PGA Information:
Select st.sid "SID", sn.name "TYPE", ceil(st.value / 1024 / 1024/1024) "GB"
from v$sesstat st, v$statname sn where st.statistic# = sn.statistic#
and sid in (select sid from v$session where username like UPPER('hrms'))
and upper(sn.name) like '%PGA%' order by st.sid, st.value desc;
Monitor CPU Usage Information:
select  ss.username, se.SID, VALUE/100 cpu_usage_seconds
from v$session ss,  v$sesstat se,  v$statname sn where se.STATISTIC# = sn.STATISTIC#
and NAME like '%CPU used by this session%' and se.SID = ss.SID
and  ss.status='ACTIVE' and  ss.username is not null order by VALUE desc;
Disk I/O Report:
WITH totreadwrite AS (SELECT SUM (phyrds) phys_reads, SUM (phywrts) phys_wrts FROM v$filestat)
SELECT   NAME, phyrds, phyrds * 100 / trw.phys_reads read_pct,
    phywrts, phywrts * 100 / trw.phys_wrts write_pct
 FROM totreadwrite trw, v$datafile df, v$filestat fs
   WHERE df.file# = fs.file# ORDER BY phyrds DESC;
IO Usage for a Query:
select b.sql_text "Statement ", a.Disk_reads "Disk Reads", a.executions "Executions",
a.disk_reads/decode(a.executions,0,1,a.executions) "Ratio",c.username
from  v$sqlarea a, v$sqltext_with_newlines b,dba_users c
where  a.parsing_user_id = c.user_id and a.address=b.address and a.disk_reads>100000
order by a.disk_reads desc,b.piece;
Display the System write batch size:
SELECT kviival write_batch_size
  FROM x$kvii
 WHERE kviidsc = 'DB writer IO clump' OR kviitag = 'kcbswc'
Monitor Disk I/O Contention:
select   NAME,  PHYRDS "Physical Reads",
    round((PHYRDS / PD.PHYS_READS)*100,2) "Read %",   PHYWRTS "Physical Writes",
    round(PHYWRTS * 100 / PD.PHYS_WRTS,2) "Write %",   fs.PHYBLKRD+FS.PHYBLKWRT "Total Block I/O's" from (    select     sum(PHYRDS) PHYS_READS, sum(PHYWRTS) PHYS_WRTS
    from    v$filestat    ) pd,  v$datafile df,  v$filestat fs
where     df.FILE# = fs.FILE#
order     by fs.PHYBLKRD+fs.PHYBLKWRT desc;
For information about database latch statistics and wait information. Click on the below link: Latch Statistics & Wait information
DB Locks/Blocks/Blocker Details:
******************************************************************************************************************************************************************
Track Block session in oracle 9i/10g  
‎select s1.username || '@' || s1.machine || ' ( SID=' || s1.sid ||  ' )  is blocking ' || s2.username || '@' || s2.machine || ' ( SID=' ||  s2.sid || ' ) ' AS blocking_status from gv$lock l1, gv$session s1, gv$lock l2, gv$session s2 where s1.sid = l1.sid and s2.sid = l2.sid  and l1.BLOCK = 1  and l2.request > 0  and l1.id1 = l2.id1  and l2.id2 = l2.id2;
select do.object_name, row_wait_obj#, row_wait_file#, row_wait_block#, row_wait_row#,
dbms_rowid.rowid_create(1, ROW_WAIT_OBJ#, ROW_WAIT_FILE#, ROW_WAIT_BLOCK#, ROW_WAIT_ROW#)
from gv$session s, dba_objects do
where sid = 543 and s.ROW_WAIT_OBJ# = do.OBJECT_ID;
For detail description of blocking you can run this on your Oracle-Home
oracle-home\rdbms\admin\utllockt.sql
Select process,sid, blocking_session from v$session where blocking_session is not null;  --in 10g
Track Locked Session & Blocked:
PROMPT Blocked and Blocker Sessions
select /*+ ORDERED */ blocker.sid blocker_sid, blocked.sid blocked_sid ,
TRUNC(blocked.ctime/60) min_blocked, blocked.request
from (select *from v$lock
where block != 0 and type = 'TX') blocker, v$lock blocked
where blocked.type='TX' and blocked.block = 0 and blocked.id1 = blocker.id1;
Track Database Lock:
Select /*+ ORDERED */ l.sid, l.lmode,
TRUNC(l.ctime/60) min_blocked, u.name||'.'||o.NAME blocked_obj
from (select * from v$lock
where type='TM' and sid in (select sid
from v$lock where block!=0)) l, sys.obj$ o, sys.user$ u
where o.obj# = l.ID1 and o.OWNER# = u.user#;
Track the Session Waiting for Lock:
SELECT holding_session bsession_id, waiting_session wsession_id, b.username busername, a.username wusername, c.lock_type TYPE, mode_held, mode_requested, lock_id1, lock_id2
FROM sys.v_$session b, sys.dba_waiters c, sys.v_$session a
WHERE c.holding_session = b.sid AND c.waiting_session = a.sid;
Track Blocker Details:
SELECT sid, serial#, username, osuser, machine
FROM v$session
WHERE sid IN (select sid from v$lock
where block != 0 and type = 'TX');
Users/Sessions/Processes Details:
******************************************************************************************************************************************************************
Average Wait Time for Particular Event:
SELECT EVENT,  TOTAL_WAITS,  TOTAL_TIMEOUTS,  TIME_WAITED, round(AVERAGE_WAIT,2) "Average Wait"
 from v$system_event order    by TOTAL_WAITS;
Sessions Waiting On A Particular Wait Event:
SELECT count(*), event
FROM v$session_wait
WHERE wait_time = 0 AND event NOT IN ('smon timer','pipe get','wakeup time manager', 'pmon timer','rdbms ipc message', 'SQL*Net message from client')
GROUP BY event ORDER BY 1 DESC;
Track Logon time of DB user and OS user:
Select to_char(logon_time,'dd/mm/yyyy hh24:mi:ss'),osuser,status,schemaname,machine from v$session where type !='BACKGROUND'; ‎
Track all Session User Details:
select sid, serial#,machine, status, osuser,username from v$session where username!='NULL';
Track Active Session User Details:
SELECT SID, Serial#, UserName, Status, SchemaName, Logon_Time FROM V$Session WHERE Status= 'ACTIVE' AND UserName IS NOT NULL;
Track Active User Details:
SELECT s.inst_id,  s.sid,  s.serial#,  p.spid,  s.username,  s.program FROM gv$session s  JOIN gv$process p ON p.addr = s.paddr AND p.inst_id = s.inst_id WHERE s.type != 'BACKGROUND';
Report OS Process ID for each session:
SELECT    ses.username  || '('  || ses.sid  || ')' users, acc.owner owner, acc.OBJECT OBJECT, ses.lockwait, prc.spid os_process
  FROM v$process prc, v$access acc, v$session ses
 WHERE prc.addr = ses.paddr AND ses.sid = acc.sid;
Show Username and SID/SPID with Program Name:
select sid,name,value from v$spparameter where isspecified='TRUE';‎
SELECT SID, Serial#, UserName, Status, SchemaName, Logon_Time FROM V$Session
WHERE Status= 'ACTIVE' AND UserName IS NOT NULL;  --to find active session
SELECT s.inst_id,  s.sid,  s.serial#,  p.spid,  s.username,  s.program    --active users details
FROM gv$session s  JOIN gv$process p ON p.addr = s.paddr AND p.inst_id = s.inst_id
WHERE s.type != 'BACKGROUND';
Track Current Transaction in Database:
‎‎select a.sid, a.username, b.xidusn, b.used_urec, b.used_ublk  from v$session a, v$transaction b
where a.saddr = b.ses_addr;‎
Important Object Information:
******************************************************************************************************************************************************************
Database Object Information:
Select owner,object_type,count(*) from dba_objects Where owner not IN ('SYS','MDSYS','CTXSYS','HR','ORDSYS','OE','ODM_MTR','WMSYS','XDB','QS_WS', 'RMAN','SCOTT','QS_ADM','QS_CBADM', 'ORDSYS','OUTLN','PM','QS_OS','QS_ES','ODM','OLAPSYS','WKSYS','SH','SYSTEM','ORDPLUGINS','QS','QS_CS')
Group by owner,object_type order by owner;
Query to Find 5 largest object in Database:
SELECT * FROM (select SEGMENT_NAME, SEGMENT_TYPE, BYTES/1024/1024/1024 GB, TABLESPACE_NAME from dba_segments order by 3 desc ) WHERE ROWNUM <= 5;
Track Last DDL Performed in database:
Select CREATED, TIMESTAMP, last_ddl_time from all_objects WHERE OWNER='HRMS' AND OBJECT_TYPE='TABLE' order by timestamp desc;
Count Invalid Object:
Select owner, object_type, count(*) from dba_objects where status='INVALID' group by  owner, object_type;
Report all Invalid Object in Database:
SELECT owner, object_name, object_type,‎ TO_CHAR (last_ddl_time, 'DD-MON-YY hh:mi:ss') last_time FROM dba_objects‎ WHERE status = 'INVALID';
Report Invalid Object with Next Action:
select 'Alter ' || decode(object_type,'PACKAGE BODY','PACKAGE',object_type) || ' ' || object_name || ' compile ' || decode(object_type,'PACKAGE BODY',' body;',';') from user_objects where object_type in ('FUNCTION','PACKAGE','PACKAGE BODY','PROCEDURE','TRIGGER','VIEW') and status = 'INVALID' order by object_type , object_name;
Click on the link to Report Invalid object and How to Compile them: Report All Invalid Objects
Track Total Number of Table/Index/Mviews:
Select count(1) from user_tables where table_name not like '%$%'
Select count(1) from user_mviews;
Select count(1) from user_indexes where index_type in ('FUNCTION-BASED NORMAL','NORMAL');
Number of Objects Created in last week:
Select count(1) from user_objects where CREATED >= sysdate - 7
Track Mviews Not Refreshed since last Week:
Select mview_name from user_mviews where LAST_REFRESH_DATE < sysdate - 7;