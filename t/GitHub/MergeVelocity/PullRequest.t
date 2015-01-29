#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use GitHub::MergeVelocity::PullRequest;

{
    my $created = DateTime->now->subtract( days => 10 );
    my $pr = GitHub::MergeVelocity::PullRequest->new(
        created_at => $created,
        number     => 99,
    );

    is( $pr->state, 'open', 'is open' );

    # allow for funkiness if tests run around midnight GMT
    ok( ( $pr->age == 10 || $pr->age == 11 ), 'age checks out' );
}

{
    my $pr = GitHub::MergeVelocity::PullRequest->new(
        created_at => '2010-01-01',
        merged_at  => '2011-06-01',
        number     => 99,
    );

    is( $pr->state, 'merged', 'is merged' );
    is( $pr->age, 516 );
}

done_testing;

