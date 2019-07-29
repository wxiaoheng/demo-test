<#-- 
HEPType:虚拟表
HEPName:虚拟表一键生成微服务代码
-->
<#-- 构造要执行的模板脚本的数组 -->
<#assign files = ["gen_table_controller.ftl", "gen_table_service.ftl", "gen_table_service_impl.ftl"]>
<#-- 判断选择对象是文件夹还是表资源 -->
<#if util.isFolder(element)>
	<#assign tableResources = util.getAllResources(element)>
	<#list tableResources as tableResource>
		<#-- 执行数组中配置的脚本 -->
		${util.executeFreeMarkers(files, tableResource, tableResource.getInfo(), util.getMap())}
	</#list>
<#else>
	<#-- 执行数组中配置的脚本 -->
	${util.executeFreeMarkers(files, element, model, util.getMap())}
</#if>