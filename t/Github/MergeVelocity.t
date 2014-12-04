use Test::Most;

use DDP;
use Github::MergeVelocity;

my $velo = Github::MergeVelocity->new(
    cache_requests  => 1,
    debug_useragent => 0,
    github_token    => $ENV{GITHUB_TOKEN},
    github_user     => $ENV{GITHUB_USER},
);

my $user = 'plack';
my $repo = 'Plack';

my $pull_requests = $velo->get_pull_requests( $user, $repo );
ok( $pull_requests, 'get_pull_requests' );
is( scalar @{$pull_requests}, 100, '100 PRs' );

ok( $velo->get_report( $user, $repo ), 'get_report' );

my $repo_summary = $velo->analyze_repo( $user, $repo, $pull_requests );
p $repo_summary;
$velo->_print_report( [$repo_summary] );

done_testing();

