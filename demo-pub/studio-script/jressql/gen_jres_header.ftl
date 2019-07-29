<#-- JRESSQL相关注解对应的文件头模板 -->
<#-- 首字母大写的表名 -->
<#assign capTableNameFirst = stringUtil.toUpperCase(element.getInfo().getName(), 1)>
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