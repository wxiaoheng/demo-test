<#include "/jressql/jres_macro_common.ftl"/>
<#-- 宏的sql语句 -->
<#assign sql= 参数列表[0]>
<#if (params?size == 0)>
    <#-- 包含字段变量（比如:user_id）的str -->
    <#assign includeVariableStr=参数列表[0]/>
    <#if (stringUtil.isNotBlank(参数列表[2]))>
        <#assign includeVariableStr += " " + 参数列表[2]/>
    </#if>
    <#if (stringUtil.isNotBlank(参数列表[3]))>
        <#assign includeVariableStr += " " +  参数列表[3]/>
    </#if>
    <#assign params = sqlUtil.getConditions(includeVariableStr)/>
</#if>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#-- sql的返回字段列表 -->
<#assign returns = "">
<#if (参数列表?size) gte 2 && stringUtil.isNotBlank(参数列表[1])>
	<#assign returns = stringUtil.split(参数列表[1], ",")/>
<#else>
	<#assign returns = sqlUtil.getReturns(sql)/>
</#if>
<#-- 自定义的查询条件列表-->
<#assign customConditionMap = util.getMap()/>
<#if (参数列表?size) gte 4>
    <#assign customConditionMap = stringUtil.convertKVString(参数列表[3])/>
</#if>
<#-- 分组排序等放到SQL结尾的语句-->
<#assign groupOrderByStatement = stringUtil.isBlank(参数列表[4])?then("", " " + 参数列表[4])/>
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
<#-- 拼接确定的条件语句到sql中  -->
<#if stringUtil.isNotBlank(参数列表[2])>
	<#assign sql += " where " + 参数列表[2]?trim/>
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
<#-- 需要import的包 -->
${builder.addImport("org.springframework.jdbc.core.namedparam.MapSqlParameterSource")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorEnum")}
${builder.addImport("org.springframework.jdbc.core.RowMapper")}
${builder.addImport("java.sql.ResultSet")}
${builder.addImport("java.sql.SQLException")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#-- 真实代码 -->
<#assign realSql = sql>
<#assign setValueStatements="">
<#assign varArgsStatements="">
<#assign indexNum = 1>
<#if (customConditionMap?size) != 0>
	String sql="${sqlUtil.format(sql)}";
	StringBuilder builder = new StringBuilder(sql);
	<#-- 如果没有写确定条件，为了拼接后面的自定义条件，需要加where 1=1，否则如果只加where关键字，那么在运行时当后面的if语句都没有进去的情况下，sql就变成了不完整的语句，jdbc执行会报错 -->
	<#if stringUtil.isBlank(参数列表[2])>
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
	sql = builder.toString();
    sql += "${groupOrderByStatement}";
	MapSqlParameterSource mapSqlParameterSource = new MapSqlParameterSource()${addValue};
	return this.namedParameterJdbcTemplate.<#rt>
<#else>
	<#-- 非动态拼接的sql -->
	<#assign realSql += groupOrderByStatement>
	<#assign allConds = sqlUtil.getConditions(realSql, false)>
	<#list allConds as con>
		<#assign setValueStatements += genSetValueBindingStatement(indexNum, method.getConditionRealDataType(con), method.getMatchParam(con))/>
		<#assign indexNum+=1>
		<#assign varArgsStatements += genVarArgsBindingStatement(method.getConditionRealDataType(con), method.getMatchParam(con))/>
	</#list>
	String sql="${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(realSql))}";
	return this.jdbcTemplate.<#rt>
</#if>
<#if returnPackageType>
	queryForList<#t>
<#else/>
	query<#t>
</#if>
(<#if (customConditionMap?size) == 0>()-></#if>new UfBaseException(<#t>
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
, sql,
<#if (customConditionMap?size) != 0>
<#-- 动态拼接的sql，用mapSqlParameterSource别名的形式 -->
mapSqlParameterSource,<#rt>
<#elseif !returnPackageType>
<#-- 非动态拼接的sql，用?加 PreparedStatementSetter形式-->
${builder.addImport("java.sql.PreparedStatement")}<#t>
new PreparedStatementSetter(){
	@Override
	public void setValues(PreparedStatement ps) throws SQLException {
		${setValueStatements}<#rt>
	}
},
</#if>
<#if returnPackageType>
	${builder.addImport("org.springframework.jdbc.core.BeanPropertyRowMapper")}<#t>
	<#-- 如果是包装类型且没有动态拼接的字段  需要加上参数字段 -->
 ${genericType}.class<#if (customConditionMap?size) == 0>${varArgsStatements}</#if>);
<#else>
	new RowMapper<${genericType}>() {
		@Override
		public ${genericType} mapRow(ResultSet rs, int rowNum) throws SQLException {
			${genericType} ${firstLowerGenericType} = new ${genericType}();
			${returnValueAssignStr}<#lt>
			return ${firstLowerGenericType};
		}
	});
</#if>