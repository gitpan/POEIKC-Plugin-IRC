package POEIKC::Plugin::IRC;

use strict;
use 5.008_001;
our $VERSION = '0.00_00';

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
			publish => $alias, [qw/
				message_respond
				/],
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



# $ poeikcd start -M=POEIKC::Plugin::IRC -n=ikcircbot -a=ikcircbot -p=46667 -s


# $ poikc -D --alias=IKC_IRC  --port=46667  -s message_respond  '{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667"}, channel=>"#test"}' XYZ
# $ikc_client->post_respond( 'IKC_IRC/message_respond' => ['{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667",channel=>"#test"}}','XYZ'] );
sub message_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my ($request) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($request);
	my ($param, $rsvp) = @{$request};
	my ($conf, $msg) = @{$param};

	POEIKC::Daemon::Utility::_DEBUG_log($msg);
	POEIKC::Daemon::Utility::_DEBUG_log($conf);

	$kernel->yield('message', $conf, $msg);
	$kernel->post( IKC => post => $rsvp, 0 );
}

#$ poikc -D --alias=ikcircbot  --port=46667 IKC_IRC  message  '{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667"}, channel=>"#test"}' aiueo
# $ikc_client->post_respond( 'ikcircbot/something_respond' => ['IKC_IRC','message','{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667",channel=>"#test"}}','aiueo'] );
sub message {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $sender  = $poe->sender ;
	my $irc = $object->{irc};
	my ($conf, $msg) = @{$poe->args};

	$conf = eval $conf unless (ref $conf);
    $conf->{ lc $_ } = delete $conf->{$_} for keys %$conf;

	POEIKC::Daemon::Utility::_DEBUG_log($conf);
	POEIKC::Daemon::Utility::_DEBUG_log($msg);

	my $irchost = $conf->{connect}->{server};
	my $channel = $conf->{channel};

	POEIKC::Daemon::Utility::_DEBUG_log($irchost);

	if ( not $irc or not $object->{irc} ) {
		$kernel->yield('irc_connect', $conf,$msg);
		push @{$object->{msg}->{$channel}}, $msg;
	}elsif(not $object->{msg}->{$channel}){
		$object->{irc}->yield(join => $channel, $conf->{channel_key});
		push @{$object->{msg}->{$channel}}, $msg;
	}else{
		$object->{irc}->yield(privmsg => $channel, $msg);
	}
	POEIKC::Daemon::Utility::_DEBUG_log($object->{msg});
}

sub irc_connect {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $heap   = $poe->heap;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my ($conf, $msg) = @{$poe->args};
	my $channel = $conf->{channel};
	my $key = $conf->{channel_key};
	POEIKC::Daemon::Utility::_DEBUG_log($channel);

	my $irc = POE::Component::IRC::State->spawn(
		nick     => 'poeikc_bot',
		username => 'poeikc_bot',
		ircname  => 'poeikc_bot',
		server   => 'localhost',
		port     => '6667',
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

	my $irc = $sender->get_heap();
    my $nick = (split /!/, $_[ARG0])[0];
	my $real_channel = $_[ARG1];

	if ($nick eq $irc->nick_name()) {
		if($object->{msg} and $object->{msg}->{$real_channel}){
			while ( my $msg = shift @{$object->{msg}->{$real_channel}} ){
				$irc->yield(privmsg => $real_channel, $msg);
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

  $ poeikcd start -M=POEIKC::Plugin::IRC -n=ikcircbot -a=ikcircbot -p=46667 -d -s

and then ..

  $ poikc -D --alias=ikcircbot  --port=46667 IKC_IRC  message  '{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667"}, channel=>"#foo"}' aiueo

or

  $ikc_client->post_respond( 'ikcircbot/something_respond' => ['IKC_IRC','message','{connect=>{Nick=>"poeN",Username=>"poeU",Ircname=>"poeI",Server=>"localhost",Port=>"6667"},channel=>"#foo"}','aiueo'] );

=head1 DESCRIPTION

POEIKC::Plugin::IRC is poeikcd plugin irc bot

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

