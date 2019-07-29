<#include "/jressql/jres_macro_common.ftl"/>
<#assign isMySql = (sqlUtil.getDbType() == "db_mysql")?then(true, false)/>
<#-- 宏的sql语句 -->
<#assign sql = 参数列表[0]>
<#if (params?size == 0)>
    <#-- 包含字段变量（比如:user_id）的str -->
    <#assign includeVariableStr=参数列表[0]/>
    <#if (stringUtil.isNotBlank(参数列表[3]))>
        <#assign includeVariableStr += " " + 参数列表[3]/>
    </#if>
    <#if (stringUtil.isNotBlank(参数列表[4]))>
        <#assign includeVariableStr += " " +  参数列表[4]/>
    </#if>
    <#assign params = sqlUtil.getConditions(includeVariableStr)/>
</#if>
<#assign limit="">
<#assign kvMap=stringUtil.convertKVString(参数列表[1])>
<#list kvMap?keys as key>
    <#if stringUtil.equalsIgnoreCase(key, "rownum")>
        <#assign limit=kvMap[key]>
    </#if>
</#list>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#-- sql的返回字段列表 -->
<#assign returns = "">
<#if (参数列表?size) gte 3 && stringUtil.isNotBlank(参数列表[2])>
    <#assign returns = stringUtil.split(参数列表[2], ",")/>
<#else>
    <#assign returns = sqlUtil.getReturns(sql)/>
</#if>
<#-- 自定义的查询条件列表-->
<#assign customConditionMap = util.getMap()/>
<#if (参数列表?size) gte 5>
    <#assign customConditionMap = stringUtil.convertKVString(参数列表[4])/>
</#if>
<#-- 分组排序等放到SQL结尾的语句-->
<#assign groupOrderByStatement = stringUtil.isBlank(参数列表[5])?then("", " " + 参数列表[5])/>
<#-- sql语句，将：XXX替换成?-->
<#-- 拼接确定的条件语句到sql中  -->
<#if stringUtil.isNotBlank(参数列表[3])>
    <#assign sql += " where " + 参数列表[3]?trim/>
</#if>
<#-- addValue语句-->
<#assign addValue="">
<#-- 获取sql中所有：xxx -->
<#assign conditions = sqlUtil.getConditions(sql)>
<#-- 遍历所有的需要条件字段-->
<#list conditions as con>
    <#-- 将：XXX替换成? -->
    <#-- addValue语句 -->
    <#assign addValue = addValue+".addValue(\""+con+"\", "+(method.getConditionRealDataType(con) == "Character")?string('JRESStringUtils.valueOf('+method.getMatchParam(con)+')',method.getMatchParam(con))+")">
</#list>
<#-- 接口方法的返回类型名-->
<#assign returnType = method.getReturn()>
<#-- 返回值是否包含泛型 -->
<#assign isGenericType = stringUtil.indexOf(returnType,"<") gte 0>
<#if isGenericType>
    <#-- 返回类型名中的泛型-->
    <#assign genericType = method.getGenericType(returnType)>
<#else>
    <#-- 泛型即为返回值类型 -->
    <#assign genericType = returnType>
</#if>
<#-- 判断返回类型中的泛型是否为包装类型和String-->
<#assign returnPackageType = stringUtil.isPackageType(genericType)>
<#-- 首字母小写的泛型名-->
<#assign firstLowerGenericType = genericType?uncap_first>
<#-- 从查询结果ResultSet获取返回值的语句-->
<#assign returnValueAssignStr = "">
<#list returns as columnName>
    <#assign trimColumnName = columnName?trim/>
    <#-- 字段名转驼峰 -->
    <#assign camelColumnName = stringUtil.toCamelCase(trimColumnName, false)>
    <#-- 获取该字段在Java中对应的类型 -->
    <#assign primitiveDataType = reference.getRealDataType(trimColumnName, "java")>
    <#if (variable!primitiveDataType)=="Character">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerGenericType + ".set" + camelColumnName + "(rs.getString(\"" + trimColumnName + "\").charAt(0));">
    <#elseif (variable!primitiveDataType)=="Integer">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerGenericType + ".set" + camelColumnName + "(rs.getInt(\"" + trimColumnName + "\"));">
    <#else>
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerGenericType + ".set" + camelColumnName + "(rs.get" + primitiveDataType + "(\"" + trimColumnName + "\"));">
    </#if>
    <#if columnName?has_next>
        <#assign returnValueAssignStr += "\r\n">
    </#if>
</#list>
<#assign realRowNum="">
<#-- 支持参数传入,用：形式 -->
<#if stringUtil.startsWith(limit,":")>
    <#assign realRowNum=method.getMatchParam(limit)>
<#else>
    <#assign realRowNum=limit>
</#if>
${builder.addImport("org.springframework.jdbc.core.namedparam.MapSqlParameterSource")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("org.springframework.jdbc.core.RowMapper")}
${builder.addImport("java.sql.ResultSet")}
${builder.addImport("java.sql.SQLException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorEnum")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#-- 真实代码 -->
UfBaseException exc = new UfBaseException(<#rt>
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
;
<#if (customConditionMap?size) != 0>
    StringBuilder builder = new StringBuilder("${sql}");
    <#-- 如果没有写确定条件，为了拼接后面的自定义条件，需要加where 1=1，否则如果只加where关键字，那么在运行时当后面的if语句都没有进去的情况下，sql就变成了不完整的语句，jdbc执行会报错 -->
    <#if stringUtil.isBlank(参数列表[3])>
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
    String sql = builder.toString();
    <#if (isMySql)>
        <#assign sqlSelect = "sql + \""+groupOrderByStatement+" limit :rownum\"">
    <#else/>
        <#assign sqlSelect = "\"select * from (\" + sql + \""+groupOrderByStatement+") where rownum <= :rownum\"">
    </#if>
    sql = ${sqlUtil.format(sqlSelect)};
    MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addValue};
    mapSqlParameterSource.addValue("rownum", ${realRowNum});

    <#if returnPackageType>
        <#if isGenericType>
        return this.namedParameterJdbcTemplate.queryForList(exc, sql, mapSqlParameterSource, ${genericType}.class);
        <#else>
        return this.namedParameterJdbcTemplate.queryForObject(exc, sql, mapSqlParameterSource, ${genericType}.class);
        </#if>
    <#else>
        return this.namedParameterJdbcTemplate.query<#if !isGenericType>ForObject</#if>(exc, sql, mapSqlParameterSource,<#rt>
     new RowMapper<${genericType}>() {
         @Override
        public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
            ${genericType} ${firstLowerGenericType} = new ${genericType}();
            ${returnValueAssignStr}<#lt>
            return ${firstLowerGenericType};
        }
    });
    </#if>
<#else/>
    <#-- 非动态拼接方式 -->
    <#if (isMySql)>
        <#assign sqlSelect = "\""+sql+groupOrderByStatement+" limit :rownum\"">
    <#else/>
        <#assign sqlSelect = "\"select * from ("+sql+groupOrderByStatement+") where rownum <= :rownum\"">
    </#if>
    <#assign allConds = sqlUtil.getConditions(sqlSelect, false)>
    <#assign setValueStatements="">
    <#assign varArgsStatements="">
    <#assign indexNum = 1>
    <#list allConds as con>
        <#assign realValue = "">
        <#assign realType = "">
        <#if stringUtil.equals("rownum", con)>
            <#assign realValue = realRowNum>
            <#assign realType = "Integer">
        <#else>
            <#assign realValue = method.getMatchParam(con)>
            <#assign realType = method.getConditionRealDataType(con)>
        </#if>
        <#assign setValueStatements += genSetValueBindingStatement(indexNum, realType, realValue)/>
        <#assign indexNum+=1>
        <#assign varArgsStatements += genVarArgsBindingStatement(realType, realValue)/>
    </#list>
    String sql = ${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sqlSelect))};
    <#if !isGenericType>
        <#if returnPackageType>
            <#-- 返回非List包装类型与String对象 -->
            return this.jdbcTemplate.queryForObject(()->exc, sql, ${genericType}.class ${varArgsStatements});
        <#else>
            <#-- 返回非List普通实体对象 -->
            return this.jdbcTemplate.queryForObject(()->exc, sql, new RowMapper<${genericType}>() {
                        @Override
                        public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
                            ${genericType} ${firstLowerGenericType} = new ${genericType}();
                            ${returnValueAssignStr}<#lt>
                            return ${firstLowerGenericType};
                        }
                    } ${varArgsStatements});
        </#if>
    <#elseif returnPackageType>
        <#-- 返回List<包装类型> 形式 -->
        return this.jdbcTemplate.queryForList(()->exc, sql, ${genericType}.class ${varArgsStatements});
    <#else>
        <#-- 返回List<对象> 形式 -->
        return this.jdbcTemplate.query(()->exc, sql, new PreparedStatementSetter(){
            @Override
            public void setValues(PreparedStatement ps) throws SQLException {
                ${setValueStatements}<#rt>
            }
        },
     new RowMapper<${genericType}>() {
                        @Override
                        public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
                            ${genericType} ${firstLowerGenericType} = new ${genericType}();
                            ${returnValueAssignStr}<#lt>
                            return ${firstLowerGenericType};
                        }
                    });
    </#if>
</#if>