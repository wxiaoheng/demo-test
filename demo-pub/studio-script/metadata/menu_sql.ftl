<#--
HEPType:菜单与功能
HEPName:生成菜单与功能sql
HEPSelect:资源
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
    ${util.dialog('生成菜单与功能SQL取消！')}
<#else>

<#assign property = util.getProjectProperty().getOracleProperty()>

<#assign menuFuncBuilder=util.getStringBuffer()>
<#assign menuBuilder=util.getStringBuffer()>
<#assign funcBuilder=util.getStringBuffer()>
<#list model.getItems() as item>
    <@genMenuFunc item,menuFuncBuilder, funcBuilder/>
    <@genMenu item,menuBuilder/>
</#list>
${menuFuncBuilder.toString()}

${funcBuilder.toString()}

${menuBuilder.toString()}
<#assign fileName = "/" + util.getProjectProperty().getSubSysId()+"_menu_or.sql">
${fileUtil.setFile(path + fileName )}
</#if>

<#-- 生成菜单功能SQL的函数 -->
<#macro genMenuFunc menu,menuFuncBuilder,funcBuilder>
    <#assign str=menuFuncBuilder.append("--菜单功能" + menu.getExtendValue("menu_code")+"\n")/>
    <#assign str=menuFuncBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=menuFuncBuilder.append("begin\n")/>
    <#assign str=menuFuncBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=menuFuncBuilder.append("    where exists (select 1 from hs_omc.tsys_trans where trans_code='"+menu.getExtendValue("menu_code")+"');\n")/>
    <#assign str=menuFuncBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=menuFuncBuilder.append("insert into hs_omc.tsys_trans (trans_code,trans_name,kind_code,model_code,remark) values (")/>
    <#assign str=menuFuncBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuFuncBuilder.append("'"+menu.getExtendValue("menu_name")+"',")/>
    <#assign str=menuFuncBuilder.append("'"+menu.getExtendValue("kind_code")+"',")/>
    <#assign str=menuFuncBuilder.append("'1',")/>
    <#assign str=menuFuncBuilder.append("'"+menu.getExtendValue("remark")+"');\n")/>
    <#assign str=menuFuncBuilder.append("  else\n")/>
    <#assign str=menuFuncBuilder.append("update hs_omc.tsys_trans set trans_code = "+"'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuFuncBuilder.append("trans_name = "+"'"+menu.getExtendValue("menu_name")+"',")/>    
    <#assign str=menuFuncBuilder.append("kind_code = "+"'"+menu.getExtendValue("kind_code")+"',")/>
    <#assign str=menuFuncBuilder.append("model_code = '1',")/> 
    <#assign str=menuFuncBuilder.append("remark = "+"'"+menu.getExtendValue("remark")+"' ")/>
    <#assign str=menuFuncBuilder.append("where trans_code = '"+menu.getExtendValue("menu_code")+"';\n")/>
    <#assign str=menuFuncBuilder.append("  end if;\n")/>
    <#assign str=menuFuncBuilder.append("  commit;\n")/>
    <#assign str=menuFuncBuilder.append("end;\n")/>
    <#assign str=menuFuncBuilder.append("/\n")/>
    <#list menu.getSlaves() as slave>
        <@genFunc menu,slave,funcBuilder/>
    </#list>
    <#list menu.getChildren() as child>
        <@genMenuFunc child,menuFuncBuilder,funcBuilder/>
    </#list>
</#macro>

<#-- 生成菜单功能子项SQL的函数 -->
<#macro genFunc menu,func,funcBuilder>
    <#assign str=funcBuilder.append("--菜单功能子项" + func.getExtendValue("sub_trans_code")+"\n")/>
    <#assign str=funcBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=funcBuilder.append("begin\n")/>
    <#assign str=funcBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=funcBuilder.append("    where exists (select 1 from hs_omc.tsys_subtrans where trans_code='"+menu.getExtendValue("menu_code")+"' and sub_trans_code='"+func.getExtendValue("sub_trans_code")+"');\n")/>
    <#assign str=funcBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=funcBuilder.append("insert into hs_omc.tsys_subtrans (trans_code,sub_trans_code,sub_trans_name,rel_serv,rel_url,ctrl_flag,login_flag,remark) values (")/>
    <#assign str=funcBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("sub_trans_code")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("sub_trans_name")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("rel_serv")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("rel_url")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("ctrl_flag")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("login_flag")+"',")/>
    <#assign str=funcBuilder.append("'"+func.getExtendValue("remark")+"');\n")/>
    <#assign str=funcBuilder.append("  else\n")/>    
    <#assign str=funcBuilder.append("update hs_omc.tsys_subtrans set trans_code = "+"'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=funcBuilder.append("sub_trans_code = "+"'"+func.getExtendValue("sub_trans_code")+"',")/>    
    <#assign str=funcBuilder.append("sub_trans_name = "+"'"+func.getExtendValue("sub_trans_name")+"',")/>
    <#assign str=funcBuilder.append("rel_serv = "+"'"+func.getExtendValue("rel_serv")+"',")/>    
    <#assign str=funcBuilder.append("rel_url = "+"'"+func.getExtendValue("rel_url")+"',")/>   
    <#assign str=funcBuilder.append("ctrl_flag = "+"'"+func.getExtendValue("ctrl_flag")+"',")/>
    <#assign str=funcBuilder.append("login_flag = "+"'"+func.getExtendValue("login_flag")+"',")/>    
    <#assign str=funcBuilder.append("remark = "+"'"+menu.getExtendValue("remark")+"' ")/>
    <#assign str=funcBuilder.append("where trans_code = '"+menu.getExtendValue("menu_code")+"' ")/>
    <#assign str=funcBuilder.append("and sub_trans_code = '"+func.getExtendValue("sub_trans_code")+"';\n")/>
    <#assign str=funcBuilder.append("  end if;\n")/>
    <#assign str=funcBuilder.append("  commit;\n")/>
    <#assign str=funcBuilder.append("end;\n")/>
    <#assign str=funcBuilder.append("/\n")/>
</#macro>

<#-- 生成菜单SQL的函数 -->
<#macro genMenu menu,menuBuilder>
    <#assign str=menuBuilder.append("--菜单 "+menu.getExtendValue("menu_code")+"\n")/>
    <#assign str=menuBuilder.append("declare v_rowcount number(5);\n")/>
    <#assign str=menuBuilder.append("begin\n")/>
    <#assign str=menuBuilder.append("  select count(*) into v_rowcount from dual\n")/>
    <#assign str=menuBuilder.append("    where exists (select 1 from hs_omc.tsys_menu where menu_code='"+menu.getExtendValue("menu_code")+"' and kind_code='"+menu.getExtendValue("kind_code")+"');\n")/>
    <#assign str=menuBuilder.append("  if v_rowcount = 0 then\n")/>
    <#assign str=menuBuilder.append("insert into hs_omc.tsys_menu (menu_code,kind_code,trans_code,sub_trans_code,menu_name,menu_type,menu_arg,menu_icon,menu_url,window_type,window_model,tip,parent_code,order_no,open_flag,tree_idx,remark) values (")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("kind_code")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_name")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_type")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_arg")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_icon")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("menu_url")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("window_type")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("window_model")+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("tip")+"',")/>
    <#if (menu.getParentItem()??)>
        <#assign str=menuBuilder.append("'"+menu.getParentItem().getExtendValue("menu_code")+"',")/>
    <#else/>
        <#assign str=menuBuilder.append("'bizroot',")/>
    </#if>
    <#assign str=menuBuilder.append(menu.getExtendValue("order_no")+",")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("open_flag")+"',")/>
    <#assign str=menuBuilder.append("'"+reference.getMenuTreeIdx(element, menu)+"',")/>
    <#assign str=menuBuilder.append("'"+menu.getExtendValue("remark")+"');\n")/>
    <#assign str=menuBuilder.append("  else\n")/>    
    <#assign str=menuBuilder.append("update hs_omc.tsys_menu set menu_code = "+"'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuBuilder.append("kind_code = "+"'"+menu.getExtendValue("kind_code")+"',")/>    
    <#assign str=menuBuilder.append("trans_code = "+"'"+menu.getExtendValue("menu_code")+"',")/>
    <#assign str=menuBuilder.append("sub_trans_code = "+"'"+menu.getExtendValue("menu_code")+"',")/>    
    <#assign str=menuBuilder.append("menu_name = "+"'"+menu.getExtendValue("menu_name")+"',")/>
    <#assign str=menuBuilder.append("menu_type = "+"'"+menu.getExtendValue("menu_type")+"',")/>    
    <#assign str=menuBuilder.append("menu_arg = "+"'"+menu.getExtendValue("menu_arg")+"',")/>
    <#assign str=menuBuilder.append("menu_icon = "+"'"+menu.getExtendValue("menu_icon")+"',")/>    
    <#assign str=menuBuilder.append("menu_url = "+"'"+menu.getExtendValue("menu_url")+"',")/> 
    <#assign str=menuBuilder.append("window_type = "+"'"+menu.getExtendValue("window_type")+"',")/>    
    <#assign str=menuBuilder.append("window_model = "+"'"+menu.getExtendValue("window_model")+"',")/>  
    <#assign str=menuBuilder.append("tip = "+"'"+menu.getExtendValue("tip")+"',")/>   
    <#assign str=menuBuilder.append("parent_code = ")/>
    <#if (menu.getParentItem()??)>
        <#assign str=menuBuilder.append("'"+menu.getParentItem().getExtendValue("menu_code")+"',")/>
    <#else/>
        <#assign str=menuBuilder.append("'bizroot',")/>
    </#if>     
    <#assign str=menuBuilder.append("order_no = "+"'"+menu.getExtendValue("order_no")+"',")/>
    <#assign str=menuBuilder.append("open_flag = "+"'"+menu.getExtendValue("open_flag")+"',")/>
    <#assign str=menuBuilder.append("tree_idx = "+"'"+reference.getMenuTreeIdx(element, menu)+"',")/>
    <#assign str=menuBuilder.append("remark = "+"'"+menu.getExtendValue("remark")+"' ")/>
    <#assign str=menuBuilder.append("where trans_code = '"+menu.getExtendValue("menu_code")+"' ")/>
    <#assign str=menuBuilder.append("and kind_code = '"+menu.getExtendValue("kind_code")+"';\n")/>
    <#assign str=menuBuilder.append("  end if;\n")/>
    <#assign str=menuBuilder.append("  commit;\n")/>
    <#assign str=menuBuilder.append("end;\n")/>
    <#assign str=menuBuilder.append("/\n\n\n")/>
    <#list menu.getChildren() as child>
        <@genMenu child,menuBuilder/>
    </#list>
</#macro>