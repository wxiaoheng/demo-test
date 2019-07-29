<#include "/jressql/jres_macro_common.ftl"/>
<#-- ftl表示当前脚本，获取当前脚本所在项目pom文件中的groupId -->
<#assign groupId=util.getResourceGroupId(ftl)>
<#-- 插入目标表 -->
<#assign target = 参数列表[0]>
<#-- 获取字段表 -->
<#assign source = 参数列表[1]>
<#-- 字段映射关系  参数2是名称不一样的字段映射-->
<#if 参数列表[2]??>
    <#assign fieldMap = reference.getFields(target, source, 参数列表[2], sqlUtil.getDbType())>
<#else/>
    <#assign fieldMap = reference.getFields(target, source, "", sqlUtil.getDbType())/>
</#if>

<#assign sql = "insert into "+target+"(">
<#assign select = " select ">
<#list fieldMap?keys as key>
    <#assign sql+=key>
    <#assign value=fieldMap[key]/>
    <#-- 支持插入值为入参的场景 -->
    <#if value?starts_with(":")>
        <#assign variable=stringUtil.substring(value, 1)/>
        <#assign select+=value/>
    <#else/>
        <#assign select+=value>
    </#if>
    <#if key?has_next>
        <#assign sql += ",">
        <#assign select += ",">
    </#if>
</#list>
<#if stringUtil.isNotBlank(参数列表[3])>
    <#assign sql+=")" + select + " from "+source + " where " + 参数列表[3]>
<#else/>
    <#assign whereMap=util.getList()>
    <#assign sql+=")" + select + " from "+source>
</#if>

<#-- 需要import的包 -->
${builder.addImport("java.sql.PreparedStatement")}
${builder.addImport("org.springframework.jdbc.core.PreparedStatementSetter")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.jres.studio.annotation.util.JRESStringUtils")}
<#assign setValueStatements="">
<#assign indexNum = 1>
    <#assign keys = sqlUtil.getConditions(sql, false)>
    <#list keys as key>
    	<#assign setValueStatements += genSetValueBindingStatement(indexNum, method.getConditionRealDataType(key), method.getMatchParam(key))/>
    	<#assign indexNum += 1>
    </#list>
    String sql = "${sqlUtil.format(sqlUtil.replaceVariantRefToPlaceholder(sql))}";
    return this.jdbcTemplate.update(() -> new UfBaseException(<#rt>
    <#if stringUtil.isEmpty(defaultError)>
        ErrorConsts.ERR_BASE_DAO<#t>
    <#else>
        ${defaultError}<#t>
    </#if>
    )<#t>
    <#if errors??>
        <#list errors?keys as key>
            .setError(${key}, ${errors[key]})<#t>
        </#list>
    </#if>
    <#if params??>
        <#list params as param>
            <#assign trimParam=param?trim/>
            .setParam("${trimParam}", ${method.getMatchParam(trimParam)})<#t>
        </#list>
    </#if>
.setTableName("${target}"), sql, new PreparedStatementSetter(){
	@Override
	public void setValues(PreparedStatement ps) throws SQLException {
		${setValueStatements}<#rt>
		}
	});