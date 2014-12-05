use Test::Most;

use DDP;
use Github::MergeVelocity;

my $velo = Github::MergeVelocity->new(
    cache_requests  => 1,
    debug_useragent => 0,
    github_token    => $ENV{GITHUB_TOKEN},
    github_user     => $ENV{GITHUB_USER},
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

