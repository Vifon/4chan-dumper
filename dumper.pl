#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;

use JSON::XS;
use Encode qw(encode);

use WWW::Curl::Easy;

sub downloader {
    my $curl = WWW::Curl::Easy->new;
    return sub {
        my ($url, $output) = @_;

        $curl->setopt(CURLOPT_URL       , $url);
        $curl->setopt(CURLOPT_WRITEDATA , $output);
        return $curl->perform;
    }
}

$| = 1;

for (@ARGV) {
    my ($board, $id) = m,4chan.org/(.*?)/res/(\d*),;

    my $dl = downloader;

    my $url = "http://api.4chan.org/$board/res/$id.json";
    my $json;
    next if $dl->($url, \$json) != 0;


    my $thread = decode_json(encode('utf-8', $json));

    for my $post (@{$thread->{posts}}) {
        next unless exists $post->{tim};

        my $filename = $post->{tim} . $post->{ext};


        my $url = "http://images.4chan.org/$board/src/$filename";
        print "$url ... ";

        print "[1;33mEXISTS[0m\n" and next if -e $filename;

        my $image;
        if ($dl->($url, \$image) == 0) {
            print "[1;32mDONE[0m"
        } else {
            print "[1;31mERROR[0m"
        }

        open(my $file, '>', $filename) or next;
        print $file $image;
        close $file;
        print "\n";
    }
}
