#!/usr/bin/perl

use strict;
use warnings;

use Plack::Builder;
use List::Util qw/shuffle/;
use CGI::PSGI;
use Cwd qw/getcwd/;
use Data::Dumper;
BEGIN { my $path = getcwd() . '/'. $0; $path =~ s{/\./}{/}g; $path =~ s/app\.psgi$//; unshift @INC, $path; };
use genbrain;
use JSON;
use Encode qw/encode decode/;
use HTML::Entities qw/encode_entities/;
use Data::Dumper;

my $cb = sub {
	my $env = shift;
	return [200, ["Content-Type", 'text/plain'], [Dumper(CGI::PSGI->new($env)->param('code'))]],
};

=over json
var brain = [
	"thebrain108.mp3": [
		info: [],
		list: [
			"0": ["t0":"0", "t1":27000, title:"Generique le Brain",artits:"Frederick S."],
		],
	],
];

=cut
sub search_cloud {
	my $data = shift;
	my %group;
	my $i = 0;
	no warnings;
	for my $b (@{ $data }) {
		my $o = 0;
		for my $t (@{ $b->{list} }) {
			next unless ref($t->[1]);
			my $art = lc($t->[1]{artist});
			if ($art) {
				push @{ $group{$art} }, [$i, $o];
			}
			$o++;
		}
		$i++;
	}
	for my $art (keys %group) {
		delete $group{$art} if @{ $group{ $art } } < 4 && $art !~ /ogosam/i;
		delete $group{$art} if $group{ $art } && @{ $group{ $art } } > 20;
	}
	my $h = '';
	for my $art (shuffle keys %group) {
		my $c = scalar @{ $group{ $art } };
		if ($art =~ /ogosam/i) { $c *= 2 } elsif (rand() > .85) { $c *=2 } elsif (rand() > .92) { $c *=3; }
		if ($c  > 30) { $c = 30 }
		elsif ($c  > 20) { $c /= 2 }
		$art =~ s/['"]//g;
		$h .= qq|<a href="#" style="font-size: ${c}px;" onclick="search_txt('$art');return false;">$art</a>&nbsp;|;
	}
	return $h;
}

sub si {
	my $t = shift;
	my $data = shift;
	my $i = 0;
	no warnings;
	if ($t =~ /^\d+$/) {
		$t = "thebrain$t";
	}
	for (@{ $data }) {
		if ($t eq $_->{title}) {
			return $i;
		}
		$i++;
	}
}
my $page = sub {
	my $env = shift;
	my $data = genbrain::readall();
	my $json = encode('latin1', JSON->new->encode($data));
	my $cloud = encode('latin1', search_cloud($data));
	my $onload = qq{random_brain()};
	my $cgi = CGI::PSGI->new($env);
	my $l = $cgi->param('l');
	my $s = $cgi->param('s');
	my $extra = $s ? ", '$s'" : "";
	if ($l) {
		my $li = si($l, $data);
		if (defined $li) {
			$onload = qq{focus_track($li$extra)};
		} else {
			$onload = '';
		}
	} elsif ($env->{REQUEST_URI} =~ /\?([a-z]+\d+)$/) {
		my $li = si($1, $data);
		if (defined $li) {
			$onload = qq{focus_track($li$extra)};
		} else {
			$onload = '';
		}
	}
	
return qq{
<!DOCTYPE html>
<html>
	<head>
		<link rel="shortcut icon" type="image/png" href="http://www.musiques-incongrues.net/forum/themes/vanilla/styles/scene/favicon.png"/>
		<title>brain prayer</title>
		<link rel="stylesheet" type="text/css" href="/git/jpe/bpui.css" >
		<script type="text/javascript">
		var db = $json;
		</script>
		<script type="text/javascript" src="/git/jpe/bpui.js" > </script>
		<script type="text/javascript">
		function pageLoaded()
		{
			show_db_listing();
			volume_button = document.getElementById('volume_button');
			audio_player = document.getElementById("aplayer");
			volume_control = document.getElementById('volume_control');
			set_volume(1.0);
			$onload;
		}
		function random_brain() {
			var brain_offset = 6;
			focus_track(Math.floor(Math.random()*( enable_radioclash ? ( db.length - brain_offset) : 33)) + ( enable_radioclash ? 0 : 6 ));
		}
		function set_volume(new_volume)
		{
			audio_player.volume = new_volume;
			update_volume_bar();
			if (volume_button) 
				volume_button.value = "Volume: "+parseInt(new_volume*100);
			var control = document.getElementById('volume_control');
			if (control) 
				control.style.display='none';
			if (volume_button) 
				but.style.display='inline';
			
		}
		function update_volume_bar()
		{

			if (volume_button) {
				new_top = volume_button.offsetHeight  - volume_control.offsetHeight;
				volume_control.style.top = new_top+"px";
				volume = audio_player.volume;
				//change the size of the volume  bar
				wrapper = document.getElementById("volume_background");
				wrapper_height = wrapper.offsetHeight;
				wrapper_top = wrapper.offsetTop;
				new_height= wrapper_height*volume;
				volume_bar = document.getElementById("volume_bar");
				volume_bar.style.height=new_height+"px";
				new_top =  wrapper_top + (  wrapper_height - new_height  );
				volume_bar.style.top=new_top+"px";
			}
		}
		
		function highlight_current(i, curt) {
			document.getElementById("content").innerHTML = "";
			var dv = document.getElementById("tt" + ctl.length);
			if (dv != undefined) {
				dv.style.background = "white";
				dv.style.fontWeight = 100;
			}
			for (o in ctl) {
				var dt = ctl[o];
				var dv = document.getElementById("tt" + (parseInt(dt[1])-1));
				if (dv != undefined) {
					dv.style.background = "white";
					dv.style.color = "black";
					dv.style.fontWeight = 100;
				}
			}
			var data = db[ci];
			if (data == undefined) return;
			var track = data["list"][i+1];
			if (track == undefined) return;
			var tdata = track[1];
			var dv = document.getElementById("tt" + i);
			if (dv != undefined && tdata != undefined) { 
				var bt = '';
				var lnk = '';
				if (tdata["href"] != '' && tdata["href"] != undefined) {
					var hr = tdata["href"];
					if (hr.length > 42) { hr = hr.substring(0, 42); }
					lnk = '<br /><a href="' + tdata["href"] + '">' + hr + '</a>';
				}
				var art = tdata["artist"];
				art = art.replace("'", 'g');
				art = art.replace('"', 'g');
				document.getElementById("href_ut").innerHTML = '<a style="background:#ccc;" href="http://www.youtube.com/results?search_query=' + tdata["artist"] + '"> ut </a>';
				document.getElementById("content").innerHTML = bt +
					'<input id="button_love" class="player_control" type="button" onClick="search_txt('+ "'" + art + "'" + ')");" style="" value="+" ></input>' +
					tdata["artist"]+"<br/>"+
					'<input id="button_love" class="player_control" type="button" onClick="click_love();" style="" value="&hearts;" ></input>'+ 
					tdata["title"];
				if (tdata["year"] == undefined) tdata["year"] = '';
				if (tdata["label"] != undefined) document.getElementById("content").innerHTML += '<br /><span style="font-size:12px;">' + tdata["label"]+" "+tdata["year"] + lnk + "</span>";
				dv.style.background = "yellow";
				dv.style.color = "#f0f";
				dv.style.fontWeight = 900;
				update_wiki(art, tdata["title"]);
			}
		}
		var lastwiki;
		function wikiname(str) {
			str = str.replace(/ /g, '_');
			str = str.replace(/\\&(amp;)?/g, '%26');
			str = str.toLowerCase();
			str = str.replace(/^(.)/g, function(\$1){return \$1.toUpperCase()});
			str = str.replace(/(\\s[a-z])/g, function(\$1){return \$1.toUpperCase()});
			return str;
		}
		function update_wiki(artist, title) {
			var art = wikiname(artist);
			var wikisrc = 'http://en.wikipedia.org/wiki/Special:Search/' + art;
			if (lastwiki != wikisrc) {
				document.getElementById("wiki").src = wikisrc;
				lastwiki = wikisrc;
			}
		}
		function toffset_current(tm) {
			var off = 0;
			for (i in ctl) {
				var dt = ctl[i];
				if (dt[0] <= tm) {
					off = tm - dt[0];
				}
			}	
			return off;
		}
		function now_playing(tm) {
			var last = 0;
			for (i in ctl) {
				var dt = ctl[i];
				if (dt[0] <= tm) {
					last = parseInt(dt[1]) - 1;
				}
			}	
			return last;
		}
		function ctrack_off(i) {
			if (c < 1) return 0;
			var c = ctl[i+1];
			var cf = c[0];
			return cf;
		}
		function ctrack_dur(i) {
			if (i < 1) return 0;
			var c = ctl[i];
			var n = ctl[i+1];
			if (n == undefined) return 0;
			var cf = c[0];
			var nf = n[0];
			return nf - cf;
		}
		var ati = 0;
		function update() {
			dur = audio_player.duration;
			time = audio_player.currentTime;
			var cur = now_playing(time);
			if (cti != cur && cti != ati) { einde_track(); }
			cti = cur;
			track_duration = ctrack_dur(cur+1);
			var min = (time - ( time % 60 ) ) / 60;
			var sec = parseInt(time - (min*60));
			var ssec = sec;
			if (ssec < 10) { ssec = "0" + ssec; }
			document.getElementById("msg").innerHTML = min + ':' + ssec + "=&gt;#" + (cur+2);
			highlight_current(cur, time);
			var toff = toffset_current(time);
			var tmin = (toff - ( toff % 60 ) ) / 60;
			var tsec = parseInt(toff - (tmin*60));
			var tssec = tsec;
			if (tssec < 10) { tssec = "0" + tssec; }
			document.getElementById("msg").innerHTML += " " + tmin + ":" + tssec;
			tdur = track_duration;
			var fraction = time/dur;
			var tfraction = toff/tdur;
			var wrapper = document.getElementById("duration_background");
			var twrapper = document.getElementById("t_duration_background");
			var new_width = wrapper.offsetWidth*fraction;
			var tnew_width = twrapper.offsetWidth*tfraction;
			document.getElementById("duration_bar").style.width=new_width+"px";
			document.getElementById("t_duration_bar").style.width=tnew_width+"px";

		}
		var searchres = [];
		var searchplayi = 0;
		function einde_track() {
			if (! searchmode_enabled()) return;
			if (searchres == null || searchres.length == 0) return;
			if ((new Date).getTime() < ati + 10000) return;
			// alert("ati=" + ati + ", nu=" + (new Date).getTime());
			searchplayi++;
			ati = (new Date).getTime();
			if (searchres[searchplayi] == null) searchplayi=0;
			focus_track(searchres[searchplayi][0], searchres[searchplayi][1]);
		}
		function playClicked() {
			element = document.getElementById("playButton");
			if (element == undefined) {
				return;
			}
			if(audio_player.paused || element.value == pb_1) {
				try { audio_player.play(); } catch (e) { };
				newdisplay = pb_0;
			}else{
				try { audio_player.pause(); } catch (e) { };
				newdisplay = pb_1;
			}
			element.value=newdisplay;
		}
		function trackEnded()
		{
			document.getElementById("playButton").value=pb_1;
			var nxt = parseInt(ci)+1;
			if (db[nxt] == undefined) nxt = 0;
			// alert("eind van " + ci + ", skip naar " + nxt);
			focus_track(nxt);
		}
		function volumeClicked(event)
		{
			var control = document.getElementById('volume_control');
			var but = document.getElementById('volume_button');
			if (control == undefined) return;
			
			if(control.style.display!="none")
			{
				control.style.display="None";
				but.style.display='';
			}else{
				control.style.display="Block";
				but.style.display='none';
				update_volume_bar();
			}
		}
		
		function volumeChangeClicked(event)
		{
			var but = document.getElementById('volume_button');
			if (but == undefined) return;
			offset =  event.currentTarget.offsetHeight - event.clientY;
			// alert("clientY=" + clientY + ",offsetTop=" + event.currentTarget.offsetTop + " => " + offset);
			volume = offset/event.currentTarget.offsetHeight;
			// alert("vol=" + volume);
			set_volume(volume);
			update_volume_bar();
			// volumeClicked();
		}
		
		function t_durationClicked(event)
		{
			//get the position of the event
			clientX = event.clientX;
			left = event.currentTarget.offsetLeft + 220;
			clickoffset = clientX - left;
			percent = clickoffset/event.currentTarget.offsetWidth;
			// alert("track_duration=" + track_duration);
			var coff = ctrack_off(cti);
			duration_seek = percent*track_duration;
			var tot = coff + duration_seek;
			// alert(" seek to " + coff + " + ( " + percent + " * " + track_duration + " ) => " + tot);
			if (tot > 0 && tot < dur) {
				document.getElementById("aplayer").currentTime=tot;
			}
		}
		function durationClicked(event)
		{
			//get the position of the event
			clientX = event.clientX;
			left = event.currentTarget.offsetLeft + 220;
			clickoffset = clientX - left;
			// alert("clientX=" + clientX + " - offsetLeft=" + left + " => " + clickoffset);
			percent = clickoffset/event.currentTarget.offsetWidth;
			dur = audio_player.duration;
			duration_seek = percent*dur;
			// alert("percent=" + percent + " * dur=" + dur + " => " + duration_seek);
			if (duration_seek > 0 && duration_seek < dur) {
				audio_player.currentTime=duration_seek; 
			}
		}
		function enable_radioclash() {
			var el = document.getElementById("enable_radioclash");
			return el.checked;
		}
		function search_db(txt) {
			var res = [];
			var re = new RegExp(txt, 'i');
			var cnt = 0;
			var clash = enable_radioclash();
			// alert(clash);
			for (dbi in db) {
				var brain = db[dbi];
				for (tri in brain["list"]) {
					var song = brain["list"][tri];
					if (song != undefined && song[1] != undefined) {
						var str = song[1]["artist"];
						str += " " + song[1]["title"];
						if (str.match(re) && (clash || brain["title"].match(/thebrain/))) {
							res.push([brain, song, dbi, tri]);
							cnt++;
							if (cnt > 50) return res;
						}
					}
				}
			}
			return res;
		}

		function search_txt(txt) {
			var div = document.getElementById("searchres");
			div.innerHTML = "<b>search(" + txt + ")</b><br/><br/>";
			var res = search_db(txt);
			searchplayi=0;
			ati = (new Date).getTime();
			searchres = [];
			for (i in res) {
				var ths = res[i];
				var brain = ths[0];
				var song = ths[1];
				var bri = ths[2];
				var tri = ths[3];
				var trn = parseInt(ths[3]) + 1;
				var offset = parseInt(song[1]["from"])+2;
				var ttl = song[1]["artist"] + " " + song[1]["title"];
				ttl = ttl.replace(txt, '<font style="font-weight:900;color:#f0f">' + txt + '</font>');
				div.innerHTML += '<span onclick="ati = (new Date).getTime();searchplayi=' + i + ';focus_track(' + bri + ', ' + (parseInt(song[1]["from"])+2) + ')">' + brain["title"] + "&nbsp;" + "#" + trn + "&nbsp;" + ttl + "</span><br/>";
				searchres[i]=[ths[2],offset];
			}
		}
		function searchmode_enabled() {
			var e = document.getElementById("searchmode");
			return e.checked;
		}
		function click_prev() {
			focus_track(ci-1);
		}
		function click_share() {
			alert("share it");
		}
		function click_love() {
			// alert("love it");
		}
		function click_next() {
			focus_track(ci+1);
		}
		</script>
		<base target="_blank">
	</head>
	<body onLoad="pageLoaded();">
	<div id='main' style="z-index: 19;height: 100%;">
		<h3 style="text-align: left; color:#f0f"><a href="http://github.com/datamoeras/brainplayer">GPL</a>&nbsp;<a href="http://www.musiques-incongrues.net/forum/discussions/" target="_blank">&#8734;&nbsp;MUSIQUES&nbsp;INCONGRUES</a></h3><br />
		<div id='player' style="position:fixed;left: 220px;width: 400px;top: 4px;">
				<div id="duration" class"player_control" >
					<div id="duration_background"  onClick="durationClicked(event);">
						<div id="duration_bar" class="duration_bar"></div>
					</div>
				</div>
				<input id="playButton" class="player_control" type="button" onClick="playClicked(this);" value="play" ></input>
				<input id="button_rand" class="player_control" type="button" onClick="random_brain();" value="rnd" ></input>
				<input id="button_prev" class="player_control" type="button" onClick="click_prev();" value="&laquo;" ></input>
				<input id="button_next" class="player_control" type="button" onClick="click_next();" value="&raquo;" ></input>
				<a style="background: #ccc" href="#" target="_blank" title="Right click" id="href_as">save</a>
				<span class="asy player_control"><a href="#" target="_blank" title="Youtube" id="href_ut">ut</a></span>
				<!--
				<div id="volume_control" class='player_control' onClick="volumeChangeClicked(event);" style="display:none">
					<div id="volume_background"  >
						<div id="volume_bar"></div>
					</div>
				</div>
				<input type="button" class='player_control'  id='volume_button' onClick="volumeClicked();" value="Vol">
				-->
			<audio id='aplayer' src="" onTimeUpdate="update();" onEnded="trackEnded();" preload="metadata" autobuffer="yes"></audio>
		</div>
		<div id="searchframe" style="z-index: 3;background: #fff; position:fixed;left: 200px;left: 450px;top: 4px;">
			<input type="checkbox" id="enable_radioclash" />radioclash<br />
			<input type="checkbox" id="searchmode" />searchmodeplaylist<br />
			<input id="searchfld" value="" onkeyup="if(event.keyCode==13){search_txt(this.value)};return false" onchange="search_txt(this.value)"/><br />
			<div id="searchres" width="300px; overflow:none">
			</div>
		</div>
		<div id="current" style="position: fixed; top: 40px;left: 220px; bottom: 0px;">
			<div id="msg" style="height: 1.2em;display: none;" class='output'></div>
			<br />
			<div id="cttl" style="height: 1.2em; width: 220px; color: black; font-decoration: italic; font-weight: 900; font-size: 14px;text-align:center;"></div>
			<div id="t_duration" class"'player_control" >
				<div id="t_duration_background"  onClick="t_durationClicked(event);">
					<div id="t_duration_bar" class="duration_bar"></div>
				</div>
			</div>
			<div id="content" style="height: 4.8em; width: 600px; color: black; font-decoration: italic;font-weight: 900; font-size: 14px;"></div>
			<br />
			<div id="tracklist" style="width: 450px; overflow: auto;">
			</div>
			<!--<div id="scloud" style="width: 450px; overflow: auto;z-index: 8;">$cloud</div>-->
			<iframe id="wiki" style="width: 100%; height: 60%;" frameborder="0" /></iframe>
		</div>
	</div>
	<div style="position: absolute; left: 0px;top: 0px;z-index: 1; width: 220px; overflow: none;" id="playlist"></div>
	<img style="position: fixed; z-index: 1; opacity: .7; bottom: 0px;right: 0px;" id="pochette" src="" onClick="this.src=''">
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-29478248-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</body>
</html>
};
};
builder {
	# enable "Static", path => sub { s!^/mp3/!! }, root => '/data/music/thebrain/';
	sub { [200, ["Content-Type", 'text/html'], [$page->(@_)]] }
}
