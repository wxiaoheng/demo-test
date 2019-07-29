<#-- 
HEPType:接口
HEPName:生成Controller类
HEPSelect:分组
-->
<#-- 生成文件的目标工程名，false为获取接口实现类的配置 -->
<#assign projectName = util.getBizInterfaceGenTarget(element, false)>
<#-- 所选资源所在工程的绝对路径 -->
<#assign projectPath = util.getProjectPathByName(projectName)>
<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = util.getGroupId(element)>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = util.getArtifactId(element)>
<#if artifactId?ends_with("-domain")>
    <#assign artifactId = artifactId?keep_before_last("-domain")/>
<#elseif artifactId?ends_with("-app")/>
    <#assign artifactId = artifactId?keep_before_last("-app")/>
</#if>
<#-- ArtifactId处理为package包路径的形式 -->
<#assign artifactPackPath = stringUtil.replaceHyphenWithDot(artifactId)>
<#assign serviceName = element.getName()>
<#-- 首字母大写的微服务名 -->
<#assign firstUpperCaseMicroServiceName = ""/>
<#if stringUtil.equalsIgnoreCase(serviceName, "inner")>
    <#assign firstUpperCaseMicroServiceName = stringUtil.toUpperCase(util.getProjectProperty().getSubSysId(), 1)/>
</#if>
<#-- 有中文名取中文名，没有取英文名 -->
<#assign serviceCName = serviceName>
<#assign camelServiceName = stringUtil.toCamelCase(serviceName)>
<#if stringUtil.equalsIgnoreCase(serviceName, "ext") || stringUtil.equalsIgnoreCase(serviceName, "out") || stringUtil.equalsIgnoreCase(serviceName, "inner")>
<#else/>
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/controller/" + camelServiceName + "Controller.java")}<#t>
</#if>
/**
 * 系统名称: UF3.0
 * 模块名称: ${artifactPackPath}
 * 类  名  称: ${camelServiceName}Controller.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.controller;

import java.util.List;

<#assign methodStr = "">
<#list util.getAllResources(element) as child>
    <@genCode child/>
</#list>
<#macro genCode bizInfo>
    <#local firstLowerCamelBizName = stringUtil.toCamelCase(bizInfo.getName(), true)>
    <#local camelBizName = stringUtil.toUpperCase(firstLowerCamelBizName, 1)>
    <#local bizModel = bizInfo.getInfo()>
    import ${groupId}.${artifactPackPath}.service.${camelServiceName}${firstUpperCaseMicroServiceName}Service.${camelBizName}Input;<#lt>
    import ${groupId}.${artifactPackPath}.service.${camelServiceName}${firstUpperCaseMicroServiceName}Service.${camelBizName}Output;<#lt>
    <#assign methodStr = methodStr + "\t/**\r\n">
    <#assign methodStr = methodStr + "\t * " + bizInfo.getInfo().getChineseName() + "\r\n">
    <#assign methodStr = methodStr + "\t * @param " + firstLowerCamelBizName + "Input\r\n">
    <#assign methodStr = methodStr + "\t * @return\r\n">
    <#assign methodStr = methodStr + "\t */\r\n">
    <#assign returnStr = "">
    <#if bizModel.isResultSetReturn()>
    <#assign returnStr="List<"+camelBizName+"Output>">
    <#else>
    <#assign returnStr=camelBizName+"Output">
    </#if>
    <#assign methodStr = methodStr + "\tpublic " + returnStr + " " + firstLowerCamelBizName + "(" + camelBizName + "Input " + firstLowerCamelBizName + "Input) {\r\n">
    <#assign methodStr = methodStr + "\t\treturn null;\r\n\t}\r\n\r\n">
</#macro>

/**
 * ${serviceCName}控制类
 *
 * @author studio-auto
 * @date
 */
@Service
public class ${camelServiceName}Controller extends BaseController {

${methodStr}
}