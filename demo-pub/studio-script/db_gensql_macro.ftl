<#-- 这个模板文件存放生成数据库脚本所需的宏 -->

<#-- 生成全量SQL的宏指令 -->
<#macro genTableCreateSql4MySQL tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#assign tableFlag = tableInfo.getTableFlag()>
    <#assign prev = tableFlag?index_of("P")> 
create table if not exists `${tableName}` (
    <#-- 调用函数 -->
    <#local columnSql = genTableColumnSql4MySQL(tableInfo)>
    <#local indexSql = genIndexSql4MySQL(tableInfo)>
    <#if columnSql?length gt 0>
${columnSql}<#if columnSql?length gt 0 && indexSql?length gt 0>,</#if>
    </#if>
    <#if indexSql?length gt 0>
${indexSql}
    </#if>
)comment = '${tableInfo.getChineseName()}';
commit;
<#if prev gte 0>
	<#assign prevTableName = "">
	<#assign nameArr = tableName?split("_")>
	<#if nameArr?size gt 1>
		<#list nameArr as name>
			<#if name_index = 0>
				<#assign prevTableName = prevTableName+name+"_">
				<#assign prevTableName = prevTableName+"prev_">
			<#elseif name_index = nameArr?size-1>
				<#assign prevTableName = prevTableName+name>
			<#else>
			<#assign prevTableName = prevTableName+name+"_">	
			</#if>		
		</#list>
	<#else>
		<#assign prevTableName = "prev_"+tableName>
	</#if>

-- 上日表全量脚本
create table if not exists `${prevTableName}` (
    <#-- 调用函数 -->
    <#local columnSql = genTableColumnSql4MySQL(tableInfo)>
    <#local indexSql = genIndexSql4MySQL(tableInfo)>
    <#if columnSql?length gt 0>
${columnSql}<#if columnSql?length gt 0 && indexSql?length gt 0></#if>
    </#if>
);
</#if>
</#macro>


<#-- 生成数据库表字段SQL的函数 -->
<#function genTableColumnSql4MySQL tableInfo>
    <#local columns = tableInfo.getColumns()>
    <#local columnStr = "">
    <#list columns as column>
            <#local columnName = column.getName()>
            <#local columnType = column.getRealDataType("mysql")>
            <#local isNullable = column.isNullable()>
            <#local defaultValue = column.getRealDataDefValue("mysql")>
            <#local cname = column.getChineseName()>
            <#-- 一个字段的SQL拼接 -->
            <#local columnStr = columnStr + "\t`" + columnName + "` " + columnType>
            <#if isNullable>
                <#local columnStr += " null">
            <#else>
                <#local columnStr += " not null">
            </#if>
            <#if stringUtil.isNotBlank(defaultValue)>
                <#local columnStr += " default " + defaultValue>
            </#if>
            <#if stringUtil.isNotBlank(cname)>
                <#local columnStr += " comment '" + cname + "'">
            </#if>
            <#if column?has_next>
                <#local columnStr += ",\r\n">
            </#if>
    </#list>
    <#return columnStr>
</#function>


<#-- 生成数据库表索引SQL的函数 -->
<#function genIndexSql4MySQL tableInfo>
    <#local indexes = tableInfo.getIndexs()>
    <#local indexStr = "">
    <#list indexes as index>
            <#local indexName = index.getName()>
            <#local isPrimary = index.isPrimary()>
            <#local isUnique = index.isUnique()>
            <#local indexColumns = index.getColumns()>
            <#-- 一条索引的SQL拼接 -->
            <#if isPrimary>
                <#local indexStr += "primary key(">
                <#list indexColumns as indexColumn>
                    <#local indexStr = indexStr + "`" + indexColumn.getName() + "`">
                    <#if indexColumn?has_next>
                        <#local indexStr += ",">
                    <#else>
                        <#local indexStr += ")">
                    </#if>
                </#list>
            <#else>
                <#if isUnique>
                    <#local indexStr += "unique index `" + indexName + "` (">
                <#else>
                    <#local indexStr += "index `" + indexName + "` (">
                </#if>
                <#list indexColumns as indexColumn>
                    <#local indexStr = indexStr + "`" + indexColumn.getName() + "`">
                    <#if indexColumn.isAscending()>
                        <#local indexStr += " asc">
                    </#if>
                    <#if indexColumn?has_next>
                        <#local indexStr += ",">
                    <#else>
                        <#local indexStr += ")">
                    </#if>
                </#list>
            </#if>
            <#if index?has_next>
                <#local indexStr += ",\r\n">
            </#if>
    </#list>
    <#return indexStr>
</#function>


<#-- 生成增量SQL的宏指令 -->
<#macro genTablePatchSql4MySQL tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#local histories = tableInfo.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <@genHistoryPatch4MySQL tableInfo = tableInfo action = action/>
        </#if>

    </#list>
</#macro>


<#macro genHistoryPatch4MySQL tableInfo action>
    <#local type = action.getType()>
-- ${type}
    <#if stringUtil.equals(type, "新建表")>
        <#-- 导入生成全量SQL的脚本 -->
        <@genTableCreateSql4MySQL tableInfo = action.getInfo()/>
    <#else>
drop procedure if exists sp_db_mysql;
delimiter $$
    create procedure sp_db_mysql()
        begin
            declare v_rowcount int;
            declare database_name varchar(100);
            select database() into database_name;
        <#if stringUtil.equals(type, "增加表字段")>
<@genAddColumnAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "删除表字段")>
<@genRemoveColumnAction4MySQL action = action/>
    <#elseif stringUtil.equals(type, "重命名表字段")>
<@genRenameColumnAction4MySQL action = action/>
    <#-- 不处理，因为表字段需为标准字段，所以这个修改类型没有意义
    <#elseif stringUtil.equals(type, "修改表字段类型")>
        <#local patchSql = genAddColumnAction4Oracle(action)>
${patchSql} -->
        <#elseif stringUtil.equals(type, "修改表字段默认值")>
<@genModifyColumnAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "修改表字段是否允许为空")>
<@genModifyColumnAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "增加索引")>
<@genAddIndexAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "删除索引")>
<@genRemoveIndexAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "修改索引")>
<@genModifyIndexAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "调整索引唯一性")>
<@genModifyIndexAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "增加索引字段")>
<@genModifyIndexColumnAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "删除索引字段")>
<@genModifyIndexColumnAction4MySQL action = action/>
        <#elseif stringUtil.equals(type, "调整索引字段顺序")>
<@genModifyIndexAction4MySQL action = action/>
        </#if>
        end$$
delimiter ;
call sp_db_mysql();
drop procedure if exists sp_db_mysql;
    </#if>
</#macro>


<#-- 增加表字段增量SQL生成 -->
<#macro genAddColumnAction4MySQL action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("mysql")>
        <#local isNullable = column.isNullable()>
        <#local cName = column.getChineseName()>
        <#local defaultValue = column.getRealDataDefValue("mysql")>
            select count(1) into v_rowcount from information_schema.columns where table_schema = database_name and table_name = '${tableName}' and column_name = '${columnName}';
            if v_rowcount = 0 then
                alter table ${tableName} add column ${columnName} ${columnType}<#if !isNullable> not null</#if><#if stringUtil.isNotBlank(defaultValue)> default ${defaultValue}</#if><#if stringUtil.isNotBlank(cName)> comment '${cName}'</#if>;
            end if;
    </#list>
</#macro>


<#-- 删除表字段增量SQL生成 -->
<#macro genRemoveColumnAction4MySQL action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
            select count(1) into v_rowcount from information_schema.columns where table_schema = database_name and table_name = '${tableName}' and column_name = '${columnName}';
            if v_rowcount = 1 then
                alter table ${tableName} drop column ${columnName};
            end if;
    </#list>
</#macro>


<#-- 重命名表字段增量SQL生成 -->
<#macro genRenameColumnAction4MySQL action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnNewName = column.getNewName()>
        <#local newColumn = column.getNewColumn()>
        <#local columnType = newColumn.getRealDataType("mysql")>
        <#local isNullable = newColumn.isNullable()>
        <#local cname = newColumn.getChineseName()>
        <#local defaultValue = newColumn.getRealDataDefValue("mysql")>
            select count(1) into v_rowcount from information_schema.columns where table_schema = database_name and table_name = '${tableName}' and column_name = '${columnName}';
            if v_rowcount = 1 then
                alter table ${tableName} change ${columnName} ${columnNewName} ${columnType}<#if !isNullable> not null</#if><#if stringUtil.isNotBlank(defaultValue)> default ${defaultValue}</#if><#if stringUtil.isNotBlank(cname)> comment '${cname}'</#if>;
           		 <#list column.getIndexs() as index>
			         <#if index.isPrimary()>
			            execute immediate 'alter table ${tableSchema}.${tableName} drop primary key cascade';
			        <#else>
			            execute immediate 'drop index ${tableSchema}.${index.getName()}';
			        </#if>
			        <@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
			        </#list>
             end if;
    </#list>
</#macro>


<#-- 修改表字段增量SQL生成 -->
<#macro genModifyColumnAction4MySQL action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("mysql")>
        <#local isNullable = column.isNullable()>
        <#local defaultValue = column.getRealDataDefValue("mysql")>
            select count(1) into v_rowcount from information_schema.columns where table_schema = database_name and table_name = '${tableName}' and column_name = '${columnName}';
            if v_rowcount = 1 then
                alter table ${tableName} change column ${columnName} ${columnName} ${columnType}<#if !isNullable> not null</#if><#if stringUtil.isNotBlank(defaultValue)> default ${defaultValue}</#if>;
            end if;
    </#list>
</#macro>


<#-- 增加索引增量SQL生成 -->
<#macro genAddIndexAction4MySQL action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
            select count(1) into v_rowcount from information_schema.statistics
                where table_schema = database_name and table_name = '${tableName}' and index_name = '<#if index.isPrimary()>primary<#else>${index.getName()}</#if>';
            if v_rowcount = 0 then
    <@genAddIndexSql4MySQL index = index indexColumns = index.getColumns()/>

            end if;
    </#list>
</#macro>


<#-- 生成索引创建SQL -->
<#macro genAddIndexSql4MySQL index indexColumns>
    <#if indexColumns?size == 0>
        <#return>
    </#if>
            alter table ${tableName}<#rt>
    <#if index.isPrimary()>
 add primary key(<#rt>
    <#else>
 add<#if index.isUnique()> unique</#if> index ${index.getName()}(<#rt>
    </#if>
    <#list indexColumns as indexColumn>
        ${indexColumn.getName()}<#if indexColumn.isAscending()> asc</#if><#if indexColumn?has_next>, <#else>);</#if><#t>
    </#list>
</#macro>


<#-- 删除索引增量SQL生成 -->
<#macro genRemoveIndexAction4MySQL action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
            select count(1) into v_rowcount from information_schema.statistics
                where table_schema = database_name and table_name = '${tableName}' and index_name = '<#if isPrimary>primary<#else>${indexName}</#if>';
            if v_rowcount > 0 then
                alter table ${tableName}<#rt>
        <#if isPrimary>
 drop primary key;
        <#else>
 drop index ${indexName};
        </#if>
            end if;
    </#list>
</#macro>


<#-- 修改索引增量SQL生成，不能进行主键相关修改，执行结果不正确 -->
<#macro genModifyIndexAction4MySQL action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
            select count(1) into v_rowcount from information_schema.statistics
                where table_schema = database_name and table_name = '${tableName}' and index_name = '<#if isPrimary>primary<#else>${indexName}</#if>';
            if v_rowcount > 0 then
                alter table ${tableName}<#rt>
        <#if isPrimary>
 drop primary key;
        <#else>
 drop index ${indexName};
        </#if>
            end if;
<@genAddIndexSql4MySQL index = index indexColumns = index.getColumns()/>

    </#list>
</#macro>


<#-- 修改索引字段增量SQL -->
<#macro genModifyIndexColumnAction4MySQL action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
            select count(1) into v_rowcount from information_schema.statistics
                where table_schema = database_name and table_name = '${tableName}' and index_name = '<#if isPrimary>primary<#else>${indexName}</#if>';
            if v_rowcount > 0 then
                alter table ${tableName}<#rt>
        <#if isPrimary>
 drop primary key;
        <#else>
 drop index ${indexName};
        </#if>
            end if;
<@genAddIndexSql4MySQL index = index indexColumns = index.getResultColumns()/>

    </#list>
</#macro>


<#-- 生成全量SQL的宏指令 -->
<#macro genTableCreateSql4Oracle tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#assign tableSchema = tableInfo.getSchema()>
    <#assign tableSpace = tableInfo.getTableSpace()>
    <#assign idxSpace = tableInfo.getTableIndexSpace()>
    <#assign tableType = tableInfo.getTableType()>
    <#assign tableVersion = tableInfo.getVersion()>
    <#assign masterVer = stringUtil.substring(tableVersion,1,stringUtil.indexOf(tableVersion,'.'))>
    <#assign secondVer = stringUtil.substring(tableVersion?keep_after("V" + masterVer + "."),0,stringUtil.indexOf(tableVersion?keep_after("V" + masterVer + "."),'.'))>
    <#assign thirdVer = stringUtil.substring(tableVersion?keep_after("V" + masterVer + "." + secondVer + "."),0,stringUtil.indexOf(tableVersion?keep_after("V" + masterVer + "." + secondVer + "."),'.'))>
    <#assign buildVer = tableVersion?keep_after("V" + masterVer + "." + secondVer + "." + thirdVer + ".")>
    <#assign tableFlag = tableInfo.getTableFlag()>
    <#assign prev = tableFlag?index_of("P")> 
prompt
prompt 检查表${tableName} 表是否存在，不存在则创建......
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from user_tables where table_name = upper('${tableName}');
    if v_rowcount = 0 then
        execute immediate '
        create table ${tableSchema}.${tableName}
        (
        <#-- 调用函数 -->
<@genTableColumnSql4Oracle tableInfo = tableInfo/>

        )
        storage(freelists 20 freelist groups 2)
        nologging
        tablespace ${tableSpace} ';
        <@genIndexSql4Oracle tableInfo = tableInfo/>
        
        <@genTableComment4Oracle tableInfo = tableInfo tableName = tableName/>
        commit;
    end if;
end;
/
<#if prev gte 0>
	<#assign prevTableName = "">
	<#assign nameArr = tableName?split("_")>
	<#if nameArr?size gt 1>
		<#list nameArr as name>
			<#if name_index = 0>
				<#assign prevTableName = prevTableName+name+"_">
				<#assign prevTableName = prevTableName+"prev_">
			<#elseif name_index = nameArr?size-1>
				<#assign prevTableName = prevTableName+name>
			<#else>
			<#assign prevTableName = prevTableName+name+"_">	
			</#if>		
		</#list>
	<#else>
		<#assign prevTableName = "prev_"+tableName>
	</#if>

-- 上日表全量脚本
prompt
prompt 检查表${prevTableName} 表是否存在，不存在则创建......
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from user_tables where table_name = upper('${prevTableName}');
    if v_rowcount = 0 then
        execute immediate '
        create table ${tableSchema}.${prevTableName}
        (
        <#-- 调用函数 -->
<@genTableColumnSql4Oracle tableInfo = tableInfo/>

        )
        storage(freelists 20 freelist groups 2)
        nologging
        tablespace ${tableSpace} ';       
        
        <@genTableComment4Oracle tableInfo = tableInfo tableName = prevTableName/>
        commit;
    end if;
end;
/		
</#if>
</#macro>
        
    end if;
end;
/

<#-- 生成字段备注信息的宏指令 -->
<#macro genTableComment4Oracle tableInfo,tableName>
    <#local tableName = tableName>
    <#local tableSchema = tableInfo.getSchema()>
    <#local tableChinese = tableInfo.getChineseName()>
        execute immediate 'comment on table ${tableSchema}.${tableName} is ''${tableChinese}''';
    <#local columns = tableInfo.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnChinese = column.getChineseName()>
        execute immediate 'comment on column ${tableSchema}.${tableName}.${columnName} is ''${columnChinese}''';
    </#list>
</#macro>

<#-- 生成数据库表字段SQL的函数 -->
<#macro genTableColumnSql4Oracle tableInfo>
    <#local columns = tableInfo.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("oracle")>
        <#local isNullable = column.isNullable()>
        <#local defaultValue = column.getRealDataDefValue("oracle")>
            ${columnName} ${columnType}<#if stringUtil.isNotBlank(defaultValue)> default ${stringUtil.convertSingleQuote(defaultValue)}</#if><#if !isNullable> not null</#if><#rt>
            <#if column?has_next>
                ,<#lt>
            </#if>
    </#list>
</#macro>


<#-- 生成数据库表索引SQL的函数 -->
<#macro genIndexSql4Oracle tableInfo>
    <#local indexes = tableInfo.getIndexs()>
    <#list indexes as index>
            <#local indexName = index.getName()>
            <#local isPrimary = index.isPrimary()>
            <#local isUnique = index.isUnique()>
            <#local indexColumns = index.getColumns()>
            <#if isPrimary>
        execute immediate 'alter table ${tableName} add constraint ${indexName} primary key(<#rt>
            <#else>
        execute immediate 'create<#if isUnique> unique</#if> index ${tableSchema}.${indexName} on ${tableSchema}.${tableName}(<#rt>
            </#if>
            <#list indexColumns as indexColumn>
                ${indexColumn.getName()}<#t>
                <#if !isPrimary>
                    <#if indexColumn.isAscending()>
 asc<#rt>
                    </#if>
                </#if>
                <#if indexColumn?has_next>
                    ,<#t>
                </#if>
            </#list>
            ) tablespace ${idxSpace}';<#lt>
    </#list></#macro>


<#-- 生成增量SQL的宏指令 -->
<#macro genTablePatchSql4Oracle tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#assign tableSchema = tableInfo.getSchema()>
    <#local histories = tableInfo.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <@genHistoryPatch4Oracle tableInfo = tableInfo action = action/>
        </#if>
        
    </#list>
</#macro>


<#macro genHistoryPatch4Oracle tableInfo action>
    <#local patchSql = "">
    <#local type = action.getType()>
    <#if stringUtil.equals(type, "新建表")>
        <#-- 导入生成全量SQL的脚本 -->
        <@genTableCreateSql4Oracle tableInfo = action.getInfo()/>
    <#else>
        <#if stringUtil.equals(type, "增加表字段")>
<@genAddColumnAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "删除表字段")>
<@genRemoveColumnAction4Oracle action = action/>
    <#elseif stringUtil.equals(type, "重命名表字段")>	
<@genRenameColumnAction4Oracle action = action/>
    <#-- 不处理，因为表字段需为标准字段，所以这个修改类型没有意义
    <#elseif stringUtil.equals(type, "修改表字段类型")>
        <#local patchSql = genAddColumnAction4Oracle(action)>
${patchSql} -->
        <#elseif stringUtil.equals(type, "修改表字段默认值")>
<@genModifyColumnDefaultValueAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "修改表字段是否允许为空")>
<@genModifyColumnNullableAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "增加索引")>
<@genAddIndexAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "删除索引")>
<@genRemoveIndexAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "修改索引")>
<@genModifyIndexAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "调整索引唯一性")>
<@genModIndexColumnUniqueAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "增加索引字段")>
<@genAddIndexColumnAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "删除索引字段")>
<@genDelIndexColumnAction4Oracle action = action/>
        <#elseif stringUtil.equals(type, "调整索引字段顺序")>
<@genModIndexColumnOrderAction4Oracle action = action/>
        </#if>
end;
/

    </#if>
</#macro>


<#-- 增加表字段增量SQL生成 -->
<#macro genAddColumnAction4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("oracle")>
        <#local isNullable = column.isNullable()>
        <#local defaultValue = column.getRealDataDefValue("oracle")>
-- ${tableName}表增加字段 ${columnName}
prompt
prompt 检查 ${tableName} 表 是否存在 ${columnName} 字段, 不存在则增加......
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from col where tname = upper('${tableName}') and cname = upper('${columnName}');
    if v_rowcount = 0 then
        execute immediate 'alter table ${tableSchema}.${tableName} add ${columnName} ${columnType}<#if stringUtil.isNotBlank(defaultValue)> default ${stringUtil.convertSingleQuote(defaultValue)}</#if><#if !isNullable> not null</#if>';
        <@genAddComment4Oracle action = action/>
    end if;
    </#list>
</#macro>

<#-- 增加表字段备注信息增量SQL生成 -->
<#macro genAddComment4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
    <#local columnName = column.getName()>
    <#local columnChinese = column.getChineseName()>     
        execute immediate 'comment on column ${tableName}.${columnName} is ''${columnChinese}''';
    </#list>
</#macro>


<#-- 删除表字段增量SQL生成 -->
<#macro genRemoveColumnAction4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
-- ${tableName}表删除字段 ${columnName}
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from col where tname = upper('${tableName}') and cname = upper('${columnName}');
    if v_rowcount = 1 then
        execute immediate 'alter table ${tableSchema}.${tableName} drop column ${columnName}';
    end if;
    </#list>
</#macro>


<#-- 重命名表字段增量SQL生成 -->
<#macro genRenameColumnAction4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnNewName = column.getNewName()>
        <#local newColumn = column.getNewColumn()>
        <#local oldType = column.getRealDataType("oracle")>
        <#local columnType = newColumn.getRealDataType("oracle")>
        <#local isNullable = newColumn.isNullable()>
        <#local defaultValue = newColumn.getRealDataDefValue("oracle")>
-- 重命名表字段
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from col where tname = upper('${tableName}') and cname = upper('${columnName}');
    if v_rowcount = 1 then
        execute immediate 'alter table ${tableName} rename ${columnName} to ${columnNewName}';
        execute immediate 'comment on column ${tableSchema}.${tableName}.${columnNewName} is ''${newColumn.getChineseName()}''';
        <#if !(stringUtil.equalsIgnoreCase(oldType, columnType))>
        execute immediate 'alter table ${tableName} modify ${columnNewName} ${columnType} ';
        </#if>
        <#list column.getIndexs() as index>
         <#if index.isPrimary()>
            execute immediate 'alter table ${tableSchema}.${tableName} drop primary key cascade';
        <#else>
            execute immediate 'drop index ${tableSchema}.${index.getName()}';
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
        </#list>
    end if;
    </#list>
</#macro>


<#-- 修改表字段默认值增量SQL生成 -->
<#macro genModifyColumnDefaultValueAction4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("oracle")>
        <#local isNullable = column.isNullable()>
        <#local defaultValue = column.getRealDataDefValue("oracle")>
-- 修改表字段默认值
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from col where tname = upper('${tableName}') and cname = upper('${columnName}');
    if v_rowcount = 1 then
        execute immediate 'alter table ${tableName} modify ${columnName} ${columnType}<#if stringUtil.isNotBlank(defaultValue)> default ${stringUtil.convertSingleQuote(defaultValue)}</#if>';
    end if;
    </#list>
</#macro>


<#-- 修改表字段是否为空增量SQL生成，是否为空修改前后不能一样，否则执行会报错 -->
<#macro genModifyColumnNullableAction4Oracle action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnType = column.getRealDataType("oracle")>
        <#local isNullable = column.isNullable()>
        <#local defaultValue = column.getRealDataDefValue("oracle")>
-- 修改表字段是否为空
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from col where tname = upper('${tableName}') and cname = upper('${columnName}');
    if v_rowcount = 1 then
        execute immediate 'alter table ${tableName} modify ${columnName} ${columnType}<#if !isNullable> not null</#if>';
    end if;
    </#list>
</#macro>


<#-- 增加索引增量SQL生成 -->
<#macro genAddIndexAction4Oracle action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
-- ${tableName} 表增加索引 ${index.getName()}
prompt
prompt 检查 ${tableName} 表 是否存在索引${index.getName()}，不存在则新增...
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from user_indexes where index_name = upper('${index.getName()}') and table_name = upper('${tableName}');
    if v_rowcount = 0 then
<@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
    end if;
    </#list>
</#macro>


<#-- 生成索引创建SQL，索引字段列表不能与其他索引相同，否则执行报错 -->
<#macro genAddIndexSql4Oracle index indexColumns>
    <#if indexColumns?size == 0>
        <#return>
    </#if>
        execute immediate '<#rt>
    <#if index.isPrimary()>
        alter table ${tableSchema}.${tableName} add constraint ${index.getName()} primary key(<#t>
    <#else>
        create<#if index.isUnique()> unique</#if> index ${index.getName()} on ${tableSchema}.${tableName}(<#t>
    </#if>
    <#list indexColumns as indexColumn>
        ${indexColumn.getName()}<#t>
        <#if !index.isPrimary()>
            <#if indexColumn.isAscending()>
 asc<#rt>
            </#if>
        </#if>
        <#if indexColumn?has_next>
            ,<#t>
        </#if>
    </#list>
    )';<#lt>
</#macro>


<#-- 删除索引增量SQL生成 -->
<#macro genRemoveIndexAction4Oracle action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
-- ${tableName} 表删除索引 ${index.getName()}
prompt
prompt 检查 ${tableName} 表 是否存在索引${index.getName()}，存在则删除...
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from user_indexes where index_name = upper('${index.getName()}') and table_name = upper('${tableName}');
    if v_rowcount = 1 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
    end if;
    </#list>
</#macro>

<#-- 修改索引增量SQL生成，不能进行主键相关修改，执行结果不正确 -->
<#macro genModifyIndexAction4Oracle action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
-- ${tableName} 表修改索引 ${index.getName()}
prompt
prompt 检查 ${tableName} 表 是否存在索引${index.getName()}，存在则更新...
declare v_rowcount number(10);
begin
    select count(1) into v_rowcount from user_indexes where index_name = upper('${index.getName()}') and table_name = upper('${tableName}');
    if v_rowcount = 1 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
    end if;
    </#list>
</#macro>

<#-- 增加索引字段增量SQL -->
<#macro genAddIndexColumnAction4Oracle action>
    <#local indexes = action.getIndexs()>
    
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
        <#local newColumns = index.getNewColumns()>
        <#list newColumns as newcol>
            <#local colName = newcol.getName()>
            <#break>
        </#list>
-- ${tableName} 表索引 ${index.getName()} 增加字段
prompt
prompt 检查 ${tableName} 表 索引${index.getName()}是否存在字段${colName}，不存在则删除索引重建索引...
declare v_rowcount number(10);
begin
    select count(1) 
      into v_rowcount 
      from user_ind_columns 
     where index_name = upper('${index.getName()}') 
       and column_name = upper('${colName}') 
       and table_name = upper('${tableName}');
    if v_rowcount = 0 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getResultColumns()/>
    end if;
    </#list>
</#macro>


<#-- 删除索引字段增量SQL -->
<#macro genDelIndexColumnAction4Oracle action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
        <#local newColumns = index.getNewColumns()>
        <#list newColumns as newcol>
            <#local colName = newcol.getName()>
            <#break>
        </#list>
-- ${tableName} 表索引 ${index.getName()} 删除字段
prompt
prompt 检查 ${tableName} 表 索引${index.getName()}是否存在字段${colName}，存在则删除索引重建索引...
declare v_rowcount number(10);
begin
    select count(1) 
      into v_rowcount 
      from user_ind_columns 
     where index_name = upper('${index.getName()}') 
       and column_name = upper('${colName}') 
       and table_name = upper('${tableName}');
    if v_rowcount = 1 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getResultColumns()/>
    end if;
    </#list>
</#macro>

<#-- 调整索引字段顺序增量SQL -->
<#macro genModIndexColumnOrderAction4Oracle action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
-- ${tableName} 表调整索引 ${index.getName()} 字段顺序
prompt
prompt ${tableName} 表调整索引 ${index.getName()} 字段顺序
declare v_rowcount number(10);
begin
    select count(1) 
      into v_rowcount from dual
     where
<#list index.getColumns() as col>
<#if col_index != 0>
       and
</#if>
     exists(select 1 from user_ind_columns 
                    where index_name = upper('${indexName}')
                      and table_name = upper('${tableName}')
                      and column_name = upper('${col.getName()}')
                      and column_position = ${col_index+1})<#if !col_has_next>;</#if>
</#list>
    if v_rowcount = 0 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
    end if;
    </#list>
</#macro>

<#-- 调整索引唯一性增量SQL -->
<#macro genModIndexColumnUniqueAction4Oracle action>
    <#local indexes = action.getIndexs()>
    
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local isUnique = index.isUnique()>
        <#local indexName = index.getName()>
-- ${tableName} 表调整索引 ${index.getName()} 唯一性
prompt
<#if isUnique>
prompt ${tableName} 表索引 ${index.getName()} 从非唯一改为唯一索引
<#else>
prompt ${tableName} 表索引 ${index.getName()} 从唯一改为非唯一索引
</#if> 
declare v_rowcount number(10);
begin
    select count(1) 
      into v_rowcount 
      from user_indexes 
     where index_name = upper('${index.getName()}') 
       and table_name = upper('${tableName}')
<#if isUnique>
       and uniqueness = 'NONUNIQUE';
<#else>
       and uniqueness = 'UNIQUE';
</#if> 
    if v_rowcount = 1 then
        execute immediate '<#rt>
        <#if isPrimary>
            alter table ${tableSchema}.${tableName} drop primary key cascade';<#lt>
        <#else>
            drop index ${tableSchema}.${indexName}';<#lt>
        </#if>
        <@genAddIndexSql4Oracle index = index indexColumns = index.getColumns()/>
    end if;
    </#list>
</#macro>


<#-- 生成全量DB2 SQL的宏指令 -->
<#macro genTableCreateSql4DB2 tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#assign schema = tableInfo.getSchema()>
    <#assign tablespace = tableInfo.getTableSpace()>
CREATE TABLE <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} (
    <#-- 调用函数 -->
    <#local columnSql = genTableColumnSql4DB2(tableInfo)>
    <#local primaryKeySql = genPrimaryKeySql4DB2(tableInfo)>
    <#if columnSql?length gt 0>
${columnSql}<#if primaryKeySql?length gt 0>,
    ${primaryKeySql}
        </#if>
    </#if>
)<#if stringUtil.isNotBlank(tablespace)> IN ${tablespace}</#if>;
    <#local cname = tableInfo.getChineseName()>
    <#if stringUtil.isNotBlank(cname)>
COMMENT ON TABLE <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} IS '${cname}';
    </#if>
    <#local commentSql = genTableColumnCommentSql4DB2(tableInfo)>
    <#if commentSql?length gt 0>
${commentSql}
    </#if>
    <#local indexSql = genIndexSql4DB2(tableInfo)>
    <#if indexSql?length gt 0>
${indexSql}
    </#if>
</#macro>

<#-- 生成DB2表字段SQL的函数 -->
<#function genTableColumnSql4DB2 tableInfo>
    <#local columns = tableInfo.getColumns()>
    <#local columnStr = "">
    <#list columns as column>
        <#local columnStr = columnStr + "\t" + genOneColumnSql4DB2(column)>
        <#if column?has_next>
            <#local columnStr += ",\r\n">
        </#if>
    </#list>
    <#return columnStr>
</#function>

<#function genOneColumnSql4DB2 column>
    <#local columnStr = "">
    <#local columnName = column.getName()>
    <#local columnType = column.getRealDataType("db2")>
    <#local isNullable = column.isNullable()>
    <#local defaultValue = column.getRealDataDefValue("db2")>
    <#local columnStr = columnName + " " + columnType?upper_case>
    <#if !isNullable>
        <#local columnStr += " NOT NULL">
    </#if>
    <#if stringUtil.isNotBlank(defaultValue)>
        <#if !isNumberType(column.getName())>
            <#local defaultValue = "'" + defaultValue + "'">
        </#if>
        <#local columnStr += " WITH DEFAULT " + defaultValue>
    </#if>
    <#return columnStr>
</#function>

<#-- 生成DB2表字段注释SQL的函数 -->
<#function genTableColumnCommentSql4DB2 tableInfo>
    <#local tableName = tableInfo.getName()>
    <#local columns = tableInfo.getColumns()>
    <#local commentStr = "">
    <#list columns as column>
        <#local commentStr += genOneColumnCommentSql4DB2(column tableName)>
        <#if column?has_next>
            <#local commentStr += "\r\n">
        </#if>
    </#list>
    <#return commentStr>
</#function>

<#function genOneColumnCommentSql4DB2 column tableName>
    <#local commentStr = "">
    <#local columnName = column.getName()>
    <#local columnCName = column.getChineseName()>
    <#if stringUtil.isNotBlank(columnCName)>
        <#local commentStr += "COMMENT ON COLUMN " + tableName + "." + columnName + " IS '" + columnCName + "';">
    </#if>
    <#return commentStr>
</#function>

<#-- 生成DB2表主键约束SQL函数 -->
<#function genPrimaryKeySql4DB2 tableInfo>
    <#local indexes = tableInfo.getIndexs()>
    <#local primaryKeyStr = "">
    <#local keys = stringUtil.createJoiner(", ")>
    <#list indexes as index>
        <#if index.isPrimary()>
            <#local indexColumns = index.getColumns()>
            <#list indexColumns as indexColumn>
                <#local keys = keys.add(indexColumn.getName())>
            </#list>
        </#if>
    </#list>
    <#if stringUtil.isNotBlank(keys.toString())>
        <#local primaryKeyStr = "PRIMARY KEY (" + keys.toString() + ")">
    </#if>
    <#return primaryKeyStr>
</#function>

<#-- 生成DB2表索引SQL的函数 -->
<#function genIndexSql4DB2 tableInfo>
    <#local indexes = tableInfo.getIndexs()>
    <#local tableName = tableInfo.getName()>
    <#local schema = tableInfo.getSchema()>
    <#local indexStr = "">
    <#list indexes as index>
        <#local indexStr += genOneIndexSql4DB2(index schema tableName)>
        <#if index?has_next>
            <#local indexStr += "\r\n">
        </#if>
    </#list>
    <#return indexStr>
</#function>

<#function genOneIndexSql4DB2 index schema tableName>
    <#-- schema开关，此处设置为空，关闭schema-->
    <#local schema = "">
    <#local indexStr = "">
    <#local indexName = index.getName()>
    <#local isUnique = index.isUnique()>
    <#local indexColumns = index.getColumns()>
    <#if stringUtil.isNotBlank(schema)>
        <#local indexName = schema + "." + indexName>
        <#local tableName = schema + "." + tableName>
    </#if>
    <#if isUnique>
        <#local indexStr += "CREATE UNIQUE INDEX " + indexName + " ON " + tableName + " (">
    <#else>
        <#local indexStr += "CREATE INDEX " + indexName + " ON " + tableName + " (">
    </#if>
    <#list indexColumns as indexColumn>
        <#local indexStr = indexStr + indexColumn.getName()>
        <#if indexColumn.isAscending()>
            <#local indexStr += " ASC">
        <#else>
            <#local indexStr += " DESC">
        </#if>
        <#if indexColumn?has_next>
            <#local indexStr += ", ">
        <#else>
            <#local indexStr += ");">
        </#if>
    </#list>
    <#return indexStr>
</#function>

<#-- 生成DB2增量SQL的宏指令 -->
<#macro genTablePatchSql4DB2 tableInfo>
    <#assign tableName = tableInfo.getName()>
    <#assign schema = tableInfo.getSchema()>
    <#assign tableInfo = tableInfo>
    <#local histories = tableInfo.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <@genHistoryPatch4DB2 tableInfo = tableInfo action = action/>
        </#if>

    </#list>
</#macro>

<#macro genHistoryPatch4DB2 tableInfo action>
    <#local type = action.getType()>
-- ${type}
    <#if stringUtil.equals(type, "新建表")>
        <#-- 导入生成全量SQL的脚本 -->
        <@genTableCreateSql4DB2 tableInfo = action.getInfo()/>
    <#else>
        <#if stringUtil.equals(type, "增加表字段")>
<@genAddColumnAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "删除表字段")>
<@genRemoveColumnAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "重命名表字段")>
<@genRenameColumnAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "修改表字段默认值")>
<@genModifyColumnDefaultValueAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "修改表字段是否允许为空")>
<@genModifyColumnNullableAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "增加索引")>
<@genAddIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "删除索引")>
<@genRemoveIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "修改索引")>
<@genModifyIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "调整索引唯一性")>
<@genModifyIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "增加索引字段")>
<@genModifyIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "删除索引字段")>
<@genModifyIndexAction4DB2 action = action/>
        <#elseif stringUtil.equals(type, "调整索引字段顺序")>
<@genModifyIndexAction4DB2 action = action/>
        </#if>
    </#if>
</#macro>

<#-- 增加DB2表字段增量SQL生成 -->
<#macro genAddColumnAction4DB2 action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnStr = genOneColumnSql4DB2(column)>
        <#local tableStr = tableName>
        <#if stringUtil.isNotBlank(schema)>
            <#local tableStr = schema + "." + tableName>
        </#if>
ALTER TABLE ${tableStr} ADD COLUMN ${columnStr};
${genOneColumnCommentSql4DB2(column tableName)}
    </#list>
CALL SYSPROC.ADMIN_CMD( 'REORG TABLE ${tableStr}' );
</#macro>

<#-- 删除DB2表字段增量SQL生成 -->
<#macro genRemoveColumnAction4DB2 action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local tableStr = tableName>
        <#if stringUtil.isNotBlank(schema)>
            <#local tableStr = schema + "." + tableName>
        </#if>
ALTER TABLE ${tableStr} DROP COLUMN ${columnName} RESTRICT;
    </#list>
CALL SYSPROC.ADMIN_CMD( 'REORG TABLE ${tableStr}' );
</#macro>

<#-- 重命名DB2表字段增量SQL生成 -->
<#macro genRenameColumnAction4DB2 action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local columnNewName = column.getNewName()>
        <#local tableStr = tableName>
        <#if stringUtil.isNotBlank(schema)>
            <#local tableStr = schema + "." + tableName>
        </#if>
ALTER TABLE ${tableStr} RENAME COLUMN ${columnName} TO ${columnNewName};
    </#list>
CALL SYSPROC.ADMIN_CMD( 'REORG TABLE ${tableStr}' );
</#macro>

<#-- 修改DB2表字段默认值增量SQL生成 -->
<#macro genModifyColumnDefaultValueAction4DB2 action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local defaultValue = column.getRealDataDefValue("db2")>
        <#local tableStr = tableName>
        <#if stringUtil.isNotBlank(schema)>
            <#local tableStr = schema + "." + tableName>
        </#if>
        <#local tmpStr = "">
        <#if stringUtil.isNotBlank(defaultValue)>
            <#if !isNumberType(column.getName())>
                <#local defaultValue = "'" + defaultValue + "'">
            </#if>
            <#local tmpStr = "SET DEFAULT " + defaultValue>
        <#else>
            <#local tmpStr = "DROP DEFAULT">
        </#if>
ALTER TABLE ${tableStr} ALTER COLUMN ${columnName} ${tmpStr};
    </#list>
CALL SYSPROC.ADMIN_CMD( 'REORG TABLE ${tableStr}' );
</#macro>

<#-- 修改DB2表字段是否为空增量SQL生成 -->
<#macro genModifyColumnNullableAction4DB2 action>
    <#local columns = action.getColumns()>
    <#list columns as column>
        <#local columnName = column.getName()>
        <#local isNullable = column.isNullable()>
        <#local tableStr = tableName>
        <#if stringUtil.isNotBlank(schema)>
            <#local tableStr = schema + "." + tableName>
        </#if>
        <#local tmpStr = "">
        <#if !isNullable>
            <#local tmpStr = "SET NOT NULL ">
        <#else>
            <#local tmpStr = "DROP NOT NULL">
        </#if>
ALTER TABLE ${tableStr} ALTER COLUMN ${columnName} ${tmpStr};
    </#list>
CALL SYSPROC.ADMIN_CMD( 'REORG TABLE ${tableStr}' );
</#macro>

<#-- 增加DB2索引增量SQL生成 -->
<#macro genAddIndexAction4DB2 action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
${genOneIndexSql4DB2(index schema tableName)}		
    </#list>
</#macro>

<#-- 删除DB2索引增量SQL生成 -->
<#macro genRemoveIndexAction4DB2 action>
    <#local indexes = action.getIndexs()>
    <#local hasPrimary = false>
    <#list indexes as index>
        <#local isPrimary = index.isPrimary()>
        <#local indexName = index.getName()>
        <#if stringUtil.isNotBlank(schema)>
            <#local indexName = schema + "." + indexName>
        </#if>
        <#if isPrimary>
            <#local hasPrimary = true>
        </#if>
DROP INDEX ${indexName};
    </#list>
    <#if hasPrimary>
        <#local primaryKeySql = genPrimaryKeySql4DB2(tableInfo)>
        <#if stringUtil.isNotBlank(primaryKeySql)>
            <#local tableStr = tableName>
            <#if stringUtil.isNotBlank(schema)>
                <#local tableStr = schema + "." + tableName>
            </#if>
ALTER TABLE ${tableStr} DROP PRIMARY KEY;
ALTER TABLE ${tableStr} ADD CONSTRAINT pk_${tableName} ${primaryKeySql};
        </#if>
    </#if>
</#macro>


<#-- 修改DB2索引增量SQL生成-->
<#macro genModifyIndexAction4DB2 action>
    <#local indexes = action.getIndexs()>
    <#list indexes as index>
        <#local indexName = index.getName()>
        <#if stringUtil.isNotBlank(schema)>
            <#local indexName = schema + "." + indexName>
        </#if>
DROP INDEX ${indexName};
${genOneIndexSql4DB2(index schema tableName)}
    </#list>
</#macro>

<#-- 生成DB2表初始数据INSERT SQL的宏指令 -->
<#macro genTableInsertSql4DB2 info tableName>
    <#local schema = getDbSchema(tableName)>
    <#local items = info.getItems()>
    <#list items as item>
<@genOneInsertRecordSql4DB2 item=item schema=schema tableName=tableName/>
    </#list>
</#macro>

<#macro genOneInsertRecordSql4DB2 item schema tableName>
    <#local dataMap = item.getExtendData()>
    <#local fields = stringUtil.createJoiner(", ")>
    <#local values = stringUtil.createJoiner(", ")>
    <#list dataMap?keys as key>
        <#local value = dataMap[key]>
        <#if stringUtil.isNotEmpty(value)>
            <#local fields = fields.add("\"" + key + "\"")>
            <#if isNumberType(key)>
                <#local values = values.add(value)>
            <#else>
                <#local values = values.add("'" + value + "'")>
            </#if>  
        </#if>
    </#list> 
    <#if stringUtil.isNotBlank(fields.toString())>
INSERT INTO <#if stringUtil.isNotBlank(schema)>${schema}.</#if>"${tableName}" (${fields.toString()}) VALUES (${values.toString()});
    </#if>
</#macro>

<#-- 生成DB2表初始数据增量INSERT SQL的宏指令 -->
<#macro genTableInsertPatchSql4DB2 info tableName>
    <#local tableInfo = reference.getTableInfo(tableName)>
    <#local schema = getDbSchema(tableName)>
    <#local histories = info.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <#local type = action.getType()>
            <#local items = action.getRecords()>
            <#if stringUtil.equals(type, "增加记录")>
-- 增加记录
                <#list items as item>
<@genOneInsertRecordSql4DB2 item=item schema=schema tableName=tableName/>              
                </#list>

            <#elseif stringUtil.equals(type, "删除记录")>
-- 删除记录
                <#list items as item>
                    <#local conditions = genConditionSql4DB2(item schema tableInfo tableName)>
<@genOneDeleteRecordSql4DB2 schema=schema tableName=tableName conditions=conditions/>
                </#list>

            <#elseif stringUtil.equals(type, "修改记录")>
-- 修改记录
                <#list items as item>
                    <#local conditions = genConditionSql4DB2(item schema tableInfo tableName)>
<@genOneUpdateRecordSql4DB2 item=item schema=schema tableName=tableName conditions=conditions/>
                </#list>

            </#if>
        </#if>
    </#list>
</#macro>

<#macro genOneDeleteRecordSql4DB2 schema tableName conditions>
    <#if stringUtil.isNotBlank(conditions)>
DELETE FROM <#if stringUtil.isNotBlank(schema)>${schema}.</#if>"${tableName}" WHERE ${conditions};
    </#if>
</#macro>

<#macro genOneUpdateRecordSql4DB2 item schema tableName conditions>
    <#local values = stringUtil.createJoiner(", ")>
    <#local dataMap2 = item.getExtendData2()>
    <#list dataMap2?keys as key>
        <#local value = dataMap2[key]>
        <#local valueStr = "\"" + key + "\"=">
        <#if isNumberType(key)>
            <#if stringUtil.isNotBlank(value)>
                <#local valueStr += value>
                <#local values = values.add(valueStr)>
            </#if>
        <#elseif stringUtil.isNotEmpty(value)>
            <#local valueStr += "'" + value + "'">
            <#local values = values.add(valueStr)>
        </#if>
    </#list>
    <#if stringUtil.isNotBlank(conditions) && stringUtil.isNotBlank(values.toString())>
UPDATE <#if stringUtil.isNotBlank(schema)>${schema}.</#if>"${tableName}" SET ${values.toString()} WHERE ${conditions};
    </#if>
</#macro>

<#function genConditionSql4DB2 item schema tableInfo tableName>
    <#local conditions = stringUtil.createJoiner(" AND ")>
    <#if tableInfo?has_content>
        <#local indexes = tableInfo.getIndexs()>
        <#list indexes as index>
            <#if index.isPrimary() || index.isUnique()>
                <#local indexColumns = index.getColumns()>
                <#list indexColumns as indexColumn>
                    <#local key = indexColumn.getName()>
                    <#local value = item.getExtendValue(key)>
                    <#local cd = "\"" + key + "\"=">
                    <#if isNumberType(key)>
                        <#if stringUtil.isNotBlank(value)>
                            <#local conditions = conditions.add(cd + value)>
                        </#if>
                    <#elseif stringUtil.isNotEmpty(value)>
                        <#local conditions = conditions.add(cd + "'" + value + "'")>
                    </#if>
                </#list>
            </#if>
        </#list>
    </#if>
    <#if stringUtil.isBlank(conditions.toString())>
        <#local dataMap = item.getExtendData()>
        <#list dataMap?keys as key>
            <#local value = dataMap[key]>
            <#local cd = "\"" + key + "\"=">
            <#if isNumberType(key)>
                <#if stringUtil.isNotBlank(value)>
                    <#local conditions = conditions.add(cd + value)>
                </#if>
            <#elseif stringUtil.isNotEmpty(value)>
                <#local conditions = conditions.add(cd + "'" + value + "'")>
            </#if>
        </#list>       
    </#if>
    <#return conditions.toString()>
</#function>

<#-- 生成MySQL表初始数据INSERT SQL的宏指令 -->
<#macro genTableInsertSql4MySQL resource info tableName>
select '初始化表${tableName}...';
truncate table ${tableName};
    <#local items = info.getItems()>
    <#list items as item>
    <@genOneInsertRecordSql4MySQL resource=resource item=item tableName=tableName/>
    </#list>
commit;
</#macro>

<#macro genOneInsertRecordSql4MySQL resource item tableName>
    <#local dataMap = item.getExtendData()>
    <#local fields = stringUtil.createJoiner(", ")>
    <#local values = stringUtil.createJoiner(", ")>
    <#local cols = resource.getCommonModelExtendValue("table_columns")>
    <#list cols as col>
    	<#local key = col.getName()>
        <#local value = dataMap[key]>
        <#if stringUtil.isNotEmpty(value)>
            <#local fields = fields.add("`" + key + "`")>
            <#if isNumberType(key)>
                <#local values = values.add(value)>
            <#else>
                <#local values = values.add("'" + value + "'")>
            </#if>  
        </#if>
    </#list> 
    <#if stringUtil.isNotBlank(fields.toString())>
INSERT INTO `${tableName}` (${fields.toString()}) VALUES (${values.toString()});
    </#if>
</#macro>

<#-- 生成MySql表初始数据增量INSERT SQL的宏指令 -->
<#macro genTableInsertPatchSql4MySQL_暂时保留 info tableName>
    <#local tableInfo = reference.getTableInfo(tableName)>
    <#local histories = info.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <#local type = action.getType()>
            <#local items = action.getRecords()>
            <#if stringUtil.equals(type, "增加记录")>
-- 增加记录
                <#list items as item>
                    <#local conditions = genConditionSql4MySQL(item tableInfo tableName)>
select '表${tableName}数据变更...';
SET @v_rowcount = 0;
  select count(*) into @v_rowcount from dual
    where exists (select * from ${tableName} where ${conditions});
  SET @sql = IF(@v_rowcount = 0, "<@genOneInsertRecordSql4MySQL item=item tableName=tableName/>", "");
PREPARE stmt FROM @sql;
EXECUTE stmt;

                </#list>
            <#elseif stringUtil.equals(type, "删除记录")>
-- 删除记录
                <#list items as item>
                    <#local conditions = genConditionSql4MySQL(item tableInfo tableName)>
<@genOneDeleteRecordSql4MySQL tableName=tableName conditions=conditions/>
                </#list>

            <#elseif stringUtil.equals(type, "修改记录")>
-- 修改记录
                <#list items as item>
                    <#local conditions = genConditionSql4MySQL(item tableInfo tableName)>
select '表${tableName}数据变更...';
SET @v_rowcount = 0;
  select count(*) into @v_rowcount from dual
    where exists (select * from ${tableName} where ${conditions});
  SET @sql = IF(@v_rowcount = 0, "<@genOneInsertRecordSql4MySQL item=item tableName=tableName/>", "<@genOneUpdateRecordSql4MySQL item=item tableName=tableName conditions=conditions/>");
PREPARE stmt FROM @sql;
EXECUTE stmt;

                </#list>
            </#if>
        </#if>
    </#list>
</#macro>

<#-- 生成MySql表初始数据增量INSERT SQL的宏指令 -->
<#macro genTableInsertPatchSql4MySQL resource info tableName>
    <#local tableInfo = reference.getTableInfo(tableName)>
    <#local items = info.getItems()>
<@genHistoryInfo info=info/>

    <#list items as item>
        <#local conditions = genConditionSql4MySQL(item tableInfo tableName)>
select '表${tableName}数据变更...';
SET @v_rowcount = 0;
  select count(*) into @v_rowcount from dual
    where exists (select * from ${tableName} where ${conditions});
  SET @sql = IF(@v_rowcount = 0, "<@genOneInsertRecordSql4MySQL resource=resource item=item tableName=tableName/>", "<@genOneUpdateRecordSql4MySQL item=item tableName=tableName conditions=conditions/>");
PREPARE stmt FROM @sql;
EXECUTE stmt;

    </#list>
</#macro>

<#macro genHistoryInfo info>
    <#local histories = info.getHistories()?reverse>
-- ${stringUtil.format("%-16s%-16s%-16s%-16s%-20s%-20s%s", "修订版本","修订时间",	"修订单号","负责人","申请人","修订内容","修订原因")}
    <#list histories as history>
        <#if history.getModification()??>
-- ${stringUtil.format("%-20s%-20s%-20s%-20s%-20s%-20s%s", history.getVersion(), history.getModifiedDate(), history.getOrderNumber(), history.getCharger(), history.getModifiedBy(), history.getModified(),	history.getModifiedReason())}		
        </#if>
    </#list>
</#macro>

<#macro genOneDeleteRecordSql4MySQL tableName conditions>
    <#if stringUtil.isNotBlank(conditions)>
DELETE FROM `${tableName}` WHERE ${conditions};
    </#if>
</#macro>

<#macro genOneUpdateRecordSql4MySQL item tableName conditions>
    <#local values = stringUtil.createJoiner(", ")>
    <#--  <#local dataMap2 = item.getExtendData2()> _暂时保留-->
    <#local dataMap2 = item.getExtendData()>
    <#list dataMap2?keys as key>
        <#local value = dataMap2[key]>
        <#local valueStr = "`" + key + "`=">
        <#if isNumberType(key)>
            <#if stringUtil.isNotBlank(value)>
                <#local valueStr += value>
                <#local values = values.add(valueStr)>
            </#if>
        <#elseif stringUtil.isNotEmpty(value)>
            <#local valueStr += "'" + value + "'">
            <#local values = values.add(valueStr)>
        </#if>
    </#list>
    <#if stringUtil.isNotBlank(conditions) && stringUtil.isNotBlank(values.toString())>
UPDATE `${tableName}` SET ${values.toString()} WHERE ${conditions};
    </#if>
</#macro>

<#function genConditionSql4MySQL item tableInfo tableName>
    <#local conditions = stringUtil.createJoiner(" AND ")>
    <#if tableInfo?has_content>
        <#local indexes = tableInfo.getIndexs()>
        <#list indexes as index>
            <#if index.isPrimary() || index.isUnique()>
                <#local indexColumns = index.getColumns()>
                <#list indexColumns as indexColumn>
                    <#local key = indexColumn.getName()>
                    <#local value = item.getExtendValue(key)>
                    <#local cd = "`" + key + "`=">
                    <#if isNumberType(key)>
                        <#if stringUtil.isNotBlank(value)>
                            <#local conditions = conditions.add(cd + value)>
                        </#if>
                    <#elseif stringUtil.isNotEmpty(value)>
                        <#local conditions = conditions.add(cd + "'" + value + "'")>
                    </#if>
                </#list>
            </#if>
        </#list>
    </#if>
    <#if stringUtil.isBlank(conditions.toString())>
        <#local dataMap = item.getExtendData()>
        <#list dataMap?keys as key>
            <#local value = dataMap[key]>
            <#local cd = "`" + key + "`=">
            <#if isNumberType(key)>
                <#if stringUtil.isNotBlank(value)>
                    <#local conditions = conditions.add(cd + value)>
                </#if>
            <#elseif stringUtil.isNotEmpty(value)>
                <#local conditions = conditions.add(cd + "'" + value + "'")>
            </#if>
        </#list>       
    </#if>
    <#return conditions.toString()>
</#function>

<#-- 生成Oracle表初始数据INSERT SQL的宏指令 -->
<#macro genTableInsertSql4Oracle resource info tableName>
    <#local schema = getDbSchema(tableName)>
prompt 初始化表${tableName}...
begin
  execute immediate 'truncate table <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName}'; 
    <#local items = info.getItems()>
    <#list items as item>
    <@genOneInsertRecordSql4Oracle resource=resource item=item schema=schema tableName=tableName/>
    </#list>
  commit;
end;
/
</#macro>

<#macro genOneInsertRecordSql4Oracle resource item schema tableName>
    <#local dataMap = item.getExtendData()>
    <#local fields = stringUtil.createJoiner(", ")>
    <#local values = stringUtil.createJoiner(", ")>
    <#local cols = resource.getCommonModelExtendValue("table_columns")>
    <#list cols as col>
    	<#local key = col.getName()>
        <#local value = dataMap[key]>
        <#if stringUtil.isNotEmpty(value)>
            <#local fields = fields.add(key)>
            <#if isNumberType(key)>
                <#local values = values.add(value)>
            <#else>
                <#local values = values.add("'" + value + "'")>
            </#if>  
        </#if>
    </#list> 
    <#if stringUtil.isNotBlank(fields.toString())>
INSERT INTO <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} (${fields.toString()}) VALUES (${values.toString()});
    </#if>
</#macro>

<#-- 生成Oracle表初始数据增量INSERT SQL的宏指令 -->
<#macro genTableInsertPatchSql4Oracle_暂时保留 info tableName>
    <#local tableInfo = reference.getTableInfo(tableName)>
    <#local schema = getDbSchema(tableName)>
    <#local histories = info.getHistories()?reverse>
    <#list histories as history>
        <#if history.getModification()??>
            <#local action = history.getModification()>
            <#local type = action.getType()>
            <#local items = action.getRecords()>
            <#if stringUtil.equals(type, "增加记录")>
-- 增加记录
                <#list items as item>
                    <#local conditions = genConditionSql4Oracle(item schema tableInfo tableName)>
prompt 表${tableName}数据变更...
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} where ${conditions});
  if v_rowcount = 0 then
    <@genOneInsertRecordSql4Oracle item=item schema=schema tableName=tableName/>
  end if;
  commit;
end;
/

                </#list>
            <#elseif stringUtil.equals(type, "删除记录")>
-- 删除记录
                <#list items as item>
                    <#local conditions = genConditionSql4Oracle(item schema tableInfo tableName)>
<@genOneDeleteRecordSql4Oracle schema=schema tableName=tableName conditions=conditions/>
                </#list>

            <#elseif stringUtil.equals(type, "修改记录")>
-- 修改记录
                <#list items as item>
                    <#local conditions = genConditionSql4Oracle(item schema tableInfo tableName)>
prompt 表${tableName}数据变更...
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} where ${conditions});
  if v_rowcount = 0 then
    <@genOneInsertRecordSql4Oracle item=item schema=schema tableName=tableName/>
  else
    <@genOneUpdateRecordSql4Oracle item=item schema=schema tableName=tableName conditions=conditions/>
  end if;
  commit;
end;
/

                </#list>
            </#if>
        </#if>
    </#list>
</#macro>

<#-- 生成Oracle表初始数据增量INSERT SQL的宏指令 -->
<#macro genTableInsertPatchSql4Oracle resource info tableName>
    <#local tableInfo = reference.getTableInfo(tableName)>
    <#local schema = getDbSchema(tableName)>
    <#local items = info.getItems()>
<@genHistoryInfo info=info/>

    <#list items as item>
        <#local conditions = genConditionSql4Oracle(item schema tableInfo tableName)>
prompt 表${tableName}数据变更...
declare v_rowcount number(5);
begin
  select count(*) into v_rowcount from dual
    where exists (select 1 from <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} where ${conditions});
  if v_rowcount = 0 then
    <@genOneInsertRecordSql4Oracle resource=resource item=item schema=schema tableName=tableName/>
  else
    <@genOneUpdateRecordSql4Oracle resource=resource item=item schema=schema tableName=tableName conditions=conditions/>
  end if;
  commit;
end;
/

    </#list>
</#macro>

<#macro genOneDeleteRecordSql4Oracle schema tableName conditions>
    <#if stringUtil.isNotBlank(conditions)>
DELETE FROM <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} WHERE ${conditions};
    </#if>
</#macro>

<#macro genOneUpdateRecordSql4Oracle resource item schema tableName conditions>
    <#local values = stringUtil.createJoiner(", ")>
    <#-- <#local dataMap2 = item.getExtendData2()> _暂时保留-->
    <#local dataMap2 = item.getExtendData()>
   <#local cols = resource.getCommonModelExtendValue("table_columns")>
    <#list cols as col>
    	<#local key = col.getName()>
        <#local value = dataMap2[key]>
        <#local valueStr = key + "=">
        <#if isNumberType(key)>
            <#if stringUtil.isNotBlank(value)>
                <#local valueStr += value>
                <#local values = values.add(valueStr)>
            </#if>
        <#elseif stringUtil.isNotEmpty(value)>
            <#local valueStr += "'" + value + "'">
            <#local values = values.add(valueStr)>
        </#if>
    </#list>
    <#if stringUtil.isNotBlank(conditions) && stringUtil.isNotBlank(values.toString())>
UPDATE <#if stringUtil.isNotBlank(schema)>${schema}.</#if>${tableName} SET ${values.toString()} WHERE ${conditions};
    </#if>
</#macro>

<#function genConditionSql4Oracle item schema tableInfo tableName>
    <#local conditions = stringUtil.createJoiner(" AND ")>
    <#if tableInfo?has_content>
        <#local indexes = tableInfo.getIndexs()>
        <#list indexes as index>
            <#if index.isPrimary() || index.isUnique()>
                <#local indexColumns = index.getColumns()>
                <#list indexColumns as indexColumn>
                    <#local key = indexColumn.getName()>
                    <#local value = item.getExtendValue(key)>
                    <#local cd = key + "=">
                    <#if isNumberType(key)>
                        <#if stringUtil.isNotBlank(value)>
                            <#local conditions = conditions.add(cd + value)>
                        </#if>
                    <#elseif stringUtil.isNotEmpty(value)>
                        <#local conditions = conditions.add(cd + "'" + value + "'")>
                    </#if>
                </#list>
            </#if>
        </#list>
    </#if>
    <#if stringUtil.isBlank(conditions.toString())>
        <#local dataMap = item.getExtendData()>
        <#list dataMap?keys as key>
            <#local value = dataMap[key]>
            <#local cd = key + "=">
            <#if isNumberType(key)>
                <#if stringUtil.isNotBlank(value)>
                    <#local conditions = conditions.add(cd + value)>
                </#if>
            <#elseif stringUtil.isNotEmpty(value)>
                <#local conditions = conditions.add(cd + "'" + value + "'")>
            </#if>
        </#list>       
    </#if>
    <#return conditions.toString()>
</#function>

<#-- 判断表字段的类型是否是数字类型 -->
<#function isNumberType columnName>
    <#local type = reference.getRealDataType(columnName, "java")>
    <#if stringUtil.isNumberType(type)>
        <#return true>
    </#if>
    <#return false>
</#function>

<#function getDbSchema tableName>
    <#local info = reference.getTableInfo(tableName)>
    <#if info?has_content>
        <#return info.getSchema()>
    </#if>
    <#return "">
</#function>