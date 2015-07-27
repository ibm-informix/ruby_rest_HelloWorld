module ApplicationHelper


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
		outPut = Array.new
		
		if ENV['VCAP_SERVICES'] == nil
			outPut.push("vcap services is nil")
			return outPut
		end
		vcap_hash = JSON.parse(ENV['VCAP_SERVICES'])["altadb-dev"]
		credHash = vcap_hash.first["credentials"]
		host = credHash["host"]
		port = credHash["rest_port"]
		dbname= credHash['db']
		user = credHash["username"]
		password = credHash["password"]
		collectionName = "restcollection"
		
		
		
		http = Net::HTTP.new(host, port)
		# check if collection exists, if so delete
		request = Net::HTTP::Get.new("/#{dbname}")
		request.basic_auth user, password
		response = http.request(request)
		outPut.push("Existing collections: #{response.body}")
		if response.body.include? "#{collectionName}"
			outPut.push("Deleting collection: #{collectionName}")
			request = Net::HTTP::Delete.new("/#{dbname}/#{collectionName}")
			response = http.request(request)
			unless code_2xx?(response.code)
				outPut.push("Failed to delete existing collection")
			end
		end
		# create collection
		outPut.push("Creating empty collection: #{collectionName}")
		request = Net::HTTP::Post.new("/#{dbname}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		request.body = {:name => "#{collectionName}"}.to_json
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to create collection: #{collectionName}")
		end

		outPut.push("Insert a single document to a collection")
		data = {:name => "test1",:value => "1"}.to_json
		request = Net::HTTP::Post.new("/#{dbname}/#{collectionName}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		request.body = data
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to insert single document: #{response.code}, #{response.message}, #{response.body}")
		end

		outPut.push("Insert multiple documents to a collection")
		data = [{:name => 'test1', :value => 1}, {:name => 'test2', :value => 2}, {:name => 'test3', :value => 3}].to_json
		request = Net::HTTP::Post.new("/#{dbname}/#{collectionName}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		request.body = data
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to insert multiple documents: #{response.code}, #{response.message}, #{response.body}")
		end

		outPut.push(" ")
		outPut.push("Find a document in a collection that matches a query condition")
		queryStr = '{"name":"test1"}'
		request = Net::HTTP::Get.new("/#{dbname}/#{collectionName}?query=#{queryStr}&fields={_id:0}&batchSize=1")
		request.basic_auth user, password
		request.content_type = 'application/json'
		response = http.request(request)
		outPut.push("Result of query: #{response.body}")

		outPut.push(" ")
		outPut.push("Find all documents in a collection that match a query condition")
		queryStr = '{"name":"test1"}'
		request = Net::HTTP::Get.new("/#{dbname}/#{collectionName}?query=#{queryStr}&fields={_id:0}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		response = http.request(request)
		outPut.push("Result of query: #{response.body}")

		outPut.push(" ")
		outPut.push("Find all documents in a collection")
		request = Net::HTTP::Get.new("/#{dbname}/#{collectionName}")
		request.basic_auth user, password
		response = http.request(request)
		outPut.push("All documents in collection:  #{response.body}")

		outPut.push(" ")
		outPut.push("Update documents in a collection")
		queryStr = '{name:"test3"}'
		updateStr = '{"$set" : {"value" : "9"} }'
		request = Net::HTTP::Put.new("/#{dbname}/#{collectionName}?query=#{queryStr}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		request.body = updateStr
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to update value")
		end

		outPut.push(" ")
		outPut.push("Delete documents in a collection")
		queryStr = '{name:"test2"}'
		request = Net::HTTP::Delete.new("/#{dbname}/#{collectionName}?query=#{queryStr}")
		request.basic_auth user, password
		request.content_type = 'application/json'
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to delete document")
		end

		outPut.push(" ")
		outPut.push("Get a listing of collections")
		request = Net::HTTP::Get.new("/#{dbname}")
		request.basic_auth user, password
		response = http.request(request)
		if code_2xx?(response.code)
			outPut.push("Existing collections: #{response.body}")
		else
			outPut.push("Failed to get existing collections")
		end

		outPut.push(" ")
		outPut.push("Drop collection: #{collectionName}")
		request = Net::HTTP::Delete.new("/#{dbname}/#{collectionName}")
		request.basic_auth user, password
		response = http.request(request)
		unless code_2xx?(response.code)
			outPut.push("Failed to drop collection")
		end
		
	return outPut

	end
end
