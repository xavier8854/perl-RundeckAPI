# NAME

RundeckAPI - simplifies authenticate, connect, request a Rundeck instance via REST API

# SYNOPSIS

	use RundeckAPI;

	# create an object of type RundeckAPI :
	my $api = RundeckAPI->new(
		'url'		=> "https://my.rundeck.instance:4440",
		'login'		=> "admin",
		'password'	=> "passwd",
		'debug'		=> 1,
 		'proxy'		=> "http://proxy.mycompany.com/",
	);

	# connect to Rundeck
	my $hashRef = $api->get("/api/27/system/info");

# METHODS

## 	# connect to Rundeck
	my $hashRef = $api->get("/api/27/system/info");
	my $json = '{some: value}';
	$hashRef = $api->put(/api/27/endpoint_for_put, $json);
	post is identical to put, and delete identical to get (items to be deleted are specified in th endpoint paramater)

Returns a hash reference containing the data sent by Rundeck.
See documentation for Rundeck's [API](https://docs.rundeck.com/docs/api/rundeck-api.html) and returned data

$method is one of GET HEAD POST PUT DELETE.

# TODO
	In this version the package is only aware of Rundeck endpoints which doesn't require POSTing data. Be patient :-)

# AUTHOR
	Xavier Humbert <xavier-at-xavierhumbert-dot-net>
