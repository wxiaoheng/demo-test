<#import "/jressql/jres_macro_common.ftl" as common/>
<#assign tableName=参数列表[0]>
<#assign model = reference.getTableInfo(tableName)>
<#assign resource = reference.getTableElement(tableName)>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getResourceGroupId(ftl)>
<#-- 如果表名包含下划线，去除前缀 -->
<#if stringUtil.indexOf(tableName,"_") gte 0>
    <#assign withoutPrefixTableName = tableName?keep_after("_")>
<#else>
    <#assign withoutPrefixTableName = tableName>
</#if>
<#-- 接口方法的返回类型名-->
<#assign returnName = method.getReturn()>
<#-- 接口方法的返回类型是否为包装类型-->
<#assign returnPackageType = stringUtil.isPackageType(returnName)>
<#-- 序列名 -->
<#assign sequenceName = 参数列表[1]>

<#-- 查询全表所有字段 -->
<#assign columns = model.getColumns()>
<#assign columnStr = "">
<#assign columnValueStr = "">
<#assign setValueStatements = ""/>
<#assign indexNum = 1/>
<#list columns as column>
    <#assign columnName = column.getName()>
    <#assign columnStr += columnName>
    <#assign columnValueStr += "?">
    <#assign setValueStatements += common.genSetValueBindingStatement(indexNum, column.getRealDataType("java"), stringUtil.toCamelCase(columnName, true))/>
    <#assign indexNum++/>
    <#if column?has_next>
        <#assign columnStr += ",">
        <#assign columnValueStr += ",">
    </#if>
</#list>

<#-- 查询表唯一索引 -->
<#assign tableIndex = model.getIndexs()>
<#assign inputGetParam = "">
<#assign hasUniqueIndex = false/>
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumns = index.getColumns()>
    </#if>
</#list>


<#-- 更新SQL语句 -->
<#assign updateSql ="update " + tableName + " set serial_counter_value = serial_counter_value + 1 where sequence_name = '" + sequenceName + "'">
<#-- 查询SQL语句 -->
<#assign selectSql = "select serial_counter_value from " + tableName + " where sequence_name = '" + sequenceName +"'">
<#-- 新增SQL语句 -->
<#assign insertSql = sqlUtil.format("insert into " + tableName + "(" + columnStr + ") values (" + columnValueStr + ")")>
<#-- 重置SQL语句 -->
<#assign resetSql = "update " + tableName + " set serial_counter_value = 0 where sequence_name = '" + sequenceName + "'">

<#-- sql变量名，下划线+大写 -->
<#assign updateSqlName= "updateSql">
<#assign selectSqlName= "selectSql">
<#assign insertSqlName= "insertSql">
<#assign resetSqlName= "resetSql">

${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorEnum")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.broker.base.AppContext")}
    
    String ${updateSqlName} = "${updateSql}";
    String ${selectSqlName} = "${selectSql}";
    String ${resetSqlName} = "${resetSql}";
    
    Long serialNo = AppContext.getTransactionTemplate().execute((status) -> {
        Long serialNoTs = 0L;
        int serialCounterEnd = 1000000000;
        <#list uniqueColumns as column>
        String ${stringUtil.toCamelCase(column.getName(), true)} = "${sequenceName}";
        </#list>
        
        int rows = this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
    <#list uniqueColumns as column>
        .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
    </#list>
, ${updateSqlName});
   
        if (rows <= 0) {
            final String ${insertSqlName} = "${insertSql}";
            int serialCounterValue = 1;
                
            try {
                this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
            <#list uniqueColumns as column>
                .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
            </#list>
, ${insertSqlName}, new PreparedStatementSetter() {
                    @Override
                    public void setValues(PreparedStatement ps) throws SQLException {
                        ${setValueStatements}<#rt>
                    }
                });
                serialNoTs = 1L;
            } catch (UfBaseException e) {
                if (ErrorEnum.DUP_VAL_ON_INDEX == e.getErrorEnum()) {                    
                    rows = this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
                    <#list uniqueColumns as column>
                        .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
                    </#list>
, ${updateSqlName});
                    serialNoTs = this.jdbcTemplate.queryForObject(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
                    <#list uniqueColumns as column>
                        .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
                    </#list>
,
                                  ${selectSqlName}, <#rt>
                    <#if returnPackageType>
${returnName}.class);
                    </#if>
                    
                    if (serialNoTs >= serialCounterEnd) {
                        this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
                                <#list uniqueColumns as column>
                                    .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
                                </#list>
                            , ${resetSqlName});
                    }
                } else {
                    throw e;
                }
            }
        } else {
            serialNoTs = this.jdbcTemplate.queryForObject(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
            <#list uniqueColumns as column>
                .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
            </#list>
, ${selectSqlName}, <#rt>
            <#if returnPackageType>
${returnName}.class);
            </#if>
            
            if (serialNoTs >= serialCounterEnd) {
                this.jdbcTemplate.update(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO).setError(ErrorEnum.DUP_VAL_ON_INDEX, ErrorConsts.ERR_BASE_DUP_VAL_ON_INDEX).setError(ErrorEnum.NO_DATA_FOUND, ErrorConsts.ERR_BASE_NO_DATA_FOUND)<#rt>
                        <#list uniqueColumns as column>
                            .setParam("${column.getName()}", ${stringUtil.toCamelCase(column.getName(), true)})<#t>
                        </#list>
                    , ${resetSqlName});
            }
        }
        return serialNoTs;
    });
    
    return serialNo;