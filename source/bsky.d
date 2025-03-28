module bsky;
import client;
import auth;
import profile;
import std.json;
import feed;

class Bsky
{  
    Client client;
    Profile profile;
    Feed feed;

    this(string handle, string app_password) {
        this.client = new Client(new Auth(handle, app_password));
        this.profile = new Profile(this);
        this.feed = new Feed(this);
    }
}