<#--
HEPType:系统全局配置
HEPName:生成系统配置代码
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
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/constant/HSSysConfigConstants.java")}<#t>
package ${groupId}.${artifactPackPath}.constant;

import com.hundsun.broker.base.constant.ErrorConsts;

/**
 * 标准错误号接口
 **/
public class HSSysConfigConstants {
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
        <#if stringUtil.isNotBlank(item.getExtendValue("macro_definition"))>
    public static int ${item.getExtendValue("macro_definition")} = ${item.getExtendValue("config_no")}; // ${item.getExtendValue("config_name")}
    	<#else>
    public static int SYSCONFIG_${item.getExtendValue("config_no")} = ${item.getExtendValue("config_no")}; // ${item.getExtendValue("config_name")}
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
        <#if stringUtil.isNotBlank(item.getExtendValue("macro_definition"))>
    public static int ${item.getExtendValue("macro_definition")} = ${item.getExtendValue("config_no")}; // ${item.getExtendValue("config_name")}
    	<#else>
    public static int SYSCONFIG_${item.getExtendValue("config_no")} = ${item.getExtendValue("config_no")}; // ${item.getExtendValue("config_name")}
        </#if>
    </#list>
    /*
     * ======================== 未分组 end
     * ===================================================================
     * ========
     */
    
</#if>
}