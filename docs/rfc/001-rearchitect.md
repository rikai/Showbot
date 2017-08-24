- Feature Name: Rearchitect Showbot
- Start Date: 2017-08-23
- RFC PR: 
- Showbot Issue: 

# Summary
[summary]: #summary

Showbot will be rearchitected to become a chatbot platform with IRC and Discord
bots combined with a backend server. 

# Motivation
[motivation]: #motivation

Showbot needs to add new features and integrate with other chat services. To 
integrate other chat services, we would need to fork Cinch and patch it for each
service we wish to add. 

Instead of taking on this technical debt, Showbot should 
be rearchitected to require as little patching as possible while exposing an API
to allow the development of as many clients as needed. Doing so would allows us 
to benefit from more community involvement and from upstream patches with little
work on our end.

# Guide-level explanation
[guide-level-explanation]: #guide-level-explanation

Currently, Showbot uses a monolithic architecture and stores data in flat files
with no real API. This design forces any new clients to be integrated directly
into Showbot.

Instead, Showbot should use a client/server model and make the API publicly
accessible. This model allows more clients to be developed with greater velocity.

In reality, the model would look something like this: a bot would run as a 
stateless application. When data needs to be stored, it would make calls to the
backend server through its API. In this way, many clients would be able to work
with the same data set.

In the interests of making the bots usable without a dependency on a data server,
they should each be written to allow for storing data locally.

In addition, the idea here is to keep the bot platform as "user-agnostic" as
possible. Ideally, anyone should be able to take this platform, add or remove
plugins, and use individual parts or the entire platform by changing the strings
to their liking.

# Reference-level explanation
[reference-level-explanation]: #reference-level-explanation

The IRC bot is the core of Showbot at the moment so I will use it as an example.

The IRC bot currently stores information about what show is live, a database of
user suggested links, etc.

Here is the proposed flow model for the user-suggested links in stateless mode:

1) User enters `!link http://link.to/store` into chat.
2) The IRC bot makes a POST call to API endpoint `jbot.com/api/link`
with the the following JSON:
```
{
    "username": "<IRC-Nick>",
    "link": "http://link.to/store"
}
```
3) The API returns a 200 to the IRC bot and the bot indicates success in the 
IRC channel.
4) The backend server stores the data in the configured database

In the case of calls to the IRC bot that do not require data store, e.g. `!bacon`, 
the IRC bot would reply to the channel directly without interacting with the
data server.

# Drawbacks
[drawbacks]: #drawbacks

We do introduce additional complexity and possible failure modes to bot.

The bots become more complex as they require two operating modes: stateless and
stateful.  Both of these modes require adding logic trees based on a
configuration flag as well as different routines to save data.

Additional failure modes include the data server going down while it is 
operating in stateless mode, causing things such as`!link` or `!suggest` to stop
working.

# Rationale and Alternatives
[alternatives]: #alternatives

The idea with this rearchitecture is to reduce technical debt as much as possible
while allowing for additional clients to be written either by third parties or
community members.

The alternative to the client/server model would be to keep the monolithic IRC
bot, patch other chat platforms into Cinch, and continue adding features using
plugins. I do not believe this to be a good idea for a few reasons:

- Doing so would require maintaining a patched fork of Cinch
- We would have to maintain the library for the Discord API ourselves, forcing
us to update for breaking changes ourselves instead of relying on an upstream 
library to do this for us.
- A fatal error in one of the bot's plugins would cause Showbot to disappear
from all chat platforms.

# Unresolved questions
[unresolved]: #unresolved-questions

This RFC should address the overall architectural design of the Showbot platform.
Other RFCs will follow to outline the design of each bot, a web client, and the 
data server.
