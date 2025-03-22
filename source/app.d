import std.stdio;
import dotenv;
import std.json;
import std.array;
import std.conv;
import std.string;
import std.utf;
import std.net.curl;

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

class FailedGetRequest : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null) pure nothrow @nogc @safe
    {
        super(msg, file, line, nextInChain);
    }
}

struct Response
{
    string response_body;
    string status_code;
    string[string] headers;

    string toString() const
    {
        return response_body;   
    }
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

    auto get_request(string ext_url, string[string] headers = null)
    {
        Response response;
        string url = base_url ~ ext_url;
        auto http = HTTP();
        if (headers !is null) {
            foreach (key, value; headers)
            {
                http.addRequestHeader(key, value);
            }
        }
        
        http.url(url);
        http.method(http.Method.get);
        http.addRequestHeader("Content-Type", "application/json");
        http.addRequestHeader("Authorization", "Bearer " ~ access_token);

        http.onReceive = (ubyte[] data) {
            response.response_body = cast(string)data;
            return data.length;
        };

        http.onReceiveHeader = (in char[] key, in char[] value) {
            response.headers[to!string(key)] = to!string(value);
        };

        http.onReceiveStatusLine = (HTTP.StatusLine status) {
            response.status_code = to!string(status.code);
        };

        http.perform();
        return response;
    }

    auto post_request(string ext_url, JSONValue req_body, string[string] headers = null)
    {
        Response response;
        string url = base_url ~ ext_url;
        auto http = HTTP();
        if (headers !is null) {
            foreach (key, value; headers)
            {
                http.addRequestHeader(key, value);
            }
        }
        
        http.url(url);
        http.method(http.Method.post);
        http.addRequestHeader("Content-Type", "application/json");
        http.addRequestHeader("Authorization", "Bearer " ~ access_token);
        http.postData = req_body.toString();

        http.onReceive = (ubyte[] data) {
            response.response_body = cast(string)data;
            return data.length;
        };

        http.onReceiveHeader = (in char[] key, in char[] value) {
            response.headers[to!string(key)] = to!string(value);
        };

        http.onReceiveStatusLine = (HTTP.StatusLine status) {
            response.status_code = to!string(status.code);
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

    auto search_actors_typeahead(string query, string limit = "")
    {
        string url = "/xrpc/app.bsky.actor.searchActorsTypeahead" ~ "?q=" ~ query;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }
        return bsky.client.get_request(url);
    }

    auto search_actors(string query, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.actor.searchActors" ~ "?q=" ~ query;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }

        if (cursor.length > 0)
        {
            url ~= "&cursor=" ~ cursor;
        }

        return bsky.client.get_request(url);
    }
}

class Feed
{
    Bsky bsky;
    this(Bsky bsky)
    {
        this.bsky = bsky;
    }

    auto describe_feed_generator()
    {
        return bsky.client.get_request("/xrpc/app.bsky.feed.describeFeedGenerator");
    }

    auto get_actor_feeds(string actor, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getActorFeeds" ~ "?actor=" ~ actor;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }

        if (cursor.length > 0)
        {
            url ~= "&cursor=" ~ cursor;
        }

        return bsky.client.get_request(url);
    }

    auto get_actor_likes(string actor, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getActorLikes" ~ "?actor=" ~ actor;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }

        if (cursor.length > 0)
        {
            url ~= "&cursor=" ~ cursor;
        }

        return bsky.client.get_request(url);
    }

    auto get_author_feed(string actor, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getAuthorFeed" ~ "?actor=" ~ actor;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }

        if (cursor.length > 0)
        {
            url ~= "&cursor=" ~ cursor;
        }

        return bsky.client.get_request(url);
    }
}

void main()
{
    Env.load;

    string handle = Env["handle"];
    string app_password = Env["app_password"];
    string access_token = Env["access_token"];
    string refresh_token = Env["refresh_token"];
    
    //auto auth = new Auth(handle, app_password);
    //writeln(auth.authorize());    
    
    
    auto client = new Client(handle, app_password, access_token, refresh_token);
    auto bsky = new Bsky(client);
    auto actor = new Actor(bsky);
    auto feed = new Feed(bsky);
    writeln(feed.get_author_feed(handle));
}
