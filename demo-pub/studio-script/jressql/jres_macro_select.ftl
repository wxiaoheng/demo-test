<#include "/jressql/jres_macro_common.ftl"/>
<#-- 宏的sql语句 -->
<#assign sql= 参数列表[0]>
<#if (params?size == 0)>
    <#-- 包含字段变量（比如:user_id）的str -->
    <#assign includeVariableStr=参数列表[0]/>
    <#if (stringUtil.isNotBlank(参数列表[2]))>
        <#assign includeVariableStr += " " + 参数列表[2]/>
    </#if>
    <#if (stringUtil.isNotBlank(参数列表[3]))>
        <#assign includeVariableStr += " " +  参数列表[3]/>
    </#if>
    <#assign params = sqlUtil.getConditions(includeVariableStr)/>
</#if>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#-- sql的返回字段列表 -->
<#assign returns = "">
<#if (参数列表?size) gte 2 && stringUtil.isNotBlank(参数列表[1])>
    <#assign returns = stringUtil.split(参数列表[1], ",")/>
<#else>
    <#assign returns = sqlUtil.getReturns(sql)/>
</#if>
<#-- 自定义的查询条件列表-->
<#assign customConditionMap = util.getMap()/>
<#if (参数列表?size) gte 4>
    <#assign customConditionMap = stringUtil.convertKVString(参数列表[3])/>
</#if>
<#-- 分组排序等放到SQL结尾的语句-->
<#assign groupOrderByStatement = stringUtil.isBlank(参数列表[4])?then("", " " + 参数列表[4])/>
<#-- 接口方法的返回类型名-->
<#assign returnName = method.getReturn()>
<#-- 接口方法的返回类型是否为包装类型-->
<#assign returnPackageType = stringUtil.isPackageType(returnName)>
<#-- 首字母小写的返回类型名-->
<#assign firstLowerReturnName = returnName?uncap_first>
<#-- 从查询结果ResultSet获取返回值的语句-->
<#assign returnValueAssignStr = "">
<#list returns as columnName>
    <#assign trimColumnName = columnName?trim/>
    <#-- 字段名转驼峰 -->
    <#assign camelColumnName = stringUtil.toCamelCase(trimColumnName, false)>
    <#assign primitiveDataType = reference.getRealDataType(trimColumnName, "java")>
    <#if (variable!primitiveDataType)=="Character">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerReturnName + ".set" + camelColumnName + "(rs.getString(\"" + trimColumnName + "\").charAt(0));">
    <#elseif (variable!primitiveDataType)=="Integer">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerReturnName + ".set" + camelColumnName + "(rs.getInt(\"" + trimColumnName + "\"));">
    <#else>
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerReturnName + ".set" + camelColumnName + "(rs.get" + primitiveDataType + "(\"" + trimColumnName + "\"));">
    </#if>
    <#if columnName?has_next>
        <#assign returnValueAssignStr += "\r\n">
    </#if>
</#list>
<#-- 拼接确定的条件语句到sql中  -->
<#if stringUtil.isNotBlank(参数列表[2])>
    <#assign sql += " where " + 参数列表[2]?trim/>
</#if>
<#-- addValue语句-->
<#assign addValue="">
<#-- 获取sql中所有：xx字段，包括重复的 -->
<#assign allConditions = sqlUtil.getConditions(sql,false)>
<#-- 遍历所有的需要条件字段-->
<#list conditions as con>
    <#-- addValue语句 -->
    <#assign addValue = addValue+".addValue(\""+con+"\", "+(method.getConditionRealDataType(con) == "Character")?string('JRESStringUtils.valueOf('+method.getMatchParam(con)+')',method.getMatchParam(con))+")">
</#list>
<#-- 需要import的包 -->
${builder.addImport("org.springframework.jdbc.core.namedparam.MapSqlParameterSource")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorEnum")}
${builder.addImport("org.springframework.jdbc.core.RowMapper")}
${builder.addImport("java.sql.ResultSet")}
${builder.addImport("java.sql.SQLException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#if returnPackageType>
${builder.addImport("org.springframework.jdbc.core.BeanPropertyRowMapper")}
</#if>
<#-- 真实代码 -->
<#assign realSql = sql>
<#assign varArgsStatements="">
<#if (customConditionMap?size) != 0>
    String sql="${sqlUtil.format(sql)}";
    StringBuilder builder = new StringBuilder(sql);
    <#-- 如果没有写确定条件，为了拼接后面的自定义条件，需要加where 1=1，否则如果只加where关键字，那么在运行时当后面的if语句都没有进去的情况下，sql就变成了不完整的语句，jdbc执行会报错 -->
    <#if stringUtil.isBlank(参数列表[2])>
    builder.append(" where 1=1");
    </#if>
    <#list customConditionMap?keys as key>
        <#assign conditionValue = customConditionMap[key]?trim/>
        <#if stringUtil.isEmpty(conditionValue)>
            <#assign realValue = method.getMatchParam(key)/>
    if (<#if reference.getRealDataType(key, "java") == "String">JRESStringUtils.isNotEmpty(${realValue})<#else/>${realValue} != null</#if>) {
        <#-- 前面肯定要有and，因为无论有没有填写确定的条件，都会有where子句 -->
        builder.append(" and ${key}=:${key}");
    }
            <#assign addValue += ".addValue(\"" + key + "\", " + (reference.getRealDataType(key, "java") == "Character")?string('JRESStringUtils.valueOf(' + realValue + ')', realValue) + ")"/>
        <#elseif conditionValue?starts_with(":")/>
            <#assign realValue = method.getMatchParam(conditionValue)/>
    if (<#if method.getConditionRealDataType(conditionValue) == "String">JRESStringUtils.isNotEmpty(${realValue})<#else/>${realValue} != null</#if>) {
        <#-- 前面肯定要有and，因为无论有没有填写确定的条件，都会有where子句 -->
        builder.append(" and ${key}=${conditionValue}");
    }
            <#assign addValue += ".addValue(\"" + stringUtil.substring(conditionValue, 1) + "\", " + (method.getConditionRealDataType(conditionValue) == "Character")?string('JRESStringUtils.valueOf(' + realValue + ')', realValue) + ")"/>
        <#else>
        <#-- 前面肯定要有and，因为无论有没有填写确定的条件，都会有where子句 -->
    builder.append(" and ${key}=${conditionValue}");
        </#if>
    </#list>
    sql = builder.toString();
    sql += "${groupOrderByStatement}";
    MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addValue};
    return this.namedParameterJdbcTemplate.<#rt>
<#else>
    <#-- 非动态拼接的sql -->
    <#assign realSql += groupOrderByStatement>
    <#assign allConds = sqlUtil.getConditions(realSql, false)>
    <#assign realSql = sqlUtil.replaceVariantRefToPlaceholder(realSql)>
    <#list allConds as con>        
        <#assign varArgsStatements += genVarArgsBindingStatement(method.getConditionRealDataType(con), method.getMatchParam(con))/>
    </#list>
    String sql="${sqlUtil.format(realSql)}";
    return this.jdbcTemplate.<#rt>
</#if>
    queryForObject(<#t>
<#if (customConditionMap?size) == 0>()-></#if>new UfBaseException(<#t>
<#if stringUtil.isEmpty(defaultError)>
    ErrorConsts.ERR_BASE_DAO<#t>
<#else>
    ${defaultError}<#t>
</#if>
)<#rt>
<#if (errors?size) gt 0>
    <#list errors?keys as key>
        .setError(${key}, ${errors[key]})<#t>
    </#list>
<#else/>
    .setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#t>
</#if>
<#list params as param>
    <#assign trimParam=param?trim/>
    .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
</#list>
<#if stringUtil.isNotBlank(errorTable)>
    .setTableName("${errorTable}")<#t>
</#if>
, sql,<#t>
<#if (customConditionMap?size) != 0> 
mapSqlParameterSource,<#rt>
</#if>
<#if returnPackageType>
 ${returnName}.class<#if (customConditionMap?size) == 0>${varArgsStatements}</#if>);
<#else>

                new RowMapper<${returnName}>() {
                    @Override
                    public ${returnName} mapRow(ResultSet rs, int rowNum) throws SQLException {
                        ${returnName} ${firstLowerReturnName} = new ${returnName}();
                        ${returnValueAssignStr}<#lt>
                        return ${firstLowerReturnName};
                    }
                }<#if (customConditionMap?size) == 0>${varArgsStatements}</#if>);
</#if>