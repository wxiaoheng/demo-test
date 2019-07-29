<#--
HEPType:数据字典
HEPName:生成数据字典sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成数据字典SQL取消！')}
<#else>
<#list model.getItems() as item>

prompt 
prompt 新增数据字典${item.getExtendValue("dict_entry")}-${item.getExtendValue("entry_name")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_dict_entry where dict_entry = ${item.getExtendValue("dict_entry")});
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_dict_entry(dict_entry, manage_level, entry_name, access_level, dict_type, dict_kind) 
      values(${item.getExtendValue("dict_entry")}, '${item.getExtendValue("manage_level")}', '${item.getExtendValue("entry_name")}', '${item.getExtendValue("access_level")}', '${item.getExtendValue("dict_type")}', '${item.getExtendValue("dict_kind")}');
    commit;
  end if;
end;
/

<#list item.getSlaves() as child>

prompt 
prompt 新增数据字典${item.getExtendValue("dict_entry")}条目${child.getExtendValue("sub_entry")}-${child.getExtendValue("dict_prompt")}
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from hs_pbs.pbs_dictionary where dict_entry = ${item.getExtendValue("dict_entry")} and sub_entry = '${child.getExtendValue("sub_entry")}');
  if v_rowcount = 0 then
    insert into hs_pbs.pbs_dictionary(branch_no, dict_entry, dict_type, sub_entry, en_system_str, access_level, dict_prompt) 
      values (${child.getExtendValue("branch_no")}, ${item.getExtendValue("dict_entry")}, '${child.getExtendValue("dict_type")}', '${child.getExtendValue("sub_entry")}', '${child.getExtendValue("en_system_str")}', '${child.getExtendValue("access_level")}', '${child.getExtendValue("dict_prompt")}');
    commit;
  end if;
end;
/
</#list>
</#list>
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_dictionary_or.sql">
${fileUtil.setFile(path + fileName)}
</#if>