package PMUI::Schedule;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my $self = shift;
	
	$self->render_static('index.html');
}
 
sub delete_entry {
	my $self = shift;

	my $entry_id = $self->param('schedule_entry_id')
		or die "Param 'schedule_entry_id' required\n";
		
	my $entry;

	$self->schema->txn_do(sub {

		$entry = $self->schema()->resultset('ScheduleEntry')->find( $entry_id )
			or die "Couldn't find schedule entry ID '$entry_id'";

		$entry->delete();

	});
	
	$self->render('json' => $entry);

}

sub schedule_json {
	my $self = shift;
	
	my @entries = $self->schedule->search_related(
		'schedule_entries', 
		undef, 
		{ 
			'result_class' => 'DBIx::Class::ResultClass::HashRefInflator', 
			'join' => ['movie_info', 'schedule_entry_end' ],
			'prefetch' => ['movie_info', 'schedule_entry_end']
		})
		->all();
	
	$self->render(json => \@entries);
}

sub add_schedule_entry {
	my $self = shift;
	
	my $data = $self->req->json;
	
	# To start, we'll assume the movie is in movie_info. 
	my $movie = $self->schema()
		->resultset('MovieInfo')
		->find({ 'mrl' => $data->{'mrl'} });
	
	my $start_time = $data->{'start_time'} or die "No start time!\n";
	
	my @conflicts = $self->schedule->movie_conflicts(
		$start_time,
		$movie->duration()
	);
	
	if (@conflicts) {
		$self->render(status => 409, json => { 'conflicts' => \@conflicts });
	}
	else {
		my $entry = $self->schedule->create_related(
			'schedule_entries',
			{
				'start_time' => $start_time,
				'mrl' => $data->{'mrl'}
			}
		);
		
		$entry->create_related(
			'schedule_entry_end',
			{
				'stop_time' => $start_time + $movie->duration()
			}
		);
		
		my %entry_hash = $entry->get_columns();
		$entry_hash{'movie_info'} = { $entry->movie_info()->get_columns() };
		$entry_hash{'schedule_entry_end'} = { $entry->schedule_entry_end()->get_columns() };
		
		$self->render( json => \%entry_hash );
	}
}

1;