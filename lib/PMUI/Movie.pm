package PMUI::Movie;
use Mojo::Base 'Mojolicious::Controller';

sub query_movies {
	my $self = shift;	

    $self->scanner()->scan();
	
	my @movies = 
		$self->movieinfo()
			->search(undef, { 
			'order_by' => 'title', 
			'result_class' => 'DBIx::Class::ResultClass::HashRefInflator' 
		} );
		
	$self->render(json => \@movies);
}

1;