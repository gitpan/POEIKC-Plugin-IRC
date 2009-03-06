#!/usr/bin/env perl

use strict;
use Data::Dumper;
use POE::Component::IKC::ClientLite;
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

my %param = (
	ip 		=> Sys::Hostname::hostname,
	port 	=> 47225,
	name 	=> join('_'=>Sys::Hostname::hostname, ($0 =~ /(\w+)/g), $$),
);
my $ikc = create_ikc_client(%param);

my $param = {
	connect=>{
		Nick=>"poeN",
		Username=>"poeU",
		Ircname=>"localhost",
		Port=>"16667",
		debug=>1,
		flood=>1,
	},
	channel=>"#test"
};

my $state = 'IKC_IRC/message_respond';

$ikc or die $POE::Component::IKC::ClientLite::error;

$ikc->post_respond( $state => ['notice'  ,$param, "-- (start) --"]);
$ikc->post_respond( $state => ['privmsg' ,$param, "-- (1) --"]);
$ikc->post_respond( $state => ['privmsg', $param, "Romaji-1"]);
$ikc->post_respond( $state => ['notice' , $param, $msg]);

$ikc->post_respond( $state => [$param, "-- (2) --"]);
$ikc->post_respond( $state => [$param, "Romaji-2"]);
$ikc->post_respond( $state => [$param, $msg]);
$ikc->post_respond( $state => [$param, "-- (3) --"]);
$ikc->post_respond( $state => [$param,  "aiueo", "irohanihoheto"]);
$ikc->post_respond( $state => [$param, ["AIUEO", "IROHANIHOHETO"]]);
$ikc->post_respond( $state => [$param, "-- (end) --"]);

print Dumper $ikc->post_respond( 'IKC_IRC/status_respond' );
print "*"x40, "\n";
####

$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Useqq=1;
$param = Dumper $param;
my $cmd = qq{poikc --alias=IKC_IRC -s message_respond  privmsg '$param' A-I-U-E-O I-Ro-Ha-Ni-Ho-He-To -D};
print $cmd,"\n";
print `$cmd`;
# $ikc_client->post_respond( 'IKC_IRC/message_respond' => ['privmsg','{"channel"=>"#test","connect"=>{"Nick"=>"poeN","Username"=>"poeU","debug"=>1,"Port"=>16667,"flood"=>1,"Ircname"=>"localhost"}}','AIUEO','IRoHaNiHoHeTo'] );
print "\n";


__END__

$ poeikcd start -M=POEIKC::Plugin::IRC -n=ikcircbot -a=ikcircbot -s

