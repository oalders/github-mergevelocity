use Test::Most;

use DDP;
use Github::MergeVelocity;

my $velo = Github::MergeVelocity->new(
    cache_requests  => 1,
    debug_useragent => 0,
    github_token    => $ENV{GITHUB_TOKEN},
    github_user     => $ENV{GITHUB_USER},
);

my $foo = $velo->get_pull_requests( 'plack', 'Plack' );
diag p $foo;

foreach my $pull ( @{$foo} ) {
    diag $pull->url;
    diag $pull->age;
    diag $pull->state;
}

ok( 1, 'ok!');

done_testing();

