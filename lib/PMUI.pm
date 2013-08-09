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

	$r->any('/')->to('schedule#index');

	$r->post('/schedule_entry')->to('schedule#schedule_entry');;

	$r->post('/delete_schedule_entry')->to('schedule#delete_schedule_entry');

}

1;