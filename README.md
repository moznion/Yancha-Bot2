# NAME

Yancha::Bot2 - Yancha向けbot作成支援モジュール。そのツー。

# SYNOPSIS

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

# DESCRIPTION

Yancha::Bot2はYancha向けのbotを作る際に便利なユーティリティを提供するモジュールです。Yancha::Botという前身のモジュールがありましたが，あれは先日捨て去られましたので，新規にbotを作成する場合はこちらを使うとよいでしょう。

# USAGE

SYNOPSISのコードを例に取ります。

`Yancha::Bot2->new()`でYancha::Bot2のインスタンスを生成します。

次に適当なPlackのレスポンスを返却するアプリケーション (CODEREF) `$app`を作成します。なお，ここで使っている`$bot->post()`は`new()`で指定した\`yancha\_url\`のYanchaに宛ててメッセージを投稿します。

そして，`$bot->up($app)`という風に，作成したアプリケーションを`$bot->up()`メソッドに食わせるとbotが起動します。

SYNOPSISの場合，[http://your-server-url.com:3000](http://your-server-url.com:3000)になんらかのアクセスがあった時に，[http://your-yancha-url.com:5000](http://your-yancha-url.com:5000)に立っているyanchaに対して"hello \#PUBLIC \#PERL"というメッセージを"Awesome Bot"というユーザ名で投稿します。

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
