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
The API runs on [node.js](http://nodejs.org/), so if you don't have it installed, do that first. Also, if you don't yet
have grunt or bower installed globally, install them now:

    npm install -g grunt-cli
    npm install -g bower
    
Then, install the required dependencies:

    npm install
    bower install
    
The security bits in the code depend on `node-gyp`, which might be sometimes a bit tricky to install. Consult
[its installation requirements](https://github.com/TooTallNate/node-gyp/) if you're using it for the first time.

Initialize the SQLite database by then running

    grunt initDB
    
Configure the application by specifying a secret value for session key generation by creating the file
`apisecret.coffee` in the root directory of the application. This file is ignored by git and not included by default
for safety reasons. The file should be a single export in the form of

    module.exports = 'your secret value here'

Finally, review the contents of `settings.coffee` and change the values to suit your own use.

Usage
-----
Run the API server from the command line:

    grunt runAPI --profile=prod
    
This will compile the required files into `release/prod/` and start the API on port 12501 by default.
For my own purposes, Express won't host the actual site; I have a dynamic link from inside an Apache installation
pointing to this folder instead.

To enable automatic recompilation of client side content, use this task instead:

    grunt develop
    
You may use or not use the profile switch with either task, but the expected usage is that `develop` is only used with
the development settings (the default environment without the profile switch).

Can I see it somewhere live?
----------------------------
The stable version of the site will eventually be hosted [here](http://soul-weaver.tk/gw2/) once enough features have
been added. The development version is located [here](http://soul-weaver.tk/gw2_edge/) and will probably be broken
most of the time.

I think this is neat!
---------------------
If you'd like to let me know you like this project, you can always send mail to Soulweaver.2190. Donations towards
Meteorlogicus are also always welcome but definitely optional - don't feel pressurized to do so if you just want
to give feedback.

License
-------
The source code is licensed under the [ISC license](http://www.isc.org/downloads/software-support-policy/isc-license/).

Guild Wars, Guild Wars 2, ArenaNet, NCSOFT, the Interlocking NC Logo, and all associated logos and designs are
trademarks or registered trademarks of NCSOFT Corporation. All other trademarks are the property of their respective
owners.
