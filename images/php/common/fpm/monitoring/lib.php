<?php
// Monitoring helper for PHP-FPM 7.x

// Only consider blocks <5M for the fragmentation
define('BLOCK_SIZE', 5*1024*1024);

$sma_info = null;

function opcache_stats(bool $full = false): array {
	// first of all, check if opcache is enabled
	$stats = opcache_get_status($full);
	if ($stats === false) {
		return [];
	}
	return $stats;
}

function apcu_stats(bool $limited = true ): array {
	global $sma_info;
	if (!function_exists('apcu_cache_info')) {
		return [];
	}
	$cache_info = apcu_cache_info($limited);
	if ($cache_info === false) {
		$cache_info = [];
	}
	if ($sma_info === null) {
		$sma_info = apcu_sma_info();
	}
	if ($sma_info === false) {
		$sma_info = [];
	}
	return array_merge($cache_info, $sma_info);
}

// Returns  % of APCu fragmentation
// This code is part of https://github.com/krakjoe/apcu/blob/master/apc.php
function apcu_frag() {
	global $sma_info;
	if ($sma_info === null) {
		$sma_info = apcu_sma_info();
	}
	if ($sma_info === false) {
		$sma_info = [];
	}
	$nseg = $freeseg = $fragsize = $freetotal = 0;
	for($i=0; $i<$sma_info['num_seg']; $i++) {
		$ptr = 0;
		foreach($sma_info['block_lists'][$i] as $block) {
			if ($block['offset'] != $ptr) {
				++$nseg;
			}
			$ptr = $block['offset'] + $block['size'];
			if($block['size']<BLOCK_SIZE) $fragsize+=$block['size'];
				$freetotal+=$block['size'];
		}
		$freeseg += count($sma_info['block_lists'][$i]);
	}
	if ($freeseg > 1) {
		$frag = $fragsize/$freetotal*100;
	} else {
		$frag = 0;
	}
	return round($frag, 5, PHP_ROUND_HALF_UP);
}

/*

  Very simple class to manage prometheus metrics printing.
  Not intended to be complete or useful outside of this context.

*/
class PrometheusMetric {
	public $description;
	public $key;
	private $value;
	private $labels;
	private $type;

	function __construct(string $key, string $type, string $description) {
		$this->key = $key;
		$this->description = $description;
		// Set labels empty
		$this->labels = [];
		$this->type = $type;
	}

	public function setValue($value) {
		if (is_bool($value) === true) {
			$this->value = (int) $value;
		} elseif (is_array($value)) {
			$this->value = implode($value, " ");
		} else {
			$this->value = $value;
		}
	}

	public function setLabel(string $name, string $value) {
		$this->labels[] = "$name=\"$value\"";
	}

	private function _helpLine(): string {
		// If the description is empty, don't return
		// any help header.
		if ($this->description == "") {
			return "";
		}
		return sprintf("# HELP %s %s\n# TYPE %s %s\n",
					$this->key, $this->description,
					$this->key, $this->type
		);
	}

	public function __toString() {
		if ($this->labels != []) {
			$full_name = sprintf('%s{%s}',$this->key, implode(",", $this->labels));
		} else {
			$full_name = $this->key;
		}
		return sprintf(
			"%s%s %s\n",
			$this->_helpLine(),
			$full_name,
			$this->value
		);
	}
}


function prometheus_metrics(): array {
	$oc = opcache_stats();
	$ac = apcu_stats();
	$af = apcu_frag();
	$defs = [
		[
			'name' => 'php_opcache_enabled',
			'type' => 'gauge',
			'desc' => 'Opcache is enabled',
			'value' => $oc['opcache_enabled']
		],
		[
			'name' => 'php_opcache_full',
			'type' => 'gauge',
			'desc' => 'Opcache is full',
			'value' => $oc['cache_full']
		],
		[
			'name' => 'php_opcache_memory',
			'type' => 'gauge',
			'label' => ['type', 'used'],
			'desc' => 'Used memory stats',
			'value' => $oc['memory_usage']['used_memory']
		],
		[
			'name' => 'php_opcache_memory',
			'type' => 'gauge',
			'label' => ['type', 'free'],
			'desc' => '',
			'value' => $oc['memory_usage']['free_memory']
		],
		[
			'name' => 'php_opcache_memory',
			'type' => 'gauge',
			'label' => ['type', 'wasted'],
			'desc' => '',
			'value' => $oc['memory_usage']['wasted_memory']
		],
		[
			'name' => 'php_opcache_wasted_memory',
			'type' => 'gauge',
			'desc' => 'Percentage of wasted memory in opcache',
			'value' => round($oc['memory_usage']['current_wasted_percentage'],5, PHP_ROUND_HALF_UP)
		],
		[
			'name' => 'php_opcache_strings_memory',
			'type' => 'gauge',
			'label' => ['type', 'used'],
			'desc' => 'Memory usage from interned strings',
			'value' => $oc['interned_strings_usage']['used_memory']
		],
		[
			'name' => 'php_opcache_strings_memory',
			'type' => 'gauge',
			'label' => ['type', 'free'],
			'desc' => '',
			'value' => $oc['interned_strings_usage']['free_memory']
		],
		[
			'name' => 'php_opcache_strings_numbers',
			'type' => 'gauge',
			'desc' => 'Memory usage from interned strings',
			'value' => $oc['interned_strings_usage']['number_of_strings'],
		],
		[
			'name' => 'php_opcache_stats_cached',
			'type' => 'gauge',
			'label' => ['type', 'scripts'],
			'desc' => 'Stats about cached objects',
			'value' => $oc['opcache_statistics']['num_cached_scripts']
		],
		[
			'name' => 'php_opcache_stats_cached',
			'type' => 'gauge',
			'label' => ['type', 'keys'],
			'desc' => '',
			'value' => $oc['opcache_statistics']['num_cached_keys']
		],
		[
			'name' => 'php_opcache_stats_cached',
			'type' => 'counter',
			'label' => ['type', 'max_keys'],
			'desc' => '',
			'value' => $oc['opcache_statistics']['max_cached_keys']
		],
		[
			'name' => 'php_opcache_stats_cache_hit',
			'type' => 'counter',
			'label' => ['type', 'hits'],
			'desc' => 'Stats about cached object hit/miss ratio',
			'value' => $oc['opcache_statistics']['hits']
		],
		[
			'name' => 'php_opcache_stats_cache_hit',
			'type' => 'counter',
			'label' => ['type', 'misses'],
			'desc' => '',
			'value' => $oc['opcache_statistics']['misses']
		],
		[
			'name' => 'php_opcache_stats_cache_hit',
			'type' => 'counter',
			'label' => ['type', 'total'],
			'desc' => '',
			'value' => ($oc['opcache_statistics']['misses'] + $oc['opcache_statistics']['hits'])
		],
		[
			'name' => 'php_apcu_num_slots',
			'type' => 'counter',
			'desc' => 'Number of distinct APCu slots available',
			'value' => $ac['num_slots'],
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'hits'],
			'desc' => 'Stats about APCu operations',
			'value' => $ac['num_hits'],
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'misses'],
			'desc' => '',
			'value' => $ac['num_misses'],
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'total_gets'],
			'desc' => '',
			'value' => ($ac['num_misses'] + $ac['num_hits']),
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'inserts'],
			'desc' => '',
			'value' => $ac['num_inserts'],
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'entries'],
			'desc' => '',
			'value' => $ac['num_entries'],
		],
		[
			'name' => 'php_apcu_cache_ops',
			'type' => 'counter',
			'label' => ['type', 'expunges'],
			'desc' => '',
			'value' => $ac['expunges'],
		],
		[
			'name' => 'php_apcu_memory',
			'type' => 'gauge',
			'label' => ['type', 'free'],
			'desc' => 'APCu memory status',
			'value' => $ac['avail_mem'],
		],
		[
			'name' => 'php_apcu_memory',
			'type' => 'gauge',
			'label' => ['type', 'total'],
			'desc' => '',
			'value' => $ac['seg_size'],
		],
		[
			'name' => 'php_apcu_fragmentation',
			'type' => 'gauge',
			'desc' => 'APCu fragementation percentage',
			'value' => $af,
		],
	];
	$metrics = [];
	foreach ($defs as $metric_def) {
		$t = isset($metric_def['type'])? $metric_def['type'] : 'counter';
		$p = new PrometheusMetric($metric_def['name'], $t, $metric_def['desc']);
		if (isset($metric_def['label'])) {
			$p->setLabel(...$metric_def['label']);
		}
		if (isset($metric_def['value'])) {
			$p->setValue($metric_def['value']);
		}
		$metrics[] = $p;
	}
	return $metrics;
}

// Views
function show_prometheus_metrics() {
	header("Content-Type: text/plain");
	foreach (prometheus_metrics() as $k) {
		printf("%s", $k);
	}
}

// If the min_avail_workers query parameter is set,
// an error will be returned to the client.
// This is useful to check if the service is overloaded
// and specifically to ensure we don't send more requests
// to a pod that is already almost fully busy.
function healthz() {
	$min_avail_workers = intval($_GET['min_avail_workers'] ?? -1);
	if ($min_avail_workers > 0) {
		// Sleep briefly to allow php-fpm to see that we have a busy
		// worker
		usleep(200000);
		$fpm_status = fpm_get_status();
		$pm = $fpm_status['idle-processes'];
		if ($pm < $min_avail_workers) {
			header("HTTP/1.1 503 Service Unavailable");
			print("Service Unavailable");
			return;
		}
	}

	header("Content-Type: text/plain");
	print("OK");
}
