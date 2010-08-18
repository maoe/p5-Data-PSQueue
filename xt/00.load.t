use Test::More tests => 6;

BEGIN {
    use_ok('Data::PSQueue::Binding');
    use_ok('Data::PSQueue::LTree');
    use_ok('Data::PSQueue::LTree::Start');
    use_ok('Data::PSQueue::LTree::Loser');
    use_ok('Data::PSQueue::Void');
    use_ok('Data::PSQueue::Winner');
}

diag("Testing internals of Data::PSQueue $Data::PSQueue::VERSION");
