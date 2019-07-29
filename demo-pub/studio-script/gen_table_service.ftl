<#-- 
HEPType:数据库表
HEPName:生成Service接口
HEPSelect:资源
-->
<#-- 所选资源所在工程的绝对路径 -->
<#assign projectPath = util.getProjectPath(element)>
<#if projectPath?ends_with("-domain")>
    <#assign projectPath = projectPath?keep_before_last("-domain") + "-app">
</#if>
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
    <#-- 微服务名 -->
    <#local microServiceName = util.getProjectProperty().getSubSysId()/>
    <#-- 如果表名包含下划线，去除前缀 -->
    <#if stringUtil.indexOf(tableName,"_") gte 0>
        <#local withoutPrefixTableName = tableName?keep_after("_")>
    <#else>
        <#local withoutPrefixTableName = tableName>
    </#if>
    <#-- 表名去下划线 -->
    <#local firstLowerCapTableName = stringUtil.replace(withoutPrefixTableName,"_","")>
    <#-- 类名首字母大写 -->
    <#local capTableName = stringUtil.toUpperCase(firstLowerCapTableName,1)>
       
	<#local columns = tableInfo.getColumns()>
	<#local tableIndex = tableInfo.getIndexs()>
	<#local inputParam = "">
	<#local dataTypeInputParam = "">
	<#local CloudFunctionParam = "">
	<#list tableIndex as index>
		<#local isUnique = index.isUnique()>
		<#local mark = index.getMark()>
		<#if isUnique && mark!="H">
			<#local uniqueColumnStr = index.getColumns()>
			<#list uniqueColumnStr as uniqueColumn>
				<#local uniqueColumnName = uniqueColumn.getName()>
				<#--local inputParam += uniqueColumnName-->
				<#local inputParam += stringUtil.toCamelCase(uniqueColumnName,true)>
				<#list columns as columnTemp>
					<#local columnTempName = columnTemp.getName()>
					<#if columnTempName==uniqueColumnName>
						<#local dataTypeInputParam = dataTypeInputParam + columnTemp.getRealDataType("java") + " " + uniqueColumnName>
						<#local CloudFunctionParam = CloudFunctionParam + "@CloudFunctionParam(\""+uniqueColumnName+"\") " + columnTemp.getRealDataType("java") + " " + stringUtil.toCamelCase(uniqueColumnName,true)>
					</#if>
				</#list>
				<#if uniqueColumn?has_next>
					<#local inputParam += ",">
					<#local dataTypeInputParam += ",">
					<#local CloudFunctionParam += ",">
				</#if>	
			</#list>
		</#if>
	</#list>
    <#-- 乐观锁字段字符串 -->
    <#local oFlagColumnStr = ""/>
    <#list columns as column>
        <#if column.getMark()?upper_case?index_of("O") != -1>
            <#if stringUtil.isNotBlank(dataTypeInputParam) || stringUtil.isNotBlank(oFlagColumnStr)>
                <#local oFlagColumnStr += ", "/>
            </#if>
            <#local oFlagColumnStr += "@CloudFunctionParam(\"" + column.getName() + "\") " + column.getRealDataType("java") + " " + stringUtil.toCamelCase(column.getName(),true)>
        </#if>
    </#list>
	${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/service/" + capTableName + "Service.java")}<#t>
/**
 * 系统名称: UF3.0
 * 模块名称: UF3.0
 * 类  名  称: ${capTableName}Service.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.service;
 

/**
 * ${tableCName}服务接口
 *
 * @author studio-auto
 * @date
 */
@CloudService
public interface ${capTableName}Service {

    	@JRESData
	class Post${capTableName}Input implements Serializable {
		private static final long serialVersionUID = 1L;
	<#local params = tableInfo.getColumns()>
	<#list params as param>
		/**
		 * ${param.getChineseName()}
		 */
		private ${param.getRealDataType("java")} ${stringUtil.toCamelCase(param.getName(), true)};
	</#list>
	}

	/**
	 * 新增${tableCName}
	 *
	 * @param post${capTableName}Input
	 * @return
	 */
	@CloudFunction(value = "${microServiceName}.post${capTableName}", apiUrl = "/${microServiceName}/post${capTableName}")
	ResultInfo post${capTableName}(@CloudFunctionParam("post${capTableName}Input") Post${capTableName}Input post${capTableName}Input);
	
	@JRESData
	class Put${capTableName}Input implements Serializable {
		private static final long serialVersionUID = 1L;
	<#local params = tableInfo.getColumns()>
	<#list params as param>
		/**
		 * ${param.getChineseName()}
		 */
		private ${param.getRealDataType("java")} ${stringUtil.toCamelCase(param.getName(), true)};
	</#list>
	}
	
	/**
	 * 修改${tableCName}
	 *
	 * @param put${capTableName}Input
	 * @return
	 */
	@CloudFunction(value = "${microServiceName}.put${capTableName}", apiUrl = "/${microServiceName}/put${capTableName}")
	ResultInfo put${capTableName}(@CloudFunctionParam("put${capTableName}Input") Put${capTableName}Input put${capTableName}Input);

    <@genDelComment tableCName = tableCName inputParam = inputParam/>
	@CloudFunction(value = "${microServiceName}.delete${capTableName}", apiUrl = "/${microServiceName}/delete${capTableName}")
	ResultInfo delete${capTableName}(${CloudFunctionParam}${oFlagColumnStr});
		
    <@genSelComment inputParam = inputParam/>	
	@CloudFunction(value = "${microServiceName}.get${capTableName}", apiUrl = "/${microServiceName}/get${capTableName}")
	${capTableName} get${capTableName}(${CloudFunctionParam});
	
	/**
	 * 多条查询
	 * 
	 * @param input
	 * @return
	 */
	@CloudFunction(value = "${microServiceName}.getAll${capTableName}", apiUrl = "/${microServiceName}/getAll${capTableName}")
	QueryPage<${capTableName}> get${capTableName}Page(@CloudFunctionParam("input") Get${capTableName}PageInput input);

	@JRESData
	class Get${capTableName}PageInput implements Serializable {
		private static final long serialVersionUID = 1L;
		private Integer pageNo;
        private Integer pageSize;

	}

}
</#macro>
<#-- 删除方法javadoc形式参数注释，编码规范要求 -->
<#macro genDelComment tableCName,inputParam>
    <#local inputParamArr = inputParam?split(",")>
    /**
     * 删除${tableCName} 
     *    
    <#list inputParamArr as param> 
     * @param ${param}
    </#list>
     * @return
     */    
</#macro>

<#-- 单条查询javadoc形式参数注释，编码规范要求 -->
<#macro genSelComment inputParam>
    <#local inputParamArr = inputParam?split(",")>
    /**
     * 单条查询
     *  
    <#list inputParamArr as param> 
     * @param ${param}
    </#list>
     * @return
     */    
</#macro>