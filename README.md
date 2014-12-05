Determine the merge velocity of a Perl distribution.

Are you planning to send a pull request for a CPAN module?  This app will help
you determine how likely it is that your pull request will be merged within a
"reasonable" amount of time.

    git clone https://github.com/oalders/github-mergevelocity
    cd github-mergevelocity
    carton install
    carton exec -- bin/velocity --github-token XXX --github-user XXX --dist HTTP-BrowserDetect --dist Plack


