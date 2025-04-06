extends Node

var logged_in
var token_expiration # Unix timestamp


func _ready():
	print("Script is running!")
	load_session()
	
func getToken_expiration():
	return token_expiration
	
func setToken_expiration(expr):
	token_expiration = expr
	check_login_status()

func getLogged_in():
	return logged_in
	
func update_token(expr ):
	#var date_string = exp.strip_edges() 
	#
	#if date_string.ends_with("Z"):
		#date_string = date_string.substr(0, date_string.length() - 1)
		#
	#var date_parts = date_string.split("T")
	
	#print("--------------RECEIVED EXPIRATION DATE: ", date_parts) 
	#token_expiration = date_parts
	#check_login_status()
	token_expiration = expr

	
func check_login_status():
	if token_expiration == null:
		logged_in = false 
		return logged_in
		
	var current_time = Time.get_datetime_string_from_system()
	var date_values = current_time.split("T") 
	
	#print(current_time)
	is_expired(token_expiration, date_values)

	
func parse_date_time(date_arr: Array) -> int:
	# Expects date_arr to be something like ["2025-04-06", "16:10:03"] or
	# ["2025-04-06", "14:12:17.565"]
	var date_str = date_arr[0]
	var time_str = date_arr[1]

	# Split the date and time strings into parts.
	var date_parts = date_str.split("-")
	var time_parts = time_str.split(":")

	var year = int(date_parts[0])
	var month = int(date_parts[1])
	var day = int(date_parts[2])
	
	var hour = int(time_parts[0])
	var minute = int(time_parts[1])
	
	# The seconds might have fractional parts. If you need sub-second precision,
	# you can handle that separately. Here, we round or truncate to an integer.
	var second = int(float(time_parts[2]))
	
	# Create a dictionary that OS.get_unix_time_from_datetime() expects.
	var dt_dict = {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}
	
	# Convert the dictionary to a Unix timestamp (seconds since epoch).
	return Time.get_unix_time_from_datetime_dict(dt_dict)

func is_expired(expiration_date: Array, current_date: Array) -> bool:
	var expiration_ts = parse_date_time(expiration_date)
	var current_ts = parse_date_time(current_date)
	
	# If current time is greater than expiration, it has expired.
	if current_ts > expiration_ts:
		logged_in = false 
		print("FALSE IT IS EXPIRED")
		return logged_in
	else:
		logged_in = true 
		print("TRUE IT IS NOT EXPIRED")
		return true
		
		
#script to save sessions token globally (for after quit)
func save_session(token: String, expiration : Array):
	var config = ConfigFile.new()
	config.set_value("session", "token", token)
	config.set_value("session", "expiration", expiration)
	
	var error = config.save("user://session.cfg")
	if error != OK:
		print("error saving session")

		
#load session data from file on startup
func load_session():
	var config = ConfigFile.new()
	var error = config.load("user://session.cfg")
	if error == OK:
		var saved_token = config.get_value("session", "token")
		var saved_exp = config.get_value("session", "expiration")
		
		print("---------DEBUG-------------")
		print("saved token ", saved_token)
		print("saved expiration", saved_exp)
		#add send token to server for validation
		update_token(saved_exp) #update global exp date
		logged_in = true
		print("successfully loaded session")
		return
	
	else:
		logged_in = false #no valid session found
		return
		
		
#func session_validation(token : String):
	#var http_request = HTTPRequest.new()
	#add_child(http_request)
	#http_request.connect("request_completed", self, "_on_request_completed")
	#var url = "http://185.155.93.105:14001/api/player/session"
	#var error = http_request.request(url, [], false, HTTPClient.METHOD_POST, {"token": token})
	#if error != OK:
		#print("An error occurred sending the session validation request.")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Session validated!")
	else:
		print("Session invalid. Forcing logout.")
		logged_in = false
