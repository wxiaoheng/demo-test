<#-- 这个模板文件存放生成SQL脚本修订记录注释的宏 -->
<#if (tables??)>
    <@genMultiTablesHistoryComment tables/>
</#if>

<#-- 生成多张表的修订记录注释 -->
<#macro genMultiTablesHistoryComment tableResources>
    <@genHistoryCommentTitle/><#t>
    <#local histories = []/>
    <#list tableResources as tableResource>
        <#local histories += tableResource.getInfo().getHistories()/>
    </#list>
    <#local histories = util.sortHistory(histories)/>
    <@genHistoryComment histories/><#t>
</#macro>

<#-- 修订记录注释的标题行 -->
<#macro genHistoryCommentTitle>
-- 总修改记录
-- 修改版本     修改日期     修改单            申请人            修改人            修改说明
</#macro>

<#-- 修订记录注释的具体内容 -->
<#macro genHistoryComment histories>
    <#list histories as history>
-- ${history.getVersion()?trim?right_pad(13)}${util.formatDate(history.getModifiedDate()?trim, "yyyyMMdd")?right_pad(13)}${history.getOrderNumber()?trim?right_pad(18)}${history.getModifiedBy()?trim?right_pad(18)}${history.getCharger()?trim?right_pad(18)}${history.getModified()?trim}
    </#list>
</#macro>

<#-- 生成单张表的修订记录注释 -->
<#macro genSingleTableHistoryComment tableInfo>
    <@genHistoryCommentTitle/><#t>
    <#local histories = tableInfo.getHistories()>
    <@genHistoryComment histories/><#t>
</#macro>