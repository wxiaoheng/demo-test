<#import "/jressql/jres_macro_common.ftl" as common/>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getResourceGroupId(ftl)>
${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
<#if 参数列表?size == 1>
    <#assign sql = 参数列表[0]/>
    <#if stringUtil.isBlank(errorTable)>
        <#assign errorTable = sqlUtil.getTableName(sql)/>
    </#if>
    <#if (params?size == 0)>
        <#assign whereIndex = sql?index_of(" where ")/>
        <#if (whereIndex gt -1)>
            <#assign params = sqlUtil.getConditions(sql[whereIndex..])/>
        </#if>
    </#if>
    <#assign conditions = sqlUtil.getConditions(sql, false)>
    <#assign setValueStatements = ""/>
    <#assign indexNum = 1/>
    <#list conditions as key>
        <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), method.getMatchParam(key))>
        <#assign indexNum++/>
    </#list>
    final String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
    return this.jdbcTemplate.update(() -> new UfBaseException(<#rt>
    <#if stringUtil.isEmpty(defaultError)>
        ErrorConsts.ERR_BASE_DAO<#t>
    <#else>
        ${defaultError}<#t>
    </#if>
    )<#t>
    <#list errors?keys as key>
        .setError(${key}, ${errors[key]})<#t>
    </#list>
    <#list params as param>
        <#assign trimParam=param?trim/>
        .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
    </#list>
    .setTableName("${errorTable}")<#t>
    , sql, new PreparedStatementSetter() {<#lt>
            @Override
            public void setValues(PreparedStatement ps) throws SQLException {
                ${setValueStatements}<#rt>
            }
        });
<#else/>
    <#assign tableName=参数列表[0]>
    <#if (params?size == 0)>
        <#assign params = sqlUtil.getConditions(参数列表[2])/>
    </#if>
    <#-- 如果表名包含下划线，去除前缀 -->
    <#if stringUtil.indexOf(tableName,"_") gte 0>
        <#assign withoutPrefixTableName = tableName?keep_after("_")>
    <#else>
        <#assign withoutPrefixTableName = tableName>
    </#if>
    <#-- 表名去下划线 -->
    <#assign firstLowerCapTableName = stringUtil.replace(withoutPrefixTableName,"_","")>
    <#-- 类名首字母大写 -->
    <#assign capTableNameFirst = stringUtil.toUpperCase(firstLowerCapTableName,1)>
    <#assign capTableName = stringUtil.toUpperCase(tableName)>
    <#-- 需要拼接的更新字段键值对 -->
    <#assign updateMap=stringUtil.convertKVString(参数列表[1])>
    <#-- 完整的更新字段字符串 -->
    <#assign updateStr=参数列表[3]/>
    <#assign sql="update "+tableName+" set ">
    <#-- 直接把完整的更新字段字符串拼到SQL后面 -->
    <#if stringUtil.isNotBlank(updateStr)>
        <#assign sql+=updateStr/>
        <#if (updateMap?size) != 0>
            <#assign sql+=", "/>
        </#if>
    </#if>
    <#-- 遍历更新字段 -->
    <#list updateMap?keys as key>
        <#assign defValue = reference.getDefValue(key,sqlUtil.getDbType())>
        <#assign realDataType = reference.getRealDataType(key,"java")>    
        <#assign realValue=key>
        <#if stringUtil.isBlank(updateMap[key])>
            <#-- 更新字段做空保护 -->
            <#assign sql = columnNullProtect(sql,key,key,defValue,realDataType)>        
        <#elseif stringUtil.startsWith(updateMap[key], ":")>
            <#assign param = stringUtil.substring(updateMap[key], 1)>
            <#assign sql = columnNullProtect(sql,key,param,defValue,realDataType)>
        <#else>
            <#assign sql = sql + key + "=" + updateMap[key]>          
        </#if>
    <#if key?has_next>
            <#assign sql += ",">
        </#if>
	</#list>
    <#assign sql += " where " + (参数列表[2])/>
    <#assign conditions = sqlUtil.getConditions(sql, false)/>
    <#assign setValueStatements = ""/>
    <#assign indexNum = 1/>
    <#list conditions as key>
        <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), method.getMatchParam(key))>
        <#assign indexNum++/>
    </#list>
    <#assign sql = sqlUtil.convertSql(sqlUtil.replaceVariantRefToPlaceholder(sql))>

    final String sql = "${sqlUtil.format(sql)}";
    return this.jdbcTemplate.update(() -> new UfBaseException(<#rt>
    <#if stringUtil.isEmpty(defaultError)>
        ErrorConsts.ERR_BASE_DAO<#t>
    <#else>
        ${defaultError}<#t>
    </#if>
    )<#t>
    <#list errors?keys as key>
        .setError(${key}, ${errors[key]})<#t>
    </#list>
    <#list params as param>
        <#assign trimParam=param?trim/>
        .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
    </#list>
    .setTableName("${tableName}"), sql, new PreparedStatementSetter() {<#lt>
            @Override
            public void setValues(PreparedStatement ps) throws SQLException {
                ${setValueStatements}<#rt>
            }
        });
</#if>

<#-- 新增、更新字段做空保护 -->
<#function columnNullProtect sql,key,value,defValue, realDataType>
    <#if stringUtil.equalsIgnoreCase(realDataType,"String") || stringUtil.equalsIgnoreCase(realDataType,"Character")>       
        <#local sql = sql + key + "=hs_nvl(:"+value+","+defValue+")"/>    
    <#elseif stringUtil.equalsIgnoreCase(key, "curr_date")>
        <#local sql = sql + key + "=hs_nvl(:"+value+","+"hs_date_int()"+")"/>        
    <#elseif stringUtil.equalsIgnoreCase(key, "curr_time")>
        <#local sql = sql + key + "=hs_nvl(:"+value+","+"hs_time_int()"+")"/>             
    <#else>
        <#local sql = sql + key + "= :"+value>
    </#if>
    <#return sql>
</#function>