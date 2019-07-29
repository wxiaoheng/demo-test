<#-- 
HEPType:数据库表
HEPName:生成实体类
HEPSelect:资源
-->
<#-- 所选资源所在工程的绝对路径 -->
<#assign projectPath = util.getProjectPath(element)>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = util.getArtifactId(element)>
<#if artifactId?ends_with("-domain")>
    <#assign artifactId = artifactId?keep_before_last("-domain")/>
<#elseif artifactId?ends_with("-app")/>
    <#assign artifactId = artifactId?keep_before_last("-app")/>
</#if>
<#-- 调用宏指令 -->
<@main element/>
<#-- 生成逻辑的主方法，ele为用户选择的对象，可能为文件夹，可能为文件资源 -->
<#macro main ele>
    <#-- 判断选择对象是文件夹还是资源，是文件夹则递归调用本方法，是文件资源则生成文件 -->
    <#if util.isFolder(ele)>
        <#list ele.getChildren() as child>
            <@main child/>
        </#list>
    <#else>
        <@genCode ele.getInfo()/>
    </#if>
</#macro>
<#macro genCode tableInfo>
    <#local tableName = tableInfo.getName()>
    <#local tableCName = tableInfo.getChineseName()>
    <#-- 如果表名包含下划线，去除前缀 -->
    <#if stringUtil.indexOf(tableName,"_") gte 0>
        <#local withoutPrefixTableName = tableName?keep_after("_")>
    <#else>
        <#local withoutPrefixTableName = tableName>
    </#if>
    <#-- 类名首字母大写 -->
    <#local capTableName = stringUtil.toUpperCase(stringUtil.replace(withoutPrefixTableName,"_",""),1)>
    ${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/entity/" + capTableName + ".java")}<#t>
/**
 * 系统名称: uf3.0
 * 模块名称: ${stringUtil.replaceHyphenWithDot(artifactId)}
 * 类  名  称: ${capTableName}.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${stringUtil.replaceHyphenWithDot(artifactId)}.entity;

import com.hundsun.broker.base.Entity;

/**
 * ${tableCName}实体类
 *
 * @author studio-auto
 * @date
 */
 @JRESData
public class ${capTableName} implements Entity {

    <#local params = tableInfo.getColumns()>
    <#list params as param>
        /**
         * ${param.getChineseName()}
         */
        private ${param.getRealDataType("java")} ${stringUtil.toCamelCase(param.getName(), true)} = ${param.getRealDataDefValue("java")};
    </#list>
    
</#macro>
}