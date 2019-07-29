<#--
HEPType:数据库表
HEPName:生成MySQL数据库表SQL
-->
<#import "db_gensql_macro.ftl" as mysql>
<#import "gen_history_comment.ftl" as history>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成MySQL全量脚本取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@mysql.genTableCreateSql4MySQL tableInfo = model/>
<#else>
	<#-- 调用宏指令 -->
	<@main element/>
</#if>
<#-- 生成逻辑的主方法，ele为用户选择的对象，可能为文件夹，可能为文件资源 -->
<#macro main ele>
	<#-- 判断选择对象是文件夹还是表资源 -->
	<#if util.isFolder(ele)>
		<#local tableResources = util.getAllResources(ele)>
        <@history.genMultiTablesHistoryComment tableResources/>

        <#local isFilePathSet = false/>
		<#list tableResources as tableResource>
			<#local tableInfo = tableResource.getInfo()>
            <#if !isFilePathSet>
		        ${fileUtil.setFile(path + "/" + tableInfo.getSchema() + "_mysql.sql")}<#t>
                <#local isFilePathSet = true/>
            </#if>
			<#local tableName = tableInfo.getName()>
			-- begin 表${tableName}全量脚本<#lt>
			<@mysql.genTableCreateSql4MySQL tableInfo = tableInfo/>
			-- end 表${tableName}全量脚本<#lt>


		</#list>
	<#else>
		<#local tableInfo = ele.getInfo()>
        <@history.genSingleTableHistoryComment tableInfo/>
		${fileUtil.setFile(path + "/" + tableInfo.getName() + "_mysql.sql")}
		<@mysql.genTableCreateSql4MySQL tableInfo = tableInfo/>
	</#if>
</#macro>