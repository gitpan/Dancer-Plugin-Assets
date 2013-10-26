package Dancer::Plugin::Assets;
{
  $Dancer::Plugin::Assets::VERSION = '1';
}
use URI;
use Dancer::Plugin;
use Dancer ":syntax";

use File::Assets;

=head1 NAME

Dancer::Plugin::Assets - Manage and minify .css and .js assets in a Dancer application

=head SYNOPSIS

# In your Dancer application

use Dancer::Plugin::Assets "add_asset";

# Sometime during the request ...

get "/index" => sub {
    add_asset "/css/beautiful.css";
    add_asset "/css/handlebars.js";
};

# Then, in your .tt, print css tags at <head>, print js tags after body

  <html>
    <head><title>[% title %]</title>
    [% add_asset("/js/jquery.js") %]
    [% css_tags %]
    </head>
    <body>
    </body>
    [% js_tags %]
  </html>

# Or you want all css and js tags inside <head>

  <html>
    <head><title>[% title %]</title>
    [% add_asset("/js/jquery.js") %]
    [% add_asset("/js/handlebars.js") %]
    [% add_asset("/css/beautiful.css") %]
    [% css_and_js_tags || js_and_css_tags %]
    </head>
    <body>
    </body>
  </html>

=head1 DESCRIPTION

Dancer::Plugin::Assets integrates File::Assets into your Dancer application. Essentially, it provides a unified way to include .css and .js assets from different parts of your program. When you're done processing a request, you can use var("assets")->export() to generate HTML or var("assets")->exports() to get a list of assets.

D::P::Assets will also handle .css files of different media types properly.

In addition, D::P::Assets includes support for minification via YUI compressor, JavaScript::Minifier, CSS::Minifier, JavaScript::Minifier::XS, and CSS::Minifier::XS

Note that Dancer::Plugin::Assets does not serve files directly, it will work with Static::Simple or whatever static-file-serving mechanism you're using.

=head1 USEAGE

For usage hints and tips, see File::Assets

=head1 CONFIGURATION

You can configure D::P::Assets by manipulating the environment configration file e.g. config.yml, environments/development.yml or environments/production.yml

The following settings are available:

    url            # The url to access the asset files default "/"

    base_dir       # A path to automatically look for assets under (e.g. "/public")
                   
                   # This path will be automatically prepended to includes, so that instead of
                   # doing ->include("/public/css/stylesheet.css") you can just do ->include("/css/stylesheet.css")
                   
                   
    output_dir     # The path to output the results of minification under (if any).
                   # For example, if output is "built/" (the trailing slash is important), then minified assets will be
                   # written to "root/<assets-path>/static/..."
                   #
                   # Designates the output path for minified .css and .js assets
                   # The default output path pattern is "%n%-l%-d.%e" (rooted at the dir of <base>)
                   
                   
    minify         # "1" or "best" - Will either use JavaScript::Minifier::XS> & CSS::Minifier::XS or
                                     JavaScript::Minifier> & CSS::Minifier (depending on availability)
                                     for minification
                   # "0" or "" or undef - Don't do any minfication (this is the default)
                   # "./path/to/yuicompressor.jar" - Will use YUI Compressor via the given .jar for minification
                   # "minifier" - Will use JavaScript::Minifier & CSS::Minifier for minification


    minified_name  # The name of the key in the stash that provides the assets object (accessible via config->{plugins}{assets}{minified_name}.
                   # By default, the <minified_name> is "minified".

=head1 Example configuration

Here is an example configuration: ( All the value are set by default )

    plugins:
        Assets:
            base_dir: "/public"
            output_dir: "static/%n%-l.%e"
            minify: 1,
            minified_name: "minified"

=head1 METHODS

=head2 assets

Return the File::Assets object that exists throughout the lifetime of the request

=cut

register assets              => \&_assets;
register add_asset           => \&_include;
register_plugin for_versions => [ 1, 2 ];

hook before_template_render => sub {
    my $stash = shift;
    $stash->{assets}          = _assets();
    $stash->{add_asset}       = \&_include;
    $stash->{css_tags}        = \&_css_tags;
    $stash->{js_tags}         = \&_js_tags;
    $stash->{css_and_js_tags} = \&_css_and_js_tags;
    $stash->{js_and_css_tags} = \&_css_and_js_tags;
};

sub _assets {
    return var("assets")
      || _build_assets();
}

sub _include {
    my $assets = _assets();
    $assets->include(@_);
    return;
}

sub _js_and_css_tags {
    return _js_tags() . _css_tags();
}

sub _css_and_js_tags {
    return _css_tags() . _js_tags();
}

sub _css_tags {
    my $assets = _assets();
    return $assets->export("css");
}

sub _js_tags {
    my $assets = _assets();
    return $assets->export("js");
}

sub _build_assets {
    my $setting = plugin_setting();

    ## https://metacpan.org/pod/File::Assets#METHODS
    my $url           = _url( $setting->{url} );
    my $base_dir      = $setting->{base_dir} || setting "public";
    my $output_dir    = $setting->{output_dir} || "static/%n%-l.%e";
    my $minify        = defined $setting->{minify} ? $setting->{minify} : 1;
    my $minified_name = $setting->{minified_name} || "minified";

    my $assets = File::Assets->new(
        name        => $minified_name,
        minify      => $minify,
        output_path => $output_dir,
        base        => [ $url, $base_dir ],
    );

    return var assets => $assets;
}

sub _url {
    my $url = shift
      or return _site_url();
    if ( $url =~ /^\// ) {
        return _site_url() . $url;
    }
    if ( $url !~/^[^\/]+\:\/\//i ) {
        return _site_url() . $url;
    }
    return $url;
}

sub _site_url {
    return _scheme() . "://" . _host();
}

sub _scheme {
    return request->env->{"psgi.url_scheme"};
}

sub _host {
    return request->host;
}

true;