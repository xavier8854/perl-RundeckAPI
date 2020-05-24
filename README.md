# NAME

RundeckAPI - simplifies authenticate, connect, queries to a Rundeck
instance via REST API
# SYNOPSIS

    use RundeckAPI;
    use Storable qw(dclone);

    # create an object of type RundeckAPI :
    my $api = RundeckAPI->new(
        'url'           => "https://my.rundeck.instance:4440",
        'login'         => "admin",
        'password'      => "passwd",
    # OR token, takes precedence
        'token'         => <token as generated with GUI, as an admin>
        'debug'         => 1,
        'proxy'         => "http://proxy.mycompany.com/",
    );
    my $hashRef = $api->get("/api/27/system/info");
    my $json = '{some: value}';
    $hashRef = $api->put(/api/27/endpoint_for_put, $json);
# METHODS
  "new"         Returns an object authenticated and connected to a Rundeck
                Instance

  "get"         Sends a GET query. Request one argument, the enpoint to the
                API. Returns a hash reference

  "post"        Sends a POST query. Request two arguments, the enpoint to
                the API an the data in json format. Returns a hash reference

  "put"         Sends a PUT query. Similar to post

  "delete"      Sends a DELETE query. Similar to get

  "postFile"    POST a file. Requet three arguments : endpoint, mime-type
                and the appropriate data. Returns a hash reference.

  "putFile"     Similar to postFile

Returns a hash reference containing the data sent by Rundeck.
See documentation for Rundeck's [API](https://docs.rundeck.com/docs/api/rundeck-api.html) and returned data


# AUTHOR
    Xavier Humbert <xavier.humbert-at-ac-nancy-metz-dot-fr>
