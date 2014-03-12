var graph=[]
var data;

function renderStandard(index) { 

	update = metricURL(gon.metrics[index].feed, gon.start, gon.stop, gon.step)
                
	$.getJSON(update, function(data) {
		if (data.error) { renderError("chart_"+index, data.error, "renderStandard"); stopUpdates(); return false} 
		if (data.length == 0) { renderError("chart_"+index, "no data returned from endpoint: "+update, "renderStandard"); stopUpdates(); return false}
		graph[index] = new Rickshaw.Graph({
			element: document.getElementById("chart_"+index),
			width: 700,
			height: 200,
			renderer: 'line',
			series: new Rickshaw.Series.FixedDuration([{name: "data" }], undefined, { 
				timeInterval: gon.step*1000,
				maxDataPoints: data.length, 
				timeBase: data[0].x  
			})
		})

		chart = "chart_"+index
		yaxis = "y_axis_"+index

		new Rickshaw.Graph.Axis.Y( {
			graph: graph[index],
			orientation: 'left',
			tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
			element: document.getElementById(yaxis)
		} );

		new Rickshaw.Graph.Axis.Time({
			graph: graph[index],
			timeFixture: new Rickshaw.Fixtures.Time.Local()
		});

		graph[index].render()
		
		new Rickshaw.Graph.HoverDetail({
			graph: graph[index],
			formatter: function (series, x, y) {
				return content = "<span class='date'>"+d3.time.format("%Y-%m-%d %H:%M:%S")(new Date(x*1000)) +"</span><br/>"+y
			}
		});

		$.each(data, function(i, point) {                                                                         
			x = {data: point.y} 
			graph[index].series.addData(x) 
		})
		graph[index].render()

		unrenderWaiting();
		renderSlider();
	}) 
}

function updateStandard(){ 
	id = setInterval(function() { 		
		now = parseInt(Date.now()/1000)

		$.each(gon.metrics, function(i, metric) { 
			if (metric.live) { 
			update = metricURL(metric.feed,now-gon.step,now,gon.step)
			$.getJSON(update, function(d){ 
				if (d.error) { renderError("flash", d.error, "updateStandard"); stopUpdates(); return false} 
				if (d.length == 0) { renderError("flash", "no data returned from endpoint: "+update, "updateStandard"); stopUpdates(); return false}
				new_data = {data: d[d.length-1].y}
				graph[i].series.addData(new_data); 
				graph[i].render()
			})
			}
		})
	}
	, gon.step*1000);
	return id
}

var complete = 0;
function renderSlider() { 
        complete++;

        // Render the multiple graph slider only when all the graphing operations have been completed.
        if (complete = gon.metrics.length) { 
        new Rickshaw.Graph.RangeSlider({ 
                graph: graph, 
                element: $("#multi_slider")
                });
        }
}
