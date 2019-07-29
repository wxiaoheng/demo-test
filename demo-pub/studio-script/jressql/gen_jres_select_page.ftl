<#-- JRESSelectList注解对应的模板 -->
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
<#assign tableIndex = model.getIndexs()>
<#assign inputParam = "">
<#list tableIndex as index>
	<#assign isUnique = index.isUnique()>
	<#assign mark = index.getMark()>
	<#if isUnique && mark!="H">
		<#assign uniqueColumnStr = index.getColumns()>
		<#list uniqueColumnStr as uniqueColumn>
			<#assign inputParam += uniqueColumn.getName()>
			<#if uniqueColumn?has_next>
				<#assign inputParam += ",">
			</#if>
		</#list>
	</#if>
</#list>
${builder.addImport("com.hundsun.broker.base.repository.QueryPage")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#if (sqlUtil.getDbType() == "db_mysql")>
    <#assign sqlList = "select "+columnStr+" from "+tableName+" order by "+inputParam+" asc limit ?,?">
<#else>
    <#assign sqlList = "select "+columnStr+" from (select rownum as row_num,a.* from "+tableName+" a order by "+inputParam+" asc) b where row_num > ? and row_num <= ?">
</#if>
<#assign sqlCount = "select count(0) from "+tableName>
	final String sqlList = "${sqlUtil.format(sqlList)}";
	final String sqlCount = "${sqlUtil.format(sqlCount)}";
	UfBaseException exc = new UfBaseException(ErrorConsts.ERR_BASE_DAO).setTableName("${tableName}");
	QueryPage<${capTableNameFirst}> queryPage = new QueryPage<${capTableNameFirst}>();
	queryPage.setCurrentPage(pageNo);
	queryPage.setTotal(this.jdbcTemplate.queryForObject(() -> exc, sqlCount, Integer.class));
	queryPage.setRows(this.jdbcTemplate.query(() -> exc, sqlList, new PreparedStatementSetter() {
                @Override
                public void setValues(PreparedStatement ps) throws SQLException {
                    ps.setInt(1, (pageNo - 1) * pageSize);
                    ps.setInt(2, pageSize);
                }
            },
			new RowMapper<${capTableNameFirst}>() {
					@Override
					public ${capTableNameFirst} mapRow(ResultSet rs, int rowNum) throws SQLException {
						${capTableNameFirst} ${firstLowerCapTableName} = new ${capTableNameFirst}();
						${returnValueAssignStr}<#lt>
						return ${firstLowerCapTableName};
					}
				}));
	return queryPage;