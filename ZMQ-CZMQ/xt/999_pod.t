use Test::More;
use Test::Requires;

test_requires 'Test::Pod';
Test::Pod::all_pod_files_ok();