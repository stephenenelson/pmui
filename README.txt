PMUI

This is an extremely bare-bones web UI for Playback Machine, the TV station in a box. It lets you add movies from the designated movies directory to the schedule, or delete them. 

PREREQUISITES

To run pmui, you'll need Video::PlaybackMachine, available at https://metacpan.org/release/Video-PlaybackMachine or https://github.com/stephenenelson/video-playbackmachine.

You'll also need Mojolicious, which you can acquire from http://mojolicio.us/.

RUNNING PMUI

Pmui is a Mojolicious app, which means you can run it in several ways. You can run it as a standalone forking server, via:

   hypnotoad pmui

You can then access the web interface on http://localhost:8080.

You can also deploy it in any other way that Mojolicious allows. See the Mojolicious docs for details.

