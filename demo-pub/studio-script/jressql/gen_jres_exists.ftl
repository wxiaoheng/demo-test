<#-- JRESExists注解对应的Oracle语法的模板 -->
<#import "/jressql/jres_macro_common.ftl" as common/>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
<#assign tableInfo = element.getInfo()>
<#assign tableName = element.getInfo().getName()>
<#assign capTableName = stringUtil.toUpperCase(tableName)>
<#-- 如果表名包含下划线，去除前缀 -->
<#if stringUtil.indexOf(tableName,"_") gte 0>
    <#assign withoutPrefixTableName = tableName?keep_after("_")>
<#else>
    <#assign withoutPrefixTableName = tableName>
</#if>
 <#-- 表名去下划线 -->
<#assign firstLowerCapTableName = stringUtil.replace(withoutPrefixTableName,"_","")>

<#assign capTableName = stringUtil.toUpperCase(tableName)>
<#assign uniqueColumnAssignStr = "">
<#assign errorParamStr = ""/>
<#assign varArgsStatements = ""/>
<#assign tableIndex = tableInfo.getIndexs()>
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign camelUniqueColumnName = stringUtil.toCamelCase(uniqueColumnName,true)/>
            <#assign uniqueColumnAssignStr += uniqueColumnName + "=?">
            <#assign errorParamStr += ".setParam(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + camelUniqueColumnName + ")"/>
            <#assign varArgsStatements += common.genVarArgsBindingStatement(reference.getRealDataType(uniqueColumnName, "java"), camelUniqueColumnName)/>
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
            </#if>	
        </#list>
    </#if>
</#list>
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#if (sqlUtil.getDbType() == "db_mysql")>
    <#assign sql = "select exists (select 1 from " + tableName + " where " + uniqueColumnAssignStr + ")">
<#else>
    <#assign sql = "select count(0) from dual where exists (select 1 from " + tableName + " where " + uniqueColumnAssignStr + ")">
</#if>
    final String sql = "${sqlUtil.format(sql)}";
    return this.jdbcTemplate.queryForObject(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setTableName("${tableName}")${errorParamStr}, sql, Boolean.class${varArgsStatements});