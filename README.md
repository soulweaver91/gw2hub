gw2hub
======
gw2hub is a personalized Guild Wars 2 information portal that incorporates tagged screenshots, character data,
unlocks, material collection hoard and other tidbits under the same roof. Although many parts of the data will
require manual updating, it will use the official Guild Wars 2 API where applicable. It is built with my own use in
mind, but you're free to fork it as long as you can handle maintaining it yourself. The server side consists of an
Express and a SQLite database running on node.js, while the client side is an AngularJS application.

**This software source code is provided as-is, and the only support I am currently capable to provide is contained in this
document.** This might change in the future, but for now please don't file any feature requests or ask additional
questions on its usage.

Installing
----------
The API runs on [node.js](http://nodejs.org/), so if you don't have it installed, do that first. You will also need
to install [GraphicsMagick](http://www.graphicsmagick.org/) as well as [FFmpeg](https://ffmpeg.org/download.html) and
make sure they are in your PATH.

If you don't yet have grunt or bower installed globally, install them now:

    npm install -g grunt-cli
    npm install -g bower
    
Then, install the required dependencies:

    npm install
    bower install
    
The security bits in the code depend on `node-gyp`, which might be sometimes a bit tricky to install. Consult
[its installation requirements](https://github.com/TooTallNate/node-gyp/) if you're using it for the first time.

Initialize the SQLite database by then running

    grunt initDB
    
Configure the application by copying the `settings.template.coffee` file into the same folder as `settings.coffee`.
Review the values inside the new file and change them to suit your own use, based on the provided guides. Make sure
you define a secure, difficult to guess API secret key in those settings!

As for the API key: make note that the site has sections that pull detailed data from the available APIs, such as the
bank/material storage. If you'd like to use this site but are not comfortable with giving all permissions to the key
you're using, you may in theory provide a limited access key. Regardless, this will cause some pages to not work at all.

Once you have the software running, remember to log in as the default user and change its password. The default
credentials are `user@db` as email and `default` as password. You might want to replace the email with a less generic
one instead, too. You can change the email address in your own control panel or, if logged in as an administrator,
from the user management section.

Usage
-----
Run the API server from the command line:

    grunt runAPI --profile=prod
    
This will compile the required files into `release/prod/` and start the API on port 12501 by default.
For my own purposes, Express won't host the actual site; I have a dynamic link from inside an Apache installation
pointing to this folder instead.

To enable automatic recompilation of client side content, use this task instead:

    grunt develop
    
You can use either task with or without the profile switch, but the expected usage is that `develop` is only used with
the development environment `dev`, which is also the default environment without the profile switch.

Can I see it somewhere live?
----------------------------
The stable version of the site will eventually be hosted on my external server once enough features have been added.
The development version is located [here](http://home.soulweaver.fi/gw2_edge/) and will probably be broken
most of the time either because I'm not running the API or because I'm actively building there.

I think this is neat!
---------------------
If you'd like to let me know you like this project, you can always send mail to Soulweaver.2190. Any kinds of donations
are also always welcome but definitely optional - don't feel pressurized to do so if you just want to give feedback.
I'll be happy even if you just let me know this project has been any use to you - my approach is from a hobbyist
project perspective, but the more good it can make the better.

License
-------
The source code is licensed under the [ISC license](http://www.isc.org/downloads/software-support-policy/isc-license/).

Guild Wars, Guild Wars 2, ArenaNet, NCSOFT, the Interlocking NC Logo, and all associated logos and designs are
trademarks or registered trademarks of NCSOFT Corporation. All other trademarks are the property of their respective
owners.
