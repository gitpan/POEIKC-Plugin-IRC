#!/usr/bin/env perl

use strict;
use Data::Dumper;
use Sys::Hostname;

my $msg = q{
	あ	い	う	え	お
あ 	a 	i 	u 	e 	o
か 	ka 	ki 	ku 	ke 	ko 	kya 	kyu 	kyo
さ 	sa 	si 	su 	se 	so 	sya 	syu 	syo
た 	ta 	ti 	tu 	te 	to 	tya 	tyu 	tyo
な 	na 	ni 	nu 	ne 	no 	nya 	nyu 	nyo
は 	ha 	hi 	hu 	he 	ho 	hya 	hyu 	hyo
ま 	ma 	mi 	mu 	me 	mo 	mya 	myu 	myo
や 	ya 	(i) 	yu 	(e) 	yo
ら 	ra 	ri 	ru 	re 	ro 	rya 	ryu 	ryo
わ 	wa 	(i) 	(u) 	(e) 	(o)
が 	ga 	gi 	gu 	ge 	go 	gya 	gyu 	gyo
ざ 	za 	zi 	zu 	ze 	zo 	zya 	zyu 	zyo
だ 	da 	(zi) 	(zu) 	de 	do 	(zya) 	(zyu) 	(zyo)
ば 	ba 	bi 	bu 	be 	bo 	bya 	byu 	byo
ぱ 	pa 	pi 	pu 	pe 	po 	pya 	pyu 	pyo
};



	use Data::Dumper;
	use POEIKC::Plugin::IRC::ClientLite;

	my $irc = POEIKC::Plugin::IRC::ClientLite->new(
#		ip		=> Sys::Hostname::hostname,
		port	=> 47402,
		timeout	=> 3,
		RaiseError => 1,
	);
	eval {
#		$irc->connect;

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
		$re or die "failed in privmsg";

	};if($@){
		warn $@;
	}



print "*"x40, "\n";


__END__

perl -I lib ./eg/clientlith2.pl

$ poeikcd start -M=POEIKC::Plugin::IRC -n=ikcircbot -a=ikcircbot -s

  $ikc_client->post_respond( 'IKC_IRC/message_respond' => ['privmsg','{"channel"=>"#test","connect"=>{"Nick"=>"poeN","Username"=>"poeU","debug"=>1,"Port"=>16667,"flood"=>1,"Ircname"=>"localhost"}}','AIUEO','IRoHaNiHoHeTo'] );