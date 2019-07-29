<#--
HEPType:菜单与功能
HEPName:生成菜单赋权sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成菜单赋权SQL取消！')}
<#else>

<#assign property = util.getProjectProperty().getOracleProperty()>

<#assign funcBuilder=util.getStringBuffer()>
<#assign roleBuilder=util.getStringBuffer()>
<#assign userBuilder=util.getStringBuffer()>
<#list model.getItems() as item>
	<@genFunc item,funcBuilder/>   
	<@genRole item,roleBuilder/>
	<@genUser item,userBuilder/> 		   
</#list>
${funcBuilder.toString()}

${roleBuilder.toString()}

${userBuilder.toString()}

<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_menu_authority.sql">
${fileUtil.setFile(path + fileName )}
</#if>

<#-- 生成菜单功能子项SQL的函数 -->
<#macro genFunc menu,funcBuilder>
	<#assign str=funcBuilder.append("--菜单功能子项" + menu.getExtendValue("menu_code")+"\n")/>
	<#assign str=funcBuilder.append("declare v_rowcount number(5);\n")/>
	<#assign str=funcBuilder.append("begin\n")/>
	<#assign str=funcBuilder.append("  select count(*) into v_rowcount from dual\n")/>
	<#assign str=funcBuilder.append("    where exists (select 1 from hs_omc.tsys_subtrans where trans_code='"+menu.getExtendValue("menu_code")+"' and sub_trans_code='"+menu.getExtendValue("menu_code")+"');\n")/>
	<#assign str=funcBuilder.append("  if v_rowcount = 0 then\n")/>
	<#assign str=funcBuilder.append("    insert into hs_omc.tsys_subtrans (trans_code,sub_trans_code,sub_trans_name,rel_serv,rel_url,ctrl_flag,login_flag,remark,ext_field_1,ext_field_2,ext_field_3,tenant_id,sub_trans_arg) values (")/>
	<#assign str=funcBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
	<#assign str=funcBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
	<#assign str=funcBuilder.append("'"+menu.getExtendValue("menu_name")+"',")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null,")/>
	<#assign str=funcBuilder.append("null);\n")/>   
	<#assign str=funcBuilder.append("  end if;\n")/>
	<#assign str=funcBuilder.append("  commit;\n")/>
	<#assign str=funcBuilder.append("end;\n")/>
	<#assign str=funcBuilder.append("/\n")/>	
    <#list menu.getChildren() as child>
        <@genFunc child,funcBuilder/>
    </#list>
</#macro>

<#-- 赋予admin角色子系统根菜单权限 -->
<#macro genRole menu,roleBuilder>
	<#assign str=roleBuilder.append("--赋予admin角色子系统根菜单权限\n")/>
    <#assign str=roleBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=roleBuilder.append("begin\n")/>
    <#assign str=roleBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=roleBuilder.append("    where exists (select 1 from hs_omc.tsys_role_right where trans_code='"+menu.getExtendValue("menu_code")+"' and sub_trans_code='"+menu.getExtendValue("menu_code")+"');\n")/>
    <#assign str=roleBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=roleBuilder.append("    insert into hs_omc.tsys_role_right (trans_code,sub_trans_code,role_code,create_by,create_date,begin_date,end_date,right_flag,right_enable) values (")/>
    <#assign str=roleBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=roleBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=roleBuilder.append("'admin',")/>
    <#assign str=roleBuilder.append("'admin',")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("'1',")/>
    <#assign str=roleBuilder.append("null);\n")/>
    <#assign str=roleBuilder.append("    insert into hs_omc.tsys_role_right (trans_code,sub_trans_code,role_code,create_by,create_date,begin_date,end_date,right_flag,right_enable) values (")/>
    <#assign str=roleBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=roleBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=roleBuilder.append("'admin',")/>
    <#assign str=roleBuilder.append("'admin',")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("0,")/>
    <#assign str=roleBuilder.append("'2',")/>
    <#assign str=roleBuilder.append("null);\n")/>
    <#assign str=roleBuilder.append("  end if;\n")/>
    <#assign str=roleBuilder.append("  commit;\n")/>
    <#assign str=roleBuilder.append("end;\n")/>
    <#assign str=roleBuilder.append("/\n")/>
    <#list menu.getChildren() as child>
        <@genRole child,roleBuilder/>
    </#list>    
</#macro>

<#-- 赋予admin用户子系统根菜单权限 -->
<#macro genUser menu,userBuilder>
	<#assign str=userBuilder.append("--赋予admin用户子系统根菜单权限\n")/>
    <#assign str=userBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=userBuilder.append("begin\n")/>
    <#assign str=userBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=userBuilder.append("    where exists (select 1 from hs_omc.tsys_user_right where trans_code='"+menu.getExtendValue("menu_code")+"' and sub_trans_code='"+menu.getExtendValue("menu_code")+"');\n")/>
    <#assign str=userBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=userBuilder.append("    insert into hs_omc.tsys_user_right (trans_code,sub_trans_code,user_id,create_by,create_date,begin_date,end_date,right_flag,right_enable) values (")/>
    <#assign str=userBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=userBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=userBuilder.append("'admin',")/>
    <#assign str=userBuilder.append("null,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("'1',")/>
    <#assign str=userBuilder.append("null);\n")/>
    <#assign str=userBuilder.append("    insert into hs_omc.tsys_user_right (trans_code,sub_trans_code,user_id,create_by,create_date,begin_date,end_date,right_flag,right_enable) values (")/>
    <#assign str=userBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=userBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=userBuilder.append("'admin',")/>
    <#assign str=userBuilder.append("null,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("0,")/>
    <#assign str=userBuilder.append("'2',")/>
    <#assign str=userBuilder.append("null);\n")/>
    <#assign str=userBuilder.append("  end if;\n")/>
    <#assign str=userBuilder.append("  commit;\n")/>
    <#assign str=userBuilder.append("end;\n")/>
    <#assign str=userBuilder.append("/\n")/>
    <#list menu.getChildren() as child>
        <@genUser child,userBuilder/>
    </#list>   	    
</#macro>