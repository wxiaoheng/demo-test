<#-- 上日表资源生成sync_datasource表的insertSQL语句 -->
<#assign projectProperty = util.getProjectProperty()/>
<#assign microServiceName = projectProperty.getSubSysId()/>
<#assign dbuser = projectProperty.getOracleProperty().getOracleUserModels()[0].getName()/>
<#assign tableName = model.getName()/>
<#assign syncDatasourceInfo = model.getSyncDatasource()/>
<#assign realSyncFlag = syncDatasourceInfo.getRealSyncFlag()/>
<#assign todapCond = syncDatasourceInfo.getTodapCond()/>
<#assign dapPartition = syncDatasourceInfo.getDapPartition()/>
<#assign primaryKeyInfo = syncDatasourceInfo.getPrimaryKeyInfo()/>
<#assign mainShardingFlag = syncDatasourceInfo.getMainShardingFlag()/>
-- 上日表${tableName}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from ${dbuser}.${microServiceName}_sync_datasource where table_name_src='${tableName}');
  if v_rowcount = 0 then
    insert into ${dbuser}.${microServiceName}_sync_datasource (table_name_src,real_sync_flag,todap_cond,dap_partition,primary_key_info,main_sharding_flag) values ('${tableName}','${realSyncFlag}','${todapCond}','${dapPartition}','${primaryKeyInfo}','${mainShardingFlag}');
  elsif v_rowcount = 1 then
    update ${dbuser}.${microServiceName}_sync_datasource set table_name_src='${tableName}',real_sync_flag='${realSyncFlag}',todap_cond='${todapCond}',dap_partition='${dapPartition}',primary_key_info='${primaryKeyInfo}',main_sharding_flag='${mainShardingFlag}' where table_name_src='${tableName}';
  end if;
  commit;
end;
/