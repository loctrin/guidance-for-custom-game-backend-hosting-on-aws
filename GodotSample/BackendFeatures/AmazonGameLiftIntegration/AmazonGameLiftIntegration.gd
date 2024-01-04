# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

extends Node

# TODO: Add the login endpoint here
const login_endpoint = "https://YOUR_ENDPOINT/prod/"
# TODO: Add your Amazon GameLift backend component endpoint here
const gamelift_integration_backend_endpoint = "https://YOUR_ENDPOINT/prod"

var aws_game_sdk

func save_login_data(user_id, guest_secret):
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_pascal_string(user_id)
	file.store_pascal_string(guest_secret)
	file = null
	
func load_login_data():
	var file = FileAccess.open("user://save_game2.dat", FileAccess.READ)
	if(file == null or file.get_length() == 0):
		return null;
	
	var user_id = file.get_pascal_string()
	var guest_secret = file.get_pascal_string()
	return [user_id, guest_secret]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get the SDK and Init
	self.aws_game_sdk = get_node("/root/AwsGameSdk")
	self.aws_game_sdk.init(self.login_endpoint, self.on_login_error)
	
	# Try to load existing user info
	var stored_user_info = self.load_login_data()
	
	# If we have stored user info, login with existing user
	if(stored_user_info != null):
		print("Logging in with existing user: " + stored_user_info[0])
		self.aws_game_sdk.login_as_guest(stored_user_info[0], stored_user_info[1], self.login_callback)
	# Else we login as new user
	else:
		print("Logging in as new user")
		self.aws_game_sdk.login_as_new_guest_user(self.login_callback)

# Called on any login or token refresh failures
func on_login_error(message):
	print("Login error: " + message)

# Receives a UserInfo object after successful login
func login_callback(user_info):
	print("Received login info.")
	print(user_info)
	
	# Store the login info for future logins
	self.save_login_data(user_info.user_id, user_info.guest_secret)
	
	# Start matchmaking
	self.aws_game_sdk.backend_post_request(self.gamelift_integration_backend_endpoint, "/request-matchmaking", "{ \"latencyInMs\": { \"us-east-1\" : 10, \"us-west-2\" : 20, \"eu-west-1\" : 30 }}", self.matchmaking_request_callback)
	
# We need to use the exact format of the callback required for HTTPRequest
func matchmaking_request_callback(result, response_code, headers, body):
	
	var string_response = body.get_string_from_utf8()
	
	if(response_code >= 400):
		print("Error code " + str(response_code) + " Message: " + string_response)
		return
		
	print("Matchmaking request response: " + string_response)
		
	#  TODO: Call the get match status
	# self.aws_game_sdk.backend_get_request(self.backend_endpoint, "/get-player-data", null, self.get_player_data_callback)

# We need to use the exact format of the callback required for HTTPRequest
func get_match_status_callback(result, response_code, headers, body):
	
	var string_response = body.get_string_from_utf8()
	
	if(response_code >= 400):
		print("Error code " + str(response_code) + " Message: " + string_response)
		return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
