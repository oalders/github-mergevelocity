#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use GitHub::MergeVelocity::Repository;
use Pithub::PullRequests;

my @urls = (
    'git@github.com:user/repository-name.git',
    'https://github.com/user/repository-name.git',
);

foreach my $url (@urls) {

    my $repo = GitHub::MergeVelocity::Repository->new(
        github_client => Pithub::PullRequests->new(),
        url           => $url,
    );
    is( $repo->user, 'user',            'repo user' );
    is( $repo->name, 'repository-name', 'repo name' );
}

done_testing;
