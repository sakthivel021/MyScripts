SELECT
      a.index_owner,            
      a.index_name,             
      a.partition_name,         
      a.high_value,     
      b.subpartition_name,        
      b.tablespace_name,
      b.logging,
      b.status
 FROM sys.dba_ind_partitions a, sys.dba_ind_subpartitions b
 WHERE 
    a.index_name=b.index_name
    And a.partition_name=b.partition_name
    and b.status != 'USABLE'
 ORDER BY a.index_owner,a.index_name,a.partition_name,
          b.subpartition_position
          