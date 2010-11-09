package Pod::Weaver::Section::Support;

# ABSTRACT: add a SUPPORT pod section

use Moose 1.01;
use Moose::Autobox 0.10;

use Pod::Weaver::Role::Section 3.100710;
with 'Pod::Weaver::Role::Section';

{
	use Moose::Util::TypeConstraints 1.01;

	has repository_link => (
		is => 'ro',
		isa => enum( [ qw( both none url web ) ] ),
		default => 'url'
	);

	no Moose::Util::TypeConstraints;
}

has repository_content => (
	is => 'ro',
	isa => 'Str',
	default => <<EOPOD
The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)
EOPOD
);

sub weave_section {
	## no critic ( ProhibitAccessOfPrivateData )
	my ($self, $document, $input) = @_;

	my $zilla = $input->{zilla} or return;

	# Is this the main module POD?
	my $main = $zilla->main_module->name;
	return if $main ne $input->{filename};

	my $dist = $zilla->name;
	my $first_char = substr( $dist, 0, 1 );
	my $lc_dist = lc( $dist );
	my $perl_name = $dist;
	$perl_name =~ s/-/::/g;
	my $repository;
	my $repository_content = '';
	if ( exists $zilla->distmeta->{resources}{repository} && $self->repository_link ne 'none' ) {
		$repository = $zilla->distmeta->{resources}{repository};
		my @repo_links = $repository;

		# for dzil v3 with CPAN Meta v2
		if ( ref $repository ) {
			if( $self->repository_link eq 'both' ){
				@repo_links = @{$repository}{qw(url web)};
			} else {
				# enum restricts this value to appropriate options
				@repo_links = $repository->{ $self->repository_link };
			}
		}

		# warn the user if any of the desired links are blank
		$zilla->log_fatal("Expected repository link not found") if grep { !$_ } @repo_links;

		if ( $self->repository_content ){
			chomp($repository_content = $self->repository_content);
			$repository_content .= "\n\n";
		}
		$repository_content .= join("\n\n", map { "L<$_>" } @repo_links);
	}

	$document->children->push(
		# Add the stopwords so the spell checker won't complain!
		Pod::Elemental::Element::Pod5::Region->new( {
			format_name => 'stopwords',
			is_pod => 1,
			content => '',
			children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( {
					content => join( " ", qw( CPAN AnnoCPAN RT CPANTS Kwalitee diff ) ),
				} ),
			],
		} ),
		Pod::Elemental::Element::Nested->new( {
			command => 'head1',
			content => 'SUPPORT',
			children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( {
					content => <<EOPOD,
You can find documentation for this module with the perldoc command.
EOPOD
				} ),
				Pod::Elemental::Element::Pod5::Verbatim->new( {
					content => "  perldoc $perl_name",
				} ),
				Pod::Elemental::Element::Nested->new( {
					command => 'head2',
					content => 'Websites',
					children => [
						Pod::Elemental::Element::Nested->new( {
							command => 'over',
							content => '4',
							children => [
								_make_item( 'Search CPAN', "L<http://search.cpan.org/dist/$dist>" ),
								_make_item( 'AnnoCPAN: Annotated CPAN documentation', "L<http://annocpan.org/dist/$dist>" ),
								_make_item( 'CPAN Ratings', "L<http://cpanratings.perl.org/d/$dist>" ),
								_make_item( 'CPAN Forum', "L<http://cpanforum.com/dist/$dist>" ),
								_make_item( 'RT: CPAN\'s Bug Tracker', "L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist>" ),
								_make_item( 'CPANTS Kwalitee', "L<http://cpants.perl.org/dist/overview/$dist>" ),
								_make_item( 'CPAN Testers Results', "L<http://cpantesters.org/distro/$first_char/$dist.html>" ),
								_make_item( 'CPAN Testers Matrix', "L<http://matrix.cpantesters.org/?dist=$dist>" ),
							( defined $repository ?
								_make_item( 'Source Code Repository', $repository_content )
								: () ),
								Pod::Elemental::Element::Pod5::Command->new( {
									command => 'back',
									content => '',
								} ),
							],
						} ),
					],
				} ),
				Pod::Elemental::Element::Nested->new( {
					command => 'head2',
					content => 'Bugs',
					children => [
						Pod::Elemental::Element::Pod5::Ordinary->new( {
							content => <<EOPOD,
Please report any bugs or feature requests to C<bug-$lc_dist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.
EOPOD
						} ),
					],
				} ),
			],
		} ),
	);
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

=for Pod::Coverage weave_section

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that lists the common support websites
and an explanation of how to report bugs. It will do this only if it is being built with L<Dist::Zilla>
because it needs the data from the dzil object.

If you have L<Dist::Zilla::Plugin::Repository> enabled in your F<dist.ini>, an extra link will be added
for the repo.

This is added B<ONLY> to the main module's POD, because it would be a waste of space to add it to all
modules in the dist.

For an example of what the hunk looks like, look at the L</SUPPORT> section in this POD :)

=head1 OPTIONS

=over 4

=item * repository_link

Specify which url to use when composing the external link.
The value corresponds to the repository meta resources (for dzil v3 with CPAN Meta v2).

Valid options are: "url", "web", "both", or "none".

"both" will include links to both the "url" and "web" in separate POD paragraphs.

"none" will skip the repository item entirely.

The default is "url".

An error will be thrown if a specified link is not found
because if you said that you wanted it you probably expect it to be there.

=item * repository_content

Text displayed before the link to the source code repository.

The default is a sufficient explanation (see L</SUPPORT>).

=back

=cut
