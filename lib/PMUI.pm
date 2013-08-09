package PMUI;

use Mojo::Base 'Mojolicious';

use lib "$ENV{'HOME'}/dev/Video-PlaybackMachine/lib";

use Video::PlaybackMachine::Schema;
use Video::PlaybackMachine::DirectoryScanner;
use DateTime;
use DateTime::Format::DateParse;
use Video::PlaybackMachine::Config;

sub startup {
	my $self = shift;

	$self->secret('aeHeer8e');

	$self->helper('pmconfig' => sub {
		my $config = Video::PlaybackMachine::Config->config()
			or die "Config file not found!\n";
		return $config;
	});

	$self->helper('timefmt' => sub {
		my $self = shift;
		my ($raw_time) = @_;

		my $dt = DateTime->from_epoch( epoch => $raw_time );

		$dt->set_time_zone( $self->pmconfig->time_zone() );
		return $dt->ymd . " " . $dt->hms;
	});

	$self->helper('schema' => sub {
		my $self = shift;

		my $schema = Video::PlaybackMachine::Schema->connect(
			"dbi:SQLite:dbname=" . $self->pmconfig->database(),
			'', '' );

		return $schema;
	});

	$self->helper('schedule' => sub {
		my $self = shift;

		my $schedule_name = $self->param('schedulename') // $self->pmconfig->schedule;
		my $schedule =
		  $self->schema->resultset('Schedule')->find( { name => $schedule_name } );
		return $schedule;

	});

	$self->helper('scanner' => sub {
		my $self = shift;

		my $scanner = Video::PlaybackMachine::DirectoryScanner->new(
			'directories'   => [ $self->pmconfig->movies() ],
			'schedule_name' => $self->pmconfig->schedule(),
			'schema'        => $self->schema()
		);
		return $scanner;
	});

	$self->helper('movieinfo' => sub {
		my $self = shift;

		my $movie_info_rs = $self->schema->resultset('MovieInfo');

		return $movie_info_rs;

	});
	
	my $r = $self->routes();

	$r->get('/' => sub {
		my $self = shift;

		$self->scanner()->scan();

		$self->stash( 'schedule', $self->schedule() );

		$self->stash( 'movies', $self->movieinfo()->search_rs(undef, { 'order_by' => 'title' } ) );

		$self->render('index');
	});

	$r->post('/schedule_entry' => sub {
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
	});

	$r->post('/delete_schedule_entry' => sub {
		my $self = shift;

		my $entry_id = $self->param('schedule_entry_id')
			or die "Param 'schedule_entry_id' required\n";
	
		$self->schema->txn_do(sub {
	
			my $entry = $self->schema()->resultset('ScheduleEntry')->find( $entry_id )
				or die "Couldn't find schedule entry ID '$entry_id'";
	
			$entry->delete();

		});
	
		$self->redirect_to('/');
	
	});

}

1;