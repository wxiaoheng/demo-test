<#--
HEPType:数据库表
HEPName:生成DB2数据库表增量SQL
-->
<#import "db_gensql_macro.ftl" as db2>
<#import "gen_history_comment.ftl" as history>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成DB2数据库表增量SQL取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@db2.genTablePatchSql4DB2 tableInfo = model/>
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

		<#list tableResources as tableResource>
			<#local tableInfo = tableResource.getInfo()>
			<#local tableName = tableInfo.getName()>
			<#if !isFilePathSet>
		        ${fileUtil.setFile(path + "/" + stringUtil.createJoiner("_").add(ele.getName()).add(tableInfo.getSchema()).toString() + "_db2_patch.sql")}<#t>
                <#local isFilePathSet = true/>
            </#if>
			-- begin 表${tableName}增量脚本<#lt>
			<@db2.genTablePatchSql4DB2 tableInfo = tableInfo/>
			-- end 表${tableName}增量脚本<#lt>


		</#list>
	<#else>
		<#local tableInfo = ele.getInfo()>
        <@history.genSingleTableHistoryComment tableInfo/>
		${fileUtil.setFile(path + "/" + tableInfo.getName() + "_db2_patch.sql")}<#t>
		<@db2.genTablePatchSql4DB2 tableInfo = tableInfo/>
	</#if>
</#macro>