<#--
HEPType:标准错误号
HEPName:生成标准错误号代码
HEPSelect:资源
-->
<#-- 所选资源所在工程的绝对路径 -->
<#assign projectPath = util.getProjectPath(element)>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = util.getArtifactId(element)>
<#-- ArtifactId处理为package包路径的形式 -->
<#assign artifactPackPath = stringUtil.replaceHyphenWithDot(artifactId)>
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/constant/HSErrorConstants.java")}<#t>
package ${groupId}.${artifactPackPath}.constant;

import com.hundsun.broker.base.constant.ErrorConsts;

/**
 * 标准错误号接口
 **/
public class HSErrorConstants {
<#assign categories=model.getCates()>
<#list categories as category>
    <#assign categoryName=category.getName()>
    /*
     * ======================== ${categoryName} begin
     * ===================================================================
     * ========
     */
    <#assign items=category.getItems()>
    <#list items as item>
        <#if stringUtil.isNotBlank(item.getExtendValue("error_constant"))>
    public static int ${item.getExtendValue("error_constant")} = ${item.getExtendValue("error_no")}; // ${item.getExtendValue("error_info")}
        </#if>
    </#list>
    /*
     * ======================== ${categoryName} end
     * ===================================================================
     * ========
     */
    
</#list>
<#assign uncategorizedItems = model.getUncategorizedItems()/>
<#if (uncategorizedItems?size != 0)>
    /*
     * ======================== 未分组 begin
     * ===================================================================
     * ========
     */
    <#list uncategorizedItems as item>
        <#if stringUtil.isNotBlank(item.getExtendValue("error_constant"))>
    public static int ${item.getExtendValue("error_constant")} = ${item.getExtendValue("error_no")}; // ${item.getExtendValue("error_info")}
        </#if>
    </#list>
    /*
     * ======================== 未分组 end
     * ===================================================================
     * ========
     */
    
</#if>
    
    static {
<#list categories as category>
    <#assign items=category.getItems()>
    <#list items as item>
        <#assign errorInfo=stringUtil.replace(item.getExtendValue("error_info"), "\\", "\\\\")>
        <#assign errorInfo=stringUtil.replace(errorInfo, "\"", "\\\"")>
        ErrorConsts.errorNoMap.put(${item.getExtendValue("error_no")}, "${errorInfo}");
    </#list>
    <#if category_has_next>
        
    </#if>
</#list>

<#list uncategorizedItems as item>
    <#assign errorInfo=stringUtil.replace(item.getExtendValue("error_info"), "\\", "\\\\")>
    <#assign errorInfo=stringUtil.replace(errorInfo, "\"", "\\\"")>
        ErrorConsts.errorNoMap.put(${item.getExtendValue("error_no")}, "${errorInfo}");
</#list>
    }

}