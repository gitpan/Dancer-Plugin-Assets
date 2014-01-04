use strict;
use warnings;
use t::TestMe;
use Dancer::Test;
use Test::More import => ["!pass"], tests => 2;
response_content_like [GET => "/js_tags"], qr{<script .*src="http://localhost/static/minified.js".*></script>};
response_content_like [GET => "/css_tags"], qr{<link .*href="http://localhost/static/minified.css".*/>};
