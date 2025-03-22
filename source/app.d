import std.stdio;
import dotenv;
import std.json;
import std.net.curl;
import std.array;
import std.conv;

class Auth
{
    string handle;
    string app_password;
    string auth_url = "https://bsky.social/xrpc/com.atproto.server.createSession";
    
    this(string handle, string app_password)
    {
        this.handle = handle;
        this.app_password = app_password;
    }

    JSONValue authorize()
    {
        auto payload = JSONValue([
            "identifier": handle,
            "password": app_password
        ]);
        
        auto http = HTTP();
        http.addRequestHeader("Content-Type", "application/json");
        auto res = post(auth_url, payload.toString(), http);
        return parseJSON(res);
    }
}

class Bsky
{
    string handle;
    string app_password;
    string access_token;
    string refresh_token;
    Client client;
    this(Client client)
    {
        this.client = client;
        this.handle = client.handle;
        this.app_password = client.app_password;
        this.access_token = client.access_token;
        this.refresh_token = client.refresh_token;
    }
}

struct Response
{
    JSONValue response_body;
    int status_code;
    string[string] headers;
}

class Client
{
    string handle;
    string app_password;
    string access_token;
    string refresh_token;
    string base_url = "https://bsky.social";
    
    this(string handle, string app_password, string access_token, string refresh_token)
    {
        this.handle = handle;
        this.app_password = app_password;
        this.access_token = access_token;
        this.refresh_token = refresh_token;
    }

    Response get_request(string ext_url, string[string] headers = null)
    {
        auto http = HTTP();
        string url = base_url ~ ext_url;
        http.addRequestHeader("Content-Type", "application/json");
        http.addRequestHeader("Authorization", "Bearer " ~ access_token);
        
        if (headers !is null) {
            foreach (key, value; headers)
            {
                http.addRequestHeader(key, value);
            }
        }

        auto response = Response();

        http.url(url);
        http.method(HTTP.Method.get);

        http.onReceiveStatusLine = (HTTP.StatusLine status_line) {
            response.status_code = to!int(to!string(status_line).split(" ")[0]);
        };

        http.onReceiveHeader = (in char[] key, in char[] value) {
            response.headers[to!string(key)] = to!string(value);
        };

        http.onReceive = (ubyte[] data) {
            response.response_body = parseJSON(cast(string)data);
            return data.length;
        };

        http.perform();
        return response;
    }

    Response post_request(string ext_url, JSONValue req_body, string[string] headers = null, )
    {
        string url = base_url ~ ext_url;
        auto http = HTTP();
        http.url(url);
        http.method(HTTP.Method.post);
        http.addRequestHeader("Content-Type", "application/json");
        http.addRequestHeader("Authorization", "bearer " ~ access_token);

        if (headers !is null) {
            foreach (key, val; headers)
            {
                http.addRequestHeader(key, val);
            }
        }

        auto response = Response();

        http.postData = req_body;

        http.onReceiveStatusLine = (HTTP.StatusLine status_line) {
            response.status_code = to!int(to!string(status_line).split(" ")[0]);
        };

        http.onReceiveHeader = (in char[] key, in char[] value) {
            response.headers[to!string(key)] = to!string(value);
        };

        http.onReceive = (ubyte[] data) {
            response.response_body = parseJSON(cast(string)data);
            return data.length;
        };

        http.perform();
        return response;
    }
}

class Actor
{
    Bsky bsky;
    this(Bsky bsky)
    {
        this.bsky = bsky;
    }

    auto get_preferences()
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getPreferences");
    }

    auto get_profile()
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getProfile");
    }

    auto get_profiles()
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getProfiles");
    }

    auto get_suggestions()
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getSuggestions");
    }

    auto put_prefernces(JSONValue value)
    {
        return bsky.client.post_request("/xrpc/app.bsky.actor.putPreferences", value);
    }
}

void main()
{
    Env.load;

    string handle = Env["handle"];
    string app_password = Env["app_password"];
    string access_token = Env["access_token"];
    string refresh_token = Env["refresh_token"];
    
    /*
    auto auth = new Auth(handle, app_password);
    writeln(auth.authorize());
    */
    
    auto client = new Client(handle, app_password, access_token, refresh_token);
    auto bsky = new Bsky(client);
    auto actor = new Actor(bsky);
    writeln(actor.get_preferences());
}
