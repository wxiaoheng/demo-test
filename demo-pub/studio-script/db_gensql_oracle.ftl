<#--
HEPType:数据库表
HEPName:生成Oracle数据库表SQL
-->
<#import "db_gensql_macro.ftl" as oracle>
<#import "gen_history_comment.ftl" as history>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('生成Oracle全量脚本取消！')}<#t>
<#elseif stringUtil.equals(path, "PREVIEW")>
	<#-- 预览模式，直接生成代码，不生成文件 -->
	<@oracle.genTableCreateSql4Oracle tableInfo = model/>
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
		        ${fileUtil.setFile(path + "/" + tableInfo.getSchema() + "_oracle.sql")}<#t>
                <#local isFilePathSet = true/>
            </#if>
			<#local tableName = tableInfo.getName()>
			-- begin 表${tableName}全量脚本<#lt>
			<@oracle.genTableCreateSql4Oracle tableInfo = tableInfo/>
			-- end 表${tableName}全量脚本<#lt>


		</#list>
	<#else>
		<#local tableInfo = ele.getInfo()>
        <@history.genSingleTableHistoryComment tableInfo/>
		${fileUtil.setFile(path + "/" + tableInfo.getName() + "_oracle.sql")}
		<@oracle.genTableCreateSql4Oracle tableInfo = tableInfo/>
	</#if>
</#macro>