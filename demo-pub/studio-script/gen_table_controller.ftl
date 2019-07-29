<#-- 
HEPType:数据库表
HEPName:生成Controller类
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
    <#list tableIndex as index>
        <#local isUnique = index.isUnique()>
        <#local mark = index.getMark()>
        <#if isUnique && mark!="H">
            <#local uniqueColumnStr = index.getColumns()>
            <#list uniqueColumnStr as uniqueColumn>
                <#local uniqueColumnName = uniqueColumn.getName()>
                <#local inputParam += stringUtil.toCamelCase(uniqueColumnName,true)>
                <#list columns as columnTemp>
                    <#local columnTempName = columnTemp.getName()>
                    <#if columnTempName==uniqueColumnName>
                        <#local dataTypeInputParam = dataTypeInputParam + columnTemp.getRealDataType("java") + " " + stringUtil.toCamelCase(uniqueColumnName,true)>
                    </#if>
                </#list>
                <#if uniqueColumn?has_next>
                    <#local inputParam += ",">
                    <#local dataTypeInputParam += ",">
                </#if>	
            </#list>
        </#if>
    </#list>
    <#-- 乐观锁字段形参字符串 -->
    <#local oFlagColumnStr = ""/>
    <#-- 乐观锁字段实参字符串 -->
    <#local oFlagColumnActualParamStr = ""/>
    <#list columns as column>
        <#if column.getMark()?upper_case?index_of("O") != -1>
            <#if stringUtil.isNotBlank(dataTypeInputParam) || stringUtil.isNotBlank(oFlagColumnStr)>
                <#local oFlagColumnStr += ", "/>
            </#if>
            <#if stringUtil.isNotBlank(inputParam) || stringUtil.isNotBlank(oFlagColumnActualParamStr)>
                <#local oFlagColumnActualParamStr += ", "/>
            </#if>
            <#local oFlagColumnStr += column.getRealDataType("java") + " " + stringUtil.toCamelCase(column.getName(),true)>
            <#local oFlagColumnActualParamStr += stringUtil.toCamelCase(column.getName(),true)/>
        </#if>
    </#list>
    ${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/controller/" + capTableName + "Controller.java")}<#t>
/**
 * 系统名称: UF3.0
 * 模块名称: UF3.0 demo
 * 类  名  称: ${capTableName}Controller.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.hundsun.broker.base.BaseController;
import com.hundsun.broker.base.repository.QueryPage;

import ${groupId}.${artifactPackPath}.dao.${capTableName}DAO;
import ${groupId}.${artifactPackPath}.service.${capTableName}Service.Get${capTableName}PageInput;
import ${groupId}.${artifactPackPath}.service.${capTableName}Service.Post${capTableName}Input;
import ${groupId}.${artifactPackPath}.service.${capTableName}Service.Put${capTableName}Input;

/**
 * ${tableCName}控制类
 *
 * @author studio-auto
 * @date
 */
@Component
public class ${capTableName}Controller extends BaseController {

    @Autowired
    private ${capTableName}DAO ${firstLowerCapTableName}DAO;

    /**
     * 新增${tableCName}
     */
    public ResultInfo post${capTableName}(Post${capTableName}Input post${capTableName}Input) {
        ${capTableName} ${firstLowerCapTableName} = new ${capTableName}();
        post${capTableName}InputTo${capTableName}(${firstLowerCapTableName}, post${capTableName}Input);
        return ${firstLowerCapTableName}DAO.insert${capTableName}(${firstLowerCapTableName});
    }

    /**
     * 修改${tableCName}
     */
    public ResultInfo put${capTableName}(Put${capTableName}Input put${capTableName}Input) {
        ${capTableName} ${firstLowerCapTableName} = new ${capTableName}();
        put${capTableName}InputTo${capTableName}(${firstLowerCapTableName}, put${capTableName}Input);
        return ${firstLowerCapTableName}DAO.update${capTableName}(${firstLowerCapTableName});
    }

    /**
     * 删除${tableCName}
     */
    public ResultInfo delete${capTableName}(${dataTypeInputParam}${oFlagColumnStr}) {
        return ${firstLowerCapTableName}DAO.delete${capTableName}(${inputParam}${oFlagColumnActualParamStr});
    }

    /**
     * 单条查询
     */
    public ${capTableName} get${capTableName}(${dataTypeInputParam}) {
        return ${firstLowerCapTableName}DAO.get${capTableName}(${inputParam});
    }

    /**
     * 多条查询
     */
    public QueryPage<${capTableName}> get${capTableName}Page(Get${capTableName}PageInput input) {
        return ${firstLowerCapTableName}DAO.list${capTableName}s(input.getPageNo(), input.getPageSize());
    }
    
    @JRESCopy
    private void post${capTableName}InputTo${capTableName}(${capTableName} ${firstLowerCapTableName}, Post${capTableName}Input post${capTableName}Input){
    }
    
    @JRESCopy
    private void put${capTableName}InputTo${capTableName}(${capTableName} ${firstLowerCapTableName}, Put${capTableName}Input put${capTableName}Input){
    }

}
</#macro>