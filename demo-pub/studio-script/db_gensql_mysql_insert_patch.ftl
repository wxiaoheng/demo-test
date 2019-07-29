<#--
HEPType:初始数据
HEPName:生成MySql数据库表的初始数据增量SQL
-->
<#import "db_gensql_macro.ftl" as mysql>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成MySql数据库表的初始数据增量SQL取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@mysql.genTableInsertPatchSql4MySQL resource=element info = model tableName = tableName/>
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
		        ${fileUtil.setFile(path + "/" + stringUtil.createJoiner("_").add(ele.getName()).add(mysql.getDbSchema(tableName)).toString() + "_mysql_insert_patch.sql")}<#t>
                <#local isFilePathSet = true/>
            </#if>
			-- begin 表${tableName}初始数据增量脚本<#lt>
			<@mysql.genTableInsertPatchSql4MySQL resource=dataResource info = info tableName = tableName/>
			-- end 表${tableName}初始数据增量脚本<#lt>


		</#list>
	<#else>
		<#local info = ele.getInfo()>
		<#local tableName = ele.getCommonModelExtendValue("table-name")>
		${fileUtil.setFile(path + "/" + tableName + "_mysql_insert_patch.sql")}
		-- begin 表${tableName}初始数据增量脚本<#lt>
		<@mysql.genTableInsertPatchSql4MySQL resource=ele info = info tableName = tableName/>
		-- end 表${tableName}初始数据增量脚本<#lt>
	</#if>
</#macro>