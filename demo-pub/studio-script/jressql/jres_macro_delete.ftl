<#include "/jressql/jres_macro_common.ftl">
<#assign tableName=参数列表[0]>
<#assign deleteMap=sqlUtil.getConditions(参数列表[1], false)>
<#-- 没有在注解上自定义错误参数，就用where条件中的变量作为错误参数 -->
<#if (params?size == 0)>
    <#assign params = sqlUtil.getConditions(参数列表[1])/>
</#if>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>

<#assign sql = "delete from " + tableName +" where "+参数列表[1]>

<#assign addValue = "">

<#-- 遍历更新字段 -->
<#assign indexNum=1>
<#list deleteMap as key>
	<#-- addValue语句 -->
	<#assign addValue += genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), method.getMatchParam(key))>
	<#assign indexNum+=1>
</#list>

<#-- 需要import的包 -->
${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}

final String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
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
.setTableName("${tableName}"), sql, new PreparedStatementSetter() {
                    @Override
                    public void setValues(PreparedStatement ps) throws SQLException {
                        ${addValue}<#rt>
                    }
                });