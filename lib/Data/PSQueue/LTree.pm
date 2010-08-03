package Data::PSQueue::LTree;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self;
}


package Data::PSQueue::LTree::Start;
use strict;
use warnings;
use base qw(Data::PSQueue::LTree);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self;
}

sub is_empty {
    1;
}


package Data::PSQueue::LTree::Loser;
use strict;
use warnings;
use base qw(Data::PSQueue::LTree Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(binding left key right));

sub new {
    my ($class, $binding, $left, $key, $right) = @_;
    my $self = $class->SUPER::new(@_);
    $self->binding($binding);
    $self->left($left);
    $self->key($key);
    $self->right($right);
    $self;
}

sub is_empty {
    0;
}

1;

__END__
