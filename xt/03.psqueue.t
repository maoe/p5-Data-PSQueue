use strict;
use warnings;

Data::PSQueue::Test->runtests;

package Data::PSQueue::Test;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Data::PSQueue;

sub setup: Test(setup) {
    my $self = shift;
    $self->{void}     = Data::PSQueue->empty;
    $self->{winner_a} = Data::PSQueue->singleton('a', 100);
    $self->{winner_b} = Data::PSQueue->singleton('b', 1);
}

sub accessors: Tests(11) {
    my $self = shift;

    eval { $self->{void}->_binding };
    ok($@ , "Data::PSQueue::Void->_binding");
    eval { $self->{void}->_ltree };
    ok($@ , "Data::PSQueue::Void->_ltree");
    eval { $self->{void}->_max_key };
    ok($@ , "Data::PSQueue::Void->_max_key");

    can_ok($self->{winner_a}, '_binding');
    is($self->{winner_a}->_binding->key, 'a');
    is($self->{winner_a}->_binding->prio, 100);

    can_ok($self->{winner_a}, '_ltree');
    isa_ok($self->{winner_a}->_ltree, 'Data::PSQueue::LTree');
    ok($self->{winner_a}->_ltree->null);

    can_ok($self->{winner_a}, '_max_key');
    is($self->{winner_a}->_max_key, 'a');
}

sub psqueue_void: Tests(4) {
    my $self = shift;
    new_ok('Data::PSQueue::Void');
    my $void = Data::PSQueue::Void->new;
    isa_ok($void, 'Data::PSQueue::Void');
    ok($void->null);
    is($void->size, 0);
}

sub psqueue_winner: Tests(7) {
    my $self = shift;
    new_ok('Data::PSQueue::Winner' => [{
        binding => Data::PSQueue::Binding->new({
            key => 'k', prio => 0
        }),
        ltree   => Data::PSQueue::LTree->new,
        max_key => 'k'
    }]);
    my $winner = Data::PSQueue::Winner->new({
        binding => Data::PSQueue::Binding->new({
            key => 'k', prio => 0
        }),
        ltree   => Data::PSQueue::LTree->new,
        max_key => 'k'
    });
    isa_ok($winner, 'Data::PSQueue::Winner');
    can_ok($winner, 'binding');
    can_ok($winner, 'ltree');
    can_ok($winner, 'max_key');
    ok(!$winner->null);
    is($winner->size, 1);
}

sub play_void_void: Tests(3) {
    my $self = shift;
    my $void = Data::PSQueue->empty;
    my $played = $self->{void}->_play($void);
    isa_ok($played, 'Data::PSQueue');
    ok($played->null);
    is($played->size, 0);
}

sub play_void_winner: Tests(10) {
    my $self = shift;
    my $played = $self->{void}->_play($self->{winner_a});
    isa_ok($played, 'Data::PSQueue');
    ok(!$played->null);
    is($played->size, 1);
    isa_ok($played->_binding, 'Data::PSQueue::Binding');
    is($played->_binding->key, 'a');
    is($played->_binding->prio, 100);
    isa_ok($played->_ltree, 'Data::PSQueue::LTree');
    ok($played->_ltree->null);
    is($played->_ltree->size, 0);
    is($played->_max_key, 'a');
}

sub play_winner_void: Tests(10) {
    my $self = shift;
    my $played = $self->{winner_a}->_play($self->{void});
    isa_ok($played, 'Data::PSQueue');
    ok(!$played->null);
    is($played->size, 1);
    isa_ok($played->_binding, 'Data::PSQueue::Binding');
    is($played->_binding->key, 'a');
    is($played->_binding->prio, 100);
    isa_ok($played->_ltree, 'Data::PSQueue::LTree');
    ok($played->_ltree->null);
    is($played->_ltree->size, 0);
    is($played->_max_key, 'a');
}

sub play_winner_winner: Tests(10) {
    my $self = shift;
    my $played = $self->{winner_a}->_play($self->{winner_b});
    isa_ok($played, 'Data::PSQueue');
    ok(!$played->null);
    is($played->size, 2);
    isa_ok($played->_binding, 'Data::PSQueue::Binding');
    is($played->_binding->key, 'b');
    is($played->_binding->prio, 1);
    isa_ok($played->_ltree, 'Data::PSQueue::LTree');
    ok(!$played->_ltree->null);
    is($played->_ltree->size, 1);
    is($played->_max_key, 'b');
}

sub insert_to_void: Tests(no_plan) {
    my $self = shift;
    my $inserted = $self->{void}->insert('a', 100);
    isa_ok($inserted, 'Data::PSQueue');
    ok(!$inserted->null);
    is($inserted->size, 1);
    isa_ok($inserted->_binding, 'Data::PSQueue::Binding');
    is($inserted->_binding->key, 'a');
    is($inserted->_binding->prio, 100);
    isa_ok($inserted->_ltree, 'Data::PSQueue::LTree');
    ok($inserted->_ltree->null);
    is($inserted->_ltree->size, 0);
    is($inserted->_max_key, 'a');
}

sub insert_to_winner: Tests(no_plan) {
    my $self = shift;
    my $inserted = $self->{winner_a}->insert('b', 10);
    isa_ok($inserted, 'Data::PSQueue');
    $inserted = $self->{winner_a}->insert('c', 10);
    isa_ok($inserted, 'Data::PSQueue');
    $inserted = $self->{winner_a}->insert('d', 1000);
    isa_ok($inserted, 'Data::PSQueue');
}

1;
__END__
