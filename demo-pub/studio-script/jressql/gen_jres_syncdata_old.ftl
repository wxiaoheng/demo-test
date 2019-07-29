<#-- JRESSyncData注解对应的模板 -->
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
<#assign uniqueColumnAssignStr = "">
<#assign errorParamStr = ""/>
<#assign addValueStr = "">
<#-- 唯一索引字段addValue语句，即作为where条件的字段的addValue语句，其值是从message消息中获取的 -->
<#assign addUniqueColumnValueStrFromIndexMap = ""/>
<#assign hasOFlagColumn = false/>
<#list columns as column>
    <#assign columnName = column.getName()>
    <#assign columnStr += columnName>
    <#assign columnValueStr += ":" + columnName>
    <#assign addValueStr += ".addValue(" + stringUtil.toUpperCase(columnName) + ", " + (column.getRealDataType("java") == "Character")?string('JRESStringUtils.valueOf('+firstLowerCapTableName+'.get'+stringUtil.toCamelCase(columnName)+'())',firstLowerCapTableName+'.get'+stringUtil.toCamelCase(columnName)+'()') + ")">
    <#if column?has_next>
        <#assign columnStr += ",">
        <#assign columnValueStr += ",">
    </#if>
</#list>
<#assign tableIndex = model.getIndexs()>
<#assign inputGetParam = "">
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign uniqueColumnType = reference.getRealDataType(uniqueColumnName, "java")/>
            <#assign uniqueColumnAssignStr = uniqueColumnAssignStr + uniqueColumnName + "=:" + uniqueColumnName>
            <#assign errorParamStr = errorParamStr + ".setParam(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + "indexMap.get(" + stringUtil.toUpperCase(uniqueColumnName) + "))"/>
            <#assign inputGetParam += (uniqueColumnType == "Character")?string('JRESStringUtils.charAt((String) indexMap.get(' + stringUtil.toUpperCase(uniqueColumnName) + '), 0)', '(' + uniqueColumnType + ') indexMap.get(' + stringUtil.toUpperCase(uniqueColumnName) + ')')>
            <#assign addUniqueColumnValueStrFromIndexMap += ".addValue(" + stringUtil.toUpperCase(uniqueColumnName) + ", " + (uniqueColumnType == "Character")?string('JRESStringUtils.valueOf(indexMap.get(' + stringUtil.toUpperCase(uniqueColumnName) + '))', 'indexMap.get(' + stringUtil.toUpperCase(uniqueColumnName) + ')') + ")">
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
                <#assign inputGetParam += ", ">
            </#if>	
        </#list>
    </#if>
</#list>
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}<#t>
${builder.addImport("com.hundsun.broker.base.mq.MessageInfo")}<#t>
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}<#t>
${builder.addImport("java.util.Map")}<#t>
<#assign sqlDelete = "delete from "+tableName+" where "+uniqueColumnAssignStr>
<#assign sqlInsert = "insert into "+tableName+"("+columnStr+") values("+columnValueStr+")">
    Object data = message.getData();
    Map<String, Object> indexMap = message.getIndexes();

    if (data == null) {
        final String sqlDelete${capTableNameFirst} = "${sqlUtil.format(sqlDelete)}";
        MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addUniqueColumnValueStrFromIndexMap};
        this.namedParameterJdbcTemplate.update(
                    new UfBaseException(ErrorConsts.ERR_BASE_SYNC_DATA).setTableName("${tableName}")${errorParamStr},
                    sqlDelete${capTableNameFirst}, mapSqlParameterSource);
    } else {
        @SuppressWarnings("unchecked")
        Map<String, Object> dataMap = (Map<String, Object>) data;
        if (exists${capTableNameFirst}(${inputGetParam})) {
            StringBuilder builder = new StringBuilder("update ${tableName} set ");
            MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource();
            boolean isAppended = false;
<#assign columnIndex = 0/>
<#list columns as column>
    <#assign columnName = column.getName()/>
            if (dataMap.containsKey(${stringUtil.toUpperCase(columnName)})) {
    <#if (columnIndex != 0)>
                if (isAppended) {
        			builder.append(",");
        		}
    </#if>
                builder.append("${columnName}=:${columnName}");
                isAppended = true;
                mapSqlParameterSource.addValue(${stringUtil.toUpperCase(columnName)}, <#if (reference.getRealDataType(columnName, "java") == "Character")>JRESStringUtils.valueOf(dataMap.get(${stringUtil.toUpperCase(columnName)}))<#else>dataMap.get(${stringUtil.toUpperCase(columnName)})</#if>);
            }
    <#assign columnIndex += 1/>
</#list>
            final String sqlUpdate${capTableNameFirst} = builder.append(" where ${uniqueColumnAssignStr}").toString();
            mapSqlParameterSource${addUniqueColumnValueStrFromIndexMap};
            this.namedParameterJdbcTemplate.update(
                    new UfBaseException(ErrorConsts.ERR_BASE_SYNC_DATA).setTableName("${tableName}")${errorParamStr},
                    sqlUpdate${capTableNameFirst}, mapSqlParameterSource);
        } else {
            final String sqlInsert${capTableNameFirst} = "${sqlUtil.format(sqlInsert)}";
            ${capTableNameFirst} ${firstLowerCapTableName} = new ${capTableNameFirst}();
<#list columns as column>
    <#assign columnName = column.getName()/>
    <#assign firstUpperCapColumnName = stringUtil.toCamelCase(columnName, false)/>
    <#assign columnRealDataType = reference.getRealDataType(columnName, "java")/>
            if (dataMap.containsKey(${stringUtil.toUpperCase(columnName)})) {
                ${firstLowerCapTableName}.set${firstUpperCapColumnName}(<#if (columnRealDataType == "Character")>JRESStringUtils.charAt((String) dataMap.get(${stringUtil.toUpperCase(columnName)}), 0)<#else/>(${columnRealDataType}) dataMap.get(${stringUtil.toUpperCase(columnName)})</#if>);
            }
</#list>
            MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addValueStr};
            this.namedParameterJdbcTemplate.update(
                    new UfBaseException(ErrorConsts.ERR_BASE_SYNC_DATA).setTableName("${tableName}")${errorParamStr},
                    sqlInsert${capTableNameFirst}, mapSqlParameterSource);
        }
    }
  }