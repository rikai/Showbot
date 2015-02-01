# TODO

Ranked by difficulty to implement, ordered within those ranking by priority to implement. <sup>Checked options are done for 2.0</sup>

Easy
---------
- [x] Correctly parse html entities in the twitter plugin
- [ ] Clean up the stdout output to make it more readable
- [x] Add a !linuxgames to get a count of the number of linux games available on steam either dynamically via the storefront API or by perhaps using [SteamLinux](https://github.com/SteamDatabase/SteamLinux)

Moderate
---------
- [ ] Fix bug in current scheduling system that sometimes gets the show dates wrongly because some ical flags are being ignored (possibly an upstream bug that needs to be addressed) - [Issue #4](https://github.com/rikai/Showbot/issues/4)
 - [ ] Actual solution might be to replace ri_cal, see third option in the next section.
- [ ] Remove the dependency on therubyracer
 - [ ] one of the other execjs alternatives may work, just needs some testing to ensure there are no issues
- [x] Add the ability to hot-reload plugins without restarting JBot
- [ ] Add the sed module to the repo and correct its broken functionality
 - [ ]  Users can currently use sed on other users text and there is also no limit to the sed length, which causes spam issues

Time Consuming
------------------

- [x] Update to work with ruby 2.x
- [ ] Write a small web frontend with user accounts to control data.json and and/remove from shows.json
- [ ] Convert schedule system to using the gdata API for reading calendars rather than scraping ics with ri_cal
- [ ] Convert the twitter module to the streaming API instead of polling
- [ ] Add a Youtube module to push release notices to the IRC channel
- [ ] Add a RSS module to push JB site releases to the IRC channel
- [ ] Redo the voting system to not be tied to IP so multiple people on the same connection can vote
- [ ] Add an IRC authentication interface for controlling restricted commands via the IRC
 - [ ] Add a plugin that allows the addition/removal of arbitrary commands when that is implemented
- [ ] Research and implement a CM system(Chef, Puppet, Ansible, etc) for easy deployment
- [ ] Make the vote page update asynchronously (aka AJAX ALL THE THINGS)
