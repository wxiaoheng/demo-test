<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = info.getGroupId()>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = info.getArtifactId()>
<#assign className = info.getClassName()>
/**
 * 系统名称: uf3.0
 * 模块名称: ${artifactId}
 * 类  名  称: ${className}Test.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                               修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${info.getTestCasePackage()};

import java.util.List;
import java.lang.reflect.InvocationTargetException;
<#if info.hasPrivateMethod()>
import java.lang.reflect.Method;
</#if>

<#if !info.isUtilClass()>
import org.springframework.beans.factory.annotation.Autowired;
</#if>
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.testng.Reporter;
import org.testng.annotations.Listeners;
import org.testng.annotations.Test;

<#if info.hasTypeInAllMethodRefTypes("SpecificationContext")>
import ${groupId}.base.BizContext;
</#if>
import ${info.getProjectBasePackage()}.TestContextConfig;
import com.hundsun.jrescloud.common.exception.BaseBizException;
import com.hundsun.studio.test.TestDbResult;
import com.hundsun.studio.test.TestResult;
import com.hundsun.studio.test.BaseTest;
import com.hundsun.studio.test.reportng.HTMLReporter;
import com.hundsun.studio.test.reportng.JUnitXMLReporter;
import com.hundsun.studio.test.util.TestUtil;
import ${info.getFullClassName()};
<#assign pojoPath = info.getClassPojoPackage()>
<#assign firstLowerClassName = util.firstChar2Lower(className)>
<#assign methods = info.getMethods()>
<#assign dataTypes = info.getDataTypes()>
<#list methods as method>
    <#list dataTypes as dataType>
import ${pojoPath}.${util.firstChar2Upper(method.getName())}_${dataType.getSuffix()};
    </#list>
</#list>

<#list info.getAllMethodRefFullTypes() as refType>
import ${refType};
</#list>

/**
 *
 * @author studio-auto
 */
@Transactional
//@Rollback(false),注释开启，则表示不进行数据库操作回滚
@ActiveProfiles("dev")
@Listeners({ HTMLReporter.class, JUnitXMLReporter.class })
@SpringBootTest(classes = { TestContextConfig.class })
public class ${className}Test extends BaseTest {

    <#if !info.isUtilClass()>
    @Autowired
    private ${className} ${firstLowerClassName};
    </#if>

    <#list methods as method>
        <#assign firstUpperMethodName = util.firstChar2Upper(method.getName())>
        <#assign returnType = method.getReturnType()>
        <#assign methodPrefix = "get">
	    <#if stringUtil.equalsIgnoreCase(returnType, "boolean")>
	        <#assign methodPrefix = "is">
	    </#if>
    @Test(dataProvider = "${className}DataProvider.set${firstUpperMethodName}", dataProviderClass = ${className}DataProvider.class)
    public void ${method.getName()}Test(${firstUpperMethodName}_TestCaseData testCaseData) throws InvocationTargetException {
        // 响应结果
		TestResult expectResult = new TestResult();
		TestResult actualResult = new TestResult();
		// 数据库结果
		List<TestDbResult> expectDbResultList = null;
		List<TestDbResult> actualDbResultList = null;
        //获取前置条件执行清空，插入表
        ${firstUpperMethodName}_BeforeData beforeData = testCaseData.getBeforeData();
        //获取输入数据
        ${firstUpperMethodName}_InPutData inPutData = testCaseData.getInPutData();
        //获取输出数据
        ${firstUpperMethodName}_OutPutCheckData outPutCheckData = testCaseData.getOutPutCheckData();
        //获取依赖数据
        ${firstUpperMethodName}_MockData mockData = testCaseData.getMockData();
        //获取数据库断言
        ${firstUpperMethodName}_DbCheckData dbCheckData = testCaseData.getDbCheckData();
        
        <#assign firstParma = firstLowerClassName>
		<#if info.isUtilClass()>
		    <#assign firstParma = "\"" + info.getFullClassName() + "\"">
		</#if>
		//若方法需要传参，则判断输入测试数据是否为空，为空，则直接跳过测试
		int methodParamNum = TestUtil.getMethodParamNum(${firstParma}, "${method.getName()}",
			new Class<?>[] {${genMethodParamTypeStrs(method)}});
		if (methodParamNum > 0 && inPutData == null) {
			Reporter.log("测试数据为空，跳过测试。 \r\n");
			allAssertFuntion(true);
			return;
		}
        
        // 执行前置处理
		if (beforeData != null) {
			Reporter.log("前置处理: 操作数据库，准备数据 {\r\n");
			prepareDbData(beforeData, applicationContext);
			Reporter.log("}\r\n");
		} else {
			Reporter.log("前置条件为空，跳过前置处理。\r\n");
		}
        
        // 构建预期结果数据包
        if(outPutCheckData != null) {
            expectResult.setErrorCode(outPutCheckData.getErrorCode());
			expectResult.setErrorMsg(outPutCheckData.getErrorMsg());
			<#if !util.isVoidType(returnType)>
			expectResult.setValue(outPutCheckData.getReturnData());
			</#if>
        }
        
        // 若存在数据库断言，则将断言添加到expectDbResultList
		if (dbCheckData != null) {
			expectDbResultList = prepareExpectDbResultList(dbCheckData);
		}
        
		//存在依赖，则构建 mock依赖对象 解析被测方法，根据被测方法来生成
		if (mockData != null) {
			Reporter.log("存在依赖条件，开始mock依赖对象{\r\n");
			List<${firstUpperMethodName}_MockDataPojo> mockDataPojoList = mockData.get${firstUpperMethodName}MockDataPojoList();
			for (${firstUpperMethodName}_MockDataPojo mockDataPojo : mockDataPojoList) {
			    mockDataPojo.mock();
			}
			Reporter.log("} \r\n");
		}
		
		//获取方法返回类型，初始化预期结果
		<#if stringUtil.equals("void", returnType)>
		String actualValue = null;
		<#elseif stringUtil.isNumberType(returnType)>
		${returnType} actualValue = 0;
		<#elseif stringUtil.equals("boolean", returnType)>
		${returnType} actualValue = false;
		<#elseif stringUtil.equals("byte", returnType)>
		${returnType} actualValue = 0;
		<#elseif stringUtil.equals("char", returnType)>
		${returnType} actualValue = 0;
		<#else>
		${returnType} actualValue = null;
		</#if>

		//调用被测方法，获取返回结果,若返回类型为void，则无返回结果值,则不需要将运行结果赋值给actualResult
		try {
			Reporter.log("调用被测方法{\r\n");
			Reporter.log("测试数据:" + TestUtil.toJsonString(inPutData) + "\r\n");

            <#assign callClass = firstLowerClassName>
            <#assign paramString = genMethodParamValueStrs(method)>
		    <#if info.isUtilClass()>
		        <#assign callClass = className>
		    </#if>
		    <#assign returnStr = "">
		    <#if !stringUtil.equals("void", returnType)>
		        <#assign returnStr = "actualValue = ">
		    </#if>
		    <#if method.isPublic()>
		    ${returnStr}${callClass}.${method.getName()}(${paramString});
		    <#else>
		    Method method = ${className}.class.getDeclaredMethod(${util.join(", ", "\"" + method.getName() + "\"", genMethodParamTypeStrs(method))});
			method.setAccessible(true);
			    <#if info.isUtilClass()>
		            <#assign callClass = "null">
		        </#if>
			${returnStr}<#if !util.isVoidType(returnType)>(${returnType}) </#if>method.invoke(${util.join(", ", callClass, paramString)});
		    </#if>
		    // 设置保存实际运行结果
			actualResult.setValue(actualValue);	
			Reporter.log("}\r\n");
			
			// 如果预期结果值存在需要进行数据断言，则查询数据库获取实际的数据库对象
			actualDbResultList = prepareActualDbResultList(expectDbResultList, applicationContext);
		} catch (BaseBizException e) {
			// 异常案例，需要补充结果
			actualResult.setErrorCode(e.getErrorCode());
			actualResult.setErrorMsg(e.getErrorMessage());
		} catch (Exception e) {
		    actualResult.setErrorCode("-999999");
			actualResult.setErrorMsg(e.getMessage());
		} finally {
			// 响应断言
			allAssertFuntion(actualResult, expectResult, actualDbResultList, expectDbResultList);
		}
    }
    
    </#list>
}

<#function genMethodParamValueStrs method>
    <#local joiner = util.newJoin(", ")>
    <#list method.getParams() as param>
        <#local typeInfo = param.getTypeInfo()>
        <#local typeName = typeInfo.getName()>
        <#local firstName = typeInfo.getFirstName()>
        <#if firstName == "SpecificationContext">
            <#local firstName = "BizContext">
        </#if>
        <#if util.isSimpleType(typeName) || util.isSimpleArrayType(typeName)>
            <#local joiner = joiner.add("inPutData." + util.getterName(param.getName(), firstName) + "()")>
        <#else>
            <#if util.isArrayType(typeName)>
                <#local firstName += "[]">
            </#if>
            <#local joiner = joiner.add("TestUtil.adapt(inPutData." + util.getterName(param.getName(), typeName) + "(), " + firstName + ".class)")>
        </#if>
    </#list>
    <#return joiner.toString()>
</#function>

<#function genMethodParamTypeStrs method>
    <#local joiner = util.newJoin(", ")>
    <#list method.getParams() as param>
        <#local typeInfo = param.getTypeInfo()>
        <#local firstName = typeInfo.getFirstName()>
        <#if firstName == "SpecificationContext">
            <#local firstName = "BizContext">
        </#if>
        <#if util.isArrayType(typeInfo.getName())>
            <#local joiner = joiner.add(firstName + "[].class")>
        <#else>
            <#local joiner = joiner.add(firstName + ".class")>
        </#if>
    </#list>
    <#return joiner.toString()>
</#function>