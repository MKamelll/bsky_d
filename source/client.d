module client;
import auth;
import std.json;
import std.net.curl;
import std.conv;
import std.stdio;
import std.string;

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

    JSONValue to_json()
    {
        return parseJSON(response_body);
    }
}

class Client
{
    Auth auth;
    string base_url = "https://bsky.social";
    
    this(Auth auth)
    {
        this.auth = auth;
    }

    Response get_request(string ext_url, string[string] headers = null)
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
        http.addRequestHeader("Authorization", "Bearer " ~ auth.access_token);

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

        if (indexOf(response.response_body, "error") != -1)
        {
            auto res_j = parseJSON(response.response_body);
            if (res_j["error"].str == "InvalidToken")
            {
                auth.authorize();
                return get_request(ext_url, headers);
            }
        }

        return response;
    }

    Response post_request(string ext_url, JSONValue req_body, string[string] headers = null)
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
        http.addRequestHeader("Authorization", "Bearer " ~ auth.access_token);
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

        if (indexOf(response.response_body, "error") != -1)
        {
            auto res_j = parseJSON(response.response_body);
            if (res_j["error"].str == "InvalidToken")
            {
                auth.authorize();
                return get_request(ext_url, headers);
            }
        }
        
        return response;
    }
}