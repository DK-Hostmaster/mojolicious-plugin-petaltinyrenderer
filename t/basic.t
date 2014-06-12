use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'PetalTinyRenderer';
app->renderer->default_handler( 'tal' );
app->defaults(foo => "bar");

get '/inline' => sub {
    shift->render(inline => '<span tal:replace="foo"/>');
};
get '/data';
get '/ns';
get '/file';
get '/missing';
get '/h';
get '/c';

my $t = Test::Mojo->new;
$t->get_ok('/inline') ->status_is(200)->content_is('bar');
$t->get_ok('/data')   ->status_is(200)->content_is("bar\n");
$t->get_ok('/ns')     ->status_is(200)->content_is("<div>bar</div>\n");
$t->get_ok('/file')   ->status_is(200)->content_is("bar\n");
$t->get_ok('/missing')->status_is(404);
$t->get_ok('/h')      ->status_is(200)->content_is("bar\n");
$t->get_ok('/c')      ->status_is(200)->content_is("bar\n");

done_testing();

__DATA__
@@ data.html.tal
<span tal:replace="foo"/>
@@ ns.html.tal
<div xmlns:fun="http://purl.org/petal/1.0/"><span fun:replace="foo"/></div>
@@ h.html.tal
<span tal:replace="h/stash --foo"/>
@@ c.html.tal
<span tal:replace="c/stash --foo"/>
