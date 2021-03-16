<?php
require __DIR__ . "/AdoyFastCgiClient.php";
use Adoy\FastCGI\Client;
# Only runs in cli mode
if ( PHP_SAPI ( ) != "cli" ) {
    error_log("This script can only be executed from cli");
    exit(1);
}

# Figure out the connection parameters, and create the client.
if ( !array_key_exists( 'FCGI_URL', $_SERVER ) ) {
    error_log("You need to define the FCGI_URL environment variable");
    exit(1);
}
$fcgi_url = $_SERVER['FCGI_URL'];
if ( strpos( $fcgi_url, 'unix://' ) === 0 ) {
    $host = $fcgi_url;
    $port = -1;
} else {
    $parsed = explode(':', $fcgi_url, 2);
    $host = $parsed[0];
    $port = $parsed[1];
}

$client = new Client($host, $port);
# For now just unconditionally call the ping path

$params = [
    'GATEWAY_INTERFACE' => 'FastCGI/1.0',
    'REQUEST_METHOD'    => 'GET',
    'SCRIPT_FILENAME'   => '/var/www/livez',
    'SCRIPT_NAME'       => '/livez',
    'REQUEST_URI'       => '/livez',
    'SERVER_SOFTWARE'   => 'php/fcgiclient',
    'REMOTE_ADDR'       => '127.0.0.1',
    'REMOTE_PORT'       => '9985',
    'SERVER_ADDR'       => '127.0.0.1',
    'SERVER_PORT'       => '80',
    'SERVER_NAME'       => php_uname('n'),
    'SERVER_PROTOCOL'   => 'HTTP/1.1',
    'CONTENT_TYPE'      => '',
    'CONTENT_LENGTH'    => 0
];

# Make the request, and wait for the response.
# If an exception is thrown, the script will exit
# with a non-zero value, which is what we want.
try {
    $reqid = $client->async_request($params, false);
    $response = $client->wait_for_response_data($reqid);
} catch ( Exception $e) {
    error_log($e);
    exit(1);
}
# Check the status of the response.
if ( $response['state'] == Client::REQ_STATE_OK ) {
    echo "OK!";
    exit(0);
} else {
    print_r($response['response']);
    exit(1);
}