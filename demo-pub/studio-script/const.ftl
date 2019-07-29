<#--
HEPType:用户常量
HEPName:生成用户常量代码
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
${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/constant/HSConstants.java")}<#t>
<#assign defaultParamNames = []/>
<#if util.getProjectProperty().getBizDefaultParamModel()??>
    <#assign defaultParamModel = util.getProjectProperty().getBizDefaultParamModel()/>
    <#assign defaultParamCates = defaultParamModel.getCates()/>
    <#list defaultParamCates as defaultParamCate>
        <#assign inputs = defaultParamCate.getInParams()/>
        <#list inputs as input>
            <#assign paramName = input.getName()/>
            <#if !defaultParamNames?seq_contains(paramName)>
                <#assign defaultParamNames += [paramName]/>
            </#if>
        </#list>
        <#assign outputs = defaultParamCate.getOutParams()/>
        <#list outputs as output>
            <#assign paramName = output.getName()/>
            <#if !defaultParamNames?seq_contains(paramName)>
                <#assign defaultParamNames += [paramName]/>
            </#if>
        </#list>
    </#list>
</#if>

package ${groupId}.${artifactPackPath}.constant;

/**
 * 常量接口
 **/
public interface HSConstants {
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
		<#assign constValue=item.getExtendValue("constant_value")>
		<#if stringUtil.equals(item.getExtendValue("enable_flag"), "1")>
			<#if constValue?starts_with("\"")>
	public static String ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
			<#elseif constValue?starts_with("'")>
	public static char ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
			<#else>
				<#if constValue?index_of(".") gt -1>
	public static double ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
				<#elseif stringUtil.isInteger(constValue)>
	public static int ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
				<#else>
	public static String ${item.getExtendValue("constant_name")} = "${constValue}"; // ${item.getExtendValue("description")}
				</#if>
			</#if>
		</#if>
	</#list>
	/*
	 * ======================== ${categoryName} end
	 * ===================================================================
	 * ========
	 */
	<#if category_has_next>
	
	</#if>
</#list>
<#assign uncategorizedItems = model.getUncategorizedItems()/>
<#if (uncategorizedItems?size != 0)>
    /*
     * ======================== 未分组 begin
     * ===================================================================
     * ========
     */
    <#list uncategorizedItems as item>
        <#assign constValue=item.getExtendValue("constant_value")>
		<#if stringUtil.equals(item.getExtendValue("enable_flag"), "1")>
			<#if constValue?starts_with("\"")>
	public static String ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
			<#elseif constValue?starts_with("'")>
	public static char ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
			<#else>
				<#if constValue?index_of(".") gt -1>
	public static double ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
				<#elseif stringUtil.isInteger(constValue)>
	public static int ${item.getExtendValue("constant_name")} = ${constValue}; // ${item.getExtendValue("description")}
				<#else>
	public static String ${item.getExtendValue("constant_name")} = "${constValue}"; // ${item.getExtendValue("description")}
				</#if>
			</#if>
		</#if>
    </#list>
    /*
     * ======================== 未分组 end
     * ===================================================================
     * ========
     */
    
</#if>
<#if defaultParamNames?size != 0>
    
    /*
     * 默认参数常量
     */
    <#list defaultParamNames as defaultParamName>
    public static String ${stringUtil.toUpperCase(defaultParamName)} = "${stringUtil.toCamelCase(defaultParamName, true)}";
    </#list>
</#if>
}