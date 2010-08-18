package Data::PSQueue;
use strict;
use warnings;

use version;
our $VERSION = qv(0.0.0);

use Class::InsideOut qw(:std);
use Data::PSQueue::Void;
use Data::PSQueue::Winner;
use Data::PSQueue::LTree;
use Data::PSQueue::Binding;

private letter => my %letter;

### CONSTRUCTORS
sub empty {
    my $self = register(shift);
    $letter{ id $self } = Data::PSQueue::Void->new;
    return $self;
}

sub singleton {
    my ($class, $key, $prio) = @_;
    my $self = register($class);
    $letter{ id $self } = Data::PSQueue::Winner->new({
        binding => Data::PSQueue::Binding->new({ key => $key, prio => $prio }),
        ltree   => Data::PSQueue::LTree->new,
        max_key => $key
    });
    return $self;
}

sub from_hashref {
    my $self = register(shift);
    if (defined $_[0] && scalar(keys %{$_[0]}) > 0) {
        ## TODO
        $letter{ id $self } = Data::PSQueue::Winner->new(shift);
    } else {
        $letter{ id $self } = Data::PSQueue::Void->new;
    }
    return $self;
}

### METHODS
sub null {
    return $letter{ id shift }->null;
}

sub size {
    return $letter{ id shift }->size;
}

sub find_min {
    return $letter{ id shift }->find_min;
}

sub delete_min {
    my $self = shift;
    my ($letter, $min) = $letter{ id $self }->delete_min;
    $letter{ id $self } = $letter;
    return $min;
}

sub lookup {
    return $letter{ id shift }->lookup(shift);
}

sub insert {
    my ($self, $key, $prio) = @_;
    $letter{ id $self } = $letter{ id $self }->insert($key, $prio);
    return $self;
}

sub delete {
    my $self = shift;
    $letter{ id $self } = $letter{ id $self }->delete(shift);
    return $self;
}

sub to_array {
    return $letter{ id shift }->to_array;
}

### INTERNAL METHODS

# _play :: PSQueue -> PSQueue -> PSQueue
sub _play {
    my ($self, $other) = @_;
    if ($other->null) {
        $letter{ id $self } = $letter{ id $self }->_play(Data::PSQueue::Void->new);
    } else {
        $letter{ id $self } = $letter{ id $self }->_play(
            Data::PSQueue::Winner->new({
                binding => $other->_binding,
                ltree   => $other->_ltree,
                max_key => $other->_max_key
            })
        );
    }
    return $self;
}

sub _binding {
    return $letter{ id shift }->binding;
}

sub _ltree {
    return $letter{ id shift }->ltree;
}

sub _max_key {
    return $letter{ id shift }->max_key;
}

1;
__END__

=head1 NAME

Data::PSQueue - [One line description of module's purpose here]


=head1 VERSION

This document describes Data::PSQueue version 0.0.1


=head1 SYNOPSIS

    use Data::PSQueue;
    my $q = Data::PSQueue->empty;
    my $q = Data::PSQueue->singleton("item", 0);

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 CONSTRUCTORS

=head2 empty

    my $q = Data::PSQueue->empty;

Creates an empty priority search queue.

=head2 singleton

    my $q = Data::PSQueue->singleton('key', 0);

Create a priority search queue which contains a given binding.

=head2 from_hashref

    my $q = Data::PSQueue->from_hashref({ 'key1' => 0, 'key2' => 100 });

Create a priority search queue which contains elements that gave
as the hash reference.

=head1 METHODS

=head2 null

    $q->null; # 1 or 0

Tests the queue is empty or not.

=head2 size

    $q->size;

Returns a number of elements of the queue.

=head2 find_min

=head2 delete_min

=head2 lookup($key)

=head2 insert($key, $prio)

=head2 delete($key)

=head2 to_array

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Data::PSQueue requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-psqueue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Mitsutoshi Aoe  C<< <maoe.maoe@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Mitsutoshi Aoe C<< <maoe.maoe@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
