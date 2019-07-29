<#-- 生成insert方法体，model为表模型， addValue表示自定义addValue参数，为空则全表字段插入，beanName表示insert方法的参数，为空则为表实体，sqlName则表示sql的变量名称 -->
<#macro genInsertBody model,addValue, beanName, sqlName>
    <#assign tableName = model.getName()>
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
    <#assign columns = model.getColumns()>
    <#assign columnStr = "">
    <#assign columnValueStr = "">
    <#assign setValueStatements = ""/>
    <#assign indexNum = 1/>
    <#list columns as column>
        <#assign columnName = column.getName()>
        <#assign columnStr += columnName>
        <#assign defValue = column.getRealDataDefValue(sqlUtil.getDbType())>
        <#assign realDataType = column.getRealDataType("java")>
         <#-- 增加空保护-->
        <#if realDataType == "String" || realDataType == "Character">
       		<#assign columnValueStr += "hs_nvl(?,"+defValue+")">
        <#elseif columnName == "curr_date">
	        <#assign columnValueStr += "hs_date_int()"/>
    	<#elseif columnName == "curr_time">
	        <#assign columnValueStr += "hs_time_int()"/>
        <#elseif columnName == "curr_milltime">
	        <#assign columnValueStr += "hs_timestamp_int(3)"/>
        <#else>
        	<#assign columnValueStr += "?">
        </#if>
        <#if column?has_next>
            <#assign columnStr += ",">
            <#assign columnValueStr += ",">
        </#if>
        <#if (columnName == "curr_date" || columnName == "curr_time" || columnName == "curr_milltime")>
            <#continue>
        </#if>
        <#assign setValueStatements += genSetValueBindingStatement(indexNum, realDataType, firstLowerCapTableName + ".get" + stringUtil.toCamelCase(columnName) + "()")/>
        <#assign indexNum++/>
    </#list>
    <#assign errorParamStr = ""/>
    <#assign tableIndex = model.getIndexs()>
    <#assign inputGetParam = "">
    <#assign addRemarkStr = "\"增加${tableName}:">
    <#assign hasUniqueIndex = false/>
    <#list tableIndex as index>
        <#assign isUnique = index.isUnique()>
        <#assign mark = index.getMark()>
        <#if isUnique && mark!="H">
            <#assign uniqueColumnStr = index.getColumns()>
            <#if (uniqueColumnStr?size) gt 0>
                <#assign hasUniqueIndex = true/>
            </#if>
            <#list uniqueColumnStr as uniqueColumn>
                <#assign uniqueColumnName = uniqueColumn.getName()>
                <#assign capUniqueColumnName = uniqueColumnName>
                <#assign inputGetParam = inputGetParam + beanName + ".get" + stringUtil.toCamelCase(uniqueColumnName) + "()">            
                <#-- 错误参数 -->
                <#assign errorParamStr += ".setParam(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + beanName + ".get" + stringUtil.toCamelCase(uniqueColumnName) + "())"/>
                <#assign addRemarkStr = addRemarkStr + capUniqueColumnName + "=\"+" + beanName + ".get" + stringUtil.toCamelCase(uniqueColumnName) + "()">
                <#if uniqueColumn?has_next>
                    <#assign inputGetParam += ",">
                    <#assign addRemarkStr += "+\",">
                </#if>	
            </#list>
            <#break>
        </#if>
    </#list>
    <#if !hasUniqueIndex>
        <#assign addRemarkStr += "\"">
    </#if>
    <#if stringUtil.isNotBlank(addValue)>
        <#assign setValueStatements = addValue>
    </#if>
    <#if stringUtil.isBlank(sqlName)>
    <#assign sql = sqlUtil.convertSql("insert into "+tableName+"("+columnStr+") values("+columnValueStr+")")>
    final String sql = "${sqlUtil.format(sql)}";
    </#if>
    if (exists${capTableNameFirst}(${inputGetParam})) {
        throw new UfBaseException(ErrorConsts.ERR_BASE_RECORD_EXISTS).setTableName("${tableName}")${errorParamStr};
    } else {
        this.jdbcTemplate.update(() -> new UfBaseException(<#rt>
    <#if stringUtil.isEmpty(defaultError)>
        ErrorConsts.ERR_BASE_DAO<#t>
    <#else>
        ${defaultError}<#t>
    </#if>
    )<#t>
    <#if errors??>
        <#list errors?keys as key>
            .setError(${key}, ${errors[key]})<#t>
        </#list>
    </#if>
    <#-- 用户自定义了错误参数，就用用户自定义的，否则用唯一索引字段作为错误参数 -->
    <#if params?? && params?size != 0>
        <#list params as param>
            <#assign trimParam=param?trim/>
            .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
        </#list>
    <#else>
        ${errorParamStr}<#t>
    </#if>
.setTableName("${tableName}"), sql, new PreparedStatementSetter() {
                @Override
                public void setValues(PreparedStatement ps) throws SQLException {
                    ${setValueStatements}<#rt>
                }
        });
        StringBuilder opRemark = new StringBuilder();
        opRemark.append(${addRemarkStr});
        opRemark.append(";");
        long serialNo = 0L;
        return new ResultInfo(opRemark.toString(), serialNo);
    }
</#macro>


<#-- 生成一条PreparedStatementSetter中的setValues方法的set语句 -->
<#function genSetValueBindingStatement indexNum realDataType valueExpression>
    <#if (realDataType == "Character")>
        <#local setValueStatement = "ps.setString(" + indexNum + ",JRESStringUtils.valueOf(" + valueExpression + "));\r\n"/>
    <#elseif (realDataType == "Integer")>
        <#local setValueStatement = "ps.setInt(" + indexNum + "," + valueExpression + ");\r\n"/>
    <#else>
        <#local setValueStatement = "ps.set" + realDataType + "(" + indexNum + "," + valueExpression + ");\r\n"/>
    </#if>
    <#return setValueStatement/>
</#function>


<#-- 生成一个表达式，该表达式代表SQL语句中对应位置上?参数的值 -->
<#function genVarArgsBindingStatement realDataType valueExpression>
    <#if (realDataType == "Character")>
        <#local varArgsStatement = ",JRESStringUtils.valueOf(" + valueExpression + ")"/>
    <#else>
        <#local varArgsStatement = "," + valueExpression/>
    </#if>
    <#return varArgsStatement/>
</#function>