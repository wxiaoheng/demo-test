<#--
HEPType:初始数据
HEPName:生成Oracle数据库表的初始数据
-->
<#import "db_gensql_macro.ftl" as oracle>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成Oracle数据库表的初始数据取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@oracle.genTableInsertSql4Oracle resource=element info = model tableName = tableName/>
<#else>
	<#-- 调用宏指令 -->
	<@main element/>
</#if>
<#-- 生成逻辑的主方法，ele为用户选择的对象，可能为文件夹，可能为文件资源 -->
<#macro main ele>
	<#-- 判断选择对象是文件夹还是初始数据资源 -->
	<#if util.isFolder(ele)>
		<#local dataResources = util.getAllResources(ele)>
		<#local isFilePathSet = false/>
		<#list dataResources as dataResource>
			<#local info = dataResource.getInfo()>
			<#local tableName = dataResource.getCommonModelExtendValue("table-name")>
			<#if !isFilePathSet>
		        ${fileUtil.setFile(path + "/" + stringUtil.createJoiner("_").add(ele.getName()).add(oracle.getDbSchema(tableName)).toString() + "_oracle_insert.sql")}<#t>
                <#local isFilePathSet = true/>
            </#if>
			-- begin 表${tableName}初始数据脚本<#lt>
			<@oracle.genTableInsertSql4Oracle resource=dataResource info = info tableName = tableName/>
			-- end 表${tableName}初始数据脚本<#lt>


		</#list>
	<#else>
		<#local info = ele.getInfo()>
		<#local tableName = ele.getCommonModelExtendValue("table-name")>
		${fileUtil.setFile(path + "/" + tableName + "_oracle_insert.sql")}
		-- begin 表${tableName}初始数据脚本<#lt>
		<@oracle.genTableInsertSql4Oracle resource=ele info = info tableName = tableName/>
		-- end 表${tableName}初始数据脚本<#lt>
	</#if>
</#macro>