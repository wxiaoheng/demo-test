<#include "/jressql/jres_macro_common.ftl">
<#assign tableName=参数列表[0]>
<#assign deleteMap=sqlUtil.getConditions(参数列表[1],false)>

<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>

<#assign sql = "delete from " + tableName +" where "+参数列表[1]>

<#assign addValue = "">

<#-- 第一个参数 应该是list对象 -->
<#assign mParam = method.getParamNames()[0]>
<#-- list里元素的类型，对象/String -->
<#assign type = method.getGenericType(method.getParamType(mParam))>

<#-- 遍历条件字段 -->
<#assign indexNum = 1>
<#list deleteMap as key>
    <#-- addValue语句 -->
    <#if type == "Character">
    	<#assign addValue += genSetValueBindingStatement(indexNum, type, "child")>
    <#elseif stringUtil.isObjectType(type)>
    	<#assign addValue += genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), "child.get" + stringUtil.toCamelCase(key) + "()")>
    <#else>
   		<#assign addValue += genSetValueBindingStatement(indexNum, type, "child")>
    </#if>
    <#assign indexNum+=1>
</#list>

<#-- 需要import的包 -->
${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}

    final String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
    return this.jdbcTemplate.batchUpdate(() -> new UfBaseException(<#rt>
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
.setTableName("${tableName}"), sql, new BatchPreparedStatementSetter(){
	 public void setValues(PreparedStatement ps, int index) throws SQLException {
                ${type} child = ${mParam}.get(index);
                ${addValue}<#rt>
            }
            
            public int getBatchSize() {
                return ${mParam}.size();
            }
});