/**
 * 系统名称: uf3.0
 * 模块名称: ${info.getArtifactId()}
 * 类  名  称: ${info.getClassName()}Test.java
 * 软件版权: 恒生电子股份有限公司
 * 修改记录:
 * 修改人员                               修改说明 <br>
 * ============  ============================================
 * studio-auto      创建	  
 * ============  ============================================
 */
package ${info.getProjectBasePackage()};

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseBuilder;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType;
import org.springframework.transaction.support.TransactionTemplate;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * 测试应用上下文配置类，默认配置：<br>
 * 1.开启dev profile<br>
 * 2.扫描com.hundsun包下的组件<br>
 * 1.创建内置H2数据源和常见的jdbcTemplate组件<br>
 * 
 * @author gonggy12040
 * @since 2019-07-03
 */
@Profile("dev")
@Configuration
@ComponentScan(excludeFilters = @ComponentScan.Filter(type = FilterType.CUSTOM, classes = {}), value = "com.hundsun")
public class TestContextConfig {
	
	@Bean(destroyMethod = "shutdown", name = "dataSourceTest")
	public DataSource dataSourceTest() {
		// 按需创建数据库类型，默认创建内置数据库
		return createEmbeddedDatabase();
		//return createOutDatabase();
	}
	
	/**
	 * 创建内置数据库，请按需配置数据库信息
	 * @return
	 */
	private DataSource createEmbeddedDatabase() {
		return new EmbeddedDatabaseBuilder()
		        .generateUniqueName(true).setType(EmbeddedDatabaseType.H2)
				.setScriptEncoding("UTF-8").ignoreFailedDrops(true)
				//.addScript("classpath:schema.sql")
				//.addScript("classpath:test_data.sql")
				.build();
	}
	
	/**
	 * 创建外置数据库，请按需配置数据库信息
	 * @return
	 */
	@SuppressWarnings("unused")
	private DataSource createOutDatabase() {
		String dirverClassName = "oracle.jdbc.driver.OracleDriver";
		String jdbcUrl = "jdbc:oracle:thin:@//127.0.0.1:1521/TEST";
		String username = "hundsun";
		String password = "hundsun";
		HikariConfig config = new HikariConfig();
		config.setDriverClassName(dirverClassName);
		config.setJdbcUrl(jdbcUrl);
		config.setUsername(username);
		config.setPassword(password);
		config.setMinimumIdle(10);
		config.setMaximumPoolSize(20);
		return new HikariDataSource(config);
	}
	
	/**
	 * 基于p6的数据库连接池，做一层拦截，实现jdbc监控统计功能
	 * 
	 * @return
	 */
	@Bean(name = "dataSource")
	public DataSource dataSource(@Qualifier("dataSourceTest") DataSource dataSource) {
		return new com.p6spy.engine.spy.P6DataSource(dataSource);
	}
	
	@Bean(name = "jdbcTemplate")
	public JdbcTemplate jdbcTemplate(@Qualifier("dataSource") DataSource dataSource) {
		return new JdbcTemplate(dataSource);
	}

	@Bean(name = "namedParameterJdbcTemplate")
	public NamedParameterJdbcTemplate namedParameterJdbcTemplate(@Qualifier("dataSource") DataSource dataSource) {
		return new NamedParameterJdbcTemplate(dataSource);
	}
	
	@Bean(name = "transactionManager")
	public DataSourceTransactionManager transactionManager(@Qualifier("dataSource") DataSource dataSource) {
		return new DataSourceTransactionManager(dataSource);
	}

	@Bean(name = "transactionTemplate")
	public TransactionTemplate transactionTemplate(@Qualifier("transactionManager") DataSourceTransactionManager transactionManager) {
		return new TransactionTemplate(transactionManager);
	}
}