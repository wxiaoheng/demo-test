<#-- JRESDelete注解对应的模板 -->
<#import "/jressql/jres_macro_common.ftl" as common/>
<#assign tableName = model.getName()>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
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
<#assign errorParamStr = ""/>
<#assign uniqueColumnAssignStr = "">
<#assign hasOFlagColumn = false/>
<#assign setValueStatements = ""/>
<#assign indexNum = 1/>
<#list columns as column>
    <#assign columnMark = column.getMark()/>
    <#if columnMark?upper_case?index_of("O") != -1>
        <#assign hasOFlagColumn = true/>
        <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>
            <#assign uniqueColumnAssignStr += " and "/>
        </#if>
        <#assign columnName = column.getName()/>
        <#assign camelColumnName = stringUtil.toCamelCase(columnName, true)/>
        <#assign errorParamStr += ".setParam(" + stringUtil.toUpperCase(columnName) + ", " + camelColumnName + ")"/>
        <#assign uniqueColumnAssignStr += columnName + "=?"/>
        <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, column.getRealDataType("java"), camelColumnName)/>
        <#assign indexNum++/>
    </#if>
</#list>
<#assign tableIndex = model.getIndexs()>
<#assign inputParam = "">
<#assign delRemarkStr = "\"删除${tableName}:">
<#assign hasUniqueIndex = false/>
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#if (uniqueColumnStr?size) != 0>
            <#assign hasUniqueIndex = true/>
            <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>
                <#assign uniqueColumnAssignStr += " and "/>
            </#if>
        </#if>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign camelUniqueColumnName = stringUtil.toCamelCase(uniqueColumnName, true)/>
            <#assign capUniqueColumnName = stringUtil.toUpperCase(uniqueColumnName)>
            <#assign uniqueColumnAssignStr = uniqueColumnAssignStr + uniqueColumnName + "=?">
            <#assign errorParamStr = errorParamStr + ".setParam(" + capUniqueColumnName + ", " + camelUniqueColumnName + ")"/>
            <#assign inputParam += camelUniqueColumnName>
            <#assign delRemarkStr = delRemarkStr + capUniqueColumnName + "=\"+" + camelUniqueColumnName>
            <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, reference.getRealDataType(uniqueColumnName, "java"), camelUniqueColumnName)/>
            <#assign indexNum++/>
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
                <#assign inputParam += ",">
                <#assign delRemarkStr += "+\",">
            </#if>
        </#list>
    </#if>
</#list>
<#if !hasUniqueIndex>
    <#assign delRemarkStr += "\"">
</#if>
${builder.addImport("com.hundsun.broker.base.BaseDAO")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#assign sql = "delete from "+tableName+" where "+uniqueColumnAssignStr>
    final String sql = "${sqlUtil.format(sql)}";
    if (exists${capTableNameFirst}(${inputParam})) {
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
        opRemark.append(${delRemarkStr});
        opRemark.append(";");
        return new ResultInfo(opRemark.toString(), 0L);		
    } else {
        throw new UfBaseException(ErrorConsts.ERR_BASE_NO_DATA_FOUND).setTableName("${tableName}")${errorParamStr};
    }