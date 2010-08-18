use strict;
use warnings;

Data::PSQueue::LTree::Test->runtests;

package Data::PSQueue::LTree::Test;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Data::PSQueue::LTree;

sub setup: Test(setup) {
    my $self = shift;
    $self->{start} = Data::PSQueue::LTree->new;
}

sub constructors: Tests(2) {
    new_ok('Data::PSQueue::LTree');
    isa_ok(Data::PSQueue::LTree->new, 'Data::PSQueue::LTree');
}

sub null: Test {
    my $self = shift;
    ok($self->{start}->null);
}

sub size: Test {
    my $self = shift;
    is($self->{start}->size, 0);
}

1;
__END__
