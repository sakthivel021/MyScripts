

REM Monitoring and tuning script for Oracle databases all versions
REM This script has no adverse affects. There are no DML or DDL actions taken
REM Parts will not work in all versions but useful info should be returned from other parts
REM Uses anonymous procedures to avoid storing objects in the SYS schema
REM therefore this script must be run as sys 
REM calls to v$parameter need to be moved into subblocks to prevent NO_DATA_FOUND exceptions
REM parameter numbers are different between Oracle Versions
REM
REM This daily script is a subset of the weekly script 
REM This script monitors only those things that might cause an application or database failure
REM and not all of those
REM
REM For nicer formatting run the following in vi: %s/  *$//
REM This strips the trailing whitespace returned from oracle
REM
REM These scripts have been collected from many sources and I am sure there are
REM acknowledgements missing from below. Among those are Steve Adams, Rachel Carmichael,
REM Jared Still and other members of the oracle-l mailing list
REM
REM	Unknown authors 	1990 - 1995
REM	Oracle Corporation	1990 - 
REM	Bill Beaton, QC Data		1995
REM	D. Morgan, QC Data		1997
REM	Hari Krishnamoorthy, QC Data	1999
REM	J. J. Wang, Bartertrust		2000
REM	D. Morgan, 1001111 Alberta Ltd.	2002
REM

set pause off
set verify off
set echo off
set term off
set heading off

REM Set up dynamic spool filename
spool tmp7_spool.sql
	select 'spool '||name||'_'||'daily'||'_'||to_char(sysdate,'yymondd')||'.dat'
	from sys.v_$database;
spool off

set heading on
set verify on
set term on
set serveroutput on size 1000000
set wrap on
set linesize 200
set pagesize 1000

/**************************************** START REPORT ****************************************************/

/* Run dynamic spool output name */
@tmp7_spool.sql

set feedback off
set heading off

select 'Report Date: '||to_char(sysdate,'Monthdd, yyyy hh:mi')
from dual;

set heading on
prompt =================================================================================================
prompt .                      DATABASE (V$DATABASE) (V$VERSION)
prompt =================================================================================================
select	NAME "Database Name",
	CREATED "Created",
	LOG_MODE "Status"
  from	sys.v_$database;

select	banner "Current Versions"
  from	sys.v_$version;

prompt =================================================================================================
prompt .                      UPTIME (V$DATABASE) (V$INSTANCE)
prompt =================================================================================================

set heading off
column sttime format A30

SELECT NAME, ' Database Started on ',TO_CHAR(STARTUP_TIME,'DD-MON-YYYY "at" HH24:MI')
FROM V$INSTANCE, v$database;
set heading on


prompt .
prompt =================================================================================================
prompt .                      SGA SIZE (V$SGA) (V$SGASTAT)
prompt =================================================================================================
column Size	format 99,999,999,999
select	decode(name,	'Database Buffers',
		'Database Buffers (DB_BLOCK_SIZE*DB_BLOCK_BUFFERS)',
		'Redo Buffers',
		'Redo Buffers     (LOG_BUFFER)', name) "Memory",
		value		"Size"
	from sys.v_$sga
UNION ALL
	select	'------------------------------------------------------'	"Memory",
		to_number(null)		"Size"
  	from	dual
UNION ALL
	select	'Total Memory' "Memory",
		sum(value)	"Size"
  	from	sys.v_$sga;

prompt .
prompt .
prompt Current Break Down of (SGA) Variable Size
prompt ------------------------------------------

column Bytes		format 999,999,999
column "% Used"		format 999.99
column "Var. Size"	format 999,999,999

select	a.name			"Name",
	bytes			"Bytes",
	(bytes / b.value) * 100	"% Used",
	b.value			"Var. Size"
from	sys.v_$sgastat a,
	sys.v_$sga b
where	a.name not in ('db_block_buffers','fixed_sga','log_buffer')
and	b.name='Variable Size'
order by 3 desc;

prompt .

set feedback ON

declare
	h_char          varchar2(100);
	h_char2		varchar(50);
	h_num1          number(25);
	result1         varchar2(50);
	result2         varchar2(50);

	cursor c1 is
        select lpad(namespace,17)||': gets(pins)='||rpad(to_char(pins),9)||
                                     ' misses(reloads)='||rpad(reloads,9)||
               ' Ratio='||decode(reloads,0,0,to_char((reloads/pins)*100,999.999))||'%'
        from v$librarycache;

begin
    dbms_output.put_line
    	('=================================================================================================');
    dbms_output.put_line('.                      SHARED POOL: LIBRARY CACHE (V$LIBRARYCACHE)');
    dbms_output.put_line
    	('=================================================================================================');
    dbms_output.put_line('.');
    dbms_output.put_line('.         Goal: The library cache ratio < 1%' );
    dbms_output.put_line('.');
    
    Begin
    	SELECT 'Current setting: '||substr(value,1,30) INTO result1
    	FROM V$PARAMETER	
    	WHERE NUM = 23;
    	SELECT 'Current setting: '||substr(value,1,30) INTO result2
    	FROM V$PARAMETER	
    	WHERE NUM = 325;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN 
    		h_num1 :=1;
    END;
    dbms_output.put_line('Recommendation: Increase SHARED_POOL_SIZE '||rtrim(result1));
    dbms_output.put_line('.                        OPEN_CURSORS '    ||rtrim(result2));
    dbms_output.put_line('.               Also write identical sql statements.');
    dbms_output.put_line('.');
        
    open c1;
    loop
	fetch c1 into h_char;
	exit when c1%notfound;
	
	dbms_output.put_line('.'||h_char);
    end loop;
    close c1;

    dbms_output.put_line('.');

    select lpad('Total',17)||': gets(pins)='||rpad(to_char(sum(pins)),9)||
                                 ' misses(reloads)='||rpad(sum(reloads),9),
               ' Your library cache ratio is '||
                decode(sum(reloads),0,0,to_char((sum(reloads)/sum(pins))*100,999.999))||'%'
    into h_char,h_char2
    from v$librarycache;
    dbms_output.put_line('.'||h_char);
    dbms_output.put_line('.           ..............................................');
    dbms_output.put_line('.           '||h_char2);

    dbms_output.put_line('.');
end;
/

declare
        h_num1          number(25);
        h_num2          number(25);
        h_num3          number(25);
        result1         varchar2(50);

begin
    dbms_output.put_line
    	('=================================================================================================');
        dbms_output.put_line('.                      SHARED POOL: DATA DICTIONARY (V$ROWCACHE)');
    dbms_output.put_line
    	('=================================================================================================');
        dbms_output.put_line('.');
        dbms_output.put_line('.         Goal: The row cache ratio should be < 10% or 15%' );
        dbms_output.put_line('.');
        dbms_output.put_line('.         Recommendation: Increase SHARED_POOL_SIZE '||result1);
        dbms_output.put_line('.');

        select sum(gets) "gets", sum(getmisses) "misses", round((sum(getmisses)/sum(gets))*100 ,3)
        into h_num1,h_num2,h_num3
        from v$rowcache;

        dbms_output.put_line('.');
        dbms_output.put_line('.             Gets sum: '||h_num1);
        dbms_output.put_line('.        Getmisses sum: '||h_num2);

        dbms_output.put_line('         .......................................');
        dbms_output.put_line('.        Your row cache ratio is '||h_num3||'%');

end;
/

declare
        h_char          varchar2(100);
        h_num1          number(25);
        h_num2          number(25);
        h_num3          number(25);
        h_num4          number(25);
        result1         varchar2(50);
begin
    dbms_output.put_line('.');
    dbms_output.put_line
    	('=================================================================================================');
        dbms_output.put_line('.                      BUFFER CACHE (V$SYSSTAT)');
    dbms_output.put_line
    	('=================================================================================================');
        dbms_output.put_line('.');
        dbms_output.put_line('.         Goal: The buffer cache ratio should be > 70% ');
        dbms_output.put_line('.');
	Begin
    		SELECT 'Current setting: '||substr(value,1,30) INTO result1
    		FROM V$PARAMETER	
    		WHERE NUM = 125;
    	EXCEPTION
    	WHEN NO_DATA_FOUND THEN 
    		result1 := 'Unknown parameter';
	END;
        dbms_output.put_line('.          Recommendation: Increase DB_BLOCK_BUFFERS '||result1);
        dbms_output.put_line('.');

        select lpad(name,15)  ,value
        into h_char,h_num1
        from v$sysstat
        where name ='db block gets';
        dbms_output.put_line('.         '||h_char||': '||h_num1);

        select lpad(name,15)  ,value
        into h_char,h_num2
        from v$sysstat
        where name ='consistent gets';
        dbms_output.put_line('.         '||h_char||': '||h_num2);

        select lpad(name,15)  ,value
        into h_char,h_num3
        from v$sysstat
        where name ='physical reads';
        dbms_output.put_line('.         '||h_char||': '||h_num3);

        h_num4:=round(((1-(h_num3/(h_num1+h_num2))))*100,3);

        dbms_output.put_line('.          .......................................');
        dbms_output.put_line('.          Your buffer cache ratio is '||h_num4||'%');

    dbms_output.put_line('.');
end;
/

declare
        h_char          varchar2(100);
        h_num1          number(25);
        h_num2          number(25);
        h_num3          number(25);

        cursor buff2 is
        SELECT name
                ,consistent_gets+db_block_gets, physical_reads
                ,DECODE(consistent_gets+db_block_gets,0,TO_NUMBER(null)
                ,to_char((1-physical_reads/(consistent_gets+db_block_gets))*100, 999.999))
        FROM v$buffer_pool_statistics;
begin
     dbms_output.put_line
    	('=================================================================================================');
        dbms_output.put_line('.                      BUFFER CACHE (V$buffer_pool_statistics)');
    dbms_output.put_line
    	('=================================================================================================');

        dbms_output.put_line('.');
        dbms_output.put_line('.');
        dbms_output.put_line('Buffer Pool:         Logical_Reads     Physical_Reads        HIT_RATIO');
        dbms_output.put_line('.');

        open buff2;
        loop
            fetch buff2 into h_char, h_num1, h_num2, h_num3;
            exit when buff2%notfound;

	    dbms_output.put_line(rpad(h_char, 15, '.')||'         '||lpad(h_num1, 10, ' ')||'         '||
	    	lpad(h_num2, 10, ' ')||'       '||lpad(h_num3, 10, ' '));

        end loop;
        close buff2;

    dbms_output.put_line('.');
end;
/

declare
        h_char          varchar2(100);
        h_num1          number(25);
        result1         varchar2(50);

        cursor c2 is
        select name,value
        from v$sysstat
        where name in ('sorts (memory)','sorts (disk)')
        order by 1 desc;

begin
 	dbms_output.put_line
    		('=================================================================================================');
        dbms_output.put_line('.                      SORT STATUS (V$SYSSTAT)');
	dbms_output.put_line
    		('=================================================================================================');
        dbms_output.put_line('.');
        dbms_output.put_line('.         Goal: Very low sort (disk)' );
        dbms_output.put_line('.');
        BEGIN
    		SELECT 'Current setting: '||substr(value,1,30) INTO result1
    		FROM V$PARAMETER	
    		WHERE NUM = 320;
    	EXCEPTION
    		WHEN NO_DATA_FOUND THEN 
    			result1 := 'Unknown parameter';
    	END;
        dbms_output.put_line('           Recommendation: Increase SORT_AREA_SIZE '||result1);
        dbms_output.put_line('.');
        dbms_output.put_line('.');
        dbms_output.put_line(rpad('Name',30)||'Count');
        dbms_output.put_line(rpad('-',25,'-')||'     -----------');

        open c2;
        loop
        fetch c2 into h_char,h_num1;
        exit when c2%notfound;
                dbms_output.put_line(rpad(h_char,30)||h_num1);
        end loop;
        close c2;
end;
/

prompt .
prompt =================================================================================================
prompt .                      TABLESPACE USAGE (DBA_DATA_FILES, DBA_FREE_SPACE)
prompt =================================================================================================
column Tablespace	format a30
column Size		format 999,999,999,999
column Used		format 999,999,999,999
column Free		format 999,999,999,999
column "% Used"		format 999.99
select	tablespace_name		"Tablesapce",
        bytes			"Size",
       	nvl(bytes-free,bytes)	"Used",
       	nvl(free,0)		"Free",
       	nvl(100*(bytes-free)/bytes,100)	"% Used"
  from(
	select ddf.tablespace_name, sum(dfs.bytes) free, ddf.bytes bytes
	FROM (select tablespace_name, sum(bytes) bytes
	from dba_data_files group by tablespace_name) ddf, dba_free_space dfs
	where ddf.tablespace_name = dfs.tablespace_name(+)
	group by ddf.tablespace_name, ddf.bytes)
  order by 5 desc;

set feedback off
set heading off
select	rpad('Total',30,'.')		"Tablespace",
  	sum(bytes)			"Size",
       	sum(nvl(bytes-free,bytes))	"Used",
       	sum(nvl(free,0))		"Free",
       	(100*(sum(bytes)-sum(free))/sum(bytes))	"% Used"
  from(
	select ddf.tablespace_name, sum(dfs.bytes) free, ddf.bytes bytes
	FROM (select tablespace_name, sum(bytes) bytes
	from dba_data_files group by tablespace_name) ddf, dba_free_space dfs
	where ddf.tablespace_name = dfs.tablespace_name(+)
	group by ddf.tablespace_name, ddf.bytes);

set feedback on
set heading on

prompt .
prompt =================================================================================================
prompt .                      FREE SPACE FRAGMENTATION (DBA_FREE_SPACE)
prompt =================================================================================================
column Tablespace	format a30
column "Available Size"	format 99,999,999,999
column "Fragmentation"	format 99,999
column "Average Size"	format 9,999,999,999
column "   Max"		format 9,999,999,999
column "   Min"		format 9,999,999,999
select tablespace_name Tablespace, 
	count(*) Fragmentation, 
	sum(bytes) "Available Size",
	avg(bytes) "Average size",
	max(bytes) Max, 
	min(bytes) Min
from dba_free_space
group by tablespace_name
order by 3 desc ;

prompt .
prompt ============================================================================================
prompt .                   SUMMARY OF INVALID OBJECTS (DBA_OBJECTS)
prompt ============================================================================================

select owner, object_type, substr(object_name,1,30) object_name, status
from dba_objects
where status='INVALID'
order by object_type;

prompt .
prompt ============================================================================================
prompt .                   LAST REFRESH OF SNAPSHOTS (DBA_SNAPSHOTS)
prompt ============================================================================================

select owner, name, last_refresh 
from dba_snapshots 
where last_refresh < (SYSDATE - 1);


prompt .
prompt ============================================================================================
prompt .                   LAST JOBS SCHEDULED (DBA_JOBS)
prompt ============================================================================================

set arraysize 10
set linesize 65
col what format a65
col log_user format a10
col job format 9999
select job, log_user, last_date, last_sec, next_date, next_sec, 
failures, what 
from dba_jobs
where failures > 0;

set linesize 100

prompt .
prompt =================================================================================================
prompt .                      ERROR- These segments will fail during NEXT EXTENT (DBA_SEGMENTS)
prompt =================================================================================================
column Tablespaces	format a30
column Segment		format a40
column "NEXT Needed"	format 999,999,999
column "MAX Available"	format 999,999,999
select	a.tablespace_name	"Tablespaces",
	a.owner			"Owner",
	a.segment_name		"Segment",
	a.next_extent		"NEXT Needed",
	b.next_ext		"MAX Available"
  from	sys.dba_segments a,
	(select tablespace_name,max(bytes) next_ext
	from sys.dba_free_space 
	group by tablespace_name) b
 where	a.tablespace_name=b.tablespace_name(+)
   and	b.next_ext < a.next_extent;

prompt =================================================================================================
prompt .                      WARNING- These segments > 70% of MAX EXTENT (DBA_SEGMENTS)
prompt =================================================================================================
column Tablespace	format a30
column Segment		format a40
column Used		format 9999
column Max		format 9999
select	tablespace_name	"Tablespace",
	owner		"Owner",
	segment_name	"Segment",
	extents		"Used",
	max_extents	"Max"
  from	sys.dba_segments
 where	(extents/decode(max_extents,0,1,max_extents))*100 > 70
   and	max_extents >0;

prompt =================================================================================================
prompt .                      LIST OF OBJECTS HAVING > 12 EXTENTS (DBA_EXTENTS)
prompt =================================================================================================
column Tablespace_ext	format a30
column Segment		format a40
column Count		format 9999
break on "Tablespace_ext" skip 1
select	tablespace_name "Tablespace_ext" ,
	owner		"Owner",
	segment_name    "Segment",
	count(*)        "Count"
  from	sys.dba_extents
 group by tablespace_name,owner,segment_name
 having count(*)>12
 order by 1,3 desc;

prompt =================================================================================================
prompt End of Report

spool off

/* Remove temp spool scripts */
host rm tmp7_*.sql

exit;


