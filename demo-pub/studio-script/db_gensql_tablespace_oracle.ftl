<#assign path = util.openDirectory("")>
<#if stringUtil.isBlank(path)>
    ${util.dialog('生成Oracle表空间SQL取消！')}<#t>
<#else>
    <#-- 调用宏指令 -->
    <@main model.getOracleTableSpaceModels()/>
</#if>
<#-- 生成逻辑的主方法，tablespaces为表空间列表 -->
<#macro main tablespaces>
    ${fileUtil.setFile(path + "/ORDevice_" + util.getProjectProperty().getSubSysId() + ".sql")}<#t>
    <#list tablespaces as tablespace>
        <#local name = tablespace.getName()>
            -- 创建表空间${name}<#lt>
            declare<#lt>
              v_rowcount integer;<#lt>
            begin<#lt>
              select count(*) into v_rowcount from dual where exists(select * from v$tablespace a where a.name = upper('${name}'));<#lt>
              if v_rowcount > 0 then<#lt>
                execute immediate 'DROP TABLESPACE ${name} INCLUDING CONTENTS AND DATAFILES';<#lt>
              end if;<#lt>
            end;<#lt>
            /<#lt>
            create tablespace ${name}<#lt>
            datafile '${tablespace.getFileName()}'<#lt>
            <#local size = tablespace.getSize()/>
            <#if stringUtil.isNotBlank(size)>
                size ${size}<#lt>     
            </#if>
            extent management local<#lt>
            segment space management auto;<#lt>

    </#list>
</#macro>