<#-- JRESSelect注解对应的模板 -->
<#import "/jressql/jres_macro_common.ftl" as common/>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
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
<#assign returnValueAssignStr = "">
<#list columns as column>
    <#assign columnName = column.getName()>
    <#assign columnStr += columnName>
    <#assign primitiveDataType = column.getRealDataType("java")>
    <#-- 字段名转驼峰 -->
    <#assign camelColumnName = stringUtil.toCamelCase(columnName, false)>
    <#if (variable!primitiveDataType)=="Character">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerCapTableName + ".set" + camelColumnName + "(rs.getString(" + stringUtil.toUpperCase(columnName) + ").charAt(0));">
    <#elseif (variable!primitiveDataType)=="Integer">
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerCapTableName + ".set" + camelColumnName + "(rs.getInt(" + stringUtil.toUpperCase(columnName) + "));">
    <#else>
        <#assign returnValueAssignStr += "\t\t\t\t\t\t" + firstLowerCapTableName + ".set" + camelColumnName + "(rs.get" + primitiveDataType + "(" + stringUtil.toUpperCase(columnName) + "));">
    </#if>
    <#if column?has_next>
        <#assign columnStr += ",">
        <#assign returnValueAssignStr += "\r\n">
    </#if>
</#list>
<#assign uniqueColumnAssignStr = "">
<#assign errorParamStr = ""/>
<#assign tableIndex = model.getIndexs()>
<#assign varArgsStatements = ""/>
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign camelUniqueColumnName = stringUtil.toCamelCase(uniqueColumnName, true)/>
            <#assign uniqueColumnAssignStr += uniqueColumnName + "=?">
            <#assign errorParamStr = errorParamStr + ".setParam(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + camelUniqueColumnName + ")"/>
            <#assign varArgsStatements += common.genVarArgsBindingStatement(reference.getRealDataType(uniqueColumnName, "java"), camelUniqueColumnName)/>
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
            </#if>	
        </#list>
    </#if>
</#list>
${builder.addImport("com.hundsun.broker.base.constant.ErrorEnum")}
${builder.addImport("org.springframework.jdbc.core.RowMapper")}
${builder.addImport("java.sql.ResultSet")}
${builder.addImport("java.sql.SQLException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#assign sql = "select "+columnStr+" from "+tableName+" where "+uniqueColumnAssignStr>
    final String sql = "${sqlUtil.format(sql)}";
    return this.jdbcTemplate.queryForObject(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND).setTableName("${tableName}")${errorParamStr}, sql, new RowMapper<${capTableNameFirst}>() {
                    @Override
                    public ${capTableNameFirst} mapRow(ResultSet rs, int rowNum) throws SQLException {
                        ${capTableNameFirst} ${firstLowerCapTableName} = new ${capTableNameFirst}();
                        ${returnValueAssignStr}<#lt>
                        return ${firstLowerCapTableName};
                    }
                }${varArgsStatements});