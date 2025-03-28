module feed;

import bsky;
import std.string;
import std.stdio;
import std.json;

class Feed {
    Bsky bsky;

    this(Bsky bsky) {
        this.bsky = bsky;
    }

    auto get_profile_feeds(string handle, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getActorFeeds" ~ "?actor=" ~ handle;
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

    auto get_at_uri(string feed_url)
    {
        auto first = indexOf(feed_url, "/profile/") + "/profile/".length;
        auto last = indexOf(feed_url, "/feed/");
        auto user = feed_url[first .. last];
        auto feed_name = feed_url[last + "/feed/".length .. $];
        auto user_feeds = get_profile_feeds(user);
        string at_url;
        foreach (feed; user_feeds.to_json["feeds"].array)
        {
            string uri = feed["uri"].str;
            if (indexOf(uri, feed_name) != -1)
            {
                at_url = uri;
            }
        }

        return at_url;
    }

    auto get_feed_generator(string feed_url)
    {
        string at_uri = get_at_uri(feed_url);        
        string url = "/xrpc/app.bsky.feed.getFeedGenerator" ~ "?feed=" ~ at_uri;
        return bsky.client.get_request(url);
    }

    auto get_feed_posts(string feed_url, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getFeed" ~ "?feed=" ~ get_at_uri(feed_url);
        if (limit.length > 0)
        {
            url ~= "&";
            url ~= "?limit=" ~ limit;
        }
        if (cursor.length > 0)
        {
            url ~= "&";
            url ~= "?cursor=" ~ cursor;
        }

        return bsky.client.get_request(url);
    }
}