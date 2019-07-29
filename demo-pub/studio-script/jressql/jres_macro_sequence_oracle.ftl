<#assign sequenceName = 参数列表[1]>

<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getResourceGroupId(ftl)>

<#-- 查询SQL语句 -->
<#assign selectSql = "select " + sequenceName + ".nextval from dual">

<#-- 需要import的包 -->
${builder.addImport("com.hundsun.broker.base.constant.ErrorConsts")}
${builder.addImport("com.hundsun.broker.base.exception.UfBaseException")}

<#-- 真实代码 -->
    String sql = "${sqlUtil.format(selectSql)}";
    return this.jdbcTemplate.queryForObject(() -> new UfBaseException(ErrorConsts.ERR_BASE_DAO), sql, Long.class);
