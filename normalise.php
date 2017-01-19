<?php
/**
 * metadata-validator normalizer
 *
 * This tool can be run either on the command line or via a POST. It
 * takes well-formed SAML metadata and returns it with namespaces
 * prefixed on all elements
 *
 * @author Guy Halse http://orcid.org/0000-0002-9388-8592
 * @copyright Copyright (c) 2016, SAFIRE - South African Identity Federation
 * @license https://github.com/safire-ac-za/metadata-validator/blob/master/LICENSE MIT License
 */

/** @var array $namespaces SAML namespaces lookup table */
$namespaces = array(
    'urn:oasis:names:tc:SAML:2.0:protocol' => 'samlp',
    'urn:oasis:names:tc:SAML:2.0:assertion' => 'saml',
    'urn:mace:shibboleth:metadata:1.0' => 'shibmd',
    'urn:oasis:names:tc:SAML:2.0:metadata' => 'md',
    'urn:oasis:names:tc:SAML:metadata:rpi' => 'mdrpi',
    'urn:oasis:names:tc:SAML:metadata:ui' => 'mdui',
    'urn:oasis:names:tc:SAML:metadata:attribute' => 'mdattr',
    'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol' => 'idpdisc',
    'urn:oasis:names:tc:SAML:profiles:SSO:request-init' => 'init',
    'http://www.w3.org/2001/XMLSchema-instance' => 'xsi',
    'http://www.w3.org/2001/XMLSchema' => 'xs',
    'http://www.w3.org/1999/XSL/Transform' => 'xsl',
    'http://www.w3.org/XML/1998/namespace' => 'xml',
    'http://schemas.xmlsoap.org/soap/envelope/' => 'SOAP-ENV',
    'http://www.w3.org/2000/09/xmldsig#' => 'ds',
    'http://www.w3.org/2001/04/xmlenc#' => 'xenc',
    'urn:oasis:names:tc:SAML:metadata:algsupport' => 'algsupport',
    'http://ukfederation.org.uk/2006/11/label' => 'ukfedlabel',
    'http://sdss.ac.uk/2006/06/WAYF' => 'wayf',
    'http://refeds.org/metadata' => 'remd',
);

if (substr(PHP_SAPI, 0, 3) === 'cli') {
    if ($argc > 1) {
        $xml = file_get_contents($argv[1]);
    } else {
        $xml = file_get_contents('php://stdin');
    }
} else {
    $xml = file_get_contents('php://input');
    header("Content-Type: text/plain");
}
if (empty($xml)) {
    print "No input given\n"; exit(1);
}

libxml_clear_errors();
$doc = new DOMDocument();
$doc->preserveWhiteSpace = false;
$doc->formatOutput = true;
if ($doc->loadXML($xml) !== true) {
    print "Error loading XML: " . libxml_get_last_error() . "\n"; exit(1);
}

/* normalise with a variant of UKAF's rules */
libxml_clear_errors();
$xslt = new XSLTProcessor();
$xslt->importStylesheet(new SimpleXMLElement(__DIR__ . '/rules/ns_norm.xsl', 0, true));
$doc = $xslt->transformToDoc($doc);

/* get some XPath */
libxml_clear_errors();
$xp = new DomXPath($doc);
foreach($namespaces as $full => $prefix) {
    $xp->registerNamespace($prefix, $full);
    /* remove namespaces that are not in use */
    if ($xp->query("//${prefix}:*")->length === 0) {
        $doc->documentElement->removeAttributeNS($full, $prefix);
    }
}

/* merge like certificates in the most simple cases */
foreach (array('IDPSSODescriptor', 'SPSSODescriptor', 'AASSODescriptor') as $sso) {
    $e = $xp->query("//md:$sso");
    if ($e->length) {
        $signing = $xp->query("//md:KeyDescriptor[@use='signing']/ds:KeyInfo/ds:X509Data/ds:X509Certificate", $e->item(0));
        $encryption = $xp->query("//md:KeyDescriptor[@use='encryption']/ds:KeyInfo/ds:X509Data/ds:X509Certificate", $e->item(0));
        $unspecified = $xp->query("//md:KeyDescriptor[not(@use)]/ds:KeyInfo/ds:X509Data/ds:X509Certificate", $e->item(0));
        if ($signing->length == 1 and
            $encryption->length == 1 and
            $signing->item(0)->nodeValue = $encryption->item(0)->nodeValue and
            (
                $unspecified->length == 0 or
                (
                    $unspecified->length == 1 and
                    $signing->item(0)->nodeValue == $unspecified->item(0)->nodeValue
                )
            )
        ) {
            $encryption->item(0)->parentNode->parentNode->parentNode->parentNode->removeChild(
                $encryption->item(0)->parentNode->parentNode->parentNode
            );
            if ($unspecified->length == 1) {
                $signing->item(0)->parentNode->parentNode->parentNode->parentNode->removeChild(
                    $signing->item(0)->parentNode->parentNode->parentNode
                );
            } else {
                $signing->item(0)->parentNode->parentNode->parentNode->removeAttribute('use');
            }
        }
    }
}

$doc->preserveWhiteSpace = false;
$doc->formatOutput = true;
$doc->normalizeDocument();
print $doc->saveXML();