<#--
HEPType:标准错误号
HEPName:生成标准错误号sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成标准错误号SQL取消！')}
<#else>
<#list model.getItems() as item>

prompt
prompt 新增错误号${item.getExtendValue("error_no")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_error_msg where error_no = ${item.getExtendValue("error_no")});
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_error_msg(error_no, error_info, error_reason, en_system_str) values ( ${item.getExtendValue("error_no")}, '${item.getExtendValue("error_info")}', '${item.getExtendValue("error_reason")}', '${item.getExtendValue("en_system_str")}');
    commit;
  end if;
end;
/
</#list>
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_error_or.sql">
${fileUtil.setFile(path + fileName )}
</#if>