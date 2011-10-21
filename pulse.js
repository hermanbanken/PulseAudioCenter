var Pulse;

(function($){

	Pulse = function Pulse(input, link, output){
		this.server = 'pulse:80';
		this.protocol = 'http';
		this.sinks = [];
		this.inputs = [];
		this.timeout = 500;
		this.refresh = [];
		this.selectors = [input, link, output];
		
		var self = this;
		this.handle = function(){
			Pulse.prototype.handle.apply(self, arguments);
		};
		
		$(this.selectors[0]+" sink").live("touchstart, mousedown", function(event){
			var input, index = $(event.target).closest("sink").attr('id');
			if(index)
			{
				for(var n in self.inputs){
					if(self.inputs[n].index == index)
						input = self.inputs[n];
				}
				
				var mh = new MouseHandler(event, function(data){
					// Do linking and handle release
					delete input.drag;
					var snap = self.snap(input, data);
					if(snap.distance < 100){
						input.sink = snap.sink.index;
					}
					self.render();
				}, self);
				input.drag = mh.getdata();
				
				event.preventDefault();
				return false;
			}
		});
		
		$("sink").live("click", function(event){
			var sink = $(event.target).closest("sink");
			console.log("Details for", sink.attr('id'));
		});
		
		this.addEmptySinks();
		this.update();
	}
	
	Pulse.prototype.addEmptySinks = function(){
		
	}
	
	Pulse.prototype.refreshFor = function(object){
		if(object in this.refresh) return;
		else this.refresh.push(object);
		this.render();
	};
	
	Pulse.prototype.snap = function(input, data){
		function d(a,b) 
		{
			return Math.sqrt(Math.pow(a.x-b.x, 2) + Math.pow(a.y-b.y, 2));
		}
		function p(item)
		{
			var a = $("#"+item.index);
			return {
				x: a.position().left + a.width()/2,
				y: a.position().top + a.height()/2
			};
		}
		
		var sink = _.reduce(this.sinks, function(best, item)
		{			
			if(best === 0 || d(p(item), data) < d(p(best), data)){
				return item;
			} else {
				return best;
			}
			
		}, 0);
		
		return { distance: d(p(sink), data), sink: sink};
	};
	
	Pulse.prototype.links = function(){
		var links = [], canvas = $(this.selectors[1]);
		_.each(this.inputs, function(item)
		{
			var a = $("#"+item.index), b = $("#"+item.sink);
			var to = {}, from = {
				x: a.position().left + a.width()/2,
				y: a.position().top + a.height()
			};
			
			if(item.drag && !item.drag.inactive){
				to = {
					x: item.drag.x,
					y: item.drag.y
				};
			} else if(b.size() > 0) {
				to = {
					x: b.position().left + b.width()/2,
					y: b.position().top
				};
			}
			links.push([from, to]);
			
		});
		
		_.each(links, function(link){
			link[0].x -= canvas.position().left;
			link[1].x -= canvas.position().left;
			link[0].y -= canvas.position().top;
			link[1].y -= canvas.position().top;
		});
		
		return links;
	}
	
	Pulse.prototype.render = function(){
		var cnv = $(this.selectors[1]).get(0);
		cnv.width = $(this.selectors[1]).width();
		cnv.height = $(this.selectors[1]).height();
		var ctx = cnv.getContext("2d");
		_.each(this.links(), function(link){
			ctx.moveTo(link[0].x, link[0].y);
			ctx.lineTo(link[1].x, link[1].y);
		});
		ctx.stroke();
		this.refresh = [];
	};
	
	// Format endPoint url for HTTP requests
	Pulse.prototype.endPoint = function(){
		return this.protocol + "://" + this.server + "/endpoint.php";
	};
	
	// Handle xhr response and differentiate between objects and array's of object.
	Pulse.prototype.handle = function(data, status, xhr){
		_.each(
			(data != null && typeof data === "object" && 'splice' in data && 'join' in data ) ? data : [data], 
			this.handleData , 
			this
		);
		this.render();
	};
	
	// Handle xhr response object redirected from Pulse.handle.
	Pulse.prototype.handleData = function(data){
		var self = this;
		
		if(!data.type) this.error(1, "Wrong response data");
		switch(data.type){
			case 'sinks': 
				var mods = this.mods(this[data.type], data[data.type], 'index');
				_.each(mods['+'], function(item){
					self.add(self.selectors[2], 'template-sink', data[data.type][item]);
				});
				_.each(mods['-'], this.remove);
				this[data.type] = data[data.type];
				break;
			case 'inputs':
				var mods = this.mods(this[data.type], data[data.type], 'index');
				_.each(mods['+'], function(item){
					self.add(self.selectors[0], 'template-sink-input', data[data.type][item]);
				});
				_.each(mods['-'], this.remove);
				this[data.type] = data[data.type];
				break;
		}
	};
	
	// Add sink or input by parent selector, template id, and data.
	Pulse.prototype.add = function(parent, template, data){
		var html = _.template($("#"+template).html(), data);
		var el = $(html).addClass('adding').appendTo(parent);
		// Remove class for animation after animation is done
		setTimeout(function(){
			el.removeClass('adding');
		}, this.timeout);
	};
	
	// Remove sink or input by id.
	Pulse.prototype.remove = function(id){
		var el = $("#"+id).addClass('removing');
		// Remove from DOM after animation is done
		setTimeout(function(){
			el.remove();
		}, this.timeout);
	};
	
	// Calculate added values and removed values.
	Pulse.prototype.mods = function(a, b, id){
		var mod = {
			// _.difference(array, other) 
			// Returns the values from array that are not present in other.
			"-": _.difference(_.pluck(a, id), _.pluck(b, id)),
			"+": _.difference(_.pluck(b, id), _.pluck(a, id))
		};
		return mod;
	};
	
	// Fetch all data from server
	Pulse.prototype.update = function(){
		$.get( this.endPoint(), { 'action': 'update' }, this.handle);
	};
	
	Pulse.prototype.error = function(no, message){
		console.error(no, message);
	};
	
})(jQuery);

var MouseHandler;

(function($){
	
	MouseHandler = function MouseHandler(event, release, listener){
		this.move = _.bind(this.move, this);
		this.end  = _.bind(this.end,  this);
	
		if ('ontouchstart' in document.documentElement) {
			document.body.addEventListener("touchmove", this.move, true);
			document.body.addEventListener("touchend", this.end, true);
		} else {
			document.body.addEventListener("mousemove", this.move, true);
			document.body.addEventListener("mouseup", this.end, true);
		}
		this.data = {
			x: null,
			y: null,
			identifier: null
		};
		listener.refreshFor(this);
		this.release = release;
		this.listener = listener;
	};
	
	MouseHandler.prototype.getdata = function(){
		return this.data;
	};
	
	MouseHandler.prototype.touch = function(event){
		this.move(event);
	};
	
	MouseHandler.prototype.move = function(event){
		if ('ontouchstart' in document.documentElement) {
			for(var n in event.touches){
				if(event.touches[n].identifier == this.data.identifier){
					this.data.x = event.touches[n].pageX;
					this.data.y = event.touches[n].pageY;
					break;
				}
			}
		} else {
			this.data.x = event.pageX;
			this.data.y = event.pageY;
		}
		this.listener.refreshFor(this);
	};
	
	MouseHandler.prototype.end = function(event){
		this.move(event);
	
		if ('ontouchstart' in document.documentElement) {
			document.body.removeEventListener("touchmove", this.move, true);
			document.body.removeEventListener("touchend", this.end, true);
		} else {
			document.body.removeEventListener("mousemove", this.move, true);
			document.body.removeEventListener("mouseup", this.end, true);
		}
		this.data.inactive = true;
		this.release(this.data);
	};
	
})(jQuery);