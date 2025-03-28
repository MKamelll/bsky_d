module profile;

import bsky;
import std.json;

class Profile {

    Bsky bsky;

    this(Bsky bsky) {
        this.bsky = bsky;
    }

     auto get_preferences()
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getPreferences");
    }

    auto get_profile(string handle="")
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getProfile" ~ "?actor=" ~ handle);
    }

    auto get_profiles(string[] handles)
    {
        string url = "/xrpc/app.bsky.actor.getProfiles";
        if (handles.length > 0) {
            foreach (handle; handles)
            {
                url ~= "?actors=";
                url ~= handle;
                url ~= "&";
            }
        }
        return bsky.client.get_request(url);
    }

    auto get_suggestions(string limit="")
    {
        return bsky.client.get_request("/xrpc/app.bsky.actor.getSuggestions" ~ "?limit=" ~ limit);
    }

    auto put_prefernces(JSONValue value)
    {
        return bsky.client.post_request("/xrpc/app.bsky.actor.putPreferences", value);
    }

    auto search_profiles_typeahead(string query, string limit = "")
    {
        string url = "/xrpc/app.bsky.actor.searchActorsTypeahead" ~ "?q=" ~ query;
        if (limit.length > 0)
        {
            url ~= "&limit=" ~ limit;
        }
        return bsky.client.get_request(url);
    }

    auto search_profiles(string query, string limit = "", string cursor = "")
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

    auto get_profile_likes(string handle, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getActorLikes" ~ "?actor=" ~ handle;
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
    
    auto get_profile_feed(string profile, string limit = "", string cursor = "")
    {
        string url = "/xrpc/app.bsky.feed.getAuthorFeed" ~ "?actor=" ~ profile;
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