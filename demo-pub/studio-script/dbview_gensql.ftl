<#--
HEPType:初始数据
HEPName:生成数据库视图SQL
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@genSql model/>
</#if>

<#macro genSql info>
SELECT 'CREATE or REPLACE VIEW ${info.getName()}-${info.getChineseName()}...';
CREATE or REPLACE VIEW ${info.getName()} as
${info.getSql()}
</#macro>