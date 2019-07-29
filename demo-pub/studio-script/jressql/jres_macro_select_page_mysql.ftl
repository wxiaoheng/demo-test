<#import "/jressql/jres_macro_common.ftl" as common/>
<#-- 宏的sql语句 -->
<#assign sql= 参数列表[0]>
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
<#-- 是否需要setTotal和setCurrentPage，打了N标记就不set -->
<#assign needSetTotalAndCurrentPage = (macroFlag?index_of("N") == -1)?then(true,false)/>
<#assign pageNo="">
<#assign pageSize="">
<#assign limit="">
<#assign kvMap=stringUtil.convertKVString(参数列表[1])>
<#list kvMap?keys as key>
    <#if stringUtil.equalsIgnoreCase(key, "rownum")>
        <#assign limit=kvMap[key]>
    <#elseif stringUtil.equalsIgnoreCase(key, "pageNo")>
        <#assign pageNo=kvMap[key]>
    <#elseif stringUtil.equalsIgnoreCase(key, "pageSize")>
        <#assign pageSize=kvMap[key]>
    <#else>
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
    <#-- addValue语句 -->
    <#assign addValue = addValue+".addValue(\""+con+"\", "+(method.getConditionRealDataType(con) == "Character")?string('JRESStringUtils.valueOf('+method.getMatchParam(con)+')',method.getMatchParam(con))+")">
</#list>
<#-- 接口方法的返回类型名-->
<#assign returnType = method.getReturn()>
<#-- 返回类型名中的泛型-->
<#assign genericType = method.getGenericType(returnType)>
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
${builder.addImport("com.hundsun.broker.base.repository.QueryPage;")}
${builder.addImport("org.springframework.jdbc.core.namedparam.MapSqlParameterSource")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("org.springframework.jdbc.core.RowMapper")}
${builder.addImport("java.sql.ResultSet")}
${builder.addImport("java.sql.SQLException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#if returnPackageType>
${builder.addImport("org.springframework.jdbc.core.BeanPropertyRowMapper")}
</#if>
<#-- 真实代码 -->
<#if (customConditionMap?size) != 0>
    StringBuilder builder = new StringBuilder("${sqlUtil.format(sql)}");
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
<#else/>
    String sql = "";
</#if>
<#if needSetTotalAndCurrentPage>
    <#assign sqlCountTotal = "select count(0) from (">
    <#if (customConditionMap?size) != 0>
        <#assign sqlCountTotal = sqlCountTotal+"\" + sql + \""+") tmp">
    <#else>
        <#assign sqlCountTotal = sqlCountTotal+sql+") tmp">
    </#if>
    <#-- 如果存在动态条件 ，则使用jdbcTemplate-->
    <#if (customConditionMap?size) == 0>
        <#assign varArgsStatements = ""/>
        <#assign sqlCountTotalConditions = sqlUtil.getConditions(sqlCountTotal,false)>
        <#assign sqlCountTotal = sqlUtil.replaceVariantRefToPlaceholder(sqlCountTotal)>
        <#list sqlCountTotalConditions as con>
            <#assign varArgsStatements += common.genVarArgsBindingStatement(method.getConditionRealDataType(con), method.getMatchParam(con))/>                
        </#list>   
    </#if>	
    final String sqlCountTotal = "${sqlUtil.format(sqlCountTotal)}";
</#if>
    <#if (customConditionMap?size) != 0>
    MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addValue};
    </#if>
    UfBaseException exc = new UfBaseException(<#rt>
<#if stringUtil.isEmpty(defaultError)>
    ErrorConsts.ERR_BASE_DAO<#t>
<#else>
    ${defaultError}<#t>
</#if>
)<#rt>
<#list errors?keys as key>
    .setError(${key}, ${errors[key]})<#t>
</#list>
<#list params as param>
    <#assign trimParam=param?trim/>
    .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
</#list>
<#if stringUtil.isNotBlank(errorTable)>
    .setTableName("${errorTable}")<#t>
</#if>
;
    ${returnType} queryPage = new ${returnType}();
<#if needSetTotalAndCurrentPage>
    <#if (customConditionMap?size) != 0>
    queryPage.setTotal(this.namedParameterJdbcTemplate.queryForObject(exc, sqlCountTotal,
            mapSqlParameterSource, Integer.class));
    <#else>
    queryPage.setTotal(this.jdbcTemplate.queryForObject(() -> exc, sqlCountTotal, Integer.class
        ${varArgsStatements}));
    </#if>
</#if>
<#if stringUtil.isNotBlank(pageNo)>
    <#-- 真实pageNo -->
    <#assign realNo = "">
    <#if stringUtil.startsWith(pageNo,":")>
        <#assign realNo = method.getMatchParam(pageNo)>
    <#else>
        <#assign realNo = pageNo>
    </#if>
    <#-- 真实pageSize -->
    <#assign realSize = "">
    <#if stringUtil.startsWith(pageSize,":")>
        <#assign realSize = method.getMatchParam(pageSize)>
    <#else>
        <#assign realSize = pageSize>
    </#if>
    
    <#assign sqlSelect = "">
    <#assign sqlSelect1 = "">
    <#if (customConditionMap?size) != 0>
        <#assign sqlSelect = "sql + \""+groupOrderByStatement+" limit :start, :end\"">
        <#assign sqlSelect1 = "sql + \""+groupOrderByStatement+" limit :rownum\"">
    <#else>
        <#assign sqlSelect = "\""+sql+groupOrderByStatement+" limit :start, :end\"">
        <#assign sqlSelect1 = "\""+sql+groupOrderByStatement+" limit :rownum\"">
    </#if>
    <#-- 如果不存在动态条件，将 rowMapper单独提取出来-->
    <#if (customConditionMap?size) == 0>
        <#if !returnPackageType>
     RowMapper<${genericType}> rowMapper = new RowMapper<${genericType}>() {
        @Override
        public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
           ${genericType} ${firstLowerGenericType} = new ${genericType}();
           ${returnValueAssignStr}<#lt>
           return ${firstLowerGenericType};
        }
    };  
        </#if>
    </#if>
    if (${realNo} > 0) {
        <#-- 如果不存在动态条件 ，则使用jdbcTemplate-->
        <#if (customConditionMap?size) == 0>
            <#assign varArgsStatements = ""/>
            <#assign sqlSelectConditions = sqlUtil.getConditions(sqlSelect,false)>
            <#assign sqlSelect = sqlUtil.replaceVariantRefToPlaceholder(sqlSelect)>
            <#list sqlSelectConditions as con>
                <#if (con == "start" || con == "end")>
                    <#assign varArgsStatements += common.genVarArgsBindingStatement("Integer", con)/>
                <#else/>
                    <#assign varArgsStatements += common.genVarArgsBindingStatement(method.getConditionRealDataType(con), method.getMatchParam(con))/>
                </#if>
            </#list>
        sql = ${sqlUtil.format(sqlSelect)};
        int start = (${realNo} - 1) * ${realSize};
        int end = ${realSize};
        queryPage.setRows(this.jdbcTemplate.query(() -> exc, sql, <#if returnPackageType>BeanPropertyRowMapper.newInstance(${genericType}.class)<#else>rowMapper</#if>${varArgsStatements}));
        <#else>  
        sql = ${sqlUtil.format(sqlSelect)};
        mapSqlParameterSource.addValue("start", (${realNo} - 1) * ${realSize}).addValue("end", ${realSize});        
        </#if>
    } else {
        <#-- 如果不存在动态条件 ，则使用jdbcTemplate-->
        <#if (customConditionMap?size) == 0>
            <#assign varArgsStatements = ""/>
            <#assign sqlSelect1Conditions = sqlUtil.getConditions(sqlSelect1,false)>
            <#assign sqlSelect1 = sqlUtil.replaceVariantRefToPlaceholder(sqlSelect1)>
            <#list sqlSelect1Conditions as con>
                <#if stringUtil.equals("rownum", con)>
                    <#assign realValue = realRowNum>
                    <#assign realType = "Integer">
                <#else>
                    <#assign realValue = method.getMatchParam(con)>
                    <#assign realType = method.getConditionRealDataType(con)>
                </#if>
                <#assign varArgsStatements += common.genVarArgsBindingStatement(realType, realValue)/>                    
            </#list> 
        sql = ${sqlUtil.format(sqlSelect1)}; 
        queryPage.setRows(this.jdbcTemplate.query(() -> exc, sql, <#if returnPackageType>BeanPropertyRowMapper.newInstance(${genericType}.class)<#else>rowMapper</#if>${varArgsStatements}));                
        <#else>
        sql = ${sqlUtil.format(sqlSelect1)};
        mapSqlParameterSource.addValue("rownum", ${realRowNum});                
        </#if>
    }
    <#if needSetTotalAndCurrentPage>
    queryPage.setCurrentPage(${realNo});
    </#if>
<#else>
    <#assign sqlBlank = "">
    <#if (customConditionMap?size) != 0>
        <#assign sqlBlank = "sql + \""+groupOrderByStatement+" limit :rownum\"">
    <#else>
        <#assign sqlBlank = "\""+sql+groupOrderByStatement+" limit :rownum\"">
    </#if>
    <#-- 如果不存在动态条件 ，则使用jdbcTemplate-->
    <#if (customConditionMap?size) == 0>
        <#assign varArgsStatements = ""/>
        <#assign sqlBlankConditions = sqlUtil.getConditions(sqlBlank,false)>
        <#assign sqlBlank = sqlUtil.replaceVariantRefToPlaceholder(sqlBlank)>
        <#list sqlBlankConditions as con>
            <#if stringUtil.equals("rownum", con)>
                <#assign realValue = realRowNum>
                <#assign realType = "Integer">
            <#else>
                <#assign realValue = method.getMatchParam(con)>
                <#assign realType = method.getConditionRealDataType(con)>
            </#if>
            <#assign varArgsStatements += common.genVarArgsBindingStatement(realType, realValue)/>                
        </#list> 
    sql = ${sqlUtil.format(sqlBlank)};    
    queryPage.setRows(this.jdbcTemplate.query(() -> exc, sql, <#if returnPackageType>BeanPropertyRowMapper.newInstance(${genericType}.class)<#else>
            new RowMapper<${genericType}>() {
                    @Override
                    public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
                        ${genericType} ${firstLowerGenericType} = new ${genericType}();
                        ${returnValueAssignStr}<#lt>
                        return ${firstLowerGenericType};
                    }
                }</#if>${varArgsStatements}));
    <#else>
    sql = ${sqlUtil.format(sqlBlank)};
    mapSqlParameterSource.addValue("rownum");    
    </#if>
</#if>
<#if (customConditionMap?size) != 0>
    queryPage.setRows(this.namedParameterJdbcTemplate.query(exc, sql, mapSqlParameterSource,<#rt>
    <#if returnPackageType>
 BeanPropertyRowMapper.newInstance(${genericType}.class)));
    <#else>
            
            new RowMapper<${genericType}>() {
                    @Override
                    public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
                        ${genericType} ${firstLowerGenericType} = new ${genericType}();
                        ${returnValueAssignStr}<#lt>
                        return ${firstLowerGenericType};
                    }
                }));
    </#if>
</#if>
    return queryPage;