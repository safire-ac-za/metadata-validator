<?php
/**
 * Template footer for metadata-validator
 *
 * SAFIRE uses SimpleSAMLphp, and so we need to skin this to look somewhat
 * like our version of SimpleSAMLphp. As such, parts of this template are
 * loosely derived from {@link http://simplesamlphp.org/ SimpleSAMLphp}
 *
 * @author Guy Halse http://orcid.org/0000-0002-9388-8592
 * @copyright Copyright (c) 2016, Tertiary Education and Research Network of South Africa
 * @license https://github.com/tenet-ac-za/metadata-validator/blob/master/LICENSE MIT License
 */

if (file_exists(dirname(__DIR__) . '/local/config.inc.php')) {
    include_once(dirname(__DIR__) . '/local/config.inc.php');
}
?>
    </div><!-- #content -->
    <div id="footer">
        <hr>
        <span><a href="https://<?php echo constant('DOMAIN') ?>/safire/policy/privacy/">Privacy statement</a></span>
        <span class="float-r"><a href="https://<?php echo constant('DOMAIN') ?>/">SAFIRE - South African Identity Federation</a></span>

        <br class="clear-r">

    </div><!-- #footer -->

</div><!-- #wrap -->

</body>
</html>

