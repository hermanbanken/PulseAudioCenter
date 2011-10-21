<?php  

require_once('pulseaudio.class.php');

$sinks = array(
	"S001" => array('index' => 'S001', 'name' => 'Denon HiFi', 'volume' => 100, 'muted' => false, 'state' => 0, 'suspend cause' =>0 , 'current latency'=>0),
	"S002" => array('index' => 'S002', 'name' => 'Waskamer', 'volume' => 80, 'muted' => true, 'state' => 0, 'suspend cause' =>0 , 'current latency'=>0),
	"S003" => array('index' => 'S003', 'name' => 'Gang', 'volume' => 80, 'muted' => true, 'state' => 0, 'suspend cause' =>0 , 'current latency'=>0),
	"S004" => array('index' => 'S004', 'name' => 'Keuken', 'volume' => 20, 'muted' => false, 'state' => 0, 'suspend cause' =>0 , 'current latency'=>0),
	"S005" => array('index' => 'S005', 'name' => 'Studeerkamer', 'volume' => 40, 'muted' => false, 'state' => 0, 'suspend cause' =>0 , 'current latency'=>0)
);
$inputs = array(
	"I001" => array('index' => 'I001', 'name' => 'VLC', 'volume' => 100, 'muted' => false, 'sink' => 'S001'),
	"I002" => array('index' => 'I002', 'name' => 'Airport Eki', 'volume' => 100, 'muted' => false, 'sink' => 'S001'),
	"I003" => array('index' => 'I003', 'name' => 'Airport Dvi', 'volume' => 100, 'muted' => false, 'sink' => 'S002'),
	"I004" => array('index' => 'I004', 'name' => 'Airport Tri', 'volume' => 100, 'muted' => false, 'sink' => 'S005'),
);

header("Content-type: text/json");

if($_SERVER['REQUEST_METHOD'] == 'POST'){
	
} elseif($_SERVER['REQUEST_METHOD'] == 'GET'){
	switch($_GET['action']){
		case 'update':
			echo json_encode(array(
				array('type'=>'sinks', 'sinks'=>$sinks),
				array('type'=>'inputs', 'inputs'=>$inputs)
			));
			break;
	}
}

?>