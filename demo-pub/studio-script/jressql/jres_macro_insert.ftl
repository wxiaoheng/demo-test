<#import "/jressql/jres_macro_common.ftl" as common>
<#assign tableName = 参数列表[0]>
<#-- sql变量名，下划线+大写 -->
<#assign sqlName= "sql"+ stringUtil.toUpperCase(method.getName(), 1)>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#assign resource=reference.getTableElement(tableName)>
<#-- sql -->
<#assign sql = "insert into "+tableName+"(">
<#-- 字段列表语句-->
<#assign cols="">
<#-- 值语句-->
<#assign values="">
<#-- addValue语句-->
<#assign addValue="">

<#assign beanName=method.getParamNames()[0]>

<#assign colMap = stringUtil.convertKVString(参数列表[1])>
<#assign indexNum = 1>
 <#list colMap?keys as key>
 	<#-- 代码空保护 -->
	<#assign defValue = reference.getDefValue(key,sqlUtil.getDbType())>
	<#assign realDataType = reference.getRealDataType(key,"java")>
	<#assign cols = cols + key>
	<#if stringUtil.isBlank(colMap[key])>
		<#-- addValue语句 -->
		<#assign values = columnNullProtect(values,key,defValue,realDataType)>
		<#assign addValue += common.genSetValueBindingStatement(indexNum, reference.getRealDataType(key, "java"), method.getMatchParam(key))>
 	<#elseif stringUtil.startsWith(colMap[key], ":")>
 		<#assign param = stringUtil.substring(colMap[key], 1)>
        <#assign values = columnNullProtect(values,param,defValue,realDataType)>
		<#-- addValue语句 -->
		<#assign addValue += common.genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), method.getMatchParam(param))>
 	<#else>
 		<#-- addValue语句 --> 		
 		<#assign values = values + "?">
 		<#assign addValue += common.genSetValueBindingStatement(indexNum, reference.getRealDataType(key, "java"), colMap[key])>
 	</#if>
 	<#assign indexNum += 1>
    <#if key?has_next>
		<#assign cols += ",">
		<#assign values += ",">
	</#if>
</#list>
<#assign sql = sqlUtil.convertSql (sql+cols+") values("+values+")")>
<#-- 需要import的包 -->
${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.broker.base.repository.support.ResultInfo")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}

final String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
<@common.genInsertBody resource.getInfo(),addValue, beanName, sqlName/>

<#-- 新增、更新字段做空保护 -->
<#function columnNullProtect values,column,defValue, realDataType>
    <#if stringUtil.equalsIgnoreCase(realDataType,"String") || stringUtil.equalsIgnoreCase(realDataType,"Character")>       
        <#local values = values + "hs_nvl(?,"+defValue+")"/>  
    <#elseif stringUtil.equalsIgnoreCase(column, "curr_date")>
        <#local values = values + "hs_date_int()"/>
    <#elseif stringUtil.equalsIgnoreCase(column, "curr_time")>
        <#local values = values + "hs_time_int()"/>    
    <#elseif stringUtil.equalsIgnoreCase(column, "curr_milltime")>
        <#local values = values + "hs_timestamp_int(3)"/>           
    <#else>
        <#local values = values + ":"+column>
    </#if>
    <#return values>
</#function>