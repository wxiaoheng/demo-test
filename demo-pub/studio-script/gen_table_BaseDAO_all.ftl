<#-- 
HEPType:数据库表
HEPName:一键生成所有数据库表BaseDAO
-->
<#-- 构造要执行的模板脚本的数组 -->
<#assign files = ["gen_table_BaseDAO.ftl"]>
<#assign map = util.getMap() + {"fileUtil", fileUtil}/>
<#-- 判断选择对象是文件夹还是表资源 -->
<#assign tableResources = reference.getHEPElements("table")>
<#list tableResources as tableResource>
	<#-- 执行数组中配置的脚本 -->
	${util.executeFreeMarkers(files, tableResource, tableResource.getInfo(), map)}
</#list>