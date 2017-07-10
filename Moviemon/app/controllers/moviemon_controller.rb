require 'fileutils'
require 'json'
require 'moviemon'

$selected = 1
$view = {}

class MoviemonController < ApplicationController

	def initialize
		super
	end

	def all_disabled
		return {
			"a" => "",
			"b" => "",
			"start" => "",
			"select" => "",
			"up" => "",
			"right" => "",
			"left" => "",
			"down" => "",
			"power" => "href=/",
		}
	end


	def titlescreen
		@title = "Moviemon"
		@output = ["Start: New Game OR Select: Load"]

		@controls = all_disabled()
		@controls["start"] = "href=worldmap"
		@controls["select"] = "href=save_slot"
		$view['previous'] = "/"
	end


	def save_slot
		@title  = "LOAD"

		$view['from'] = $view['previous']
		if $view['previous'] == "/"
			@output = ["A - Load", "B - Cancel"]
			$view['from'] = $view['previous']
			$view['previous'] = "save_slot_load"
		elsif ($view['previous'] == "save_slot_load" || $view['previous'] = "save_slot") && params[:dir] == "up"
			if $selected == 1
				$selected = 3
			else
				$selected -= 1
			end
		elsif ($view['previous'] == "save_slot_load" || $view['previous'] = "save_slot") && params[:dir] == "down"
			if $selected == 3
				$selected = 1
			else
				$selected += 1
			end
		else
			@title  = "SAVE"
			@output = ["A - Save", "B - Cancel"]
			$view['previous'] = "save_slot"
		end
		@controls = all_disabled()
		@controls["a"] = "href=worldmap"
		@controls["up"] = "href=save_slot?dir=up"
		@controls["down"] = "href=save_slot?dir=down"			
		@controls["select"] = "href=#{$view['from']}"
		@output = ["Select: Go back"]
		@selected = $selected
	end


	def worldmap
		@title = "WORLDMAP"
		@output = ["Start: Moviedex Select: Option"]
		@party = MoviemonModel.new
		if $view['previous'] == "/"
			puts ">>>>>>>>> NEW GAME <<<<<<<<"
			@party.loadDefaultSettings
		elsif $view['previous'] == "save_slot_load"
			@party.load_existing_save("save#{$selected}.json")
		elsif $view['previous'] == "save_slot"
			@party.save("save#{$selected}.json")
		elsif $view['previous'] == "battle"
			if request.get?
				if params[:battle] == "run-away"
					$game["moviemons"]["#{params[:moviemon]}"]["movie_life"] = $game["moviemons"]["#{params[:moviemon]}"]["imdbRating"].to_f * 1.5
					@status = "Coward!"
				elsif params[:battle] == "lost"
					$game["moviemons"].delete("#{params[:moviemon]}")
					$game["moviemon_ids"].delete("#{params[:moviemon]}")
					puts "MOVIEMON #{params[:moviemon]} LEFT GAME : #{$game["moviemon_ids"]}"
				end
				$player["player_life"] = 3.0 + $player["moviedex"].length
				$player['player_strength'] = 3.0 + $player["moviedex"].length
			end
		end
		if request.get?
			if $view['previous'] == "battle" && params[:battle] == "win"
				@output = ["You won ! GG !"]
			elsif $view['previous'] == "battle" && params[:battle] == "lost"
				@output = ["You lose ! BOUUUUUUUH !"]
			elsif $view['previous'] == "battle" && params[:battle] == "run-away"
				@output = ["You ran away HAHHAHA !"]
			end
			if params[:dir] == "left"
				unless $player["cell_player"]["x"] == 0
					$player["cell_player"]["x"] =  $player["cell_player"]["x"] - 1
				end
			end
			if params[:dir] == "right"
				unless $player["cell_player"]["x"] == 9
					$player["cell_player"]["x"] = $player["cell_player"]["x"] + 1
				end
			end
			if params[:dir] == "up"
				unless $player["cell_player"]["y"] == 0
					$player["cell_player"]["y"] = $player["cell_player"]["y"] - 1
				end
			end
			if params[:dir] == "down"
				unless $player["cell_player"]["y"] == 9
					$player["cell_player"]["y"] = $player["cell_player"]["y"] + 1
				end
			end

			@controls = all_disabled()
			rd = rand(0..5)
			if ($game['moviemons'].length > 0) && rd == 0 # Si il reste des films sur la map et que random tombe sur 0, alors battle
				@mmIsFound = true
				@output = ["A moviemon! A: Fight or run !"]
				moviemon_found = $game['moviemon_ids'].sample
				@controls["a"] = "href=battle/#{moviemon_found}"
			else
				@mmIsFound = false
				@controls["a"] = ""
			end


		end
		if $player["moviedex"] == nil
			@controls["start"] = "href=moviedex"
		else
			@controls["start"] = "href=moviedex/#{$player["moviedex"].keys[0]}"
		end
		@controls["up"] = "href=worldmap?dir=up"
		@controls["down"] = "href=worldmap?dir=down"
		@controls["left"] = "href=worldmap?dir=left"
		@controls["right"] = "href=worldmap?dir=right"
		@controls["select"] = "href=save_slot"
		$view["previous"] = "worldmap"
	end

	def battle
		@title = "BATTLE"
		@controls = all_disabled()
		@output = ["A: Hit OR B: Run"]
		@controls["b"] = "href=/worldmap?battle=run-away&moviemon=#{params[:id]}"
		if request.get?

			@id = params[:id]
			@controls["a"] = "href=/battle/#{params[:id]}?hit=yes"

			if $player["player_life"] > 0
				puts "player life > 0 : yes #{$player["player_life"]}"

				if params[:hit] == "yes"
					puts "param hit : #{params[:hit]}"
					$game["moviemons"]["#{params[:id]}"]["movie_life"] -= $player["player_strength"]

					puts "moviemon has been hit, new PV : #{$game["moviemons"]["#{params[:id]}"]["movie_life"]}"

					if $game["moviemons"]["#{params[:id]}"]["movie_life"] <= 0
						puts "moviemon is dead : yes"
						$player["moviedex"]["#{params[:id]}"] = $game["moviemons"]["#{params[:id]}"]
						$game["moviemons"].delete("#{params[:id]}")
						$game["moviemon_ids"].delete("#{params[:id]}")

						@controls["b"] = "href=/worldmap?battle=win"
						$player['player_life'] = 3.0 + $player["moviedex"].length
						@output = ["B: Back ", "The moviemon captured! "]
						@controls["a"] = ""
						puts "MOVIEMONS IDS #{$game["moviemon_ids"]}"
						puts "MOVIEDEX #{$player["moviedex"]}"
					else
						puts "moviemon is dead : no"
						moviemonStrength = $game["moviemons"]["#{params[:id]}"]["imdbRating"].to_f
						moviemonStrength.round(2)
						$player["player_life"] -= moviemonStrength
						puts "moviemon strength : #{moviemonStrength} hits back living player : #{$player["player_life"]}"
						if $player["player_life"] <= 0

							$player['player_life'] = 3.0 + $player["moviedex"].length
							$game["moviemons"]["#{params[:id]}"]["movie_life"] = $game["moviemons"]["#{params[:id]}"]["imdbRating"].to_f * 1.5

							@controls["a"] = ""
							@controls["b"] = "href=/worldmap?battle=lost&moviemon=#{params[:id]}"
							@output = ["B : Back to worldmap", "Sorry buddy, you're dead..."]

						end

					end

				end

			else

				puts "player life < 0 : yes #{$player["player_life"]}"
				@controls["b"] = "href=/worldmap?battle=lost&moviemon=#{params[:id]}"

			end

		end
		$view["previous"] = "battle"		
	end

	def moviedex
		@title = "Moviedex"
		@controls = all_disabled()
		@output = ["Arrows: Moviemons Select: Map"]
		@controls["select"] = "href=/worldmap"

		if $view["previous"] != "moviedex"
			$selected = 0
		end
		if $player["moviedex"] == nil || $player["moviedex"].empty?
			@output = ["Select: Back to worldmap", "You haven't caught any moviemon yet... LOSER !"]
		else
			moviedexSize = $player["moviedex"].length
			moviedexSize -= 1
			if request.get?
				if params[:dir] == "left"
					if $selected == 0
						$selected = moviedexSize
					else
						$selected -= 1
					end
				end
				if params[:dir] == "right"
					if $selected == moviedexSize
						$selected = 0
					else
						$selected += 1
					end
				end
			end

			if moviedexSize >= 1
				if $selected == 0
					hrefLeft = "href=#{$player["moviedex"].keys[moviedexSize - 1]}"
					hrefRight = "href=#{$player["moviedex"].keys[$selected + 1]}"
				elsif $selected == moviedexSize
					hrefLeft = "href=#{$player["moviedex"].keys[$selected - 1]}"
					hrefRight = "href=#{$player["moviedex"].keys[0]}"
				else
					hrefLeft = "href=#{$player["moviedex"].keys[$selected - 1]}"
					hrefRight = "href=#{$player["moviedex"].keys[$selected + 1]}"
				end
				@controls["left"] = "#{hrefLeft}?dir=left"
				@controls["right"] = "#{hrefRight}?dir=right"			
			end
			@id = $player["moviedex"].keys[$selected]

		end
		$view['previous'] = "moviedex"		
	end

end

