package POEIKC::Plugin::IRC::ClientLite;

use strict;
use 5.008_001;
our $VERSION = '0.01';
use Sys::Hostname ();
use POE::Component::IKC::ClientLite;

sub new {
    my $class = shift ;
    my $self = {
        	ikc 		=> undef,
        	RaiseError 	=> 0,
        	error => undef,
        	@_
        };
    for (qw(ip port name serialiser timeout connect_timeout block_size)){
		$self->{create_ikc_client}->{$_} = delete $self->{$_} if exists $self->{$_};
    }
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}

sub ikc {
	my $self = shift;
	$self->{ikc} = shift if @_ >= 1;
	return $self->{ikc};
}

sub error {shift->{error}}

sub connect {
	my $self = shift;
	$self->{error} = undef;
	my %param = (
		ip 		=> Sys::Hostname::hostname,
		port 	=> 40101,
		name 	=> join('_'=>Sys::Hostname::hostname, ($0 =~ /(\w+)/g), $$),
		%{$self->{create_ikc_client}},
		@_
	);
	$self->{ikc} = create_ikc_client(%param);
	if (not($self->{ikc})) {
		$self->{error}  = $POE::Component::IKC::ClientLite::error;
		$self->{RaiseError} and die($POE::Component::IKC::ClientLite::error);
	}
	return $self->{ikc};
}

sub privmsg {
	my $self = shift;
	$self->{error} = undef;
	my $irc_conf_hash_ref = shift;
	$self->{ikc} ||= $self->connect;
	if ( $self->{ikc} ) {
		my $ret = $self->{ikc}->post_respond(
			'IKC_IRC/message_respond' => [
				'privmsg',
				$irc_conf_hash_ref,
				@_
				# {"channel"=>"#test","connect"=>{"Nick"=>"poeN","Username"=>"poeU","debug"=>1,"Port"=>6667,"flood"=>1,"Ircname"=>"localhost"}},
				# messages ..
			] 
		);
		return $ret;
	}
	return ;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

POEIKC::Plugin::IRC::ClientLite - Synchronous interface

=head1 SYNOPSIS

	use Data::Dumper;
	use POEIKC::Plugin::IRC::ClientLite;

	my $irc = POEIKC::Plugin::IRC::ClientLite->new(
		ip		=> irc_bot_host_name,
		port	=> 47301,
		timeout	=> 3,
		RaiseError => 1,
	);
	eval {
		$irc->connect;

		my $re = $irc->privmsg(
			{
				"channel"=>"#test",
				"connect"=>{
					"Nick"=>"poeN",
					"Username"=>"poeU",
					"debug"=>1,
					"Port"=>6667,
					"flood"=>1,
					"Ircname"=>"localhost"
				}
			},
			'AIUEO','IRoHaNiHoHeTo'
		);
		$re or die "failed in enqueue";

	};if($@){
		warn $@;
	}


=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<poeikcd>
L<POEIKC::Plugin::IRC>

=cut
