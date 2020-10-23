package com.hundsun.jres.studio.demo.pub;


import org.apache.http.client.HttpClient;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.socket.LayeredConnectionSocketFactory;
import org.apache.http.conn.socket.PlainConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;

import javax.net.ssl.SSLContext;
import java.security.NoSuchAlgorithmException;


public class HttpClientFactory {


    private static HttpClientFactory instance = null;

    private HttpClientFactory()
    {
    }

    public synchronized static HttpClientFactory getInstance()
    {
        if (instance == null)
        {
            instance = new HttpClientFactory();
        }
        return instance;
    }


    public synchronized HttpClient getHttpClient()
    {
        HttpClient httpClient = new HttpClientBuilder().getHttpClient();

        return httpClient;
    }

    public HttpPost httpPost(String httpUrl)
    {
        HttpPost httpPost = null;
        httpPost = new HttpPost(httpUrl);

        return httpPost;
    }



    private  static class  KeepAliveHttpClientBuilder{

        private  static HttpClient httpClient;

        /**
         * 获取http长连接
         */
        private synchronized HttpClient getKeepAliveHttpClient()
        {
            if (httpClient == null)
            {
                LayeredConnectionSocketFactory sslsf = null;
                try {
                    sslsf = new SSLConnectionSocketFactory(SSLContext.getDefault());
                } catch (NoSuchAlgorithmException e) {
                    e.printStackTrace();
                }

                Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder
                        .<ConnectionSocketFactory> create().register("https", sslsf)
                        .register("http", new PlainConnectionSocketFactory()).build();
                PoolingHttpClientConnectionManager cm = new PoolingHttpClientConnectionManager(socketFactoryRegistry);

                RequestConfig requestConfig = RequestConfig.custom().build();
                // 创建连接
                httpClient =  HttpClients.custom().setDefaultRequestConfig(requestConfig).setConnectionManager(cm).build();
            }

            return httpClient;
        }
    }


    private  static class  HttpClientBuilder{
        private  HttpClient httpClient;
        /**
         * 获取http短连接
         */
        private synchronized HttpClient getHttpClient()
        {
            if(httpClient == null){
                RequestConfig requestConfig = RequestConfig.custom().build();
                // 创建连接
                httpClient = HttpClients.custom().setDefaultRequestConfig(requestConfig).build();
            }
            return httpClient;
        }
    }


}