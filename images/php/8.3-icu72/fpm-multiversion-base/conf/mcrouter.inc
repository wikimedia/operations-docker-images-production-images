; mcrouter location, this variable is read in mc.php.
; if the ENV variable is not set, mediawiki will fallback
; to a default variable.
env['MCROUTER_SERVER'] = ${MW__MCROUTER_SERVER}

; Please note: this file is a temporary solution for backwards compatibility.
; It will be removed as soon as all the mw deployments have picked up the new
; envvars system.