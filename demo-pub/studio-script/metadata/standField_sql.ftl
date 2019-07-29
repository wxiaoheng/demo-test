<#--
HEPType:标准字段
HEPName:生成标准字段sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成标准字段SQL取消！')}
<#else>

<#assign user = "hs_pbs">
<#assign standFieldBuilder=util.getStringBuffer()>

<#list model.getItems() as item>
	<@genStandField item, standFieldBuilder/>
</#list>
${standFieldBuilder.toString()}
<#assign fileName = "/" + "pbs_pbs_FieldToname_or.sql">
${fileUtil.setFile(path + fileName )}
</#if>

<#-- 标准字段SQL的函数 -->
<#macro genStandField standfield, standFieldBuilder>
	<#assign str=standFieldBuilder.append("--标准字段" + standfield.getName()+"\n")/>
	<#assign str=standFieldBuilder.append("prompt\n")/>
	<#assign str=standFieldBuilder.append("prompt 新增标准字段" + standfield.getName() + ";\n")/>
    <#assign str=standFieldBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=standFieldBuilder.append("begin\n")/>
    <#assign str=standFieldBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=standFieldBuilder.append("    where exists (select 1 from "+user+".pbs_field_toname where english_name ='"+standfield.getName()+"');\n")/>
    <#assign str=standFieldBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=standFieldBuilder.append("    insert into "+user+".pbs_field_toname (english_name,entry_name,dict_entry) values (")/>
    <#assign str=standFieldBuilder.append("'"+standfield.getName()+"',")/>
    <#assign str=standFieldBuilder.append("'"+standfield.getChineseName()+"',")/>
    <#assign dictEntry = standfield.getDictType()>
    <#if stringUtil.isBlank(dictEntry)>
        <#assign dictEntry = "0">
    </#if>
    <#assign str=standFieldBuilder.append(dictEntry + ");\n")/>
    <#assign str=standFieldBuilder.append("  end if;\n")/>
    <#assign str=standFieldBuilder.append("  commit;\n")/>
    <#assign str=standFieldBuilder.append("end;\n")/>
    <#assign str=standFieldBuilder.append("/\n")/>
</#macro>