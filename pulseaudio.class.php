<?php
class PulseAudio {
	
	public function __construct(){
		// Void
	}
	
	// Get all inputs
	public function get_sink_inputs(){
		$output = shell_exec('pacmd list-sink-inputs');
		$result = parse_shell_output($output, array('index', 'volume', 'muted', 'sink'));
		print_r($result);
	}
	
	// Get all outputs
	public function get_sinks(){	
		$output = shell_exec('pacmd list-sinks');
		$result = parse_shell_output($output, array('index', 'name', 'volume', 'muted', 'state', 'suspend cause', 'current latency'));
		print_r($result);
	}
	
	private function parse_shell_output($output, $keys = array('index', 'name', 'volume', 'muted', 'state')){
		$lines = explode('\n', $output);
		$spacing = "[\t\s]*";
		$match = "/^$spacing(?P<default>\*)?$spacing(?P<key>".implode("|", $keys)."): (?P<value>.*)$/";
		$devices = array();
		$default = 0;
		foreach($lines as $nr => $line){
			if(preg_match($match, $line, $matches)){
				if($matches['key'] == 'index') $devices[] = array();
				if($matches['default'] && $matches['default'] == "*") $default = count($devices)-1;
				
				if(is_array($devices[count($devices)-1]))
					$devices[count($devices)-1][$matches['key']] = $matches['value'];
			}
		}
		$devices['default'] = $default;
		return array('devices'=>$devices, 'default'=>$default);
	}
	
	// Mute input
	public function mute_sink_input($IID, $mute){
		$output = shell_exec('pacmd set-sink-input-mute '.intval($IID).' '.intval($mute));
	}
	
	// Mute output
	public function mute_sink($OID, $mute){
		$output = shell_exec('pacmd set-sink-mute '.intval($OID).' '.intval($mute));
	}
	
	// Set default output
	public function set_default_sink($OID){
		$output = shell_exec('pacmd set-default-sink '.intval($OID));
	}
	
	// Move input to output
	public function move_sink($IID, $OID){
		$output = shell_exec('pacmd move-sink-input '.intval($IID).' '.intval($OID));
	}
	
	// Set input vol
	public function set_input_vol($IID, $vol){
		$output = shell_exec('pacmd set-sink-input-volume '.intval($IID).' '.(65535 * $vol / 100));
	}
	
	// Set output vol
	public function set_output_vol($OID, $vol){
		$output = shell_exec('pacmd set-sink-volume '.intval($OID).' '.(65535 * $vol / 100));
	}
	
}
?>