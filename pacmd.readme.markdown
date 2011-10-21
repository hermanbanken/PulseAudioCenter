TYP(x3)(y3)
type = switch
x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
y = VAL(MID(ENVIRON("QUERY_STRING"), 9, 1))

#Mute
Eg. MUT001000 to mute the idx 1, and MUT001001 to unmute it
pacmd set-sink-input-mute x 0
pacmd set-sink-input-mute x 1

#Vol
Eg. VOL020095 to make volume at 95% for idx 20
pacmd set-sink-input-volume x INT(65535 * y / 100)

#SMT
Mute given sink. Eg. SMT001000 to mute the sink #1, and SMT001001 to unmute it
pacmd set-sink-mute x 0
pacmd set-sink-mute x 1

#SVL
Sets sink's volume, Eg. SVL002070 to set sink #2 to 70% volume
pacmd set-sink-volume x INT(65535 * y / 100)

#MOV
Move sink-input to another sink. Eg. MOV028002 moves the 028 app to sink #2
pacmd move-sink-input x y

#SDS
Set Default Sink - sets the def. sink (eg. SDS028000 to make the sink #28 default)
pacmd set-default-sink x

#List sinks
pacmd list-sinks

#List sink inputs
pacmd list-sink-inputs

#pacmd list-sinks >>> 1 sink(s) available.
  * index: 0										#if * then is default sink
	name: <auto_null>								
	driver: <module-null-sink.c>
	flags: DECIBEL_VOLUME LATENCY DYNAMIC_LATENCY
	state: SUSPENDED
	suspend cause: IDLE 
	priority: 1000
	volume: 0: 100% 1: 100%							#volume: eerste waarde xxx%
	        0: 0.00 dB 1: 0.00 dB
	        balance 0.00
	base volume: 100%
	             0.00 dB
	volume steps: 65537
	muted: no										#mute = "no" or not
	current latency: 0.00 ms
	max request: 344 KiB
	max rewind: 344 KiB
	monitor source: 0
	sample spec: s16le 2ch 44100Hz
	channel map: front-left,front-right
	             Stereo
	used by: 0
	linked by: 0
	configured latency: 0.00 ms; range is 0.50 .. 10000.00 ms
	module: 11
	properties:
		device.description = "Dummy Output"			#description
		device.class = "abstract"
		device.icon_name = "audio-card"
		
#pacmd list-sink-inputs >>> 1 sink-input(s) available.
	sink: 001 										# sink no.
	volume: 100%									# vol
	muted: no										# muted
	application.name: name							# name
	application.icon_name: name						# icon
	# owner ???
	# host ???
	
	
