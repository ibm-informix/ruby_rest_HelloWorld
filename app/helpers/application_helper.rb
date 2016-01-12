require "net/http"
require "uri"

module ApplicationHelper

	# To run locally, set URL, USER, DBNAME, and PASSWORD fields here for REST connectivity
	URL = ""
	DBNAME = ""
	USER = ""
	PASSWORD = ""
	
	# When deploying to Bluemix, controls whether or not to use SSL
	USE_SSL = false

	def runHelloWorld()

		def code_2xx?(responseCode)
			# response codes in 200's are returned upon success
			# this function should be more robust, but works for this specific use
			if responseCode.start_with?('2')
				return true
			else
				return false
			end
		end 

		# create array to store info for output
		output = Array.new
		
		if (URL == nil || URL == "")
			logger.info("parsing VCAP_SERVICES")
			if ENV['VCAP_SERVICES'] == nil
				output.push("Cannot find VCAP_SERVICES in environment")
				return output
			end
                        serviceName = "timeseriesdatabase"
			if ENV['SERVICE_NAME'] != nil
				serviceName = ENV['SERVICE_NAME']
			end
			logger.info("Using service name " + serviceName)
			vcap_hash = JSON.parse(ENV['VCAP_SERVICES'])[serviceName]
			credHash = vcap_hash.first["credentials"]
			dbname = credHash["db"]
			user = credHash["username"]
			password = credHash["password"]
			if (USE_SSL)
				rest_url = credHash["rest_url_ssl"]
			else
				rest_url = credHash["rest_url"]
			end
		else
			rest_url = URL
			dbname = DBNAME
			user = USER
			password = PASSWORD
		end

		uri = URI.parse(rest_url)
		collectionName = "restcollection"
		
		# check if collection exists, if so delete
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new(uri + "#{dbname}")
		request.basic_auth(user, password)
		response = http.request(request)
		cookie = response['set-cookie'].split('; ')
		output.push("Existing collections: #{response.body}")
		if response.body.include? "#{collectionName}"
			output.push("Deleting collection: #{collectionName}")
			request = Net::HTTP::Delete.new(uri + "/#{dbname}/#{collectionName}")
			request['cookie'] = cookie
			response = http.request(request)
			unless code_2xx?(response.code)
				output.push("Failed to delete existing collection")
			end
		end

		# create collection
		output.push("Creating new collection: #{collectionName}")
		request = Net::HTTP::Post.new(uri + "#{dbname}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		request.body = {:name => "#{collectionName}"}.to_json
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to create collection: #{collectionName}")
		end

		output.push("Insert a single document to a collection")
		data = {:name => "test1",:value => "1"}.to_json
		request = Net::HTTP::Post.new(uri + "#{dbname}/#{collectionName}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		request.body = data
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to insert single document: #{response.code}, #{response.message}, #{response.body}")
		end

		output.push("Insert multiple documents to a collection")
		data = [{:name => 'test1', :value => 101}, {:name => 'test2', :value => 202}, {:name => 'test3', :value => 303}].to_json
		request = Net::HTTP::Post.new(uri + "/#{dbname}/#{collectionName}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		request.body = data
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to insert multiple documents: #{response.code}, #{response.message}, #{response.body}")
		end

		output.push(" ")
		output.push("Find a document in a collection that matches a query condition")
		queryStr = '{"name":"test1"}'
		request = Net::HTTP::Get.new(uri + "/#{dbname}/#{collectionName}?query=#{queryStr}&fields={_id:0}&limit=1")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		response = http.request(request)
		output.push("Result of query: #{response.body}")

		output.push(" ")
		output.push("Find all documents in a collection that match a query condition")
		queryStr = '{"name":"test1"}'
		request = Net::HTTP::Get.new(uri + "/#{dbname}/#{collectionName}?query=#{queryStr}&fields={_id:0}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		response = http.request(request)
		output.push("Result of query: #{response.body}")

		output.push(" ")
		output.push("Find all documents in a collection")
		request = Net::HTTP::Get.new(uri + "/#{dbname}/#{collectionName}")
		request['cookie'] = cookie
		response = http.request(request)
		output.push("All documents in collection:  #{response.body}")

		output.push(" ")
		output.push("Update documents in a collection")
		queryStr = '{name:"test3"}'
		updateStr = '{"$set" : {"value" : "9"} }'
		request = Net::HTTP::Put.new(uri + "/#{dbname}/#{collectionName}?query=#{queryStr}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		request.body = updateStr
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to update value")
		end

		output.push(" ")
		output.push("Delete documents in a collection")
		queryStr = '{name:"test2"}'
		request = Net::HTTP::Delete.new(uri + "/#{dbname}/#{collectionName}?query=#{queryStr}")
		request.content_type = 'application/json'
		request['cookie'] = cookie
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to delete document")
		end

		output.push(" ")
		output.push("Get a listing of collections")
		request = Net::HTTP::Get.new(uri + "#{dbname}")
		request['cookie'] = cookie
		response = http.request(request)
		if code_2xx?(response.code)
			output.push("Existing collections: #{response.body}")
		else
			output.push("Failed to get existing collections")
		end

		output.push(" ")
		output.push("Drop collection: #{collectionName}")
		request = Net::HTTP::Delete.new(uri + "/#{dbname}/#{collectionName}")
		request['cookie'] = cookie
		response = http.request(request)
		unless code_2xx?(response.code)
			output.push("Failed to drop collection")
		end
		
	return output

	end
end
