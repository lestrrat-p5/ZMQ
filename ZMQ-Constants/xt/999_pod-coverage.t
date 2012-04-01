use strict;
use Test::More;
use Test::Requires;

test_requires 'Test::Pod::Coverage';

foreach my $module ( Test::Pod::Coverage::all_modules() ) {
    if ( $module =~ /::(?:Basic|V[\d_]+)$/ ) {
        next;
    }
    Test::Pod::Coverage::pod_coverage_ok(
        $module,
        {
            trustme => [ qr/^[A-Z_]+$/ ],
        },
        "Pod coverage on $module"
    );
}

done_testing;
