<#-- 
HEPType:接口
HEPName:接口一键生成测试用例
HEPSelect:分组
-->
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = util.getArtifactId(element)>
<#if artifactId?ends_with("-domain")>
    <#assign artifactId = artifactId?keep_before_last("-domain")/>
<#elseif artifactId?ends_with("-app")/>
    <#assign artifactId = artifactId?keep_before_last("-app")/>
</#if>
<#assign serviceName = element.getName()>
<#assign microServiceName = util.getProjectProperty().getSubSysId()/>
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
    ${util.dialog('生成接口测试实例取消！')}<#t>
</#if>
<#assign microResource = reference.getHEPElementByFileName("business_prop_config.data")>
<#assign prefix = "">
<#if microResource??>
	<#assign microInfo = microResource.getInfo()>
	<#if microInfo??>
		<#list microInfo.getItems() as item>
			<#if stringUtil.equalsIgnoreCase(item.getExtendValue("config_name"), microServiceName)>
				<#assign prefix = item.getExtendValue("micro_service_prefix")>
				<#break>
			</#if>
		</#list>
	</#if>
</#if>
${fileUtil.setFile(path + "/" + artifactId +"-" + serviceName + "测试用例.xml")}<#t>
<?xml  version='1.0' encoding='utf-8'?>   
<TEST_PACK node=''>   
    <Test>
<#list util.getAllResources(element) as interface>
    <#assign bizName = interface.getName()>
    <#assign bizInputs = interface.getInfo().getInputs()>
    <#assign bizOutputs = interface.getInfo().getOutputs()>
    <#assign bizCName = interface.getInfo().getChineseName()>
        <sub id='${microServiceName}.${bizName}' mgr='1' block='1' livetime='5000' pri='8' pack_ver='32' note='${bizCName}'>
            <route esb_name='' esb_no='' neighbor='' plugin='' system='' sub_system='' branch='' shardingInfo='{"cust_id":""}' security='' group='' service='${prefix}' version=''/>
            <inparams note='' type='obj'>
    <#list bizInputs as param>
        <#assign isCollection = param.isCollection()/>
        <#assign isObj = param.isObj()/>
        <#assign paramName = param.getName()>
            <in name='${paramName}' value='<#rt>
            <#if (isCollection)>
                [<#t>
                <#if (isObj)>
                    <@genObjParamValue param.getChildren()/><#t>
                </#if>
                ]<#t>
            <#elseif (isObj)>
                <@genObjParamValue param.getChildren()/><#t>
            </#if>
            '/><#lt>
    </#list>
            </inparams>
            <outparams note='' type='obj'>
    <#list bizOutputs as param>
        <#assign isCollection = param.isCollection()/>
        <#assign isObj = param.isObj()/>
        <#assign paramName = param.getName()>
            <out name='${paramName}' value='<#rt>
            <#if (isCollection)>
                [<#t>
                <#if (isObj)>
                    <@genObjParamValue param.getChildren()/><#t>
                </#if>
                ]<#t>
            <#elseif (isObj)>
                <@genObjParamValue param.getChildren()/><#t>
            </#if>
            '/><#lt>
    </#list>
            </outparams>
        </sub>
</#list>
    </Test>
</TEST_PACK>
<#-- 生成对象类型参数的value，为json格式 -->
<#macro genObjParamValue children>
{<#t>
    <#list children as child>
        "${child.getName()}":<#if (child.isObj())>{}<#else>""</#if><#t>
        <#if (child?has_next)>
            ,<#t>
        </#if>
    </#list>
}<#t>
</#macro>