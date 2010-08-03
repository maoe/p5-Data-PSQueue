package Data::PSQueue::Binding;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(key prio compare));

sub new {
    my ($class, $key, $prio) = @_;
    my $self = $class->SUPER::new;
    $self->key($key);
    $self->prio($prio);
    $self->compare(
        looks_like_number($key) ?
            sub { my ($a, $b) = @_; $a <=> $b } :
            sub { my ($a, $b) = @_; $a cmp $b }
    );
    $self;
}

1;

__END__
