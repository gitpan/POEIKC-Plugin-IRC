package POEIKC::Plugin::IRC;

use strict;
use 5.008_001;
our $VERSION = '0.00_02';

use Data::Dumper;
use Class::Inspector;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Client
	Component::IRC::State
	Component::IRC::Plugin::AutoJoin
);

use POEIKC::Daemon::Utility;

sub spawn
{
	my $class = shift;
    my $self = {
        	@_
        };
    $class = ref $class if ref $class;
    bless  $self,$class ;
	POEIKC::Daemon::Utility::_DEBUG_log($self);
	my $session = POE::Session->create(
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ],
	);
	return $session->ID;
}

sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $alias = 'IKC_IRC';
	$kernel->alias_set($alias);

	$kernel->sig( HUP  => '_stop' );
	$kernel->sig( INT  => '_stop' );
	$kernel->sig( TERM => '_stop' );
	$kernel->sig( KILL => '_stop' );

	$kernel->call(
		IKC =>
			publish => $alias, [
				grep {/_respond$/} @{Class::Inspector->methods(__PACKAGE__)}
			],
	);

	POEIKC::Daemon::Utility::_DEBUG_log("alias_list"=>$kernel->alias_list());
}

sub _stop {
	my $poe = sweet_args;
}


sub test {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	POEIKC::Daemon::Utility::_DEBUG_log($kernel->alias_list());

}


sub message_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my ($request) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($request);
	my ($param, $rsvp) = @{$request};

	POEIKC::Daemon::Utility::_DEBUG_log($param);

	$kernel->yield(privmsg_notice=>$param);
	$kernel->post( IKC => post => $rsvp, 1 );
}

sub status_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my ($request) = @{$poe->args};
	my ($param, $rsvp) = @{$request};
	$kernel->post( IKC => post => $rsvp, $object->{status} );
	#POEIKC::Daemon::Utility::_DEBUG_log($object);
}


sub privmsg_notice {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $sender  = $poe->sender ;
	my $irc = $object->{irc};
	my ($pn, $conf, @msg) = (ref $poe->args->[0]->[0] eq 'HASH') ? (undef, @{$poe->args->[0]}) : @{$poe->args->[0]};
	@msg = @{$msg[0]} if ref $msg[0] eq 'ARRAY';

	$conf = eval $conf unless (ref $conf);
    $conf->{ lc $_ } = delete $conf->{$_} for keys %$conf;

	POEIKC::Daemon::Utility::_DEBUG_log($conf);
	POEIKC::Daemon::Utility::_DEBUG_log("($pn, $conf, @msg)");

	my $irchost = $conf->{connect}->{server};
	my $channel = $conf->{channel};

	POEIKC::Daemon::Utility::_DEBUG_log($irchost);

	my @msglist;
	push @msglist, /\n/ ? split /\n/, $_ : $_ for(@msg);
	$pn ||= @msglist > 1 ? 'notice' : 'privmsg';
	$pn = lc $pn;
	SWITCH: {
		( not $object->{status}->{irc_connect} ) and do {
			$object->{status}->{irc_connect}++;
			$object->{status}->{join}->{$channel}++;
			$kernel->yield('irc_connect', $conf);
			push @{$object->{status}->{msg}->{$channel}}, [$pn,\@msglist];
			last;};
		(not $object->{status}->{join}->{$channel}) and do {
			$object->{status}->{join}->{$channel}++;
			$irc->yield(join => $channel, $conf->{channel_key});
			push @{$object->{status}->{msg}->{$channel}}, [$pn,\@msglist];
			last;};
		(not $object->{status}->{joined}->{$channel}) and do {
			push @{$object->{status}->{msg}->{$channel}}, [$pn,\@msglist];
			last;};
		(@{$object->{status}->{msg}->{$channel}} >= 1) and do {
			push @{$object->{status}->{msg}->{$channel}}, [$pn,\@msglist];
			last;};
		# else
			$kernel->yield(put=>$pn, $channel, \@msglist);
	}
	POEIKC::Daemon::Utility::_DEBUG_log($object->{status}->{msg});
}

sub put {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object  = $poe->object ;
	my $irc = $object->{irc};
	my ($pn, $channel, $msg) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log("irc_join: ($pn, $channel, $msg)");
	$irc->yield($pn => $channel, $_) for @$msg;
	#$irc->yield($pn => $channel, shift(@$msg));
	#$kernel->delay(put => 0.1, $pn, $channel, $msg) if @$msg;
}

sub irc_connect {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my ($conf) = @{$poe->args};
	my $channel = $conf->{channel};
	my $key = $conf->{channel_key};
	POEIKC::Daemon::Utility::_DEBUG_log($channel);

	my $irc = POE::Component::IRC::State->spawn(
		nick     => 'poeikc_bot',
		username => 'poeikc_bot',
		ircname  => 'poeikc_bot',
		server   => 'localhost',
		port     => '6667',
		#flood=>1,
		%{$conf->{connect} || {}}
	);
	$irc->plugin_add('AutoJoin',
		POE::Component::IRC::Plugin::AutoJoin->new(
			Channels => $conf->{channel_key} ? {$channel=>$key} : [ $channel ],
		)
	);
	$irc->yield(register => 'all');
	$irc->yield('connect');

	my $irchost = $conf->{connect}->{server};
	$object->{irc} = $irc;
}



sub irc_join {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $sender  = $poe->sender ;
    my $nick = (split /!/, $_[ARG0])[0];
	my $channel = $_[ARG1];

	$object->{status}->{joined}->{$channel}++;
	my $irc = $sender->get_heap();
	POEIKC::Daemon::Utility::_DEBUG_log("irc_join: $channel");

	if ($nick eq $irc->nick_name()) {
		if($object->{status}->{msg} and $object->{status}->{msg}->{$channel}){
			while ( my $ary = shift @{$object->{status}->{msg}->{$channel}} ){
				my ($pn, $msg) = @$ary;
				POEIKC::Daemon::Utility::_DEBUG_log("irc_join: ($pn, $msg)");
				$kernel->yield(put=>$pn, $channel, $msg);
			}
		}
	}
}



1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

POEIKC::Plugin::IRC - PoCo-IKC and PoCo-IRC based irc bot.

=head1 SYNOPSIS

  $ poeikcd start -M=POEIKC::Plugin::IRC -a=irc_bot -s

and then ..

  $ poikc --alias=IKC_IRC -s message_respond  privmsg '{"channel" => "#test","connect" => {"Nick" => "poeN","Username" => "poeU","debug" => 1,"Port" => 16667,"flood" => 1,"Ircname" => "localhost"}}' AIUEO IRoHaNiHoHeTo -D

or

  $ikc_client->post_respond( 'IKC_IRC/message_respond' => ['privmsg','{"channel"=>"#test","connect"=>{"Nick"=>"poeN","Username"=>"poeU","debug"=>1,"Port"=>16667,"flood"=>1,"Ircname"=>"localhost"}}','AIUEO','IRoHaNiHoHeTo'] );


=head1 DESCRIPTION

POEIKC::Plugin::IRC is poeikcd plugin irc bot

=head1 EXAMPLES

    use strict;
    use Data::Dumper;
    use POE::Component::IKC::ClientLite;
    use Sys::Hostname;

    my %param = (
        ip      => Sys::Hostname::hostname,
        port    => 47225,
        name    => join('_'=>Sys::Hostname::hostname, ($0 =~ /(\w+)/g), $$),
    );
    my $ikc = create_ikc_client(%param);

    my $param = {
        connect=>{
            Nick=>"poeN",
            Username=>"poeU",
            Ircname=>"localhost",
            Port=>"16667",
            #debug=>1,
            flood=>1,
        },
        channel=>"#test"
    };

    my $state = 'IKC_IRC/message_respond';

    $ikc or die $POE::Component::IKC::ClientLite::error;

    my $msg = q{
    a   i   u   e   o
    ka  ki  ku  ke  ko  kya     kyu     kyo
    sa  si  su  se  so  sya     syu     syo
    ta  ti  tu  te  to  tya     tyu     tyo
    na  ni  nu  ne  no  nya     nyu     nyo
    ha  hi  hu  he  ho  hya     hyu     hyo
    ma  mi  mu  me  mo  mya     myu     myo
    ya  (i)     yu  (e)     yo
    ra  ri  ru  re  ro  rya     ryu     ryo
    wa  (i)     (u)     (e)     (o)
    ga  gi  gu  ge  go  gya     gyu     gyo
    za  zi  zu  ze  zo  zya     zyu     zyo
    da  (zi)    (zu)    de  do  (zya)   (zyu)   (zyo)
    ba  bi  bu  be  bo  bya     byu     byo
    pa  pi  pu  pe  po  pya     pyu     pyo
    };

    $ikc->post_respond( $state => ['notice'  ,$param, "-- (start) --"]);
    $ikc->post_respond( $state => ['privmsg' ,$param, "-- (1) --"]);
    $ikc->post_respond( $state => ['privmsg', $param, "Romaji-1"]);
    $ikc->post_respond( $state => ['privmsg' , $param, $msg]);

    $ikc->post_respond( $state => [$param, "-- (2) --"]);
    $ikc->post_respond( $state => [$param, "Romaji-2"]);
    $ikc->post_respond( $state => [$param, $msg]);
    $ikc->post_respond( $state => [$param, "-- (3) --"]);
    $ikc->post_respond( $state => [$param, "aiueo", "irohanihoheto"]);
    $ikc->post_respond( $state => [$param, ["AIUEO", "IROHANIHOHETO"]]);
    $ikc->post_respond( $state => [$param, "-- (end) --"]);

    print Dumper $ikc->post_respond( 'IKC_IRC/status_respond' );

    print "*"x40, "\n";

    $Data::Dumper::Terse=1;
    $Data::Dumper::Indent=0;
    $Data::Dumper::Useqq=1;
    $param = Dumper $param;
    my $cmd = qq{poikc --alias=IKC_IRC -s message_respond  privmsg '$param' AIUEO IRoHaNiHoHeTo -D};
    print $cmd,"\n";
    print `$cmd`;
    print "\n";

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<poeikcd>
L<poikc>
L<POE::Component::IRC>
L<POE::Component::IKC::ClientLite >

=cut

