#!/usr/bin/ruby

require 'json'
require 'zlib'
require 'uri'
require 'net/http'
require 'stringio'
require 'optparse'

BEGIN {
   service_name = File.basename($0)
   $0 = service_name
}


source, destination = "", ""

#OptionParse is used to define a command line in RubyScript
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: small_degree_separation.rb [options]"
  
  opts.on( '-s', '--source', 'Person 1 Name' ) do |s|
    source = s
  end
  
  opts.on( '-d', '--destination', 'Person 2 Name' ) do |d|
    destination = d
  end
   
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!                     

#Convert values in to millisecond
class Time
   def to_ms
	(self.to_f * 1000.0).to_i
   end
end

class DegreeSeparation

	Person = Struct.new(:url, :name, :role, :ref) # It will hold movie list reference
	Movie  = Struct.new(:url, :name, :role, :ref) # It will hold person list reference
	DOS    = Struct.new(:movie, :role1, :name1, :role2, :name2) # It will hold degreeOfSeparation details

	def initialize(source, destination)
		@root_url  = 'http://data.moviebuff.com/'
		@source   = source
		@destination = destination

		@visited_person = Hash.new(0)
		@visited_movies = Hash.new(0)

		# Root Element
		@data_tree = Person.new(source,'root','root',nil)

		@degree_of_separation = []
		@need_to_build_tree = []
		@total_no_requests = 0
		@time_taken = 0
	end

	def handle_input
		if (@source != @destination)
			# Is this really a Person?

			# at very first time
			if (@data_tree.ref == nil)
				@need_to_build_tree[0], @data_tree.ref = buildSubTree(@data_tree)
				return true
			end
		end
		return false
	end

	def getHTTPResponse(urlStr)
		begin
			@total_no_requests += 1
			rStart = Time.now  # debug
			res = Net::HTTP.get_response(URI.parse("#{@root_url}#{urlStr}"))
			rEnd = Time.now    # debug
			@time_taken = @time_taken + ( rEnd.to_ms - rStart.to_ms )
			if ( res.is_a?(Net::HTTPSuccess) && res.code == '200' )
				gz = Zlib::GzipReader.new(StringIO.new(res.body.to_s)) 
				jResponse = gz.read
				return jResponse
			end
		rescue => err
			puts "Error : Not able to fetch data for #{urlStr}"
			return false
		end
		return false
	end

	def getMovieDetails(movieName)
		personList = []

		return false if @visited_movies.has_key?(movieName)
		@visited_movies[movieName] += 1

		json = getHTTPResponse(movieName)
		return false if json == false

		jsonOut = JSON.parse(json)

		# "cast" details
		jsonOut['cast'].each do |h|
			personList << Person.new(h['url'], h['name'], h['role'],nil)
			if (h['url'] == @destination)
				return false, personList 
			end
		end

		# "crew" details
		jsonOut['crew'].each do |h|
			personList << Person.new(h['url'], h['name'], h['role'],nil)
			if (h['url'] == @destination)
				return false, personList 
			end
		end

		return true, personList
	end

	def getPersonDetails(personName)
		moviesList = []

		return false if @visited_person.has_key?(personName)
		@visited_person[personName] += 1

		json = getHTTPResponse(personName)
		return false if json == false

		jsonOut = JSON.parse(json)

		# "movies" details
		jsonOut['movies'].each do |h|
			moviesList << Movie.new(h['url'], h['name'], h['role'],nil)
		end

		return moviesList
	end

	def getPersonRoleInMovie(personURL, movieName)
		json = getHTTPResponse(personURL)
		return false if json == false

		jsonOut = JSON.parse(json)

		jsonOut['movies'].each do |h|
			if (movieName == h['name'])
				return jsonOut['name'], h['role']
			end
		end
	end

	def buildSubTree(person)
		if (movieList = getPersonDetails(person.url))
			movieList.each_with_index do |movie,idx|
				buildTree, personList = getMovieDetails(movie.url)
				if( personList )
					movie.ref = personList
					return buildTree, movieList if buildTree == false
				else
					movieList.delete_at(idx)
				end
			end
		end
		return true, movieList
	end

	def findSmallestDegree(treeStruct,depth=0)
		return false if treeStruct.ref == nil

		# accessing each movies one by one
		treeStruct.ref.each do |movieRef|
			next if movieRef.ref == nil

			# initializing the degree of separation
			@degree_of_separation[depth] = DOS.new(movieRef.name, nil, nil, nil, nil)

			# accessing each persons one by one
			movieRef.ref.each do |personRef|

				# Degrees of Separation
				if (depth > 0)
					@degree_of_separation[depth].role1 = @degree_of_separation[depth-1].role2
					@degree_of_separation[depth].name1 = @degree_of_separation[depth-1].name2
				else
					if (personRef.url == @source)
						@degree_of_separation[depth].role1 = personRef.role
						@degree_of_separation[depth].name1 = personRef.name
					end
				end
				@degree_of_separation[depth].role2 = personRef.role
				@degree_of_separation[depth].name2 = personRef.name

				return true if (personRef.url == @destination)

				if (personRef.ref == nil && @need_to_build_tree[depth])
					  if (@need_to_build_tree[depth+1] != false)
						  @need_to_build_tree[depth+1], personRef.ref = buildSubTree(personRef)
					  end
				elsif (personRef.ref != nil)
					return findSmallestDegree(personRef,depth+1)
				end
			end
		end
		return false
	end

	def printResult
		# if source person details is not found yet, then
		if( @degree_of_separation[0].role1 == nil or @degree_of_separation[0].name1 == nil )
			@degree_of_separation[0].name1, @degree_of_separation[0].role1 = getPersonRoleInMovie(@source,@degree_of_separation[0].movie)
		end

		puts "Total no.of.request sent : #{@total_no_requests}"
		puts "Total time taken (in ms) : #{@time_taken}"
		puts "\nDegrees of Separation  : #{@degree_of_separation.size}\n\n"

		@degree_of_separation.each do |details|
			puts "Movie : #{details.movie}"
			puts "#{details.role1} : #{details.name1}"
			puts "#{details.role2} : #{details.name2}"
			puts "\n\n"
		end
	end

	def start_degree_of_separation
		if (!handle_input)
			puts "Usage : ruby #{$0} <PersonURL-1> <PersonURL-2>"
			exit(2)
		end

		while(true)
			if (findSmallestDegree(@data_tree))
				printResult
				break
			end
		end
	end
end


degree_separation = DegreeSeparation.new(ARGV[0], ARGV[1])
degree_separation.start_degree_of_separation
