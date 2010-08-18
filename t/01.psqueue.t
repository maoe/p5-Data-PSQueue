use strict;
use warnings;

Data::PSQueue::Test->runtests;

package Data::PSQueue::Test;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Data::PSQueue;
use Data::Dumper;

sub setup: Test(setup) {
    my $self = shift;
    $self->{emptyq}  = Data::PSQueue->empty;
    $self->{singleq} = Data::PSQueue->singleton('key', 0);
    $self->{someq}   = Data::PSQueue->from_hashref({
        'key1' => 10,
        'key2' => 1000,
        'key3' => 0,
        'key4' => 100
    });
}

sub constructors: Tests(11) {
    my $self = shift;
    isa_ok($self->{emptyq},  'Data::PSQueue');
    isa_ok($self->{singleq}, 'Data::PSQueue');

    my $empty_hashq = Data::PSQueue->from_hashref;
    isa_ok($empty_hashq, 'Data::PSQueue');
    ok($empty_hashq->null);
    is($empty_hashq->size, 0);

    $empty_hashq = Data::PSQueue->from_hashref({});
    isa_ok($empty_hashq, 'Data::PSQueue');
    ok($empty_hashq->null);
    is($empty_hashq->size, 0);

    my $some_hashq = Data::PSQueue->from_hashref({
        'key1' => 0,
        'key2' => 100,
        'key3' => 10
    });
    isa_ok($some_hashq, 'Data::PSQueue');
    ok(!$some_hashq->null);
    is($some_hashq->size, 3);
}

sub null: Tests(2) {
    my $self = shift;
    ok($self->{emptyq}->null);
    ok(!$self->{singleq}->null);
}

sub size: Tests(2) {
    my $self = shift;
    is($self->{emptyq}->size, 0);
    is($self->{singleq}->size, 1);
}

sub find_min_from_empty: Tests(1) {
    my $self = shift;
    my $min = $self->{emptyq}->find_min;
    ok(!defined $min);
}

sub find_min_from_singleton: Tests(5) {
    my $self = shift;
    # my $min = $self->{singleq}->find_min;
    my $min = Data::PSQueue->singleton('key', 0)->find_min;
    isa_ok($min, 'Data::PSQueue::Binding');
    is($min->key, 'key');
    is($min->prio, 0);
    ok(!$self->{singleq}->null);
    is($self->{singleq}->size, 1);
}

sub delete_min_from_empty: Tests(3) {
    my $self = shift;
    my $min = $self->{emptyq}->delete_min;
    is($min, undef);
    ok($self->{emptyq}->null);
    is($self->{emptyq}->size, 0);
}

sub delete_min_from_singleton: Tests(5) {
    my $self = shift;
    my $min = $self->{singleq}->delete_min;
    isa_ok($min, 'Data::PSQueue::Binding');
    is($min->key, 'key');
    is($min->prio, 0);
    ok($self->{singleq}->null);
    is($self->{singleq}->size, 0);
}

sub delete_min_from_someq: Tests(no_plan) {
    my $self = shift;
    my $min = $self->{someq}->delete_min;
    isa_ok($min, 'Data::PSQueue::Binding');
    is($min->key, 'key3');
    is($min->prio, 0);
    ok(!$self->{someq}->null);
    is($self->{someq}->size, 3);
}

sub lookup_from_empty: Tests(1) {
    my $self = shift;
    is($self->{emptyq}->lookup('a'), undef);
}

sub lookup_from_singleton: Tests(2) {
    my $self = shift;
    is($self->{singleq}->lookup('key'), 0);
    is($self->{singleq}->lookup('kez'), undef);
}

sub lookup: Tests(no_plan) {
    my $self = shift;
    my $iteration = 30;

    for my $i (0..$iteration-1) {
        $self->{emptyq}->insert(sprintf("x%04d", $i), $i);
    }
    for my $i (0..$iteration-1) {
        is($self->{emptyq}->lookup(sprintf("x%04d", $i)), $i);
    }
}

sub insert_from_empty: Tests(3) {
    my $self = shift;
    my $inserted = $self->{emptyq}->insert('key', 100);
    isa_ok($inserted, 'Data::PSQueue');
    ok(!$inserted->null);
    is($inserted->size, 1);
}

sub insert_from_singleton: Tests(3) {
    my $self = shift;
    my $inserted = $self->{singleq}->insert('key2', 100);
    ok($inserted, $self->{singleq});
    ok(!$inserted->null);
    is($inserted->size, 2);
}

sub insert: Tests(no_plan) {
    my $self = shift;
    for my $i (1..100) {
        $self->{emptyq}->insert("$i", rand(10000));
    }
    ok(!$self->{emptyq}->null);
    is($self->{emptyq}->size, 100);
}

sub delete_from_empty: Tests(4) {
    my $self = shift;
    $self->{emptyq}->delete('key');
    ok($self->{emptyq}->null);
    is($self->{emptyq}->size, 0);
    $self->{emptyq}->delete('dummy');
    ok($self->{emptyq}->null);
    is($self->{emptyq}->size, 0);
}

sub delete_from_singleton: Tests(6) {
    my $self = shift;
    $self->{singleq}->delete('dummy');
    ok(!$self->{singleq}->null);
    is($self->{singleq}->size, 1);
    $self->{singleq}->delete('key');
    ok($self->{singleq}->null);
    is($self->{singleq}->size, 0);
    $self->{singleq}->delete('dummy');
    ok($self->{singleq}->null);
    is($self->{singleq}->size, 0);
}

sub to_array_from_empty: Tests(1) {
    my $self = shift;
    my @a = $self->{emptyq}->to_array;
    is(@a, 0);
}

sub to_array_from_singleton: Tests(4) {
    my $self = shift;
    my @a = $self->{singleq}->to_array;
    is(@a, 1);
    isa_ok($a[0], 'Data::PSQueue::Binding');
    is($a[0]->key, 'key');
    is($a[0]->prio, 0);
}

sub to_array: Tests(no_plan) {
    my $self = shift;
    my $iteration = 30;

    for my $i (0..$iteration-1) {
        $self->{emptyq}->insert(sprintf("x%04d", $i), $i);
        is($self->{emptyq}->size, $i+1);
    }

    my @a = $self->{emptyq}->to_array;
    is(scalar @a, $iteration);
    for my $i (0..$iteration-1) {
        is($a[$i]->key, sprintf("x%04d", $i));
        is($a[$i]->prio, $i);
    }
}

sub senario_tournament: Tests(no_plan) {
    my $q = Data::PSQueue->singleton("Nigel", 7);
    $q->insert("Doaitse", 2);
    $q->insert("Lambert", 3);
    $q->insert("Ade", 4);
    $q->insert("Vladimir", 8);
    $q->insert("Elco", 1);
    $q->insert("Johan", 6);
    $q->insert("Piet", 5);

    is($q->size, 8);
    is($q->lookup('Elco'), 1);
    is($q->lookup('dummy'), undef);

    my $min = $q->find_min;
    is($min->key, "Elco");
    is($min->prio, 1);

    my @a = $q->to_array;
    is(scalar @a, 8);
    is($a[0]->key, "Ade");
    is($a[0]->prio, 4);

    $min = $q->delete_min;
    is($min->key, "Elco");
    is($min->prio, 1);
    is($q->size, 7);
    is($q->lookup('Elco'), undef);

    $min = $q->find_min;
    is($min->key, "Doaitse");
    is($min->prio, 2);

    @a = $q->to_array;
    is(scalar @a, 7);
    is($a[0]->key, "Ade");
    is($a[0]->prio, 4);

    $q->delete('Johan');
    is($q->size, 6);
    is($min->key, "Doaitse");
    is($min->prio, 2);
    @a = $q->to_array;
    is(scalar @a, 6);
    is($a[0]->key, "Ade");
    is($a[0]->prio, 4);
    for my $binding (@a) {
        cmp_ok($binding->key, 'ne', 'Johan');
    }
    is($q->lookup('Johan'), undef);
}

1;
__END__
