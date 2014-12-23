package AWS::CLI::Config;
use 5.008001;
use strict;
use warnings;

use Carp ();
use Config::Tiny;
use File::Spec;

our $VERSION = "0.01";

my $DEFAULT_PROFILE = 'default';

my $CREDENTIALS;
my %CREDENTIALS_PROFILE_OF;
my $CONFIG;
my %CONFIG_PROFILE_OF;

my %ACCESSORS;
BEGIN: {
    %ACCESSORS = (
        access_key_id     => +{ env => 'AWS_ACCESS_KEY_ID',     key => 'aws_access_key_id' },
        secret_access_key => +{ env => 'AWS_SECRET_ACCESS_KEY', key => 'aws_secret_access_key' },
        session_token     => +{ env => 'AWS_SESSION_TOKEN',     key => 'aws_session_token' },
        region            => +{ env => 'AWS_DEFAULT_REGION' },
        output            => +{},
    );

    MK_ACCESSOR: {
        no strict 'refs';
        for my $attr (keys %ACCESSORS) {
            my $func = __PACKAGE__ . "::$attr";
            *{$func} = _mk_accessor($attr, %{$ACCESSORS{$attr}});
        }
    }
}

sub _mk_accessor {
    my $attr = shift;
    my %opt  = @_;

    my $env_var = $opt{env};
    my $profile_key = $opt{key} || $attr;

    return sub {
        if ($env_var && exists $ENV{$env_var} && $ENV{$env_var}) {
            return $ENV{$env_var};
        }

        my $profile = shift || _default_profile();

        my $credentials = credentials($profile);
        if ($credentials && $credentials->$profile_key) {
            return $credentials->$profile_key;
        }

        my $config = config($profile);
        if ($config && $config->$profile_key) {
            return $config->$profile_key;
        }

        return undef;
    };
}

sub credentials {
    my $profile = shift || _default_profile();
    $CREDENTIALS ||= sub {
        my $path = File::Spec->catfile(_default_dir(), 'credentials');
        return +{} unless (-r $path);
        return Config::Tiny->read($path);
    }->();
    return unless (exists $CREDENTIALS->{$profile});
    $CREDENTIALS_PROFILE_OF{$profile} ||= AWS::CLI::Config::Profile->_new($CREDENTIALS->{$profile});
    return $CREDENTIALS_PROFILE_OF{$profile};
}

sub config {
    my $profile = shift || _default_profile();
    $CONFIG ||= sub {
        my $path
            = (exists $ENV{AWS_CONFIG_FILE} && $ENV{AWS_CONFIG_FILE})
            ? $ENV{AWS_CONFIG_FILE}
            : File::Spec->catfile(_default_dir(), 'config');
        return +{} unless (-r $path);
        return Config::Tiny->read($path);
    }->();
    return unless (exists $CONFIG->{$profile});
    $CONFIG_PROFILE_OF{$profile} ||= AWS::CLI::Config::Profile->_new($CONFIG->{$profile});
    return $CONFIG_PROFILE_OF{$profile};
}

sub _base_dir {
    ($^O eq 'MSWin32') ? $ENV{USERPROFILE} : $ENV{HOME};
}

sub _default_dir {
    File::Spec->catdir(_base_dir(), '.aws');
}

sub _default_profile {
    (exists $ENV{AWS_DEFAULT_PROFILE} && $ENV{AWS_DEFAULT_PROFILE})
        ? $ENV{AWS_DEFAULT_PROFILE}
        : $DEFAULT_PROFILE;
}

PROFILE: {
    package AWS::CLI::Config::Profile;
    use 5.008001;
    use strict;
    use warnings;

    my @ACCESSORS;

    BEGIN {
        @ACCESSORS = qw(
            aws_access_key_id
            aws_secret_access_key
            aws_session_token
            region
            output
        );
    }

    use Object::Tiny @ACCESSORS;

    sub _new {
        my $class = shift;
        my $data  = shift;
        return bless $data, $class;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

AWS::CLI::Config - It's new $module

=head1 SYNOPSIS

    use AWS::CLI::Config;

=head1 DESCRIPTION

AWS::CLI::Config is ...

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

