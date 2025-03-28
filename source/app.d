import std.stdio;
import dotenv;
import client, auth, bsky;


void main()
{
    Env.load;

    string handle = Env["handle"];
    string app_password = Env["app_password"];

    auto bsky = new Bsky(handle, app_password);
    auto feed_url = "https://bsky.app/profile/aendra.com/feed/verified-news";
    writeln(bsky.feed.get_feed_posts(feed_url, "10"));
}
