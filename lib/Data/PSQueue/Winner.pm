package Data::PSQueue::Winner;
use strict;
use warnings;
use Class::InsideOut qw(:std new);
use base qw(Data::PSQueue);
use Switch;

readonly binding => my %binding;
readonly ltree   => my %ltree;
readonly max_key => my %max_key;

### METHODS

sub null {
    return 0;
}

sub size {
    return shift->ltree->size + 1;
}

sub find_min {
    return shift->binding;
}

sub delete_min {
    my $self = shift;
    my $min  = $self->binding;

    if ($self->size == 1) {
        return (Data::PSQueue::Void->new, $min);
    } else {
        my $ltree = $self->ltree;
        my $new;
        if ($ltree->_binding->key le $ltree->_key) {
            my ($tr) = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_right,
                max_key => $self->max_key
            })->delete_min;
            ($new) = Data::PSQueue::Winner->new({
                binding => $ltree->_binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            })->_play($tr);
        } else {
            my ($tl) = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            })->delete_min;
            ($new) = $tl->_play(
                Data::PSQueue::Winner->new({
                    binding => $ltree->_binding,
                    ltree   => $ltree->_right,
                    max_key => $self->max_key
                })
            );
        }
        return ($new, $min);
    }
}

# lookup :: Winner -> k -> Maybe p
sub lookup {
    my ($self, $key) = @_;
    my $cur = $self;
    my $ret;

    while (1) {
        if ($cur->size == 1) {
            $ret = ($key eq $cur->binding->key) ? $cur->binding->prio : undef;
            last;
        } else {
            my $lt = $cur->ltree;
            my $tl;
            my $tr;

            if ($lt->_binding->key le $lt->_key) {
                # Winner b' tl k `play` Winner b tr m
                $tl = Data::PSQueue::Winner->new({
                    binding => $lt->_binding,
                    ltree   => $lt->_left,
                    max_key => $lt->_key
                });
                $tr = Data::PSQueue::Winner->new({
                    binding => $cur->binding,
                    ltree   => $lt->_right,
                    max_key => $cur->max_key
                });
            } else {
                # Winner b tl k `play` Winner b' br m
                $tl = Data::PSQueue::Winner->new({
                    binding => $cur->binding,
                    ltree   => $lt->_left,
                    max_key => $lt->_key
                });
                $tr = Data::PSQueue::Winner->new({
                    binding => $lt->_binding,
                    ltree   => $lt->_right,
                    max_key => $cur->max_key
                });
            }
            # lookup k (tl `play` tr)
            if ($key le $tl->max_key) {
                # | k <= max-key tl = lookup k tl
                $cur = $tl;
            } else {
                # | otherwise       = lookup k tr
                $cur = $tr;
            }
        }
    }
    return $ret;
}

# insert :: Winner -> (k :-> p) -> Winner
sub insert {
    my ($self, $key, $prio) = @_;
    my $binding = Data::PSQueue::Binding->new({
        key  => $key,
        prio => $prio
    });

    if ($self->size == 1) {
        switch ($key cmp $self->binding->key) {
            case -1 {
                return Data::PSQueue::Winner->new({
                    binding => $binding,
                    ltree   => Data::PSQueue::LTree->new,
                    max_key => $key
                })->_play($self);
            }
            case 0 {
                $binding{ id $self } = $binding;
                $ltree{ id $self }   = Data::PSQueue::LTree->new;
                $max_key{ id $self } = $key;
                return $self;
            }
            else {
                return $self->_play(
                    Data::PSQueue::Winner->new({
                        binding => $binding,
                        ltree   => Data::PSQueue::LTree->new,
                        max_key => $key
                    })
                );
            }
        }
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($ltree->_binding->key le $ltree->_key) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::Winner->new({
                binding => $ltree->_binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            });
            $tr = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_right,
                max_key => $self->max_key
            });
        } else {
            # Winner b tl k `play` Winner b' tr m
            $tl = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            });
            $tr = Data::PSQueue::Winner->new({
                binding => $ltree->_binding,
                ltree   => $ltree->_right,
                max_key => $self->max_key
            });
        }

        # insert b (tl `play` tr)
        if ($key le $tl->max_key) {
            return $tl->insert($key, $prio)->_play($tr);
        } else {
            return $tl->_play($tr->insert($key, $prio));
        }
    }
}

# delete :: Winner -> k -> Maybe [k :-> p]
sub delete {
    my ($self, $key) = @_;

    if ($self->size == 1) {
        if ($key eq $self->binding->key) {
            return Data::PSQueue::Void->new;
        } else {
            return $self;
        }
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($ltree->_binding->key le $ltree->_key) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::Winner->new({
                binding => $ltree->_binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            });
            $tr = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_right,
                max_key => $self->max_key
            });
        } else {
            # Winner b tl k `play` Winner b' tr m
            $tl = Data::PSQueue::Winner->new({
                binding => $self->binding,
                ltree   => $ltree->_left,
                max_key => $ltree->_key
            });
            $tr = Data::PSQueue::Winner->new({
                binding => $ltree->_binding,
                ltree   => $ltree->_right,
                max_key => $self->max_key
            });
        }
        # delete k (tl `play` tr)
        if ($key le $tl->max_key) {
            return $tl->delete($key)->_play($tr);
        } else {
            return $tl->_play($tr->delete($key));
        }
    }
}

# to_array :: Winner -> [k :-> p]
sub to_array {
    my $self = shift;
    if ($self->size == 1) {
        return ($self->binding);
    } else {
        my $ltree = $self->ltree;

        # to-ord-list (t1 `play` tr) = to-ord-list tl ++ to-ord-list tr
        # Winner b (Loser b' tl k tr) m
        if ($ltree->_binding->key le $ltree->_key) {
            # Winner b' tl k `play` Winner b tr m
            return (
                Data::PSQueue::Winner->new({
                    binding => $ltree->_binding,
                    ltree   => $ltree->_left,
                    max_key => $ltree->_key
                })->to_array,
                Data::PSQueue::Winner->new({
                    binding => $self->binding,
                    ltree   => $ltree->_right,
                    max_key => $self->max_key
                })->to_array
            );
        } else {
            # Winner b tl k `play` Winner b' tr m
            return (
                Data::PSQueue::Winner->new({
                    binding => $self->binding,
                    ltree   => $ltree->_left,
                    max_key => $ltree->_key
                })->to_array,
                Data::PSQueue::Winner->new({
                    binding => $ltree->_binding,
                    ltree   => $ltree->_right,
                    max_key => $self->max_key
                })->to_array
            );
        }
    }
}

### INTERNAL METHODS

# _play :: Winner -> (Void|Winner) -> Winner
sub _play {
    my ($self, $other) = @_;
    if ($other->null) {
        # do nothing
    } elsif ($self->binding->prio <= $other->binding->prio) {
        $binding{ id $self } = $self->binding;
        $ltree{ id $self } = Data::PSQueue::LTree->new({
            binding => $other->binding,
            left    => $self->ltree,
            key     => $self->max_key,
            right   => $other->ltree
        });
        $max_key{ id $self } = $other->max_key;
    } else {
        $ltree{ id $self } = Data::PSQueue::LTree->new({
            binding => $self->binding,
            left    => $self->ltree,
            key     => $self->max_key,
            right   => $other->ltree
        });
        $binding{ id $self } = $other->binding; # This statement must be here because of a destructive assignment.
        $max_key{ id $self } = $other->max_key;
    }
    return $self;
}

1;
__END__
=head1 NAME

Data::PSQueue::Winner - [One line description of module's purpose here]


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

=head2 new

Data::PSQueue is an abstract data structure. This interface may be changed
in future versions. Therefore DO NOT depend on it. Use C<empty>, C<singleton>
or C<from_array> to construct a queue.

=head2 empty

    my $q = Data::PSQueue->empty;

Creates an empty priority search queue.

=head2 singleton($key, $priority)

    my $q = Data::PSQueue->empty;

=head2 from_hash(%hash)

=head1 METHODS

=head2 null

    $q->null; # 1 or 0

Tests the queue is empty or not.

=head2 size

    $q->size;

Returns a number of elements of the queue.

=head2 find_min

=head2 delete_min

=head2 lookup

=head2 insert

=head2 delete

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
