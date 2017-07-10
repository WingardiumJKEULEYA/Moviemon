require 'open-uri'
require 'json'

$player = {}
$game = {}

class MoviemonModel

	def initialize
	end

	def loadDefaultSettings
		moviemon_ids = [
			'tt4326444',
			'tt2392672',
			'tt1567437',
			'tt0080179',
			'tt3612616',
			'tt2724064',
			'tt2574698',
			'tt0087981',
			'tt0369226',
			'tt2467046',
			'tt0804492',
			'tt4009460',
			'tt5898034',
			'tt2241351',
			'tt0198781',
			'tt0088751',
			'tt2100623',
			'tt5538124'
			]
		movieData = Hash.new
		moviemon_ids.each do | movie |
			url = "http://www.omdbapi.com/?i=#{movie}"
			data = open(url).read
			result = JSON.parse(data)
			result["movie_life"] = result["imdbRating"].to_f * 1.5
			result["movie_life"].round(2)
			movieData["#{movie}"] = result
		end
		$player['cell_player'] = {"x" => 0, "y" => 0}
		$player['moviedex'] = {}
		$player['player_strength'] = 3.0
		$player['player_life'] = 3.0
		$game['moviemons'] = movieData
		$game['moviemon_ids'] = moviemon_ids
		$game['player'] = $player
		puts ">>>>> NEW GAME INITIALIZE"
	end

	def save(filename)
		file = File.open(filename, "w")
		file << JSON.pretty_generate($game)
		file.close
		# Pour save la partie
		# instance.save("SLOT_A")

	end

	def load_existing_save(file)
		if File.exists? file
			file = File.open(file, "r")
			$game = JSON.parse(file.read)
		else
			loadDefaultSettings
		end
		$player = $game['player']
		# pour recup la partie
		# instance.load_existing(file)
	end

	def get_movie(movieId)
		return $game['moviemons']["#{movieId}"]
	end

end
