Determine the merge velocity of a Perl distribution.

Are you planning to send a pull request for a CPAN module?  This app will help
you determine how likely it is that your pull request will be merged within a
"reasonable" amount of time.

    git clone https://github.com/oalders/github-mergevelocity
    cd github-mergevelocity

    # using carton
    carton install
    carton exec -- bin/velocity.pl --dist HTTP-BrowserDetect --dist Plack

    # without carton
    cpanm --installdeps .
    perl bin/velocity.pl --dist HTTP-BrowserDetect --dist Plack

If you want to run a lot of queries, you'll need a Github token and username.  For help:

    carton exec -- bin/velocity.pl
