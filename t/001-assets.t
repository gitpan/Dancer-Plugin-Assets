use strict;
use warnings;
use t::TestMe;
use Dancer::Test;
use Test::More import => ["!pass"], tests => 2;
response_content_is [GET => "/js_tags"], q{<script src="http://localhost/static/minified.js" type="text/javascript"></script>};
response_content_is [GET => "/css_tags"], q{<link rel="stylesheet" href="http://localhost/static/minified.css" type="text/css"/>};
