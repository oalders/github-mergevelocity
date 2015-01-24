use Test::Most;

use DDP;
use GitHub::MergeVelocity;

my $velo = GitHub::MergeVelocity->new(
    cache_requests  => $ENV{GMV_CACHE_REQUESTS},
    debug_useragent => $ENV{GMV_DEBUG_USERAGENT},
    $ENV{GMV_GITHUB_TOKEN}
    ? (
        github_token => $ENV{GMV_GITHUB_TOKEN},
        github_user  => $ENV{GMV_GITHUB_USER},
        )
    : (),
    dist => [
        'HTML-Restrict',

        #'Moose',
        'PAUSE-Permissions', 'Text-Xslate',

        #'CGI',               'libwww-perl',
        'Plack-Session', 'DateTime',

        #'Dist-Zilla'
    ],
);

my @urls = (
    'git@github.com:user/repository-name.git',
    'https://github.com/user/repository-name.git',
);

foreach my $url (@urls) {
    my ( $user, $repo ) = $velo->_parse_github_url($url);
    is( $user, 'user',            'repo user' );
    is( $repo, 'repository-name', 'repo name' );
}

ok( $velo->report, 'report' );
diag p $velo->report;
diag $velo->print_report;

done_testing();

