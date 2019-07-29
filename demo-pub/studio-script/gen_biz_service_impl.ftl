<#-- 
HEPType:接口
HEPName:生成Service实现类
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
<#-- 对外接口 -->
<#assign isPublicService = false/>
<#if stringUtil.equalsIgnoreCase(serviceName, "ext") || stringUtil.equalsIgnoreCase(serviceName, "out") || stringUtil.equalsIgnoreCase(serviceName, "inner")>
    <#assign isPublicService = true/>
</#if>
<#assign microServiceName = util.getProjectProperty().getSubSysId()>
<#-- 首字母大写的微服务名 -->
<#assign firstUpperCaseMicroServiceName = ""/>
<#if stringUtil.equalsIgnoreCase(serviceName, "inner")>
    <#assign firstUpperCaseMicroServiceName = stringUtil.toUpperCase(microServiceName, 1)/>
</#if>
<#assign lowerServiceName = stringUtil.toLowerCase(serviceName, 1)>
<#assign serviceCName = serviceName>
<#assign camelServiceName = stringUtil.toCamelCase(serviceName)>
<#-- 公共代码检查中服务类别枚举类型 -->
<#assign serviceType = "">
<#if stringUtil.equalsIgnoreCase(serviceName, "ext") || stringUtil.equalsIgnoreCase(serviceName, "out") || stringUtil.equalsIgnoreCase(serviceName, "inner") || stringUtil.equalsIgnoreCase(serviceName, "cms")>
    <#assign serviceType = stringUtil.toUpperCase(serviceCName)/>
<#else>
	<#assign serviceType = "COUNTER"/>
</#if>
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/service/impl/" + camelServiceName + firstUpperCaseMicroServiceName + "ServiceImpl.java")}<#t>
<#-- 需要数据脱敏 -->
<#assign needDataMask = false/>
<#list util.getAllResources(element) as child>
    <#assign bizInfo = child.getInfo()/>
    <#if (bizInfo.getBizFlag()?contains("Z"))>
        <#assign needDataMask = true/>
        <#break>
    </#if>
</#list>
/**
 * 系统名称: UF3.0
 * 模块名称: UF3.0 demo
 * 类  名  称: ${camelServiceName}${firstUpperCaseMicroServiceName}ServiceImpl.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.service.impl;

import java.util.List;
import java.util.Map;

<#if isPublicService>

<#else/>
import ${groupId}.${artifactPackPath}.controller.${camelServiceName}Controller;
</#if>
import ${groupId}.${artifactPackPath}.service.${camelServiceName}${firstUpperCaseMicroServiceName}Service;
import ${groupId}.base.util.ExceptionUtils;
import com.hundsun.broker.base.AppContext;
import com.hundsun.broker.base.mq.MessageInfo;

/**
 * ${serviceCName}服务接口实现类
 *
 * @author studio-auto
 * @date
 */
@CloudComponent
public class ${camelServiceName}${firstUpperCaseMicroServiceName}ServiceImpl extends BaseService implements ${camelServiceName}${firstUpperCaseMicroServiceName}Service {
<#if isPublicService>
    <#-- 保存接口名第二个词（也就是去掉下划线的表名）的列表，用来生成Controller -->
    <#assign tableNameList = []/>
    <#list util.getAllResources(element) as child>
        <#assign tableName = stringUtil.getWord(child.getName(), 1)/>
        <#if !tableNameList?seq_contains(tableName)>  
            <#assign tableNameList += [tableName]/>
        </#if>
    </#list>
    <#list tableNameList as tableName>
        
    @Autowired
    private ${tableName}Controller ${tableName?lower_case}Controller;
    </#list>
<#else/>

    @Autowired
    private ${camelServiceName}Controller ${lowerServiceName}Controller;

</#if>	
<#if (needDataMask)>
    @Autowired
    private DataAuthority dataAuthorityController;
</#if>
<#list util.getAllResources(element) as child>
    <@genCode child/>
</#list>
}
<#macro genCode bizInfo>
    <#local firstLowerCamelBizName = stringUtil.toCamelCase(bizInfo.getName(), true)>
    <#local camelBizName = stringUtil.toUpperCase(firstLowerCamelBizName, 1)>
    <#local bizModel = bizInfo.getInfo()>
    
    @Override
    public <#if bizModel.isResultSetReturn()>List<${camelBizName}Output><#else>${camelBizName}Output</#if> ${firstLowerCamelBizName}(${camelBizName}Input ${firstLowerCamelBizName}Input) {
        return ExceptionUtils.wrap(() -> {
            // 生成代码：参数校验、身份检查、权限检查、系统状态检查
            <#-- 增加公共检查代码-->
            Map<String, PublicChecker> beans = AppContext.getApplicationContext().getBeansOfType(PublicChecker.class);
            if (beans.size() > 0) {
	            CommonInfo commonInfo = new CommonInfo();
	            ${firstLowerCamelBizName}InputToCommonInfo(commonInfo, ${firstLowerCamelBizName}Input);
	            for (PublicChecker publicChecker : beans.values()) {
	            	publicChecker.check(commonInfo, ServiceTypeEnum.${serviceType}.getCode());
	            }
            }
            
            <#local bizFlag = bizModel.getBizFlag()>
            <#if stringUtil.equalsIgnoreCase(serviceName, "ext")>
	    		<#-- 支持无密访问和密码访问双模式 -->
	    		<#local check = "false">
	    		<#if stringUtil.indexOf(bizFlag,'P') gte 0>
	    			<#local check = "true">
	    		</#if>
	    		AucUtils.checkIdentity(${firstLowerCamelBizName}Input, "${microServiceName}.${firstLowerCamelBizName}",${check});
            </#if>
    		<#-- 默认参数 -->
            <@initDefaultParams bizInfo, firstLowerCamelBizName/>
            <#if stringUtil.indexOf(bizFlag,'C') gte 0>
                RpcContext.getContext().set(BaseConsts.KEY_DATASOURCE_FLAG, BaseConsts.DATASOURCE_FLAG_READONLY);
    		</#if>
            <#if bizModel.isResultSetReturn()>
                List<${camelBizName}Output> outputs<#t>
            <#else>
                ${camelBizName}Output output<#t>
            </#if>
            <#if isPublicService>
                 = ${stringUtil.getWord(firstLowerCamelBizName, 1)?lower_case}Controller.${firstLowerCamelBizName}(${firstLowerCamelBizName}Input);<#t>
            <#else/>
                 = ${lowerServiceName}Controller.${firstLowerCamelBizName}(${firstLowerCamelBizName}Input);<#t>
            </#if>
            <#-- 数据脱敏代码 -->
            <#local needDataMask = bizFlag?contains("Z")/>
            <#if (needDataMask)>
                <@genDataMaskCode bizModel, camelBizName, firstLowerCamelBizName/>
            </#if>
            <#if bizModel.isResultSetReturn()>
                return outputs;
            <#else/>
                return output;
            </#if>
        });
    }
    
    @JRESCopy
    private void ${firstLowerCamelBizName}InputToCommonInfo(CommonInfo commonInfo, ${camelBizName}Input ${firstLowerCamelBizName}Input){
    }
</#macro>
<#macro initDefaultParams bizInfo, firstLowerCamelBizName>
    <#-- 获取接口的默认入参 -->
    <#local defaultParams = util.getProjectProperty().getBizDefaultParamModel().getDefaultParams(bizInfo, true)/>
    <#list defaultParams as param>
        <#local paramName = param.getName()/>
        <#local firstLowerParamCamelName = stringUtil.toCamelCase(paramName, true)/>
        <#local firstUpperParamCamelName = stringUtil.toUpperCase(firstLowerParamCamelName, 1)/>
            RpcContext.getContext().set("${firstLowerParamCamelName}", ${firstLowerCamelBizName}Input.get${firstUpperParamCamelName}());
    </#list>
</#macro>
<#-- 生成数据脱敏代码 -->
<#macro genDataMaskCode bizInfo, camelBizName, firstLowerCamelBizName>
    <#local outputs = bizInfo.getOutputs()/>
    String[] keys = {<#rt>
    <#list outputs as param>
        "${param.getName()}"<#t>
        <#if (param?has_next)>
            ,<#t>
        </#if>
    </#list>};
    String[] checkKeys = dataAuthorityController.checkData(keys);
    if (checkKeys != null) {
        for (String checkKey : checkKeys) {
    <#list outputs as param>
        <#local paramName = param.getName()/>
            if ("${paramName}".equals(checkKey)) {
                <#if bizInfo.isResultSetReturn()>
                for (${camelBizName}Output output : outputs) {
                    output.set${stringUtil.toCamelCase(paramName)}("******");
                }
                <#else/>
                output.set${stringUtil.toCamelCase(paramName)}("******");
                </#if>
                continue;
            }
    </#list>
        }
    } 
</#macro>