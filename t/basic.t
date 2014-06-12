use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'PetalTinyRenderer';
app->defaults(foo => "bar");

get '/inline' => sub {
    shift->render(inline => "<span tal:replace='foo'/>\n", handler => 'tal');
};
for ( qw/ data ns file missing h c / ) {
    get "/$_";
}

my $t = Test::Mojo->new;
for ( qw/ inline data file h c / ) {
    $t->get_ok("/$_")->status_is(200)->content_is("bar\n");
}
$t->get_ok('/ns')->status_is(200)->content_is("<div>bar</div>\n");
$t->get_ok('/missing')->status_is(404);

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
