package Data::PSQueue::PSQ;
use strict;
use warnings;
use Data::PSQueue::LTree;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}

sub from_ordered_list {
    my $class = shift;
    my $queue = Data::PSQueue::PSQ->empty;
    for my $binding (@_) {
       $queue = $queue->play(
           Data::PSQueue::PSQ->singleton($binding->key, $binding->prio)
       );
    }
    $queue;
}

# The constructor for the empty queue.
sub empty {
    Data::PSQueue::PSQ::Void->new;
}

# The constructor for the singleton queue.
sub singleton {
    my ($class, $binding) = @_;
    Data::PSQueue::PSQ::Winner->new(
        $binding,
        Data::PSQueue::LTree::Start->new,
        $binding->key
    );
}

package Data::PSQueue::PSQ::Void;
use strict;
use warnings;
use base qw(Data::PSQueue::PSQ);
use Data::PSQueue::Binding;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self;
}

sub is_empty {
    1;
}

sub is_singleton {
    0;
}

# Play a match
sub play {
    my ($self, $queue) = @_;
    $queue;
}

sub delete_min {
    my $self = shift;
    $self;
}

sub to_ordered_list {
    ();
}

sub lookup {
    undef;
}

sub adjust {
    my $self = shift;
    $self;
}

sub insert {
    my ($self, $key, $prio) = @_;

    Data::PSQueue::PSQ->singleton(
        Data::PSQueue::Binding->new($key, $prio)
    );
}

sub delete {
    Data::PSQueue::PSQ->empty;
}

sub find_min {
    undef;
}

package Data::PSQueue::PSQ::Winner;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Switch;
use UNIVERSAL::isa;
use base qw(Data::PSQueue::PSQ Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(binding ltree max_key));

sub new {
    my ($class, $binding, $ltree, $max_key) = @_;
    my $self = $class->SUPER::new(@_);
    $self->binding($binding);
    $self->ltree($ltree);
    $self->max_key($max_key);
    $self;
}

sub is_empty {
    0;
}

sub is_singleton {
    my $self = shift;
    defined $self->binding && $self->ltree->isa('Data::PSQueue::LTree::Start');
}

# Play a match
sub play {
    my ($self, $other) = @_;

    if ($other->is_empty) {
        $self;
    } elsif ($self->binding->prio <= $other->binding->prio) {
        Data::PSQueue::PSQ::Winner->new(
            $self->binding,
            Data::PSQueue::LTree::Loser->new(
                $other->binding,
                $self->ltree,
                $self->max_key,
                $other->ltree
            ),
            $other->max_key
        );
    } else {
        Data::PSQueue::PSQ::Winner->new(
            $other->binding,
            Data::PSQueue::LTree::Loser->new(
                $self->binding,
                $self->ltree,
                $self->max_key,
                $other->ltree
            ),
            $other->max_key
        );
    }
}


sub delete_min {
    my $self = shift;

    if ($self->is_singleton) {
        Data::PSQueue::PSQ->empty;
    } else {
        my $ltree = $self->ltree;
        my $compare = $self->binding->compare;

        if ($compare->($ltree->binding->key, $ltree->key)) {
            Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->left,
                $ltree->key
            )->play(
                Data::PSQueue::PSQ::Winner->new(
                    $self->binding,
                    $ltree->right,
                    $self->max_key
                )
            );
        } else {
            Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->left,
                $ltree->key
            )->delete_min->play(
                Data::PSQueue::PSQ::Winner->new(
                    $ltree->binding,
                    $ltree->right,
                    $self->max_key
                )
            );
        }
    }
}

# Converts a queue into a list of bindings ordered by key
sub to_ordered_list {
    my $self = shift;

    if ($self->is_singleton) {
        # to-ord-list {b} = [b]
        ($self->binding);
    } else {
        my $ltree = $self->ltree;
        my $compare = $self->binding->compare;

        # to-ord-list (t1 `play` tr) = to-ord-list tl ++ to-ord-list tr
        # Winner b (Loser b' tl k tr) m
        if ($compare->($ltree->binding->key, $ltree->key) <= 0) {
            # Winner b' tl k `play` Winner b tr m
            (
                Data::PSQueue::PSQ::Winner->new(
                    $ltree->binding,
                    $ltree->left,
                    $ltree->key
                )->to_ordered_list,
                Data::PSQueue::PSQ::Winner->new(
                    $self->binding,
                    $ltree->right,
                    $self->max_key
                )->to_ordered_list
            );
        } else {
            # Winner b tl k `play` Winner b' br m
            (
                Data::PSQueue::PSQ::Winner->new(
                    $self->binding,
                    $ltree->left,
                    $ltree->key
                )->to_ordered_list,
                Data::PSQueue::PSQ::Winner->new(
                    $ltree->binding,
                    $ltree->right,
                    $self->max_key
                )->to_ordered_list
            );
        }
    }
}

sub lookup {
    my ($self, $key) = @_;
    my $compare = $self->binding->compare;

    if ($self->is_singleton) {
        # lookup k {b}
        if ($compare->($key, $self->binding->key) == 0) {
            # | k == key b = Just (prio b)
            $self->prio;
        } else {
            # | otherwise  = Nothing
            undef;
        }
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($compare->($ltree->binding->key, $ltree->key) <= 0) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->right,
                $self->max_key
            );
        } else {
            # Winner b tl k `play` Winner b' br m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->right,
                $self->max_key
            );
        }

        # lookup k (tl `play` tr)
        if ($compare->($key, $tl->max_key) <= 0) {
            # | k <= max-key tl = lookup k tl
            $tl->lookup($key);
        } else {
            # | otherwise       = lookup k tr
            $tr->lookup($key);
        }
    }
}

sub adjust {
    my ($self, $f, $key) = @_;
    my $compare = $self->binding->compare;

    if ($self->is_singleton) {
        # adjust f k {b}
        if ($compare->($key, $self->binding->key) == 0) {
            # k == key b = {k :-> f (prio b)}
            Data::PSQueue::PSQ->singleton(Data::PSQueue::Binding->new($key, $f->($self->binding->prio)));        
        } else {
            # otherwise  = {b}
            $self;
        }
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($compare->($ltree->binding->key, $ltree->key) <= 0) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->right,
                $self->max_key
            );
        } else {
            # Winner b tl k `play` Winner b' br m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->right,
                $self->max_key
            );
        }

        # lookup k (tl `play` tr)
        if ($compare->($key, $tl->max_key) <= 0) {
            # | k <= max-key tl = adjust f k tl `play` tr
            $tl->adjust($f, $key)->play($tr);
        } else {
            # | otherwise       = tl `play` adjust f k tr
            $tl->play($tr->adjust($f, $key));
        }
    }
}

sub insert {
    my ($self, $key, $prio) = @_;
    my $binding = Data::PSQueue::Binding->new($key, $prio);
    my $compare = $self->binding->compare;

    if ($self->is_singleton) {
        # insert b {b'}
        my $ret;
        switch ($compare->($key, $self->binding->key)) {
            case -1 {
                # | key b < key b' = {b} `play` {b'}
                $ret = Data::PSQueue::PSQ->singleton($binding)->play($self);
            }
            case 0 {
                # | key b == key b' = {b}
                $ret = Data::PSQueue::PSQ->singleton($binding);
            }
            else {
                # | key b > key b' = {b'} `play` {b}
                $ret = $self->play(Data::PSQueue::PSQ->singleton($binding));
            }
        }
        $ret;
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($compare->($ltree->binding->key, $ltree->key) <= 0) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->right,
                $self->max_key
            );
        } else {
            # Winner b tl k `play` Winner b' br m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->right,
                $self->max_key
            );
        }

        # insert b (tl `play` tr)
        if ($compare->($key, $tl->max_key) <= 0) {
            # | key b <= max-key tl = insert b tl `play` tr
            $tl->insert($key, $prio)->play($tr);
        } else {
            # | otherwise           = tl `play` insert b tr
            $tl->play($tr->insert($key, $prio));
        }
    }
}

sub delete {
    my ($self, $key) = @_;
    my $compare = $self->binding->compare;

    if ($self->is_singleton) {
        # delete k {b}
        if ($compare->($key, $self->binding->key) == 0) {
            # k == key b = empty
            Data::PSQueue::PSQ->empty;
        } else {
            # otherwise  = {b}
            $self;
        }
    } else {
        my $ltree = $self->ltree;
        my $tl;
        my $tr;

        # Winner b (Loser b' tl k tr) m
        if ($compare->($ltree->binding->key, $ltree->key) <= 0) {
            # Winner b' tl k `play` Winner b tr m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->right,
                $self->max_key
            );
        } else {
            # Winner b tl k `play` Winner b' br m
            $tl = Data::PSQueue::PSQ::Winner->new(
                $self->binding,
                $ltree->left,
                $ltree->key
            );
            $tr = Data::PSQueue::PSQ::Winner->new(
                $ltree->binding,
                $ltree->right,
                $self->max_key
            );
        }

        # delete k (tl `play` tr)
        if ($compare->($key, $tl->max_key) <= 0) {
            # | k <= max-key tl = delete k tl `play` tr
            $tl->delete($key)->play($tr);
        } else {
            # | otherwise       = tl `play` delete k tr
            $tl->play($tr->delete($key));
        }
    }
}

sub find_min {
    my $self = shift;
    $self->binding;
}


1;

__END__
