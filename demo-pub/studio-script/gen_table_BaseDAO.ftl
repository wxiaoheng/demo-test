<#-- 
HEPType:数据库表
HEPName:生成BaseDAO接口
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
    <#-- 如果表名包含下划线，去除前缀 -->
    <#if stringUtil.indexOf(tableName,"_") gte 0>
        <#local withoutPrefixTableName = tableName?keep_after("_")>
    <#else>
        <#local withoutPrefixTableName = tableName>
    </#if>
    <#-- 表名去下划线 -->
    <#local firstLowerCapTableName = stringUtil.replace(withoutPrefixTableName,"_","")>
    <#-- 类名首字母大写 -->
    <#local capTableNameFirst = stringUtil.toUpperCase(firstLowerCapTableName,1)>
    ${fileUtil.setFile(projectPath + "/src/main/java/" + stringUtil.convertStr2Path(groupId) + "/" + stringUtil.convertStr2Path(artifactId) + "/dao/base/Base" + capTableNameFirst + "DAO.java")}<#t>
    <#-- 该表需要做日终操作 -->
    <#local needDayendClosing = (tableInfo.getTableFlag()?index_of("E") != -1)?then(true, false)/>
/**
 * 系统名称: UF3.0
 * 模块名称: UF3.0 demo
 * 类  名  称: Base${capTableNameFirst}DAO.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                    修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${groupId}.${artifactPackPath}.dao.base;

import com.hundsun.broker.base.mq.MessageInfo;
/**
 * ${capTableNameFirst}常用增删改查操作
 *
 * @author studio-auto
 * @date
 */
<#if (needDayendClosing)>
@Initialize(initTableName = "${tableName}", initCriteria = "${tableInfo.getClearCondition()}")
</#if>
public interface Base${capTableNameFirst}DAO extends MqDAO{
    <#local capTableName = stringUtil.toUpperCase(tableName)>
    <#local columns = tableInfo.getColumns()>
    <#local inputParam = "">
    <#local dataTypeInputParam = "">
    <#local tableIndex = tableInfo.getIndexs()>
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
                    <#local dataTypeInputParam += ", ">
                </#if>	
            </#list>
        </#if>
    </#list>
    <#local existComment = "是否存在">
    <#local insertComment = "新增">
    <#local modifyComment = "修改">
    <#local deleteComment = "删除">
    <#local selSingleComment = "单条查询">
    <#-- 乐观锁字段字符串 -->
    <#local oFlagColumnStr = ""/>
    <#list columns as column>
        <#if column.getMark()?upper_case?index_of("O") != -1>
            <#if stringUtil.isNotBlank(dataTypeInputParam) || stringUtil.isNotBlank(oFlagColumnStr)>
                <#local oFlagColumnStr += ", "/>
            </#if>
            <#local oFlagColumnStr += column.getRealDataType("java") + " " + stringUtil.toCamelCase(column.getName(),true)>
        </#if>
    </#list>
    <#-- 将数据库表字段 定义在BaseDao中，防止JRESSynData生成的方法中含有魔法值-->
    <#list columns as column>
    	<#local colName = column.getName()>
    	<#local colCName = column.getChineseName()>
    	<#local colUpperName = stringUtil.toUpperCase(colName)>
    /**
     * ${colCName}	
     */
    String ${colUpperName} = "${colName}";
    </#list>
    
    <@genComment commentName = existComment inputParam = inputParam/>
    @JRESExists("${tableName}")
    boolean exists${capTableNameFirst}(${dataTypeInputParam});
  
    <@genComment commentName = insertComment inputParam = firstLowerCapTableName/>      
    @JRESInsert("${tableName}")
    ResultInfo insert${capTableNameFirst}(${capTableNameFirst} ${firstLowerCapTableName});

    <@genComment commentName = modifyComment inputParam = firstLowerCapTableName/>         
    @JRESUpdate("${tableName}")
    ResultInfo update${capTableNameFirst}(${capTableNameFirst} ${firstLowerCapTableName});

    <@genComment commentName = deleteComment inputParam = inputParam/>
    @JRESDelete("${tableName}")
    ResultInfo delete${capTableNameFirst}(${dataTypeInputParam}${oFlagColumnStr});

    <@genComment commentName = selSingleComment inputParam = inputParam/>
    @JRESSelect("${tableName}")
    ${capTableNameFirst} get${capTableNameFirst}(${dataTypeInputParam});

    /**
     * 分页查询
     * 
     * @param pageNo
     * @param pageSize
     * @return
     */
    @JRESSelectPage("${tableName}")
    QueryPage<${capTableNameFirst}> list${capTableNameFirst}s(Integer pageNo, Integer pageSize);

    /**
     * 同步数据
     * 
     * @param message
     */
    @JRESSyncData("${tableName}")
    void syncData(MessageInfo<Object> message);
}
</#macro>

<#-- 删除方法javadoc形式参数注释，编码规范要求 -->
<#macro genComment commentName inputParam>
    <#local inputParamArr = inputParam?split(",")>
    /**
     * ${commentName} 
     *    
    <#list inputParamArr as param> 
     * @param ${param}
    </#list>
     * @return
     */    
</#macro>