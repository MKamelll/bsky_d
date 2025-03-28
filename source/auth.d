module auth;
import std.json;
import std.net.curl;

class Auth
{
    string handle;
    string app_password;
    string access_token;
    string refresh_token;
    string auth_url = "https://bsky.social/xrpc/com.atproto.server.createSession";
    
    this(string handle, string app_password)
    {
        this.handle = handle;
        this.app_password = app_password;
    }

    void authorize()
    {
        auto payload = JSONValue([
            "identifier": handle,
            "password": app_password
        ]);
        
        auto http = HTTP();
        http.addRequestHeader("Content-Type", "application/json");
        auto res = post(auth_url, payload.toString(), http);
        auto res_js = parseJSON(res);
        access_token = res_js["accessJwt"].str;
        refresh_token = res_js["refreshJwt"].str;
    }
}