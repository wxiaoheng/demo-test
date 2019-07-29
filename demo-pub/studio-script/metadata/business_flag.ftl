<#--
HEPType:业务标志
HEPName:生成业务标志sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成业务标志SQL取消！')}
<#else>
<#list model.getItems() as item>

prompt 
prompt 新增业务标志${item.getExtendValue("business_flag")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_business_flag where business_flag = ${item.getExtendValue("business_flag")});
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_business_flag (business_flag, business_name, business_subject, business_kind, en_system_str, business_group, join_business_flag, opp_business_flag)
      values (${item.getExtendValue("business_flag")}, '${item.getExtendValue("business_name")}', '${item.getExtendValue("business_subject")}', '${item.getExtendValue("business_kind")}', '${item.getExtendValue("en_system_str")}', '${item.getExtendValue("business_group")}', ${item.getExtendValue("join_business_flag")}, ${item.getExtendValue("opp_business_flag")});
    commit;
  end if;
end;
/
</#list>
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_businessflag_or.sql">
${fileUtil.setFile(path + fileName)}
</#if>