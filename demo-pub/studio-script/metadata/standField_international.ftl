<#--
HEPType:标准字段
HEPName:标准字段国际化
-->
<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
	${util.dialog('标准字段国际化取消！')}
<#else>
export default {
  m: {
    i: {
      locale: 'zh-CN',
      field: {
      <#list model.getItems() as item>
      	${item.getName()}: '${item.getChineseName()}'<#if item?has_next>,</#if>
      </#list>
      }
    }
  }
}
<#assign fileName = "/zh-CN-field.js">
${fileUtil.setFile(path + fileName)}
</#if>