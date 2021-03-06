<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright 2015 Red Hat, Inc. and/or its affiliates
    and other contributors as indicated by the @author tags.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xalan="http://xml.apache.org/xalan"
                xmlns:ra="urn:jboss:domain:resource-adapters:2.0"
                version="2.0"
                exclude-result-prefixes="xalan ra">

  <!-- will indicate if this is a "dev" build or "production" build -->
  <xsl:param name="kettle.build.type"/>

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" xalan:indent-amount="4" standalone="no"/>
  <xsl:strip-space elements="*"/>

  <!-- add system properties -->
  <xsl:template name="system-properties">
    <system-properties>
      <property name="hawkular-metrics.backend" value="embedded_cass" />
    </system-properties>
  </xsl:template>

  <xsl:template match="node()[name(.)='extensions']">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <extension module="org.keycloak.keycloak-subsystem"/>
    </xsl:copy>
    <xsl:call-template name="system-properties"/>
  </xsl:template>

  <!-- Keycloak-related - datasource, our secured deployments (important) and security domain definitions -->
  <xsl:template match="node()[name(.)='datasources']">
    <xsl:copy>
      <xsl:apply-templates select="node()[name(.)='datasource']"/>
      <datasource jndi-name="java:jboss/datasources/KeycloakDS" pool-name="KeycloakDS" enabled="true" use-java-context="true">
        <connection-url>jdbc:h2:${jboss.server.data.dir}${/}h2${/}keycloak;AUTO_SERVER=TRUE</connection-url>
        <driver>h2</driver>
        <security>
          <user-name>sa</user-name>
          <password>sa</password>
        </security>
      </datasource>
      <xsl:apply-templates select="node()[name(.)='drivers']"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node()[name(.)='profile']">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <subsystem xmlns="urn:jboss:domain:keycloak:1.0">
        <auth-server name="main-auth-server">
          <enabled>true</enabled>
          <web-context>auth</web-context>
        </auth-server>
        <realm name="hawkular">
          <auth-server-url>http://localhost:8080/auth</auth-server-url>
          <ssl-required>none</ssl-required>
        </realm>
        <secure-deployment name="hawkular-accounts.war">
          <realm>hawkular</realm>
          <resource>hawkular-accounts-backend</resource>
          <use-resource-role-mappings>true</use-resource-role-mappings>
          <enable-cors>true</enable-cors>
        </secure-deployment>
      </subsystem>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node()[name(.)='security-domains']">
    <xsl:copy>
      <xsl:apply-templates select="node()[name(.)='security-domain']"/>
      <security-domain name="keycloak">
        <authentication>
          <login-module code="org.keycloak.adapters.jboss.KeycloakLoginModule" flag="required"/>
        </authentication>
      </security-domain>
      <security-domain name="sp" cache-type="default">
        <authentication>
          <login-module code="org.picketlink.identity.federation.bindings.wildfly.SAML2LoginModule" flag="required"/>
        </authentication>
      </security-domain>
    </xsl:copy>
  </xsl:template>
  <!-- End of Keycloak-related changes -->

  <!-- Add a cache for Hawkular Accounts -->
  <xsl:template match="node()[name(.)='cache-container'][1]">
    <xsl:copy>
      <xsl:copy-of select="node()|@*"/>
    </xsl:copy>
    <cache-container name="hawkular-accounts" default-cache="role-cache">
      <local-cache name="role-cache"/>
    </cache-container>
  </xsl:template>

  <!-- add our JMS queues/topices that are required to be defined as admin-objects -->
  <xsl:template name="admin-objects">
    <admin-objects>
      <admin-object use-java-context="true"
                    enabled="true"
                    class-name="org.apache.activemq.command.ActiveMQTopic"
                    jndi-name="java:/topic/HawkularNotifications"
                    pool-name="HawkularNotifications">
        <config-property name="PhysicalName">HawkularNotifications</config-property>
      </admin-object>
      <admin-object use-java-context="true"
                    enabled="true"
                    class-name="org.apache.activemq.command.ActiveMQTopic"
                    jndi-name="java:/topic/HawkularMetricData"
                    pool-name="HawkularMetricData">
        <config-property name="PhysicalName">HawkularMetricData</config-property>
      </admin-object>
      <admin-object use-java-context="true"
                    enabled="true"
                    class-name="org.apache.activemq.command.ActiveMQTopic"
                    jndi-name="java:/topic/HawkularAvailData"
                    pool-name="HawkularAvailData">
        <config-property name="PhysicalName">HawkularAvailData</config-property>
      </admin-object>
    </admin-objects>
  </xsl:template>

  <xsl:template match="ra:admin-objects">
    <xsl:call-template name="admin-objects"/>
  </xsl:template>

  <!-- copy everything else as-is -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
