<#-- 
HEPType:数据库表
HEPName:数据库一键生成微服务代码
-->
<#-- 构造要执行的模板脚本的数组 -->
<#assign files = ["entity.ftl","gen_table_BaseDAO.ftl", "gen_table_DAO.ftl", "gen_table_controller.ftl", "gen_table_service.ftl", "gen_table_service_impl.ftl"]>
<#assign map = util.getMap() + {"fileUtil", fileUtil}/>
<#-- 判断选择对象是文件夹还是表资源 -->
<#if util.isFolder(element)>
	<#assign tableResources = util.getAllResources(element)>
	<#list tableResources as tableResource>
		<#-- 执行数组中配置的脚本 -->
		${util.executeFreeMarkers(files, tableResource, tableResource.getInfo(), map)}
	</#list>
<#else>
	<#-- 执行数组中配置的脚本 -->
	${util.executeFreeMarkers(files, element, model, util.getMap())}
</#if>