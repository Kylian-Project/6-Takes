extends Node

var logged_in
var token_expiration # Unix timestamp


func _ready():
	print("Script is running!")
	
func getToken_expiration():
	return token_expiration
	
func setToken_expiration(expr):
	token_expiration = expr
	check_login_status()

func getLogged_in():
	return logged_in
	
func update_token(exp ):
	var date_string = exp.strip_edges() 
	
	if date_string.ends_with("Z"):
		date_string = date_string.substr(0, date_string.length() - 1)
		
	var date_parts = date_string.split("T")
	
	print("--------------RECEIVED EXPIRATION DATE: ", date_parts) 
	token_expiration = date_parts
	#check_login_status()

	
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
		
