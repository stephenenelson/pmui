#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Mojolicious::Commands;

Mojolicious::Commands->start_app('PMUI');
