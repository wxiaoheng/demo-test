<#--
HEPType:系统全局配置
HEPName:生成sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成系统配置SQL取消！')}
<#else>
<#list model.getItems() as item>
prompt 
prompt 新增系统配置${item.getExtendValue("config_no")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_sys_config where config_no = ${item.getExtendValue("config_no")});
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_sys_config (branch_no, config_no, config_name, config_type, manage_level, access_level, en_system_str, data_type, char_config, int_config, str_config, company_type, sysbusi_type, remark) 
      values (${item.getExtendValue("branch_no")}, ${item.getExtendValue("config_no")}, '${item.getExtendValue("config_name")}', '${item.getExtendValue("config_type")}', '${item.getExtendValue("manage_level")}', '${item.getExtendValue("access_level")}', '${item.getExtendValue("en_system_str")}', '${item.getExtendValue("data_type")}', '${item.getExtendValue("char_config")}', ${item.getExtendValue("int_config")}, '${item.getExtendValue("str_config")}', '${item.getExtendValue("company_type")}', '${item.getExtendValue("sysbusi_type")}', '${stringUtil.replace(item.getExtendValue("remark"), "'", "''")}');
    commit;
  end if;
end;
/
</#list>
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_sysconfig_or.sql">
${fileUtil.setFile(path + fileName )}
</#if>