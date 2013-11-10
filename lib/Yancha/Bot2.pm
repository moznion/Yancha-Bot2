package Yancha::Bot2;
use 5.008005;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP::Request;
use Carp;
use Furl;
use Twiggy::Server;
use URI;

our $VERSION = "0.03";

sub new {
    my ($class, $config, $callback) = @_;

    # setup the default values
    $config               ||= {};
    $config->{bot_name}   ||= 'YanchaBot';
    $config->{tags}       ||= ['#PUBLIC'];
    $callback             ||= sub {};

    if (ref $config->{tags} ne 'ARRAY') {
        croak "タグはArrayRefで与えてくれんと困りますよほんと";
    }

    unless ($config->{yancha_url}) {
        croak '投稿先URLが指定されていません';
    }

    bless +{
        config     => $config,
        callback   => $callback,
        auth_token => '',
    }, $class;
}

sub up {
    my ($self, $app) = @_;

    my $config = $self->{config};

    if (!$config->{server}->{host} || !$config->{server}->{port}) {
        croak 'サーバのホスト及びポートが指定されていません';
    }

    my $uri = URI->new($config->{yancha_url});
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
    my $server = Twiggy::Server->new(%{$self->{config}->{server}});
    $server->register_service($app);
    print "Ready...\n";
    $cv->recv;
}

sub post {
    my ($self, $message) = @_;

    my $config = $self->{config};

    my $serialized_tags = $self->_serialize_tags;

    my $uri = URI->new($config->{yancha_url});
    $uri->path('/api/post');
    $uri->query_form(
        token => $self->{auth_token},
        text  => "$message $serialized_tags",
    );

    my $req = AnyEvent::HTTP::Request->new({
        method => 'GET',
        uri    => $uri->as_string,
        cb     => sub { shift },
    });

    $req->send;
}

sub single_shot {
    my ($self, $message) = @_;

    my $config = $self->{config};

    unless ($self->{auth_token}) {
        my $auth_uri = URI->new($config->{yancha_url});
        $auth_uri->path('/login');
        $auth_uri->query_form(
            nick       => $config->{bot_name},
            token_only => 1,
        );
        $self->{auth_token} = Furl->new->get($auth_uri->as_string)->content;
    }

    my $post_uri = URI->new($config->{yancha_url});
    $post_uri->path('/api/post');
    $post_uri->query_form(
        token => $self->{auth_token},
        text  => $message,
    );
    Furl->new->get($post_uri->as_string);
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

sub _serialize_tags {
    my ($self) = @_;

    unless ($self->{_serialized_tags}) {
        my $config = $self->{config};
        my $serialized_tags = '';
        for my $tag (@{$config->{tags}}) {
            my $correct_tag = $tag;
            if (index($correct_tag, '#') != 0) {
                $correct_tag = '#' . $correct_tag;
            }
            $serialized_tags .= $correct_tag . ' ';
        }
        $self->{_serialized_tags} = $serialized_tags;
    }

    return $self->{_serialized_tags};
}

1;
__END__

=encoding utf-8

=for stopwords yancha

=head1 NAME

Yancha::Bot2 - Yancha向けbot作成支援モジュール。そのツー。

=head1 SYNOPSIS

    use Yancha::Bot2;

    my $bot = Yancha::Bot2->new({
        bot_name   => 'Awesome Bot',
        tags       => ['#PUBLIC', '#PERL'],
        yancha_url => 'http://your-yancha-url.com:5000',
        server     => {
            host => 'http://your-server-url.com',
            port => '3000',
        },
    });

    my $app = sub {
        $bot->post('hello');
        return [ 200, [], [''] ];
    };

    $bot->up($app);

    # upせずに単発で投稿することも出来ます
    $bot->single_shot('hello');

=head1 DESCRIPTION

Yancha::Bot2はYancha向けのbotを作る際に便利なユーティリティを提供するモジュールです。Yancha::Botという前身のモジュールがありましたが，あれは先日捨て去られましたので，新規にbotを作成する場合はこちらを使うとよいでしょう。

=head1 USAGE

SYNOPSISのコードを例に取ります。

C<Yancha::Bot2-E<gt>new()>でYancha::Bot2のインスタンスを生成します。

次に適当なPlackのレスポンスを返却するアプリケーション (CODEREF) C<$app>を作成します。なお，ここで使っているC<$bot-E<gt>post()>はC<new()>で指定した`yancha_url`のYanchaに宛ててメッセージを投稿します。

そして，C<$bot-E<gt>up($app)>という風に，作成したアプリケーションをC<$bot-E<gt>up()>メソッドに食わせるとbotが起動します。

SYNOPSISの場合，L<http://your-server-url.com:3000>になんらかのアクセスがあった時に，L<http://your-yancha-url.com:5000>に立っているyanchaに対して"hello #PUBLIC #PERL"というメッセージを"Awesome Bot"というユーザ名で投稿します。

=head1 METHODS

=over 4

=item * new(\%args)
コンストラクタ。SYNOPSIS参照。

=item * up($app)
bot活性化

=item * post($message)
メッセージを投稿します (内部的にはAE+Twiggyで動作)。 C<up()>に与えるアプリケーション内で呼んで下さい。B<それ以外の場所で呼んでも何一つ良い事ありません。>

=item * single_shot($message)
メッセージを投稿します (内部的にはFurlで動作)。単発で動作するので，C<up()>を呼ぶ必要がありません。

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

