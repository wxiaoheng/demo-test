<#--
HEPType:序列
HEPName:生成序列SQL
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成数据库访问类取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@genSql model/>
<#else>
	<#-- 调用宏指令 -->
	<@main element/>
</#if>
<#-- 生成逻辑的主方法，ele为用户选择的对象，可能为文件夹，可能为文件资源 -->
<#macro main ele>
	<#-- 判断选择对象是文件夹还是表资源 -->
	<#if util.isFolder(ele)>
		${fileUtil.setFile(path + "/" + ele.getName() + "_sequence.sql")}<#t>
		<#local resources = util.getAllResources(ele)>
		<#list resources as res>
			<#local info = res.getInfo()>
			<#local name = info.getName()>
			-- begin 序列${name}脚本<#lt>
			<@genSql info/>
			-- end 序列${name}脚本<#lt>


		</#list>
	<#else>
		<#local info = ele.getInfo()>
		${fileUtil.setFile(path + "/" + info.getName() + "_sequence.sql")}
		<@genSql info/>
	</#if>
</#macro>

<#macro genSql info>
    <#local isDB2 = util.testDBType("db2")>
    <#if isDB2>
CREATE SEQUENCE "${info.getName()}" AS ${info.getDataType()}
<@genDB2 info/>
    <#else>
CREATE SEQUENCE ${info.getName()}
<@genOracle info/>
    </#if>

<#if info.isHistory()>
    <#if isDB2>
CREATE SEQUENCE "his_${info.getName()}" AS ${info.getDataType()}
<@genDB2 info/>
    <#else>
CREATE SEQUENCE his_${info.getName()}
<@genOracle info/>
    </#if>
</#if>
</#macro>

<#macro genDB2 info>
START WITH ${info.getStart()}
INCREMENT BY ${info.getIncrement()}
    <#if stringUtil.isBlank(info.getMinValue())>
NO MINVALUE
    <#else>
MINVALUE ${info.getMinValue()}
    </#if>
    <#if stringUtil.isBlank(info.getMaxValue())>
NO MAXVALUE
    <#else>
MAXVALUE ${info.getMaxValue()}
    </#if>
<#if !info.isCycle()>NO </#if>CYCLE <#if !info.isOrder()>NO </#if>ORDER 
<#if info.isUseCache()>CACHE ${info.getCache()}<#else>NO CACHE</#if>;
    <#if stringUtil.isNotBlank(info.getDescription())>
COMMENT ON SEQUENCE "${info.getName()}" IS '${info.getDescription()}';
    </#if>
</#macro>

<#macro genOracle info>
INCREMENT BY ${info.getIncrement()}
START WITH ${info.getStart()}
MAXVALUE ${info.getMaxValue()}
<#if info.isCycle()>CYCLE <#else>NOCYCLE</#if>
<#if info.isUseCache()>CACHE ${info.getCache()} <#else>NOCACHE </#if>;
</#macro>