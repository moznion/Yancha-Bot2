#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Yancha::Bot2;

my $bot = Yancha::Bot2->new({
    bot_name   => 'test',
    tags       => ['#PUBLIC'],
    yancha_url => 'http://yancha.hachiojipm.org:3000',
});

# もしくはupせずにメッセージを単発ポストすることもできます
$bot->single_shot('foo');
