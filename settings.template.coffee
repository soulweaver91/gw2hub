module.exports = {
    ###
    This file has three sections: dev, prod and common.
    Each setting should exist either in the common section or in both dev and prod sections.
    If a setting is defined both in common and in the currently running profile, the profile one takes precedence;
    if it is completely missing on both common and the current profile, bad things will happen (and the application
    won't probably run at all).

    The currently running profile is set by the --profile switch on the command grunt was launched with; if it's prod,
    prod is used, otherwise (even if not dev) dev is used implicitly.
    ###
    dev:
        # The directory to build the frontend to, relative to the release folder. You will need to run a web server and
        # have an alias point at this directory. (The directory has to be inside this application's directory;
        # you could change that by adding a flag to Gruntfile to allow grunt-contrib-clean and such to access other
        # folders, but this application does not ship with that set for you for security reasons.)
        deployDir: 'dev'
        # The port to run the API on.
        APIPort: 12500
        # The filename of the database. For now, only SQLite3 databases are supported.
        database: 'db/dev.sqlite'
        # The path to the media files on the API side. Used by the file scanner. Relative to the root folder of this
        # application if not absolute.
        localMediaLocation: 'C:/Users/example/Documents/Guild Wars 2/Screens'
        # The path to the media files on the frontend, relative to the frontend if not absolute.
        # Used for fetching the media.
        remoteMediaLocation: '/gw2s/'
    prod:
        # Same settings as in dev. See the comment at the top for details on these sections and their relation.
        deployDir: 'prod'
        APIPort: 12501
        database: 'db/prod.sqlite'
        localMediaLocation: 'C:/Users/example/Documents/Guild Wars 2/Screens'
        remoteMediaLocation: '/gw2s/'
    common:
        # The secret key to use in the hashing function on the API side. It is essential that you set this to a secure,
        # difficult to guess value to ensure the security of your site. For security reasons, the application will also
        # refuse to start up at launch if you don't change this one.
        APISecret: ''
        # The domain the API is running on. Required by the frontend to be able to communicate with it.
        APIAddress: 'http://localhost'
        # The domain the frontend is running on.
        # The API will only accept requests from pages with that domain as the referrer.
        siteAddress: 'http://localhost'
        # The cost parameter used when encrypting values like passwords with bcrypt. Without going too much into
        # details, this value defines how much calculation the algorithm has to do to turn a plain text value into
        # its irreversible hash. Larger values are more secure and also intentionally slower - this is beneficial
        # because quickly solved hashes mean that a potential attacker's attempts are also faster.
        # In 2015, a recommendable value for this would be no less than 15, but in the hypothetical scenario that you
        # are using this in the far future, as computers become better it is recommended to eventually raise this.
        saltRounds: 16
        # The number of concurrent threads the file scanner is allowed to create for thumbnail generation. Too high a
        # number with a lot of files will bring your computer to its knees, so be careful.
        scannerConcurrency: 20
}
