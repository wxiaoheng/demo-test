<#-- 所选资源所在工程的pom文件的GroupId -->
<#assign groupId = info.getGroupId()>
<#-- 所选资源所在工程的pom文件的ArtifactId -->
<#assign artifactId = info.getArtifactId()>
<#assign className = info.getClassName()>
/**
 * 系统名称: uf3.0
 * 模块名称: ${artifactId}
 * 类  名  称: ${className}DataProvider.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                               修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${info.getTestCasePackage()};

import org.testng.annotations.DataProvider;
<#assign pojoPath = info.getClassPojoPackage()>
<#assign methods = info.getMethods()>
<#list methods as method>
import ${pojoPath}.${util.firstChar2Upper(method.getName())}_TestCaseData;
</#list>

/**
 *
 * @author studio-auto
 */
public class ${className}DataProvider {

    <#list methods as method>
    <#assign firstUpperMethodName = util.firstChar2Upper(method.getName())>
    @DataProvider(name = "${className}DataProvider.set${firstUpperMethodName}")
    public ${firstUpperMethodName}_TestCaseData[][] set${firstUpperMethodName}() {
        return ${firstUpperMethodName}_TestCaseData.INSTANCE.newDefaultDataArray();
    }
    
    </#list>
}