# SUSE's openQA tests
#
# Copyright © 2016-2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: testcase 5255-1503973: Gnome: Applications starts on login
# Maintainer: xiaojun <xjin@suse.com>

use base "x11test";
use strict;
use warnings;
use testapi;
use utils;
use version_utils qw(is_leap is_sle is_tumbleweed);
use x11utils 'handle_relogin';

sub tweak_startupapp_menu {
    my ($self) = @_;
    if (is_tumbleweed) {
        x11_start_program 'gnome-tweaks';
    }
    elsif (is_sle('15+')) {
        # tweak-tool entry is not in gnome-control-center of SLE15;
        x11_start_program 'gnome-tweak-tool';
    }
    else {
        $self->start_gnome_settings;
        type_string "tweak";
        assert_screen "settings-tweak-selected";
        send_key "ret";
    }
    assert_screen "tweak-tool";
    # increase the default timeout - the switching can be slow
    send_key_until_needlematch "tweak-startapp", "down", 10, 2;
}

sub start_dconf {
    my ($self) = @_;

    if (is_tumbleweed || is_sle('15+')) {
        # dconf-editor entry is not in gnome-control-center of SLE15;
        x11_start_program 'dconf-editor';
    }
    else {
        $self->start_gnome_settings;
        type_string "dconf";
        assert_screen "settings-dconf";
        send_key "ret";
    }

    # dconf-editor always show the notice to be careful after the main window
    assert_and_click 'will-be-careful';
    assert_screen 'dconf-editor';
}

sub alter_status_auto_save_session {
    my ($self) = @_;
    $self->start_dconf;
    # Old behavior for non SLE15 or non TW
    if (!is_sle('15+') && !is_leap('15.0+')) {
        send_key_until_needlematch "dconf-org", "down";
        assert_and_click "unfold";
        send_key_until_needlematch "dconf-org-gnome", "down";
        assert_and_click "unfold";
        send_key_until_needlematch "dconf-gnome-evolution", "down";
        assert_and_click "scroll-down";    #this step aim to work around screen not scroll down automate issue
        send_key_until_needlematch "gnome-session", "down";
    }
    # New behavior for SLE15 and TW
    else {
        send_key 'ctrl-f';
        assert_screen 'dconf-search-bar';
        type_string "auto-save-session\n";
    }
    assert_and_click "auto-save-session";
    if (check_screen("changing-scheme-popup", 30)) {
        assert_and_click "auto-save-session-alter-use-default";
        assert_and_click "auto-save-session-true";
        assert_and_click "auto-save-session-apply";
    }
    send_key "alt-f4";
    wait_still_screen;
    send_key "alt-f4";
}

sub restore_status_auto_save_session {
    my ($self) = @_;
    $self->start_dconf;
    assert_and_click "auto-save-session" unless is_sle('15+');
    assert_and_click "auto-save-session-alter-use-default";
    assert_and_click "auto-save-session-apply";
    send_key "alt-f4";
    wait_still_screen;
    send_key "alt-f4";
}

sub run {
    my ($self) = @_;
    #add firefox to startup application
    assert_screen "generic-desktop";
    $self->tweak_startupapp_menu;
    assert_and_click "tweak-startapp-add";
    assert_screen "tweak-startapp-applist";
    if (is_sle('12-SP2+') || is_tumbleweed) {
        assert_and_click "startupApp-searching";
        wait_still_screen;
        assert_screen "focused-on-search";
        type_string "firefox";
        assert_and_click "firefox-searched";
    }
    else {
        send_key_until_needlematch "applicationstart-firefox", "down";
    }
    assert_and_click "tweak-addapp-2startup";
    assert_screen "startapp-firefox-added";
    send_key "alt-f4";
    wait_still_screen;
    send_key "alt-f4";

    handle_relogin;
    $self->firefox_check_default;
    $self->firefox_check_popups;
    assert_screen "firefox-gnome", 90;
    send_key "alt-f4";
    wait_still_screen;
    send_key "ret";
    wait_still_screen;
    assert_screen "generic-desktop";

    #remove firefox from startup application
    $self->tweak_startupapp_menu;
    assert_screen "startapp-firefox-added";
    assert_and_click "startapp-delete";
    wait_still_screen;
    send_key "alt-f4";
    assert_screen "generic-desktop";

    handle_relogin;
    assert_screen "generic-desktop";

    #set auto-save-session;
    ##reference information: start from gnome 3,
    ##for lacking maintainence,
    ##auto-save-session functionality has been abandoned;
    ##current status: just firefox works
    ##so in the future will consider remove openqa code for this session
    unless (is_sle('15+') || is_tumbleweed) {
        $self->alter_status_auto_save_session;

        x11_start_program('firefox');
        wait_still_screen;
        $self->firefox_check_popups;
        assert_screen "firefox-gnome", 90;
        handle_relogin;
        $self->firefox_check_popups;
        assert_screen "firefox-gnome", 90;
        send_key "alt-f4";
        wait_still_screen;
        send_key "ret";
        wait_still_screen;

        if (is_sle('12-SP2+')) {
            $self->restore_status_auto_save_session;
        }
        else {
            $self->alter_status_auto_save_session;
        }
    }
}

1;
