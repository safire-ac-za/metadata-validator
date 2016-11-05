<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
	xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
	xmlns:mdxURL="xalan://uk.ac.sdss.xalan.md.URLchecker"
	xmlns:set="http://exslt.org/sets"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:shibmd="urn:mace:shibboleth:metadata:1.0"
	xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi"
	xmlns:php="http://php.net/xsl"
	xmlns="urn:oasis:names:tc:SAML:2.0:metadata">

	<!--
		Common support functions.
	-->
	<xsl:import href="../rules/check_framework.xsl"/>

	<!--
		This XSLT does validation against SAFIRE federation registry rules.
		These are not SAML metadata syntax issues; they're SAFIRE conventions.
		As such, they may or may not be appropriate for other federations. YMMV.

		This file contains common checks for both Identity and Service Providers
	-->

	<!-- Check length of description of purpose -->
	<xsl:template match="mdui:Description">
		<xsl:if test="string-length(text()) > 140">
			<xsl:choose>
				<xsl:when test="string-length(text()) > 160">
					<xsl:call-template name="error">
						<xsl:with-param name="m">
							<xsl:text>mdui:Description MUST be 160 chars or less (currently </xsl:text>
							<xsl:value-of select="string-length(text())"/>
							<xsl:text> characters)</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="warning">
						<xsl:with-param name="m">
							<xsl:text>mdui:Description should be 140 chars or less (currently </xsl:text>
							<xsl:value-of select="string-length(text())"/>
							<xsl:text> characters)</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<!-- Check that there is no RegistrationInfo (note we have to disable Ian's check for this) -->
	<xsl:template match="mdrpi:RegistrationInfo">
		<xsl:call-template name="warning">
			<xsl:with-param name="m">RegistrationInfo should not be set by Participants</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- Check the metadata certificates -->
	<xsl:template match="ds:X509Certificate">
		<xsl:if test="php:functionString('xsltfunc::checkBase64', text()) = 0">
			<xsl:call-template name="error">
				<xsl:with-param name="m">X509Certificate MUST be BASE64 encoded</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="php:functionString('xsltfunc::checkCertSelfSigned',text()) = 0">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">X509Certificate should be self-signed</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="php:functionString('xsltfunc::checkCertValid',text(),'from') = 0">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">X509Certificate is not yet valid</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="php:functionString('xsltfunc::checkCertValid',text(),'to') = 0">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">X509Certificate has expired or expires within 30 days</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Note about SAML1 (hub doesn't support it) -->
	<xsl:template match="md:IDPSSODescriptor[contains(@protocolSupportEnumeration, 'urn:oasis:names:tc:SAML:1.1:protocol')]|md:SPSSODescriptor[contains(@protocolSupportEnumeration, 'urn:oasis:names:tc:SAML:1.1:protocol')]">
		<xsl:call-template name="info">
			<xsl:with-param name="m">Metadata contains unused Shib/SAML1 bindings</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Check ContactPerson email addresses -->
	<xsl:template match="md:ContactPerson[not(descendant::md:EmailAddress)]">
		<xsl:call-template name="error">
			<xsl:with-param name="m">
				<xsl:text>EmailAddress must be set for ContactPerson of type </xsl:text>
				<xsl:value-of select="@contactType"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="md:EmailAddress[php:functionString('xsltfunc::checkEmailAddress', text()) = 0]">
		<xsl:call-template name="error">
			<xsl:with-param name="m">
				<xsl:value-of select='text()'/>
				<xsl:text> is not a valid EmailAddress for ContactPerson of type </xsl:text>
				<xsl:value-of select='ancestor::md:ContactPerson/@contactType'/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>


	<xsl:template match="md:EntityDescriptor">
		<!-- Organization must be set (Ian's rules do the rest once it is set) -->
		<xsl:if test="not(descendant::md:Organization)">
			<xsl:call-template name="error">
				<xsl:with-param name="m">Organization details MUST be set</xsl:with-param>
			</xsl:call-template>
		</xsl:if>

		<!-- Check ContactPerson requirements -->
		<xsl:if test="count(md:ContactPerson[@contactType='technical'])=0">
			<xsl:call-template name="error">
				<xsl:with-param name="m">ContactPerson of type technical MUST be set</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="count(md:ContactPerson[@contactType='technical'])>1">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">More than one ContactPerson of type technical</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="count(md:ContactPerson[@contactType='support'])=0">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">ContactPerson of type support should be set</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="count(md:ContactPerson[@contactType='support'])>1">
			<xsl:call-template name="warning">
				<xsl:with-param name="m">More than one ContactPerson of type support</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>


	<!-- Check @Location uses a valid certificate -->
	<xsl:template match="md:*[@Location and starts-with(@Location, 'https:') and php:functionString('xsltfunc::checkURLCert', @Location) = 0]">
		<xsl:call-template name="error">
			<xsl:with-param name="m">
				<xsl:value-of select='local-name()'/>
				<xsl:text> Location does not use a valid SSL certificate</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- Check that @Location point at web servers that exist -->
	<xsl:template match="md:*[@Location and php:functionString('xsltfunc::checkURL', @Location) = 0]">
		<xsl:call-template name="error">
			<xsl:with-param name="m">
				<xsl:value-of select='local-name()'/>
				<xsl:text> Location is not a valid URL</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- Check entityID  -->
	<xsl:template match="md:EntityDescriptor[php:functionString('xsltfunc::checkURL', @entityID) = 0]">
		<xsl:call-template name="warning">
			<xsl:with-param name="m">
				<xsl:value-of select='@entityID'/>
				<xsl:text> entityID is not a valid URL (should use well-known location scheme)</xsl:text>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates/>
	</xsl:template>

</xsl:stylesheet>