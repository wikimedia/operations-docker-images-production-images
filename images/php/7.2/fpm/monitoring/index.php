<?php
/*

Admin cli interface for php-fpm. It supports a /metrics endpoint where we expose data
in a format prometheus likes.
*/
require('lib.php');

$usage = <<<'EOD'
Supported urls:

  /metrics         Metrics about APCu and OPcache usage
  /healthz         Health endpoint.

EOD;

ob_start();

switch ($_SERVER['SCRIPT_NAME']) {
	case '/metrics':
		show_prometheus_metrics();
		break;
	case '/healthz':
		healthz();
		break;
	default:
		header("Content-Type: text/plain");
		echo $usage;
}

ob_flush();