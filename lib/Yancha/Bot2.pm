package Yancha::Bot2;
use 5.008005;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP::Request;
use Carp;
use Twiggy::Server;

our $VERSION = "0.01";

sub new {
    my ($class, $config, $callback) = @_;

    # setup the default values
    $config               ||= {};
    $config->{server_url} ||= 'http://127.0.0.1:3000';
    $config->{bot_name}   ||= 'YanchaBot';
    $config->{tags}       ||= ['#PUBLIC'];
    $callback             ||= sub {};

    bless +{
        config     => $config,
        callback   => $callback,
        auth_token => '',
    }, $class;
}

sub up {
    my ($self, $app, $server_opt) = @_;

    my $config = $self->{config};

    my $uri = URI->new($config->{server_url});
    $uri->path('/login');
    $uri->query_form(
        nick       => $config->{bot_name},
        token_only => 1,
    );

    my $req = AnyEvent::HTTP::Request->new({
        method => 'GET',
        uri    => $uri->as_string,
        cb     => sub {
            my $body = shift;
            $self->{auth_token} = $body;
            if ($self->{auth_token}) {
                $self->callback_later(0);
            }
        }
    });
    $req->send();

    my $cv     = AnyEvent->condvar;
    my $server = Twiggy::Server->new(%$server_opt);
    $server->register_service($app);
    print "Ready...\n";
    $cv->recv;
}

sub post {
    my ($self, $message) = @_;

    my $config = $self->{config};

    if (ref $config->{tags} ne 'ARRAY') {
        croak "タグはArrayRefで与えてくれんと困りますよほんと";
    }

    my @tags;
    for my $tag (@{$config->{tags}}) {
        my $correct_tag = $tag;
        if (index($correct_tag, '#') != 0) {
            $correct_tag = '#' . $correct_tag;
        }
        push @tags, $correct_tag;
    }

    my $uri = URI->new($config->{server_url});
    $uri->path('/api/post');
    $uri->query_form(
        token => $self->{auth_token},
        text  => join (' ', $message, @tags),
    );

    my $req = AnyEvent::HTTP::Request->new({
        method => 'GET',
        uri    => $uri->as_string,
        cb     => sub { shift },
    });

    $req->send;
}

sub callback_later {
    my ($self, $after) = @_;

    return if $self->{callback};

    my $timer;
    $timer = AnyEvent->timer(
        after => $after || 0,
        cb    => sub {
            undef $timer;
            $self->{callback}->($self);
        },
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Yancha::Bot2 - おい、こっちのほうがいいぞ！

=head1 SYNOPSIS

    use Yancha::Bot2;

=head1 DESCRIPTION

Yancha::Bot2 is ...

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

