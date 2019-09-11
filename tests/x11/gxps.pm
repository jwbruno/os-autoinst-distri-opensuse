# SUSE's openQA tests
#
# Copyright © 2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Add gxps tests
#    Checks exif metadata from given image.
#    Checks gxps functionalities like renaming and creating preview image from metadata.
#
#    The examined images were created for this test purpose only.
#
# Maintainer: João Walter Bruno Filho <bfilho@suse.com>

use base "x11test";
use strict;
use warnings;
use testapi;
use utils;

sub run {
    select_console "x11";
    x11_start_program('xterm');

    #prepare
    become_root;
    pkcon_quit;
    zypper_call "se gxps";
    zypper_call "in libgxps-tools";

    #Get assets to local directory
    ##1092125
    assert_script_run "wget --quiet " . data_url('gxps/bsc_769197_poc.xps');
    assert_script_run "wget --quiet " . data_url('gxps/POC_glib_stackoverflow.xps');
    assert_script_run "wget --quiet https://github.com/Microsoft/Windows-classic-samples/raw/master/Samples/Win7Samples/xps/XpsLoadModifySave/sample1.xps";
    
    assert_script_run "xpstopng sample1.xps";
    assert_script_run "xpstojpeg sample1.xps";

    script_run "eog page-1.png", 0;
    assert_screen "xpstopng_page-1.png";
    send_key 'alt-f4';

    script_run "eog page-1.jpg", 0;
    assert_screen "xpstopng_page-1.jpg";
    send_key 'alt-f4';


    # just run without segmentation fault
    assert_script_run "xpstojpeg bsc_769197_poc.xps"; #bsc #1092125
    assert_script_run "xpstojpeg POC_glib_stackoverflow.xps"; #bsc #1092123


    # clean-up
    assert_script_run "rm sample1.xps";
    assert_script_run "rm bsc_769197_poc.xps";
    assert_script_run "rm POC_glib_stackoverflow.xps";
    assert_script_run "rm page-*.jpg";
    assert_script_run "rm page-*.png";
    send_key "alt-f4";
}

1;
