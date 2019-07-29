<#--
HEPType:外部错误号
HEPName:生成外部错误号sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成外部错误号SQL取消！')}
<#else>
<#list model.getItems() as item>

prompt
prompt 新增外部错误号${item.getExtendValue("extern_code")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_extern_error where error_sort = '${item.getExtendValue("error_sort")}' and error_source = '${item.getExtendValue("error_source")}' and extern_code = '${item.getExtendValue("extern_code")}' and error_no = ${item.getExtendValue("error_no")});
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_extern_error(error_sort, error_source, extern_code, error_no, error_info, en_system_str) 
      values ('${item.getExtendValue("error_sort")}', '${item.getExtendValue("error_source")}', '${item.getExtendValue("extern_code")}', ${item.getExtendValue("error_no")}, '${item.getExtendValue("error_info")}', '${item.getExtendValue("en_system_str")}');
    commit;
  end if;
end;
/
</#list>
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_externerror_or.sql">
${fileUtil.setFile(path + fileName )}
</#if>