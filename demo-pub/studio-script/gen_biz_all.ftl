<#-- 
HEPType:接口
HEPName:接口一键生成微服务代码
HEPSelect:分组
-->
<#-- 构造要执行的模板脚本的数组 -->
<#assign files = ["gen_biz_controller.ftl", "gen_biz_service.ftl", "gen_biz_service_impl.ftl"]>
<#-- 执行数组中配置的脚本 -->
${util.executeFreeMarkers(files, element, model, util.getMap())}