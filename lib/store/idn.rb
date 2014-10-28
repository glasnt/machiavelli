# IDN Datasource
# From Bureau of Meteorology JSON outputs of Latest Observations
# Assumes a list of json files in a directory called @data_folder
# 
# Suggestion: place the @data_folder in a subfolder of public/ and use nginx's autoindex to serve the folder for debugging, etc
#
# sample config:
#
# location /files {
#        root /path/to/machiavelli/public;
#        autoindex on;
#    }
 

class Store::Idn < Store::Store

	def initialize origin,settings
		super
		@data_folder = mandatory_param :data_folder, "store_settings"
	end

	def get_metrics_list
		list = []
		Dir[@data_folder+"/*/*"].each{|f|
			d = JSON.parse(File.read(f))
			site = nameparse(d.observations.header.first.name)
			measures = d.observations.data.first.map{|k,v| k}.select{|m| METS.include? m}
			list.push( measures.map{|m| "#{site}#{sep}#{m}"})
		}
	
		set_idn_sitemap
			
		list.flatten.uniq
	end


 # In lieu of pinging a href, confirm the existance of the file
        def is_up?
                File.exists?(@data_folder)
        end

        # Flat files don't auto update, therefore cannot be assumed to be live
        def live?
                false
        end


	def get_metric_url m,_,_,_
		name = m.id.split(SEP).last.split(sep).first
		id = idn_sitemap(name).first.split("/")[2]
		dir = @data_folder.gsub("public/","")
		return "#{dir}/#{id}"
	end

	def get_metric m, start=nil, stop=nil, step=nil
		site, met = m.id.split(SEP).last.split(sep)

		unless idn_sitemap(site).length > 1 then
			return {error: "Site #{site} does not exist"}.to_json
		end


		blob = []; zone = "";
		idn_sitemap(site).each { |f|
			blob += JSON.parse(File.read(f)).observations.data
			zone = JSON.parse(File.read(f)).observations.header.first.time_zone
		}

		offset = "+10" if zone == "EST"
		offset = "+11" if zone == "EDT"

		blob = blob.uniq{|k| k.local_date_time_full}
		data = []

		blob.each{|b|
			date = DateTime.parse("#{b.local_date_time_full}#{offset}").strftime("%s").to_i
			data.push({x: date, y: b[met].to_f}) if date.between?(start,stop)
		}

		step =  data[1] ? (data[1][:x] - data[0][:x]).abs : 1800
		data = [{x:(stop - (stop-start)/2).to_i,y:nil}] if data.empty?

		data = data.sort{|a,b| a[:x] <=> b[:x]} if data

		padded = []

		(data[0][:x] - step).step(start, -step).each{|x| padded.push({x:x, y:nil}) }

		padded.reverse!
		padded.concat data

		((data[-1][:x] + step)..stop).step(step).each{|x| padded.push({x:x, y:nil}) }

		padded.take((stop-start)/step).to_json

	end


# Magic Hash to Object widget
class ::Hash
	def method_missing(name)
		return self[name] if key? name
		self.each { |k,v| return v if k.to_s.to_sym == name }
		super.method_missing name
	end
end

METS = ["delta_t","gust_kmh","rain_trace","rel_hum","wind_spd_kmh","air_temp","apparent_t"]

def nameparse n; n.gsub(" ","").gsub("-",""); end

def set_idn_sitemap
	r = redis_conn
	Dir[@data_folder+"/*/*"].each{|f|
		site = nameparse(JSON.parse(File.read(f)).observations.header.first.name)
		r.sadd "#{REDIS_KEY}BOM:IDN_SITEMAP:#{site}",f 
	}
end

def idn_sitemap site
	redis_conn.smembers "#{REDIS_KEY}BOM:IDN_SITEMAP:#{site}"
end

def sep; "-"; end

end
