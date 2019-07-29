<#include "/jressql/jres_macro_common.ftl"/>
<#assign table = 参数列表[0]>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#assign conditions=sqlUtil.getConditions(参数列表[1], false)>
<#-- 没有在注解上自定义错误参数，就用where条件中的变量作为错误参数 -->
<#if (params?size == 0)>
    <#assign params = conditions/>
</#if>
<#-- sql -->
<#if (sqlUtil.getDbType() == "db_mysql")>
	<#assign sql = "select exists (select 1 from "+table+" where " + (参数列表[1])+")">
<#else>
	<#assign sql = "select count(0) from dual where exists (select 1 from "+table+" where " + (参数列表[1])+")">
</#if>

<#assign varArgsStatements="">

<#list conditions as key>
	<#assign varArgsStatements += genVarArgsBindingStatement(method.getConditionRealDataType(key), method.getMatchParam(key))/>
</#list>
<#-- 需要import的包 -->
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
	String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
	return this.jdbcTemplate.queryForObject(() -> new UfBaseException(<#rt>
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
.setTableName("${table}"), sql, Boolean.class${varArgsStatements});