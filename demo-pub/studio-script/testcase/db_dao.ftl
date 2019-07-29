<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = info.getGroupId()>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = info.getArtifactId()>
<#assign className = info.getClassName()>
<#assign firstLowerClassName = myUtil.firstChar2Lower(className)>
/**
 * 系统名称: uf3.0
 * 模块名称: ${artifactId}
 * 类  名  称: ${className}Dao.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                               修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${info.getDbDaoPackage()};

import java.util.List;

import ${info.getDbEntityPackage()}.${className};

import org.springframework.jdbc.core.namedparam.BeanPropertySqlParameterSource;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.stereotype.Repository;
import com.hundsun.jres.studio.annotation.util.JRESStringUtils;
import com.hundsun.studio.test.pojo.TestPojo;
import com.hundsun.studio.test.dao.TestDao;
import com.hundsun.studio.test.dao.BaseTestDao;
import com.hundsun.jrescloud.common.exception.BaseBizException;

<#assign tableName = model.getName()>
<#assign columns = model.getColumns()>
<#assign columnStr = "">
<#assign columnValueStr = "">
<#assign columnAssignStr = "">
<#list columns as column>
    <#assign columnName = column.getName()>
    <#assign fieldName = myUtil.getCamelName(columnName, false)>
    <#assign columnStr += columnName>
    <#assign columnValueStr = columnValueStr + ":" + fieldName>
    <#assign columnAssignStr = columnAssignStr + columnName + "=:" + fieldName>
    <#if column?has_next>
        <#assign columnStr += ",">
        <#assign columnValueStr += ",">
        <#assign columnAssignStr += " and ">
    </#if>
</#list>
<#assign uniqueColumnAssignStr = "">
<#assign tableIndex = model.getIndexs()>
<#assign addUniqueValueStr = "">
<#list tableIndex as index>
    <#assign isUnique = index.isUnique()>
    <#assign mark = index.getMark()>
    <#if isUnique && mark!="H">
        <#assign uniqueColumnStr = index.getColumns()>
        <#list uniqueColumnStr as uniqueColumn>
            <#assign uniqueColumnName = uniqueColumn.getName()>
            <#assign uniqueColumnAssignStr = uniqueColumnAssignStr + uniqueColumnName + "=:" + uniqueColumnName>
            <#assign columnGetterName = firstLowerClassName+ "." + myUtil.getterName(uniqueColumnName, reference.getRealDataType(uniqueColumnName,"java")) + "()">
            <#assign addUniqueValueStr = addUniqueValueStr + ".addValue(\"" + uniqueColumnName + "\", " + (reference.getRealDataType(uniqueColumnName, "java") == "Character")?string('JRESStringUtils.valueOf('+columnGetterName+')',columnGetterName) + ")">
            <#if uniqueColumn?has_next>
                <#assign uniqueColumnAssignStr += " and ">
            </#if>	
        </#list>
    </#if>
</#list>
/**
 * 表${tableName}的Dao类，必须实现接口{@link TestDao}
 * @author studio-auto
 */
@Repository
public class ${className}Dao extends BaseTestDao {
	
	/**
	 * 根据对象，查询表记录
	 * @param ${firstLowerClassName}
	 * @return
	 */
	@Override
	public ${className}[] queryTable(TestPojo ${firstLowerClassName}) {
	    final String SELECT_SQL = "select ${columnStr} from ${tableName} where <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>${uniqueColumnAssignStr}<#else>${columnAssignStr}</#if>";
	    <#if stringUtil.isNotBlank(addUniqueValueStr)>
        MapSqlParameterSource sqlParameterSource = new MapSqlParameterSource()${addUniqueValueStr};
        <#else>
        BeanPropertySqlParameterSource sqlParameterSource = new BeanPropertySqlParameterSource(${firstLowerClassName});
        </#if>
        List<${className}> result = namedParameterJdbcTemplate.query(SELECT_SQL, sqlParameterSource, BeanPropertyRowMapper.newInstance(${className}.class));
        return result.toArray(new ${className}[result.size()]);
	}

	/**
	 * 根据对象，查询表记录数
	 * @param ${firstLowerClassName}
	 * @return
	 */
	@Override
	public int queryTableRowCount(TestPojo ${firstLowerClassName}) {
		final String ROWCOUNT_SQL = "select count(1) from ${tableName} where <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>${uniqueColumnAssignStr}<#else>${columnAssignStr}</#if>";
		<#if stringUtil.isNotBlank(addUniqueValueStr)>
        MapSqlParameterSource sqlParameterSource = new MapSqlParameterSource()${addUniqueValueStr};
        <#else>
        BeanPropertySqlParameterSource sqlParameterSource = new BeanPropertySqlParameterSource(${firstLowerClassName});
        </#if>
        return namedParameterJdbcTemplate.queryForObject(ROWCOUNT_SQL, sqlParameterSource, Integer.class);
	}

	/**
	 * 根据对象，插入一条记录
	 * @param ${firstLowerClassName}
	 * @return
	 */
	@Override
	public int insertTable(TestPojo ${firstLowerClassName}) {
		final String INSERT_SQL = "insert into ${tableName}(${columnStr}) values(${columnValueStr})";
		BeanPropertySqlParameterSource sqlParameterSource = new BeanPropertySqlParameterSource(${firstLowerClassName});
		return namedParameterJdbcTemplate.update(INSERT_SQL, sqlParameterSource);
	}

	/**
	 * 根据对象，删除已存在的记录
	 * @param ${firstLowerClassName}
	 * @return
	 */
	@Override
	public int deleteTable(TestPojo ${firstLowerClassName}) {
		<@genDeleteSql/>
	}

}

<#macro genDeleteSql>
    <#local errorParamStr = ""/>
    <#local uniqueColumnAssignStr = "">
    <#local addUniqueValueStr = "">
    <#local hasOFlagColumn = false/>
    <#list columns as column>
        <#local columnMark = column.getMark()/>
        <#if columnMark?upper_case?index_of("O") != -1>
            <#local hasOFlagColumn = true/>
            <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>
                <#local uniqueColumnAssignStr += " and "/>
            </#if>
            <#local columnName = column.getName()/>
            <#local columnGetterName = firstLowerClassName+ "." + myUtil.getterName(columnName, reference.getRealDataType(columnName,"java")) + "()">
            <#local errorParamStr += "(\"" + columnName + "\", " + columnGetterName + ")"/>
            <#local uniqueColumnAssignStr += columnName + "=:" + columnName/>
            <#local addUniqueValueStr += ".addValue(\"" + columnName + "\", " + (reference.getRealDataType(columnName, "java") == "Character")?string('JRESStringUtils.valueOf('+columnGetterName+')',columnGetterName) + ")"/>
        </#if>
    </#list>
    <#local tableIndex = model.getIndexs()>
    <#local hasUniqueIndex = false/>
    <#list tableIndex as index>
        <#local isUnique = index.isUnique()>
        <#local mark = index.getMark()>
        <#if isUnique && mark!="H">
            <#local uniqueColumnStr = index.getColumns()>
            <#if (uniqueColumnStr?size) != 0>
                <#local hasUniqueIndex = true/>
                <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>
                    <#local uniqueColumnAssignStr += " and "/>
                </#if>
            </#if>
            <#list uniqueColumnStr as uniqueColumn>
                <#local uniqueColumnName = uniqueColumn.getName()>
                <#local columnGetterName = firstLowerClassName+ "." + myUtil.getterName(uniqueColumnName, reference.getRealDataType(uniqueColumnName,"java")) + "()">
                <#local uniqueColumnAssignStr = uniqueColumnAssignStr + uniqueColumnName + "=:" + uniqueColumnName>
                <#local errorParamStr = errorParamStr + "(\"" + uniqueColumnName + "\", " + columnGetterName + ")"/>
                <#local addUniqueValueStr = addUniqueValueStr + ".addValue(\"" + uniqueColumnName + "\", " + (reference.getRealDataType(uniqueColumnName, "java") == "Character")?string('JRESStringUtils.valueOf('+columnGetterName+')',columnGetterName) + ")">
                <#if uniqueColumn?has_next>
                    <#local uniqueColumnAssignStr += " and ">
                </#if>
            </#list>
        </#if>
    </#list>
        final String DELETE_SQL = "delete from ${tableName} where <#if stringUtil.isNotBlank(uniqueColumnAssignStr)>${uniqueColumnAssignStr}<#else>${columnAssignStr}</#if>";
        <#if stringUtil.isNotBlank(addUniqueValueStr)>
        MapSqlParameterSource sqlParameterSource = new MapSqlParameterSource()${addUniqueValueStr};
        <#else>
        BeanPropertySqlParameterSource sqlParameterSource = new BeanPropertySqlParameterSource(${firstLowerClassName});
        </#if>
        int idx = namedParameterJdbcTemplate.update(DELETE_SQL, sqlParameterSource);
        <#if hasOFlagColumn>
        if (idx <= 0) {
            throw new BaseBizException(-999, "没有数据").setErrorMessage("${tableName}:${errorParamStr}");
        }
        </#if>
        return idx;
</#macro>