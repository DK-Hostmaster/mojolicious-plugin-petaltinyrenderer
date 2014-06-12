package Mojolicious::Plugin::PetalTinyRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw(encode md5_sum);
use Petal::Tiny;

our $VERSION = '0.01';

my $tal_ns = q{xmlns:tal="http://purl.org/petal/1.0/"};

sub register {
    my ($self, $app, $conf) = @_;

    $app->renderer->add_handler($conf->{name} || 'tal' => \&_petal);
}

sub _petal {
    my ($renderer, $c, $output, $options) = @_;

    my $inline = $options->{inline};
    my $name   = $renderer->template_name($options);
    $name = md5_sum encode($options->{encoding}, $inline) if defined $inline;
    return undef unless defined $name;

    $$output = '';

    my $log = $c->app->log;

    if (defined $inline) {
        $log->debug(qq{Rendering inline template "$name".});
        $$output = _render_xml($inline, $c);
    }
    else {
        if (defined(my $path = $renderer->template_path($options))) {
            $log->debug(qq{Rendering template "$name".});

            if (open my $file, "<", $path) {
                my $xml = join "", <$file>;
                $$output = _render_xml($xml, $c);
                close $file;
            }
            else {
                $log->debug(qq{Template "$name" ($path) not readable.});
                return undef;
            }
        }
        elsif (my $d = $renderer->get_data_template($options)) {
            $log->debug(qq{Rendering template "$name" from DATA section.});
            $$output = _render_xml($d, $c);
        }
        else {
            $log->debug(qq{Template "$name" not found.});
            return undef;
        }
    }

    return 1;
}

sub _render_xml {
    my ($xml, $c) = @_;

    my $deldiv = 0;
    if ($xml !~ /\bxmlns:/) {
        $xml = "<div $tal_ns>$xml</div>";
        $deldiv = 1;
    }

    my $template = Petal::Tiny->new($xml);

    my $helper = Mojolicious::Plugin::PetalTinyRenderer::Helper->new(ctx => $c);
    my $html = $template->process(%{$c->stash}, c => $c, h => $helper);

    if ($deldiv) {
        $html =~ s,\A<div>,,;
        $html =~ s,</div>\z,,;
    }

    return $html;
}

1;

package
  Mojolicious::Plugin::PetalTinyRenderer::Helper;

use base 'Mojo::Base';

our $AUTOLOAD;

__PACKAGE__->attr('ctx');

# stolen from  Mojolicious::Plugin::TtRenderer::Helper
sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;

    return if $method =~ /^[A-Z]+?$/;
    return if $method =~ /^_/;
    return if $method =~ /(?:\:*?)DESTROY$/;

    $method = (split '::' => $method)[-1];

    die qq/Unknown helper: $method/ unless $self->ctx->app->renderer->helpers->{$method};

    return $self->ctx->$method(@_);
}

# lifted from http://www.perlmonks.org/?node_id=44911
sub can {
    my ($self, $method) = @_;
    my $subref = $self->SUPER::can($method);
    return $subref if $subref; # can found it; it's a real method

    # Method doesn't currently exist; should it, though?
    return unless exists $self->ctx->app->renderer->helpers->{$method};

    # Return an anon sub that will work when it's eventually called
    sub {
        my $self = $_[0];

        # The method is being called.  The real method may have been
        # created in the meantime; if so, don't call AUTOLOAD again
        my $subref = $self->SUPER::can($method);
        goto &$subref if $subref;

        $AUTOLOAD=$method;
        goto &AUTOLOAD;
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PetalTinyRenderer - Petal::Tiny renderer plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('PetalTinyRenderer');

  # Mojolicious::Lite
  plugin 'PetalTinyRenderer';

=head1 DESCRIPTION

L<Mojolicious::Plugin::PetalTinyRenderer> is a renderer for templates
written for L<Petal::Tiny>, which is a Perl implementation of the
Template Attribute Language (TAL).

=head1 OPTIONS

L<Mojolicious::Plugin::PetalTinyRenderer> supports the following
option.

=head2 name

  # Mojolicious::Lite
  plugin PetalTinyRenderer => {name => 'petal'};

Handler name, defaults to C<tal>.

=head1 STASH

The stash is directly available in the templates, see the use of foo in the example.

=head2 h

Helpers are available via the C<h> entry in the stash.

 <a tal:attributes="href h/url_for --index" href="/">go back to index</a>

=head2 c

The current controller instance can be accessed as C<c>.

 I see you are requesting a document from 
 <span tal:replace="c/req/headers/host">Lorem ipsum</span>.

=head1 USEFUL PATTERNS

Call helper-function without generating html (-- prefixes a literal
string):

 <span tal:condition="true:h/layout --default" tal:omit-tag="" />

Use a temporary variable to hold dynamically generated string for
helper function:

 <span tal:define="mytitle h/localization --login"
       tal:condition="true:h/title mytitle"
       tal:omit-tag="" />

Insert styled paragraph with error-message, if any (the structure
keyword means don't escape returned html):

 <p style="color:red" tal:condition="true:message" tal:content="structure message">
   Error message
 </p>

Include other action/template:

 <span tal:replace="structure h/include --example/welcome" />

See L<Petal::Tiny> for more.

Author's observation: If you need to write very complex
TAL-constructs, maybe you should reconsider what belongs in the
controller and what belongs in the template. TAL seems to be very good
at exposing this anti-pattern.

=head1 EXAMPLE

 use Mojolicious::Lite;

 plugin 'PetalTinyRenderer';

 get '/' => sub {
     my $self = shift;
     $self->stash( foo => [ 1,2,3 ] );
     $self->render('index');
 };

 app->start;

 __DATA__

 @@ layouts/default.html.tal
 <!DOCTYPE html>
 <html>
   <head><title tal:content="title">Lorem</title></head>
   <body tal:content="structure h/content">Ipsum</body>
 </html>

 @@ index.html.tal
 <span tal:condition="true:h/layout --default" tal:omit-tag="" />
 <span tal:condition="true:h/title --Welcome" tal:omit-tag="" />

 <p tal:repeat="i foo"><span tal:replace="i"/>: Welcome to the PetalTinyRenderer plugin!</p>

=head1 SEE ALSO

L<Petal::Tiny>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Lars Balker <lars@balker.dk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by DK Hostmaster A/S.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
