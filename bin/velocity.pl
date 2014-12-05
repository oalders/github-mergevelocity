#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Github::MergeVelocity;

Github::MergeVelocity->new_with_options->print_report;
