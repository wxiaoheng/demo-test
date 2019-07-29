<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
    ${util.dialog('生成MySQL数据库用户SQL取消！')}<#t>
<#else>
    <#-- 调用宏指令 -->
    <@main model.getDatabaseModels()/>
</#if>
<#-- 生成逻辑的主方法，dbusers为数据库用户列表 -->
<#macro main databases>
    ${fileUtil.setFile(path + "/MySQLUser_" + util.getProjectProperty().getSubSysId() + ".sql")}<#t>
    <#list databases as database>
        <#local name = database.getName()>
        <#local charset = database.getCharset()/>
        <#local password = database.getPassword()/>
-- 创建数据库${name}
CREATE DATABASE IF NOT EXISTS ${name}<#if stringUtil.isNotBlank(charset)> DEFAULT CHARACTER SET ${charset}</#if>;
-- 创建用户${name}
GRANT USAGE ON ${name}.* to '${name}'@'%' IDENTIFIED BY '${password}';
GRANT USAGE ON ${name}.* to '${name}'@'localhost' IDENTIFIED BY '${password}';

    </#list>
</#macro>