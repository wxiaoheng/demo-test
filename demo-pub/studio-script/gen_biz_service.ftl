<#-- 
HEPType:接口
HEPName:生成Service接口
HEPSelect:分组
-->
<#-- 生成文件的目标工程名，true为获取接口定义类的配置 -->
<#assign projectName = util.getBizInterfaceGenTarget(element, true)>
<#assign objs="">
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
<#-- 获取模块信息中接口扩展属性字段 -->
<#assign inParams = element.getExtendValue("inparams")>
<#-- 微服务名 -->
<#assign microServiceName = util.getProjectProperty().getSubSysId()/>
<#-- 首字母大写的微服务名 -->
<#assign firstUpperCaseMicroServiceName = ""/>
<#assign isInner = false/>
<#if stringUtil.equalsIgnoreCase(serviceName, "inner")>
    <#assign isInner = true/>
    <#assign firstUpperCaseMicroServiceName = stringUtil.toUpperCase(microServiceName, 1)/>
</#if>
<#assign isPublicService = false/>
<#if stringUtil.equalsIgnoreCase(serviceName, "inner") || stringUtil.equalsIgnoreCase(serviceName, "ext") || stringUtil.equalsIgnoreCase(serviceName, "out") || stringUtil.equalsIgnoreCase(serviceName, "cms")>
    <#assign isPublicService = true/>
</#if>
<#assign serviceCName = serviceName>
<#assign camelServiceName = stringUtil.toCamelCase(serviceName)>
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/service/" + camelServiceName + firstUpperCaseMicroServiceName + "Service.java")}<#t>
/**
 * 系统名称: UF3.0
 * 模块名称: ${artifactPackPath}
 * 类  名  称: ${camelServiceName}${firstUpperCaseMicroServiceName}Service.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.service;
 
import java.util.List;

import javax.validation.constraints.NotNull;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

<#if isInner>
import com.hundsun.broker.base.mq.MessageInfo;
</#if>

/**
 * ${serviceCName}服务接口
 *
 * @author studio-auto
 * @date
 */
@CloudService(validation=true, validationNull= <#if stringUtil.equalsIgnoreCase(inParams,"true")>${inParams}<#else>false</#if>)
public interface ${camelServiceName}${firstUpperCaseMicroServiceName}Service {
<#list util.getAllResources(element) as child>
    <@genCode child/>
    
</#list>
    <@genObjectsClass/>
}

<#macro genCode bizInfo>
    <#local bizName = bizInfo.getName()>
    <#local firstLowerBizCamelName = stringUtil.toCamelCase(bizName, true)>
    <#local bizCamelName = stringUtil.toUpperCase(firstLowerBizCamelName, 1)>
    <#local bizModel = bizInfo.getInfo()>
    <#local bizInputs = bizModel.getInputs()>
    <#local bizFlag = bizModel.getBizFlag()>
    <#local partition = bizModel.getPartition()/>
    <#local partitionStr = stringUtil.isNotBlank(partition)?string(', partition = "' + partition + '"', "")/>
    <#-- 保证在所有输入参数都未传情况下，输入参数对象不为null -->
    <#local nullToObject = (bizFlag?index_of("T") != -1)?then(true, false)/>

    @JRESData
    <#if stringUtil.equalsIgnoreCase(serviceName, "ext")>
    <#-- 支持无密访问和密码访问双模式 -->
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public class ${bizCamelName}Input implements ParamsValues, Serializable {
    <#else>
    public class ${bizCamelName}Input implements Serializable {
    </#if>
        private static final long serialVersionUID = 1L;
    <#list bizInputs as param>
        <@genInitStr param, bizFlag, true/>
    </#list>
    }
    
    @JRESData
    public class ${bizCamelName}Output implements Serializable {
        private static final long serialVersionUID = 1L;
    <#local bizOutputs = bizModel.getOutputs()>
    <#list bizOutputs as param>
        <@genInitStr param, bizFlag, false/>
    </#list>
    }
    
    /**
     * ${bizInfo.getInfo().getChineseName()}
     *
     * @param ${firstLowerBizCamelName}Input
     * @return
     */
    @CloudFunction(value = "${microServiceName}.${firstLowerBizCamelName}", apiUrl = "/${firstLowerBizCamelName}"${partitionStr})
    <#if bizModel.isResultSetReturn()>
    List<${bizCamelName}Output> ${firstLowerBizCamelName}(<#if (nullToObject)>@CloudFunctionParam(value = "${stringUtil.toUnderline(firstLowerBizCamelName)}_input", nullToObject = true)</#if>${bizCamelName}Input ${firstLowerBizCamelName}Input);	
    <#else>
    ${bizCamelName}Output ${firstLowerBizCamelName}(<#if (nullToObject)>@CloudFunctionParam(value = "${stringUtil.toUnderline(firstLowerBizCamelName)}_input", nullToObject = true)</#if>${bizCamelName}Input ${firstLowerBizCamelName}Input);	
    </#if>
</#macro>

<#macro genInitStr param, bizFlag, isInput>
    <#local type = param.getRealType()>
    <#local isObj = param.isObj()>
    <#if isObj>
        <#local type = stringUtil.toCamelCase(param.getType(), false)>
        <#assign objs=objs+param.getType()+"@">
    </#if>
    <#local pCamelName = stringUtil.toCamelCase(param.getName(), true)>
    <#-- 有N标记则不添加默认值 -->
    <#local defValue="">
    <#-- 是否集合 -->
    <#local isList=param.isCollection()>
    <#if isList>
        <#local type = "List<"+type+">">
    <#else>
        <#if stringUtil.indexOf(bizFlag,'N') lt 0>
            <#if stringUtil.isNotBlank(param.getRealDefaultValue())>
                <#local defValue="="+param.getRealDefaultValue()>
            </#if>
        </#if>
    </#if>
        /**
         * ${param.getChineseName()} ${param.getDescription()}
         */
    <#if isInput>
        <#local isNotNull = param.isNecessarily()>
        <#if isNotNull>
            <#if type == "String">
                <#local length = param.getLength()/>
                <#if stringUtil.isNotBlank(length)>
        @SinogramLength(min = 1, max = ${length}, charset="utf-8")
        @NotNull(message="不能为空")
                <#else/>
        @NotEmpty(message="不能为空")
                </#if>
            <#else>
        @NotNull(message="不能为空")
            </#if>
        <#else/>
            <#if type == "String">
                <#local length = param.getLength()/>
                <#if stringUtil.isNotBlank(length)>
        @SinogramLength(min = 0, max = ${length}, charset="utf-8")
                </#if>
            </#if>
        </#if>
        <#local rule = param.getRule()>
        <#if stringUtil.isNotBlank(rule)>
        @Pattern(regexp = "${rule}", message = "需要符合正则表达式${rule}")
        </#if>
    </#if>
    <#if !isPublicService && type == "Long">
        @JsonSerialize(using = LongJsonSerializer.class)
        @JsonDeserialize(using = LongJsonDeserializer.class)
    </#if>
        private ${type} ${pCamelName}${defValue};
</#macro>

<#macro genObjectsClass>
    <#assign index=stringUtil.indexOf(objs, "@")>
    <#if index gt -1>
        <#local obj=stringUtil.substring(objs,0,index)>
        <#if reference.getResourceInfo(obj, "hepobj")??>
        <#local objInfo=reference.getResourceInfo(obj, "hepobj")>
        <#local objName=stringUtil.toCamelCase(objInfo.getName(), false)>
    @JRESData
    public class ${objName} implements Serializable {
        private static final long serialVersionUID = 1L;
    <#local params = objInfo.getParams()>
    <#list params as param>
        <@genInitStr param, ""/>
    </#list>
    }
        </#if>
        <#assign objs=stringUtil.replace(objs, obj+"@", "")>
        <@genObjectsClass/>
    </#if>
</#macro>