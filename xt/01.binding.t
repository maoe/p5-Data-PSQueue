use strict;
use warnings;

Data::PSQueue::Binding::Test->runtests;

package Data::PSQueue::Binding::Test;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Data::PSQueue::Binding;

sub setup: Test(setup) {
    my $self = shift;
    $self->{binding} = Data::PSQueue::Binding->new({
        key  => 'key',
        prio => 10
    });
}

sub constructors: Tests(1) {
    new_ok('Data::PSQueue::Binding' => [{'key' => 1}]);
}

sub accessors: Tests(4) {
    my $self = shift;
    is($self->{binding}->key,  'key');
    is($self->{binding}->prio, 10);

    eval { $self->{binding}->key('other key') };
    ok($@, "Data::PSQueue::Binding::key is read-only");
    eval { $self->{binding}->prio(10) };
    ok($@, "Data::PSQueue::Binding::prio is read-only");
}

1;
__END__
