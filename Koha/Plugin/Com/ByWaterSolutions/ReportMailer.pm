package Koha::Plugin::Com::ByWaterSolutions::ReportMailer;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);


## Here we set our plugin version
our $VERSION         = "1.0";
our $MINIMUM_VERSION = "22.05";

our $metadata = {
    name            => 'Report Mailer',
    author          => 'Liz Rea',
    date_authored   => '2023-03-20',
    date_updated    => "1900-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Schedule a report to be mailed to an address',
};

=head3 new

=cut

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

=head3 configure

=cut

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            run_on_dow => $self->retrieve_data('run_on_dow'),
	    toaddress		  => $self->retrieve_data('toaddress'),
            filename              => $self->retrieve_data('filename'), 
            csv_header            => $cgi->param('csv_header'),
            subject               => $cgi->param('subject'),
	    sql_params            => $cgi->param('sql_params'),
            report_id            => $cgi->param('reportid')

        );

	# want this but not rn
#       if ( $cgi->param('test') ) {
	#    try {
	#        my $sftp = $self->get_sftp();
	#    }
	#    catch {
	#        $template->param( test_completed => 1, test_results => $_ );
	#    }
	#}

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                report_id             => $cgi->param('reportid'),
                debug      => $cgi->param('debug'),
                run_on_dow => $cgi->param('run_on_dow'),
                toaddress             => $cgi->param('toaddress'),
                filename              => $cgi->param('filename'),
                csv_header            => $cgi->param('csv_header'),
                subject               => $cgi->param('subject'),
                sql_params            => $cgi->param('sql_params')
            }
        );
        $self->go_home();
    }
}


=head3 cronjob_nightly

=cut

sub cronjob_nightly {
    my ( $self, $p ) = @_;

    my $debug = $self->retrieve_data('debug');

    my $run_on_dow = $self->retrieve_data('run_on_dow');
    if ($run_on_dow) {
        if ( (localtime)[6] == $run_on_dow ) {
            say "Run on Day of Week $run_on_dow matches current day of week "
              . (localtime)[6]
              if $debug >= 1;
        }
        else {
            say
"Run on Day of Week $run_on_dow does not match current day of week "
              . (localtime)[6]
              if $debug >= 1;
            return;
        }
    }

    my $attached_filename = $self->retrieve_data('filename');

    my $toaddress             = $self->retrieve_data('toaddress');
    my $csv_header            = $self->retrieve_data('csv_header');
    my $subject               = $self->retrieve_data('subject');
    my $sql_params            = $self->retrieve_data('sql_params');
    my $reportid              = $self->retrieve_data('reportid');

    my $cmd =
      qq{/usr/share/koha/bin/runreport.pl --to=$toaddress --subject=$subject -a --format=csv };

    $cmd .= " --csv-header "                if $csv_header;
    $cmd .= " $sql_params "                 if $sql_params;
    $cmd .= " $reportid";

    warn "COMMAND: $cmd" if $debug;

    my $output = qx{$cmd};

    warn "COMMAND OUTPUT: $output" if $debug;

}

=head3 install

This is the 'install' method. Any database tables or other setup that should
be done when the plugin if first installed should be executed in this method.
The installation method should always return true if the installation succeeded
or false if it failed.

=cut

sub install() {
    my ( $self, $args ) = @_;

    $self->store_data(
        {
            run_on_dow => "0",
        }
    );

    return 1;
}

=head3 upgrade

This is the 'upgrade' method. It will be triggered when a newer version of a
plugin is installed over an existing older version of a plugin

=cut

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

=head3 uninstall

This method will be run just before the plugin files are deleted
when a plugin is uninstalled. It is good practice to clean up
after ourselves!

=cut

sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

1;

