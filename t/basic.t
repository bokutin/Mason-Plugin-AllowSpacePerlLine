use strict;
use feature ":5.10";
use Test::More;

use lib "lib";

use File::Path qw(remove_tree);
use FindBin;
use Mason;

{
    remove_tree("$FindBin::Bin/data");
    my $interp = Mason->new(
        comp_root => "t/comps",
        data_dir  => "t/data",
        plugins => [
        ],
    );
    like $interp->run("/sample")->output, qr/Disable AllowSpacePerlLine syntax/;
}

{
    remove_tree("$FindBin::Bin/data");
    my $interp = Mason->new(
        comp_root => "t/comps",
        data_dir  => "t/data",
        plugins => [
            "AllowSpacePerlLine",
        ],
    );
    unlike $interp->run("/sample")->output, qr/Disable AllowSpacePerlLine syntax/;
}

done_testing();
