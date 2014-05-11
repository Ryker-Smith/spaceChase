#!/usr/bin/perl
use strict;

# Creator: Eoin Kearney
# Space Chase 
# 1/2014

use SDL;
use SDL::Video;
use SDLx::App;
use SDL::Surface;
use SDL::Rect;
use SDL::Image;
use SDL::Event;
use SDL::Mouse;
use SDLx::Text;
use SDL::GFX::Rotozoom;
use SDLx::Music;
use SDLx::Sound;

# constants 
use constant bottomLimit=>750;
use constant screenWidth => 600;
use constant screenHeight => 800;
use constant some_basic_value => 50;
# for testing:
use constant canDie => 1;
# max number of random asteroids
# use constant $maxRocks => 5;
use constant rockSpeed => 15;
use constant repeatDuration => 10;
use constant everyDuration => 40;
use constant maxLives => 3;
use constant showLivesStartX => 400;
use constant showLivesStartY => 20;
use constant shipStartX => 200;
use constant shipStartY => 650;
use constant asteroidUpScore => 500;
use constant livesUpScore => 2500;

my $maxRocks = 1;
# How many lives??
my $lives=maxLives;
#
my ($app, $background, $backgroundRect, $event, $filename, $goodguy, $goodguyRect, $goodguyX, $goodguyY, $music, $playing);
my ($granularity, $goodguyX_min, $goodguyX_max, $goodguyY_min, $goodguyY_max);
my ($cover);
my ($coverRect, $old_x);
my ($goodguyMaster);
my ($objectRect, $objectStart, $objectMaster);
my ($object, $objectImage, @allObjects);
my ($old_ship_x, $old_ship_y);
my ($new_badguy_rect);

###################################################################

$goodguyX = shipStartX;
$goodguyY = shipStartY;
# Min & Max for the X co-ordinates 
$goodguyX_min = 0;
$goodguyX_max = 540;
# sets the movement speed for the space ship
$granularity = 30;
# Min & Max for the Y co-ordinates
$goodguyY_min = 0;
$goodguyY_max = 720;

# First create a new App
$app = SDLx::App->new(
    title  => "Space Chase",
    width  => screenWidth, # use same width as background image
    height => screenHeight, # use same height as background image
    depth  => 16,
    exit_on_quit => 1 # Enable 'X' button
);

# Event handlers
$app->add_event_handler(\&quit_event);
$app->add_event_handler(\&key_event);
# Move handlers
$app->add_move_handler(\&collisions);
$app->add_move_handler(\&moveBadGuys);
$app->add_move_handler(\&scoreCalculate);
# Show handlers
# Must be in correct order
$app->add_show_handler(\&Level);
$app->add_show_handler(\&showGoodGuy);
$app->add_show_handler(\&showBadGuys);
$app->add_show_handler(\&scoreUpdate);
$app->add_show_handler(\&showLives);

# The music is played here.
# Loop is set to 0 so it loops indefinitely
$music = SDLx::Music->new();
$music->data(music => 'Exhilarate.ogg');
$music->play($music->data('music'), loops => 0);

# Set up the background image + rectangle
$filename = "images/background.png";
$background = SDL::Image::load( $filename);
$cover = $background;
$backgroundRect = SDL::Rect->new(0,0,$background->w,$background->h);

# The good guy
$filename = "images/spaceship04.png";
$goodguy = SDL::Image::load( $filename);
# make master recatngle for later copying
$goodguyMaster = SDL::Rect->new(0,0,$goodguy->w,$goodguy->h);

# The image that will be falling down
$filename = "images/asteroid05.png";
# Load asteroids
$objectImage = SDL::Image::load( $filename);

# The asteroids location
$objectMaster = SDL::Rect->new(0,0, $objectImage->w,$objectImage->h);

# scores:
my ($score, $scoreBanner, $scoreMaster, $scoreRect, $scoreText, @scoreDigits);
$filename = "images/ScoreBanner.png";
$scoreBanner = SDL::Image::load( $filename);
$scoreMaster=SDL::Rect->new(0,0, $scoreBanner->w,$scoreBanner->h);
# a text box for the score
$scoreText = SDLx::Text->new(size=>'32', # font can also be specified
                            color=>[229,202,122], # [R,G,B]
                            x =>150,
                            y=> 25);
$score=0;
$scoreText->write_to($app,"$score");
$scoreRect= SDL::Rect->new(0,0,$scoreBanner->w,$scoreBanner->h);

# collision info
my ($collisionBanner, $collisionMaster, $collisionRect);
$filename = "images/CollisionAdvisory.png";
$collisionBanner = SDL::Image::load( $filename);
$collisionMaster=SDL::Rect->new(0,0, $collisionBanner->w,$collisionBanner->h);
# have to calculate how to center on x-axis:
$collisionRect= SDL::Rect->new( (screenWidth-$collisionBanner->w)/2, 100,$collisionBanner->w,$collisionBanner->h);

# loop to create random asteroids
for (my $i=0; $i<$maxRocks; $i++) {
  $object={};
  $object->{image}=$objectImage;
  $object->{x}= randStartRockX();
  $object->{y} = randStartRockY();
  $object->{rect}= SDL::Rect->new($object->{x}, $object->{y}, $object->{image}->w, $object->{image}->h);;
  push @allObjects, $object;
}

$goodguyRect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);

# set key repeat on after Xs, then every Yms
SDL::Events::enable_key_repeat(repeatDuration, everyDuration);
$app->add_show_handler(sub{$app->sync()}); #Sync must always run LAST
# Start the game loop
$app->run;

############################################################ SUBROUTINES #########################################################################


sub quit_event {
  my ($event, $app) = @_;
	if($event->type == SDL_QUIT) {
    $app->stop;
  }
}

sub key_event {
  my ($event, $app) = @_;
  my $key_name = SDL::Events::get_key_name( $event->key_sym );  
  my ( $new_ship_rect, $coverRect);
  $old_ship_y = $goodguyY;
  $old_ship_x = $goodguyX;
  if (($key_name eq "x") || ($key_name eq "X") ) {
    $app->stop;
  }
  elsif ($key_name eq "up") {
    $goodguyY -=$granularity;
    if ($goodguyY < $goodguyY_min) {
      $goodguyY = $goodguyY_min;
    }
  }
  elsif ($key_name eq "down") {
    $goodguyY +=$granularity;
    if ($goodguyY > $goodguyY_max) {
      $goodguyY = $goodguyY_max;
    }
  }
  elsif ($key_name eq "left") {  
    $goodguyX -=$granularity;
    if ($goodguyX < $goodguyX_min) {
      $goodguyX = $goodguyX_min;
    }
  }
  elsif ($key_name eq "right") {
    $goodguyX +=$granularity;
    if ($goodguyX > $goodguyX_max) {
      $goodguyX = $goodguyX_max;
    }
  }
  elsif (($key_name eq "p") || ($key_name eq "P")) {
    $app->pause();
  }
}

sub moveBadGuys {
  my ($step, $app, $t) = @_;
  foreach my $thing (@allObjects) {
  # 288 sets speed for the asteriod
    $thing->{y} += rockSpeed;
    if ($thing->{y} > bottomLimit) {
      $thing->{y} = randStartRockY();
      $thing->{x} = randStartRockX();
      # add something for each asteroid we survive?
      $score+=10;
    }
  }
}

sub showBadGuys {
  my ($delta, $app) = @_;
  foreach my $thing (@allObjects) {
    my ($badguy_x, $badguy_y) = ($thing->{x}, $thing->{y});
    my ($old_rock_x, $old_rock_y) = ($thing->{old_rock_x},$thing->{old_rock_y} );
    my $object = $thing->{image};
    if (($badguy_x != $old_rock_x) || ($badguy_y != $old_rock_y)) {
      $new_badguy_rect = SDL::Rect->new($badguy_x,$badguy_y,$object->w,$object->h);
      SDL::Video::blit_surface( $object, $objectMaster, $app, $new_badguy_rect);
    }
  }
}

sub showGoodGuy {
  my ($delta, $app) = @_;
  my ($new_ship_rect, $coverRect);
  $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
  SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );
  $coverRect = SDL::Rect->new($old_ship_x, $old_ship_y, $goodguy->w, $goodguy->h);
  SDL::Video::blit_surface ( $goodguy, $goodguyMaster, $app, $new_ship_rect);
}

sub randStartRockX {
  return int(rand(screenWidth-5))+5;
}

sub randStartRockY {
  my $y=int(rand(200));
  return (0-$y);
}

sub collisions {
  my ($step, $app, $t) = @_;
  my ($objectcenterX, $objectcenterY, $pos);
  # this may be kludgy ...
  $pos=0; # count position in array
  foreach my $thing (@allObjects) {
    if ($thing != ()) {};
    my ($objectX, $objectY) = ($thing->{x}, $thing->{y});
    # Using formula for distance between two points
    my $distance = sqrt (($objectX - $goodguyX)**2 + ($objectY - $goodguyY)**2);
    $distance=int($distance);
    if (($distance < some_basic_value) && (canDie)) {
      $lives--;
      $goodguyX = shipStartX;
      $goodguyY = shipStartY;
      showLives();
      # show collision msg
      SDL::Video::blit_surface ( $collisionBanner, $collisionMaster, $app, $collisionRect);
      SDL::Video::update_rects($app, $collisionRect);
      # if more than one array element (asteroids), use splice to remove the
      # one we've just hit
      if (scalar @allObjects > 1) {
        splice @allObjects, $pos ,1;
      }
      # pause for applause
      $app->pause;
      #
      if ($lives == 0) {
        my $snd = SDLx::Sound->new();
        # loads and plays a single sound now
        $snd->play('youdead.wav');
        # but give OS time to send it to the audio card
        sleep 1;
        print "You've been hit!\n";
        print "Your score was $score\n";
        SDL::Video::blit_surface( $background, $backgroundRect, $app, $backgroundRect);

        $app->stop;
      }
      else {
        # if we're not dead, then hop out of loop cleanly
        last;
      }
    }
    $pos++;
  }
}

sub scoreCalculate {
  my ($step, $app, $t) = @_;
  $score++;
}

sub scoreUpdate {
  my ($delta, $app) = @_;
  SDL::Video::blit_surface ( $scoreBanner, $scoreMaster, $app, $scoreRect);
  $scoreText->write_to($app, $score);
}

sub Level {
  my ($event, $app) = @_;
  # Checks if score is multiple of 500
  # If so, adds another asteroid
  if ($score % asteroidUpScore == 0) {
    $object={};
    $object->{image}=$objectImage;
    $object->{x}= randStartRockX();
    $object->{y} = randStartRockY();
    $object->{rect}=SDL::Rect->new($object->{x}, $object->{y}, $object->{image}->w, $object->{image}->h);;
    push @allObjects, $object;
  }
  # every 2500 points, add 1 life
  if ( ($score % livesUpScore == 2500) && ($lives < maxLives) ){
    $lives++;
  }
}

sub showLives {
  my ($delta, $app) = @_;
  #my $score_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
  #SDL::Video::blit_surface ( $goodguy, $goodguyMaster, $app, $score_ship_rect);
  my ($zoom_x, $zoom_y)=(.5, .5);
  my $squashed = SDL::GFX::Rotozoom::surface_xy( $goodguy, 0, $zoom_x, $zoom_y, SMOOTHING_ON );
  foreach (1..$lives) {
    SDL::Video::blit_surface( $squashed, SDL::Rect->new(0, 0, $squashed->w, $squashed->h),
                              $app,  SDL::Rect->new(showLivesStartX+(($squashed->w+5) * $_), showLivesStartY, 0, 0) );
  }
}