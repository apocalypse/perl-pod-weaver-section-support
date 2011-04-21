package Pod::Weaver::Section::Support;

# ABSTRACT: Add a SUPPORT section to your POD

use Moose 1.03;
use Moose::Autobox 0.10;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( websites irc bugs_content email_content irc_content repository_content websites_content ) }

=attr all_modules

Enable this if you want to add the SUPPORT section to all the modules in a dist, not only the main one.

The default is false.

=cut

has all_modules => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

=attr perldoc

Specify if you want the paragraph explaining about perldoc to be displayed or not.

The default is true.

=cut

has perldoc => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

=attr bugs

Specify the bugtracker you want to use. You can use the CPAN RT tracker or your own, specified in the metadata.

Valid options are: "rt", "metadata", or "none"

If you pick the "rt" option, this module will generate a predefined block of text explaining how to use the RT system.

If you pick the "metadata" option, this module will check the L<Dist::Zilla> metadata for the bugtracker to display. Be sure
to verify that your metadata contains both 'web' and 'mailto' keys if you want to use them in the content!

The default is "rt".

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	has bugs => (
		is => 'ro',
		isa => enum( [ qw( rt metadata none ) ] ),
		default => 'rt',
	);

	no Moose::Util::TypeConstraints;
}

=attr bugs_content

Specify the content for the bugs section.

Please put the "{EMAIL}" and "{WEB}" placeholders somewhere!

The default is a sufficient explanation (see L</SUPPORT>).

=cut

has bugs_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
Please report any bugs or feature requests by email to {EMAIL}, or through
the web interface at {WEB}. You will be automatically notified of any
progress on the request by the system.
EOPOD
		];
	},
);

=attr websites

Specify what website links you want to see. This is an array, and you can pick any combination. You can also
specify it as a comma-delimited string. The ordering of the options are important, as they are reflected in
the final POD.

Valid options are: "none", "search", "rt", "anno", "ratings", "forum", "kwalitee", "testers", "testmatrix", "deps" and "all".

The default is "all".

	# Where the links go to:
	search		- http://search.cpan.org/dist/$dist
	rt		- http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist
	anno		- http://annocpan.org/dist/$dist
	ratings		- http://cpanratings.perl.org/d/$dist
	forum		- http://cpanforum.com/dist/$dist
	kwalitee	- http://cpants.perl.org/dist/overview/$dist
	testers		- http://cpantesters.org/distro/$first_char/$dist
	testmatrix	- http://matrix.cpantesters.org/?dist=$dist
	deps		- http://deps.cpantesters.org/?module=$module

	# in weaver.ini
	[Support]
	websites = search
	websites = forum
	websites = testers , testmatrix

P.S. If you know other websites that I should include here, please let me know!

=cut

# TODO how do I Moosify this into a fancy type system where it coerces from CSV strings and bla bla?
has websites => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ 'all' ] },
);

=attr websites_content

Specify the content to be displayed before the website list.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

has websites_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.
EOPOD
		];
	},
);

=attr irc

Specify an IRC server/channel/nick for online support. You can specify as many networks/channels as you want.
The ordering of the options are important, as they are reflected in the final POD.

You specify a network, then a list of channels/nicks to ask for support.

The default is none.

	# in weaver.ini
	[Support]
	irc = irc.home.org, #support, supportbot
	irc = irc.acme.com, #acmecorp, #acmehelp, #acmenewbies

=cut

has irc => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ ] },
);

=attr irc_content

Specify the content to be displayed before the irc network/channel list.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

has irc_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:
EOPOD
		];
	},
);

=attr repository_link

Specify which url to use when composing the external link.
The value corresponds to the repository meta resources (for dzil v3 with CPAN Meta v2).

Valid options are: "url", "web", "both", or "none".

"both" will include links to both the "url" and "web" in separate POD paragraphs.

"none" will skip the repository item entirely.

The default is "both".

An error will be thrown if a specified link is not found
because if you said that you wanted it you probably expect it to be there.

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	has repository_link => (
		is => 'ro',
		isa => enum( [ qw( both none url web ) ] ),
		default => 'both',
	);

	no Moose::Util::TypeConstraints;
}

=attr repository_content

Specify the content to be displayed before the link to the source code repository.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

has repository_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)
EOPOD
		];
	},
);

=attr email

Specify an email address here so users can contact you directly for help.

If you supply a string without '@' in it, we assume it is a PAUSE id and mangle it into 'USER at cpan.org'.

The default is none.

=cut

has email => (
	is => 'ro',
	isa => 'Maybe[Str]',
	default => undef,
);

=attr email_content

Specify the content for the email section.

Please put the "{EMAIL}" placeholder somewhere!

The default is a sufficient explanation ( see L</SUPPORT>).

=cut

has email_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
You can email the author of this module at {EMAIL} asking for help with any problems you have.
EOPOD
		];
	},
);

sub weave_section {
	## no critic ( ProhibitAccessOfPrivateData )
	my ($self, $document, $input) = @_;

	my $zilla = $input->{zilla} or die 'Please use Dist::Zilla with this module!';

	# Is this the main module POD?
	if ( ! $self->all_modules ) {
		return if $zilla->main_module->name ne $input->{filename};
	}

	$document->children->push(
		# Add the stopwords so the spell checker won't complain!
		# TODO make this smarter so it loads only the stopwords we need for specific sections... ohwell
		Pod::Elemental::Element::Pod5::Region->new( {
			format_name => 'stopwords',
			is_pod => 1,
			content => '',
			children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( {
					content => join( " ", qw( cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders ) ),
				} ),
			],
		} ),
		Pod::Elemental::Element::Nested->new( {
			command => 'head1',
			content => 'SUPPORT',
			children => [
				$self->_add_perldoc( $zilla ),
				$self->_add_websites( $zilla ),
				$self->_add_email( $zilla ),
				$self->_add_irc( $zilla ),
				$self->_add_bugs( $zilla, $input->{'distmeta'} ),
				$self->_add_repo( $zilla ),
			],
		} ),
	);
}

sub _add_email {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! defined $self->email;

	# pause id for email?
	my $address = $self->email;
	if ( $address !~ /\@/ ) {
		$address = 'C<' . uc( $address ) . ' at cpan.org>';
	} else {
		$address = "C<$address>";
	}

	my $content = join( "\n", @{ $self->email_content } );
	$content =~ s/\{EMAIL\}/$address/;

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Email',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $content,
			} ),
		],
	} );
}

sub _add_bugs {
	my( $self, $zilla, $distmeta ) = @_;

	# Do we have anything to do?
	return () if $self->bugs eq 'none';

	# Which kind of text should we display?
	my $text = join( "\n", @{ $self->bugs_content } );
	if ( $self->bugs eq 'rt' ) {
		my $dist = $zilla->name;
		my $mailto = "C<bug-" . lc( $dist ) . " at rt.cpan.org>";
		my $web = "L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist>";

		$text =~ s/\{WEB\}/$web/;
		$text =~ s/\{EMAIL\}/$mailto/;
	} else {
		# code copied from Pod::Weaver::Section::Bugs, thanks RJBS!
		$zilla->log_fatal( 'No bugtracker in metadata!' ) unless exists $distmeta->{resources}{bugtracker};
		my $bugtracker = $distmeta->{resources}{bugtracker};
		my( $web, $mailto ) = @{$bugtracker}{qw/web mailto/};
		$zilla->log_fatal( 'No bugtracker in metadata!' ) unless defined $web || defined $mailto;

		$text =~ s/\{WEB\}/L\<$web\>/ if defined $web;
		$text =~ s/\{EMAIL\}/C\<$mailto\>/ if defined $mailto;

		# sanity check the content
		if ( $text =~ /\{WEB\}/ ) {
			$zilla->log_fatal( "The metadata doesn't have a website for the bugtracker but you specified it in the bugs_content!" );
		}
		if ( $text =~ /\{EMAIL\}/ ) {
			$zilla->log_fatal( "The metadata doesn't have an email for the bugtracker but you specified it in the bugs_content!" );
		}
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Bugs / Feature Requests',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $text,
			} ),
		],
	} );
}

sub _add_perldoc {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! $self->perldoc;

	my $perl_name = $zilla->name;
	$perl_name =~ s/-/::/g;

	# TODO add language detection as per RT#63726

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Perldoc',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
			content => <<'EOPOD',
You can find documentation for this module with the perldoc command.
EOPOD

			} ),
			Pod::Elemental::Element::Pod5::Verbatim->new( {
				content => "  perldoc $perl_name",
			} ),
		],
	} );
}

sub _add_irc {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! scalar @{ $self->irc };

	my @networks;
	foreach my $entry ( @{ $self->irc } ) {
		# Split it into fields
		my @data = split( /\,/, $entry );
		$_ =~ s/^\s+//g for @data;
		$_ =~ s/\s+$//g for @data;

		# Add the network data!
		my $net = shift @data;
		my @chans;
		my @nicks;
		foreach my $e ( @data ) {
			if ( $e =~ /^\#/ ) {
				push( @chans, $e );
			} else {
				push( @nicks, $e );
			}
		}
		my $text = "You can connect to the server at '$net'";
		if ( @chans ) {
			if ( @chans > 1 ) {
				$text .= " and join those channels: ";
				$text .= join( ' , ', @chans );
			} else {
				$text .= " and join this channel: $chans[0]";
			}
		}
		if ( @nicks ) {
			if ( @chans ) {
				$text .= " then";
			} else {
				$text .= " and";
			}

			if ( @nicks > 1 ) {
				$text .= " talk to those people for help: ";
				$text .= join( ' , ', @nicks );
			} else {
				$text .= " talk to this person for help: $nicks[0]";
			}
		}
		if ( ! @nicks ) {
			$text .= " to get help";
		}
		$text .= '.';

		push( @networks, _make_item( $net, $text ) );
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Internet Relay Chat',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => join( "\n", @{ $self->irc_content } ),
			} ),
			Pod::Elemental::Element::Nested->new( {
				command => 'over',
				content => '4',
				children => [
					@networks,
					Pod::Elemental::Element::Pod5::Command->new( {
						command => 'back',
						content => '',
					} ),
				],
			} ),
		],
	} );
}

sub _add_repo {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if $self->repository_link eq 'none';

	my $repo;
	if ( exists $zilla->distmeta->{resources}{repository} ) {
		$repo = $zilla->distmeta->{resources}{repository};
	} else {
		$zilla->log_fatal( [ "Repository information missing and you wanted: %s", $self->repository_link ] );
	}

	my $text = join( "\n", @{ $self->repository_content } );
	$text .= "\n"; # for the links to be appended

	# for dzil v3 with CPAN Meta v2
	if ( ref $repo ) {
		# add the web url?
		if ( $self->repository_link eq 'web' or $self->repository_link eq 'both' ) {
			if ( exists $repo->{web} ) {
				$text .= 'L<' . $repo->{web} . ">";
			} else {
				$zilla->log_fatal("Expected to find 'web' repository link but it is missing in the metadata!");
			}
		}

		if ( $self->repository_link eq 'url' or $self->repository_link eq 'both' ) {
			if ( ! exists $repo->{url} ) {
				$zilla->log_fatal("Expected to find 'url' repository link but it is missing in the metadata!");
			}

			if ( $self->repository_link eq 'both' ) {
				$text .= "\n\n";
			}

			# do we have a type?
			$text .= '  ';
			if ( exists $repo->{type} ) {
				# list of repo types taken from Dist::Zilla::Plugin::Repository v0.16
				if ( $repo->{type} eq 'git' ) {
					$text .= 'git clone';
				} elsif ( $repo->{type} eq 'svn' ) {
					$text .= 'svn checkout';
				} elsif ( $repo->{type} eq 'darcs' ) {
					$text .= 'darcs get';
				} elsif ( $repo->{type} eq 'hg' ) {
					$text .= 'hg clone';
				} else {
					# TODO add support for other formats? cvs/bzr? they're not in DZP::Repository...
				}

				$text .= ' ' . $repo->{url};
			} else {
				$text .= $repo->{url};
			}
		}
	} else {
		$zilla->log_warning("You need to update Dist::Zilla::Plugin::Repository to at least v0.15 for the correct metadata!");
		$text .= "L<$repo>";
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Source Code',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $text,
			} ),
		],
	} );
}

sub _add_websites {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! scalar @{ $self->websites };
	return () if grep { $_ eq 'none' } @{ $self->websites };

	# explode CSV lists
	my @newlist;
	foreach my $w ( @{ $self->websites } ) {
		if ( $w =~ /,/ ) {
			my @list = split( /\,/, $w );
			$_ =~ s/^\s+//g for @list;
			$_ =~ s/\s+$//g for @list;
			push( @newlist, @list );
		} else {
			$w =~ s/^\s+//g;
                        $w =~ s/\s+$//g;
			push( @newlist, $w );
		}
	}
	@{ $self->websites } = @newlist;

	# sanity check
	foreach my $type ( @{ $self->websites } ) {
		if ( $type !~ /^(?:search|rt|anno|ratings|forum|kwalitee|testers|testmatrix|deps|all)$/i ) {
			$zilla->log_fatal( "Unknown website type: $type" );
		}
	}

	# Set the default ordering for "all"
	if ( grep { $_ eq 'all' } @{ $self->websites } ) {
		@{ $self->websites } = qw( search rt anno ratings forum kwalitee testers testmatrix deps );
	}

	# Make the website links!
	my @links;
	my %seen_type;
	foreach my $type ( @{ $self->websites } ) {
		next if $seen_type{$type}++;
		$type = '_add_websites_' . $type;
		my $main_module = $zilla->main_module->name;
		$main_module =~ s|^lib/||i;
		$main_module =~ s/\.pm$//;
		$main_module =~ s|/|::|g;
		push( @links, $self->$type( $zilla->name, $main_module ) );
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Websites',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => join( "\n", @{ $self->websites_content } ),
			} ),
			Pod::Elemental::Element::Nested->new( {
				command => 'over',
				content => '4',
				children => [
					@links,
					Pod::Elemental::Element::Pod5::Command->new( {
						command => 'back',
						content => '',
					} ),
				],
			} ),
		],
	} );
}

sub _add_websites_search {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'Search CPAN', <<"EOF" );
The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/$dist>
EOF
}

sub _add_websites_rt {
	my( $self, $dist, $module ) = @_;

	return _make_item( "RT: CPAN's Bug Tracker", <<"EOF" );
The default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist>
EOF
}

sub _add_websites_anno {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'AnnoCPAN', <<"EOF" );
AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/$dist>
EOF
}

sub _add_websites_ratings {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'CPAN Ratings', <<"EOF" );
CPANRatings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/$dist>
EOF
}

sub _add_websites_forum {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'CPAN Forum', <<"EOF" );
The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/$dist>
EOF
}

sub _add_websites_kwalitee {
	my( $self, $dist, $module ) = @_;

	# TODO add link for http://perl-qa.hexten.net/wiki/index.php/Kwalitee ?
	return _make_item( 'CPANTS', <<"EOF" );
The CPANTS service analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/$dist>
EOF
}

sub _add_websites_testers {
	my( $self, $dist, $module ) = @_;

	my $first_char = substr( $dist, 0, 1 );

	return _make_item( 'CPAN Testers', <<"EOF" );
The CPAN Testers service is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/$first_char/$dist>
EOF
}

sub _add_websites_testmatrix {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'CPAN Testers Matrix', <<"EOF" );
The CPAN Testers Matrix provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=$dist>
EOF
}

sub _add_websites_deps {
	my( $self, $dist, $module ) = @_;

	return _make_item( 'CPAN Testers Dependencies', <<"EOF" );
The CPAN Testers Dependencies chart shows the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=$module>
EOF
}

sub _make_item {
	my( $title, $contents ) = @_;

	my $str = $title;
	if ( defined $contents ) {
		$str .= "\n\n$contents";
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'item',
		content => '*',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $str,
			} ),
		],
	} );
}

1;

=pod

=for stopwords dist dzil repo

=for Pod::Coverage weave_section mvp_multivalue_args

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that lists the various ways to get support
for this module. It will do this only if it is being built with L<Dist::Zilla>
because it needs the data from the dzil object.

If you have L<Dist::Zilla::Plugin::Repository> enabled in your F<dist.ini>, be sure to check the
repository_link attribute!

This is added B<ONLY> to the main module's POD, because it would be a waste of space to add it to all
modules in the dist.

For an example of what the hunk looks like, look at the L</SUPPORT> section in this POD :)

=cut
