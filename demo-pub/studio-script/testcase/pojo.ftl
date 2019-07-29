<#assign isDbEntity = helper.isDbEntity()>
<#assign model = helper.getDataCategory()>
<#assign className = helper.getClassName()>
/**
 * 系统名称: uf3.0
 * 模块名称: ${helper.getArtifactId()}
 * 类  名  称: ${className}.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                               修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${helper.getPackageName()};

import java.util.List;
import java.util.ArrayList;
<#list helper.getAllRefType() as typeName>
    <#if typeName == "Map" || typeName == "Set" || typeName == "HashMap" || typeName == "HashSet" || typeName == "LinkedList">
import java.util.${typeName};
    <#elseif typeName == "SpecificationContext">
import ${helper.getGroupId()}.base.BizContext;
    </#if>
</#list>

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.hundsun.studio.test.pojo.BaseTestPojo;
<#if helper.isMockDataPojo()>
import com.hundsun.studio.test.MockObjectInfo;
    <#if helper.hasData()>
import com.hundsun.studio.test.MockObjectProvider;
import com.hundsun.studio.test.util.TestUtil;
import mockit.Mock;
import mockit.MockUp;
    </#if>
</#if>
<#assign imports = helper.collectImports()>
<#list imports as import>
import ${import};
</#list>

/**
 * ${helper.getChineseName()}
 * @author studio-auto
 */
public class ${className} extends BaseTestPojo<${className}> {

    @JsonIgnore
    public static final ${className} INSTANCE = new ${className}();

    <#assign head = model.getHead()>
    <#assign fieldStr = "">
    <#list head as headItem>
        <#assign varType = headItem.getVarType()>
        <#assign varName = headItem.getVarName()>
        <#assign fieldStr = fieldStr + varType + " " + varName>
        <#if headItem?has_next>
             <#assign fieldStr += ", ">
        </#if>
    /** ${headItem.getChineseName()} */
    private ${varType} ${varName};
    
    </#list>
    <#if helper.isMockDataPojo()>
    public ${className}() {}
    
    public ${className}(${fieldStr}) {
        super();
        <#list head as headItem>
            <#assign varName = headItem.getVarName()>
        this.${varName} = ${varName};
        </#list>
    }
    </#if>
    <#list head as headItem>
        <#assign varType = headItem.getVarType()>
        <#assign varName = headItem.getVarName()>
    public ${varType} ${util.getterName(varName, varType)}() {
        return ${varName};
    }
    
    public void ${util.setterName(varName)}(${varType} ${varName}) {
        this.${varName} = ${varName};
    }
    
    </#list>
    <#if helper.isMockDataPojo()>
    public MockObjectInfo getMockObjectInfo() {
    	return new MockObjectInfo(mockEntry);
    }
    
    public Object getMockValue() {
    	return null;
    }
    
    public void mock() {}
    </#if>

    /**
     * 新建默认数据集
     * @return
     */
    @Override
    public ${className}[] newDefaultDatas() {
        List<${className}> list = new ArrayList<>();
<#assign rowDatas = helper.getRowDatas()>
<#if helper.isMockDataPojo()>
    <#list rowDatas as rowData>
        <#assign mockObjectInfo = helper.getMockObjectInfo(rowData)>
            <#if mockObjectInfo?has_content>
                <#assign returnType = mockObjectInfo.getOutClassType()>
        {
            ${className} obj = new ${className}(${helper.genParamValueStr(rowData)}) {
        	     @Override
        	     public Object getMockValue() {
        		     for(${returnType} item : ${returnType}.INSTANCE.getDefaultDatas()) {
        		         if(item.getTestCaseGroupNo() == getReturnNo()) {
        		             return item.getReturnData();
        		         }
        		     }
        		     return null;
        	     }
        	     
        	     <#assign paramsClass = helper.getMockParamsClassStr(mockObjectInfo)>
        	     <#if !util.isBlank(paramsClass)>
        	     @Override
        	     public MockObjectInfo getMockObjectInfo() {
    	             return new MockObjectInfo(getMockEntry()) {
    		             @Override
    		             public Class<?>[] getParamsClass() {
    	                     return new Class[]{${paramsClass}};
    	                 }
    	             };
    	         }
    	         </#if>
    	         
    	         @Override
    	         public void mock() {
    	             new MockObjectProvider(getMockObjectInfo(), getMockValue()) {
						@Override
						protected void doMock(Class<?> mockClass, Object mockValue) {
							new MockUp<Object>(mockClass) {
								@Mock
								${helper.getMockMethodDefine(mockObjectInfo)} throws Exception {
								<#assign mockReturnType = mockObjectInfo.getSimpleReturnType()>
								<#if util.isSimpleType(mockReturnType)>
								    return (${mockReturnType}) mockValue;
								<#else>
								    return TestUtil.adapt(mockValue, ${mockReturnType}.class);
								</#if>
								}
							};
						}
					}.mock();
    	         }
             };
             list.add(obj);
        }
    
        </#if>    
    </#list>
<#else>
    <#list rowDatas as rowData>
        {
            ${className} obj = new ${className}();
        <#list rowData as dataEntry>
            <#assign fieldType = dataEntry.getFieldType()>
            <#assign fieldName = dataEntry.getFieldName()>
            <#assign value = dataEntry.getRealValue()>
            <#if !util.isBlank(value)>
                <#if util.isArrayType(fieldType)>
                     <#if util.isSimpleArrayType(fieldType)>
            obj.${fieldName} = new ${fieldType}{${value}};
                     <#else>
                         <#assign fieldType = util.removeArrayBrackets(fieldType)>
                         <#assign indexs = util.split(value, ",")>
            obj.${fieldName} = new ${fieldType}[${indexs?size}];
            {
                int index = 0;
                for(${fieldType} pojo : ${fieldType}.INSTANCE.getDefaultDatas()) {
                    int no = pojo.getTestCaseGroupNo();
                    if(${util.joinStringWithPrefix(" || ", "no == ", indexs)}) {
                        obj.${fieldName}[index] = pojo;
                        index++;
                    }
                }
            }
                     </#if>
                <#elseif util.isListType(fieldType)>
                    <#assign genericType = util.getGenericTypeInner(fieldType)>
            obj.${fieldName} = new ArrayList<>();
            for(${genericType} pojo : ${genericType}.INSTANCE.getDefaultDatas()) {
                int no = pojo.getTestCaseGroupNo();
                if(${util.joinStringWithPrefix(" || ", "no == ", util.split(value, ","))}) {
                    obj.${fieldName}.add(pojo);
                }
            }
                <#elseif util.getGenericTypePrefix(fieldType) == "SpecificationContext">
                    <#assign genericType = util.getGenericTypeInner(fieldType)>
            for(${genericType} pojo : ${genericType}.INSTANCE.getDefaultDatas()) {
                if(pojo.getTestCaseGroupNo() == ${value}) {
                    obj.${fieldName} = new BizContext<>(pojo);
                    break;
                }
            }
                <#elseif util.isUserObjType(fieldType)>
            for(${fieldType} pojo : ${fieldType}.INSTANCE.getDefaultDatas()) {
                if(pojo.getTestCaseGroupNo() == ${value}) {
                    obj.${fieldName} = pojo;
                    break;
                }
            }
                <#else>
            obj.${fieldName} = ${value};
                </#if>
            </#if>
        </#list>
            list.add(obj);
        }
        
    </#list>
</#if>
        return list.toArray(new ${className}[list.size()]);
    }
    
}