use Test::Most;

use DDP;
use Github::MergeVelocity;

my $velo = Github::MergeVelocity->new(
    cache_requests  => $ENV{GMV_CACHE_REQUESTS},
    debug_useragent => $ENV{GMV_DEBUG_USERAGENT},
    github_token    => $ENV{GMV_GITHUB_TOKEN},
    github_user     => $ENV{GMV_GITHUB_USER},
    dist            => [
        'HTML-Restrict',     'Moose',
        'PAUSE-Permissions', 'Text-Xslate',
        'CGI',               'libwww-perl',
        'Plack::Session',    'DateTime',
        'Dist-Zilla'
    ],
);

ok( $velo->report, 'report' );
diag p $velo->report;
diag $velo->print_report;

done_testing();

