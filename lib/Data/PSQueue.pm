package Data::PSQueue;
use strict;
use warnings;
use Data::PSQueue::PSQ;

our $VERSION = '0.01';

sub empty {
    Data::PSQueue::PSQ->empty;
}

sub singleton {
    my ($self, $key, $prio) = @_;
    Data::PSQueue::PSQ->singleton(
        Data::PSQueue::Binding->new($key, $prio)
    );
}

1;

__END__
