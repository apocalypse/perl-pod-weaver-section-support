package Pod::Weaver::Section::Support;

# ABSTRACT: add a SUPPORT pod section

use Moose 1.03;
use Moose::Autobox 0.10;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( websites irc ) }

=attr all_modules

Enable this if you want to add the SUPPORT section to all the modules in a dist, not only the main one.

The default is false.

=cut

has all_modules => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

=attr bugs

Specify the bugtracker you want to use. You can use the CPAN RT tracker or your own, specified in the metadata.

Valid options are: "rt", "metadata", or "none"

If you pick the "rt" option, this module will generate a predefined block of text explaining how to use the RT system.

If you pick the "metadata" option, this module will check the L<Dist::Zilla> metadata for the bugtracker to display.

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

=attr perldoc

Specify if you want the paragraph explaining about perldoc to be displayed or not.

The default is true.

=cut

has perldoc => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

=attr websites

Specify what website links you want to see. This is an array, and you can pick any combination. You can also
specify it as a comma-delimited string. The ordering of the options are important, as they are reflected in
the final POD.

Valid options are: "none", "search", "rt", "anno", "ratings", "forum", "kwalitee", "testers", "testmatrix" and "all".

The default is "all".

	# Where the links go to:
	search		- http://search.cpan.org/dist/$dist
	rt		- http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist
	anno		- http://annocpan.org/dist/$dist
	ratings		- http://cpanratings.perl.org/d/$dist
	forum		- http://cpanforum.com/dist/$dist
	kwalitee	- http://cpants.perl.org/dist/overview/$dist
	testers		- http://cpantesters.org/distro/$first_char/$dist.html
	testmatrix	- http://matrix.cpantesters.org/?dist=$dist

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
	isa => 'Str',
	default => <<'EOPOD',
You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:
EOPOD

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

Text displayed before the link to the source code repository.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

has repository_content => (
	is => 'ro',
	isa => 'Str',
	default => <<'EOPOD',
The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)
EOPOD

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
					content => join( " ", qw( CPAN AnnoCPAN RT CPANTS Kwalitee diff irc ) ),
				} ),
			],
		} ),
		Pod::Elemental::Element::Nested->new( {
			command => 'head1',
			content => 'SUPPORT',
			children => [
				$self->_add_perldoc( $zilla ),
				$self->_add_websites( $zilla ),
				$self->_add_irc( $zilla ),
				$self->_add_bugs( $zilla, $input->{'distmeta'} ),
				$self->_add_repo( $zilla ),
			],
		} ),
	);
}

sub _add_bugs {
	my( $self, $zilla, $distmeta ) = @_;

	# Do we have anything to do?
	return () if $self->bugs eq 'none';

	my $dist = $zilla->name;
	my $lc_dist = lc( $dist );

	# Which kind of text should we display?
	my $text;
	if ( $self->bugs eq 'rt' ) {
		$text = <<"EOPOD";
Please report any bugs or feature requests by email to C<bug-$lc_dist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.
EOPOD

	} else {
		# code copied from Pod::Weaver::Section::Bugs, thanks RJBS!
		die 'No bugtracker in metadata!' unless exists $distmeta->{resources}{bugtracker};
		my $bugtracker = $distmeta->{resources}{bugtracker};
		my( $web, $mailto ) = @{$bugtracker}{qw/web mailto/};
		die 'No bugtracker in metadata!' unless defined $web || defined $mailto;

		$text = "Please report any bugs or feature requests ";

		if ( defined $web ) {
			$text .= "on the bugtracker website L<$web>";
			$text .= defined $mailto ? " or " : ".";
		}

		if ( defined $mailto ) {
			$text .= "by email to '$mailto'.";
		}

		$text .= " I will be notified, and then you'll automatically ";
		$text .= "be notified of progress on your bug as I make changes.";
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
	# TODO when I do the lang thing, make this a head2 section...
	return (
		Pod::Elemental::Element::Pod5::Ordinary->new( {
			content => <<'EOPOD',
You can find documentation for this module with the perldoc command.
EOPOD

		} ),
		Pod::Elemental::Element::Pod5::Verbatim->new( {
			content => "  perldoc $perl_name",
		} ),
	);
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
				content => $self->irc_content,
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

	my $text = $self->repository_content . "\n";

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
		if ( $type !~ /^(?:search|rt|anno|ratings|forum|kwalitee|testers|testmatrix|all)$/i ) {
			die "Unknown website type: $type";
		}
	}

	# Set the default ordering for "all"
	if ( grep { $_ eq 'all' } @{ $self->websites } ) {
		@{ $self->websites } = qw( search rt anno ratings forum kwalitee testers testmatrix );
	}

	# Make the website links!
	my @links;
	my %seen_type;
	foreach my $type ( @{ $self->websites } ) {
		next if $seen_type{$type}++;
		$type = '_add_websites_' . $type;
		push( @links, $self->$type( $zilla->name ) );
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Websites',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => <<EOPOD,
The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.
EOPOD
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
	my( $self, $dist ) = @_;

	return _make_item( 'Search CPAN', "L<http://search.cpan.org/dist/$dist>" );
}

sub _add_websites_rt {
	my( $self, $dist ) = @_;

	return _make_item( 'RT: CPAN\'s Bug Tracker', "L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist>" );
}

sub _add_websites_anno {
	my( $self, $dist ) = @_;

	return _make_item( 'AnnoCPAN: Annotated CPAN documentation', "L<http://annocpan.org/dist/$dist>" );
}

sub _add_websites_ratings {
	my( $self, $dist ) = @_;

	return _make_item( 'CPAN Ratings', "L<http://cpanratings.perl.org/d/$dist>" );
}

sub _add_websites_forum {
	my( $self, $dist ) = @_;

	return _make_item( 'CPAN Forum', "L<http://cpanforum.com/dist/$dist>" );
}

sub _add_websites_kwalitee {
	my( $self, $dist ) = @_;

	return _make_item( 'CPANTS Kwalitee', "L<http://cpants.perl.org/dist/overview/$dist>" );
}

sub _add_websites_testers {
	my( $self, $dist ) = @_;

	my $first_char = substr( $dist, 0, 1 );

	return _make_item( 'CPAN Testers Results', "L<http://cpantesters.org/distro/$first_char/$dist.html>" );
}

sub _add_websites_testmatrix {
	my( $self, $dist ) = @_;

	return _make_item( 'CPAN Testers Matrix', "L<http://matrix.cpantesters.org/?dist=$dist>" );
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

This section plugin will produce a hunk of pod that lists the common support websites
and an explanation of how to report bugs. It will do this only if it is being built with L<Dist::Zilla>
because it needs the data from the dzil object.

If you have L<Dist::Zilla::Plugin::Repository> enabled in your F<dist.ini>, be sure to check the
repository_link attribute!

This is added B<ONLY> to the main module's POD, because it would be a waste of space to add it to all
modules in the dist.

For an example of what the hunk looks like, look at the L</SUPPORT> section in this POD :)

=cut
