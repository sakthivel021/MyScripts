
select
 index_name
from
  all_indexes
where
  owner not in ('SYS', 'SYSTEM')
  and
  status != 'VALID'
  and (
    status != 'N/A'
    or
    index_name in (
      select
        index_name
      from
        all_ind_partitions
      where
        status != 'USABLE'
        and (
          status != 'N/A'
          or
          index_name in (
            select
              index_name
            from
              all_ind_subpartitions
            where
              status != 'USABLE'
          )
        )
    )
);