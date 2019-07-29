<#-- JRESUpdate注解对应的模板 -->
<#import "/jressql/jres_macro_common.ftl" as common/>
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
<#assign columnAssignStr = "">
<#assign uniqueColumnAssignStr = "">
<#assign errorParamStr = ""/>
<#assign addValueStr = "">
<#assign setValueStatements = ""/>
<#assign indexNum = 1/>
<#assign oFlagColumnList = []/>
<#assign hasOFlagColumn = false/>
<#list columns as column>
    <#assign columnName = column.getName()>
    <#if (columnName == "curr_date" || columnName == "curr_time" || columnName == "curr_milltime")>
        <#continue>
    </#if>
    <#assign camelColumnName = stringUtil.toCamelCase(columnName)/>
    <#assign columnMark = column.getMark()/>
	<#assign defValue = column.getRealDataDefValue(sqlUtil.getDbType())>
	<#assign realDataType = column.getRealDataType("java")>
    <#if columnMark?upper_case?index_of("O") != -1>
        <#assign hasOFlagColumn = true/>
        <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>
            <#assign uniqueColumnAssignStr += " and "/>
        </#if>
        <#if columnName == "update_date">
            <#assign columnAssignStr += columnName + "=hs_date_int()"/>
        <#elseif columnName == "update_time">
            <#assign columnAssignStr += columnName + "=hs_time_int()"/>
        <#else/>
	        <@nullProtect/>
        </#if>
        <#assign uniqueColumnAssignStr += columnName + "=?"/>
        <#assign oFlagColumnNameList += column/>
        <#assign errorParamStr += ".setParam(" + stringUtil.toUpperCase(columnName) + ", " + firstLowerCapTableName + ".get" + camelColumnName + "())"/>
    <#else/>
        <@nullProtect/>
    </#if>
    <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, column.getRealDataType("java"), firstLowerCapTableName + ".get" + camelColumnName + "()")>
    <#assign indexNum++/>
    <#if column?has_next>
        <#assign columnAssignStr += ",">
    </#if>
</#list>
<#list oFlagColumnList as column>
    <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, column.getRealDataType("java"), firstLowerCapTableName + ".get" + stringUtil.toCamelCase(columnName) + "()")>
    <#assign indexNum++/>
</#list>
<#assign tableIndex = model.getIndexs()>
<#assign inputGetParam = "">
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#if stringUtil.isNotBlank(uniqueColumnAssignStr) && (uniqueColumnStr?size) != 0>
            <#assign uniqueColumnAssignStr += " and "/>
        </#if>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign camelUniqueColumnName = stringUtil.toCamelCase(uniqueColumnName)/>
            <#assign uniqueColumnAssignStr += uniqueColumnName + "=?">
            <#assign errorParamStr = errorParamStr + ".setParam(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + firstLowerCapTableName + ".get" + camelUniqueColumnName + "())"/>
            <#assign inputGetParam = inputGetParam + firstLowerCapTableName + ".get" + camelUniqueColumnName + "()">
            <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, reference.getRealDataType(uniqueColumnName, "java"), firstLowerCapTableName + ".get" + camelUniqueColumnName + "()")>
            <#assign indexNum++/>
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
                <#assign inputGetParam += ",">
            </#if>	
        </#list>
    </#if>
</#list>
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#assign sql = sqlUtil.convertSql("update "+tableName+" set "+columnAssignStr+" where "+uniqueColumnAssignStr)>
    final String sql = "${sqlUtil.format(sql)}";
    ${capTableNameFirst} oldInfo = this.get${capTableNameFirst}(${inputGetParam});
    <#if hasOFlagColumn>int idx = </#if>this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setTableName("${tableName}")${errorParamStr}, sql, new PreparedStatementSetter() {
            @Override
            public void setValues(PreparedStatement ps) throws SQLException {
                ${setValueStatements}<#rt>
            }
        });
    <#if hasOFlagColumn>
    if (idx <= 0) {
        throw new UfBaseException(ErrorConsts.ERR_BASE_NO_DATA_FOUND).setTableName("${tableName}")${errorParamStr};
    }
    </#if>
    StringBuilder opRemark = new StringBuilder();
    opRemark.append("修改${tableName}:");
    <#list columns as column>
		updateField(${stringUtil.toUpperCase(column.getName())}, opRemark, oldInfo.get${stringUtil.toCamelCase(column.getName())}(), ${firstLowerCapTableName}.get${stringUtil.toCamelCase(column.getName())}());
    </#list>
    return new ResultInfo(opRemark.toString(), 0L);
}

private void updateField(String field, StringBuilder opRemark, Object obj1, Object obj2){
	if (!obj1.equals(obj2)) {                
		opRemark.append(field.toUpperCase()).append("=[");
        opRemark.append(obj1);
        opRemark.append("->");
        opRemark.append(obj2);
        opRemark.append("];");
    }
<#macro nullProtect>
    <#if stringUtil.equalsIgnoreCase(realDataType,"String") || stringUtil.equalsIgnoreCase(realDataType,"Character")>
        <#assign columnAssignStr += columnName + "=hs_nvl(?," + defValue + ")"/>
    <#else>
        <#assign columnAssignStr += columnName + "=?"/>
    </#if>
</#macro>