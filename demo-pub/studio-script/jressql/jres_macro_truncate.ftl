<#assign tableName=参数列表[0]>

<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>

<#assign sql = "truncate table " + tableName>

<#-- 需要import的包 -->
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}

    final String sql = "${sqlUtil.format(sql)}";
    return this.jdbcTemplate.update(() -> new UfBaseException(<#rt>
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
.setTableName("${tableName}"), sql);