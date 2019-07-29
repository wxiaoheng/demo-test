<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
    ${util.dialog('生成Oracle数据库用户SQL取消！')}<#t>
<#else>
    <#-- 调用宏指令 -->
    <@main model.getOracleUserModels()/>
</#if>
<#-- 生成逻辑的主方法，dbusers为数据库用户列表 -->
<#macro main dbusers>
    ${fileUtil.setFile(path + "/ORUser_" + util.getProjectProperty().getSubSysId() + ".sql")}<#t>
    <#list dbusers as dbuser>
        <#local name = dbuser.getName()>
-- 删除用户 ${name}
declare
	v_rowcount integer;
begin
	select count(*)
	into v_rowcount
	from dual
	where exists
		(
			select * from all_users a where a.username = upper('${name}')
		);
	if v_rowcount > 0 then
		execute immediate 'DROP USER ${name} CASCADE';
	end if;
end;
/
-- 创建用户 ${name}
        <#local defaultTablespace = dbuser.getDefaultTableSpace()/> 
CREATE USER ${name} IDENTIFIED BY "${dbuser.getPassword()}"<#if stringUtil.isNotBlank(defaultTablespace)> DEFAULT TABLESPACE ${defaultTablespace}</#if> TEMPORARY TABLESPACE TEMP;
        <#local privileges = stringUtil.split(dbuser.getPrivilege(), ",")/>
        <#if privileges?size != 0>
-- 用户 ${name} 赋权限
        </#if>
        <#list privileges as privilege> 
GRANT ${privilege} TO ${name};
        </#list>

    </#list>
</#macro>