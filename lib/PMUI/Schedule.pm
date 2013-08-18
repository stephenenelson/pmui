package PMUI::Schedule;
use Mojo::Base 'Mojolicious::Controller';
 
sub index {
		my $self = shift;

		$self->scanner()->scan();
		
		$self->stash( 'schedule_name', $self->schedule()->name() );

		$self->stash( 'schedule', $self->schedule() );

		$self->stash( 'movies', $self->movieinfo()->search_rs(undef, { 'order_by' => 'title' } ) );

		$self->render();
}

sub schedule_entry {
	my $self = shift;

	$self->param('start_time') or die "No start time";

	my $start_time_dt =
	  DateTime::Format::DateParse->parse_datetime( $self->param('start_time'),
		$self->pmconfig->time_zone() )
	  or die "Invalid start time ", $self->param('start_time');

	my $mrl = $self->param('movie') or die "No MRL";

	my $movie_info = $self->movieinfo->find( { mrl => $mrl } )
	  or die "Couldn't find movie for mrl '$mrl'";

	my @conflicts = $self->schedule->movie_conflicts( 
		$start_time_dt->epoch(),
		$movie_info->duration()
	);

	if (scalar @conflicts) {
		die "Movie '" . $movie_info->title() . "' conflicts with: ",
			join(', ', map { $_->mrl() } @conflicts ),
			"\n";
	}
	
	$self->schema->txn_do(
		sub {

			my $schedule_row =
			  $self->schema->resultset('ScheduleEntry')->create(
				{
					'start_time'  => $start_time_dt->epoch(),
					'mrl'         => $mrl,
					'schedule_id' => $self->schedule->schedule_id
				}
			  );

			my $schedule_end_row =
			  $self->schema->resultset('ScheduleEntryEnd')->create(
				{
					'stop_time' => $start_time_dt->epoch() +
					  $movie_info->duration(),
					'schedule_entry_id' => $schedule_row->schedule_entry_id()
				}
			  );
		}
	);

	$self->redirect_to('/');
}

sub delete_schedule_entry {
	my $self = shift;

	my $entry_id = $self->param('schedule_entry_id')
		or die "Param 'schedule_entry_id' required\n";

	$self->schema->txn_do(sub {

		my $entry = $self->schema()->resultset('ScheduleEntry')->find( $entry_id )
			or die "Couldn't find schedule entry ID '$entry_id'";

		$entry->delete();

	});
	
	$self->redirect_to('/');
	
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