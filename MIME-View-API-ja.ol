$B!X(BSEMI 1.5 MIME-View API $B$N<j0z!Y(B
by $B<i2,(B $BCNI'(B

* $B$O$8$a$K(B

$B$3$NJ8=q$OMxMQ<T3&LL$H(B SEMI MIME-View $B$N3&LL$r:n$k?M$d(B SEMI MIME-View
$B$N(B method $B$r=q$/%O%C%+!<$N$?$a$K!"(BSEMI MIME View $B$N;EAH$_$r2r@b$7!"(BAPI 
$B$N;EMM$rL@<($7$^$9!#(B


* MIME message


** content-type

[$B9=B$BN(B] mime-content-type

	Content-Type $BMs$N2r@O7k2L$r<}$a$k$?$a$N9=B$BN!#(B

	[$BMWAG(B]

	primary-type	media-type $B$N<g7?(B (symbol).

	subtype		media-type $B$NI{7?(B (symbol).

	parameters	Content-Type $BMs$N(B parameter ($BO"A[(B list).

	$B>e5-$NMWAG$O;2>H4X?t(B `mime-content-type-$BMWAGL>(B' $B$G;2>H$9$k!#(B


[$B4X?t(B] make-mime-content-type (type subtype &optional parameters)

	content-type $B$N@8@.;R!#(B


[$B4X?t(B] mime-content-type-parameter (content-type parameter)

	CONTENT-TYPE $B$N(B PARAMETER $B$NCM$rJV$9!#(B


[$B4X?t(B] mime-parse-Content-Type (string)

	STRING $B$r(B content-type $B$H$7$F2r@O$7$?7k2L$rJV$9!#(B


[$B4X?t(B] mime-read-Content-Type ()

	$B8=:_$N(B buffer $B$N(B Content-Type $BMs$rFI$_<h$j!"2r@O$7$?7k2L$rJV$9!#(B

	Content-Type $BMs$,B8:_$7$J$$>l9g$O(B nil $B$rJV$9!#(B


[$B4X?t(B] mime-type/subtype-string (type &optional subtype)

	type $B$H(B subtype $B$+$i(B type/subtype $B7A<0$NJ8;zNs$rJV$9!#(B


** content-disposition

[$B9=B$BN(B] mime-content-disposition

	Content-Type $BMs$N2r@O7k2L$r<}$a$k$?$a$N9=B$BN!#(B

	[$BMWAG(B]

	disposition-type	disposition-type (symbol).

	parameters		Content-Disposition $BMs$N(B parameter
				($BO"A[(B list).

	$B>e5-$NMWAG$O;2>H4X?t(B `mime-content-disposition-$BMWAGL>(B' $B$G;2>H(B
	$B$9$k!#(B


[$B4X?t(B] mime-content-disposition-parameter (content-disposition parameter)

	CONTENT-DISPOSITION $B$N(B PARAMETER $B$NCM$rJV$9!#(B


[$B4X?t(B] mime-content-disposition-filename (content-disposition)

	CONTENT-DISPOSITION $B$N(B filename $B$NCM$rJV$9!#(B



* Message $B$NI=8=$HI=<($K4X$9$k35@b(B

Internet $B$NEE;R=q4J!&%M%C%H%K%e!<%9$J$I$N=qLL(B (message) $B$NI=8=7A<0$O(B 
STD 11 $B$K4p$E$$$F$$$^$9!#(BSTD 11 $B$N=qLLK\BN(B (message body) $B$O9T$rM#0l$N(B
$B9=B$$H$9$k4J0WJ8LL(B (plain text) $B$G$"$j!"J8;zId9f$b(B us-ascii $B$HDj$a$i$l(B
$B$F$$$^$9!#<B:]$K$O!"J8;zId9f$r(B us-ascii $B$NBe$o$j$K$=$N8@8l7w$GMQ$$$i$l(B
$B$kJ8;zId9f$H$7$?!XCO0h2=$5$l$?(B STD 11$B!Y=qLL$bMQ$$$i$l$F$-$^$7$?$,!"$3(B
$B$N>l9g$b=qLL$NJ8;zId9f$O#1$D$G$9!#$3$N$?$a!"MxMQ<T3&LL(B (Message User
Agent) $B$O!"$7$P$7$P!"(Bbyte $BNs(B = us-ascii $BJ8;zNs!"$J$$$7$O!"(Bbyte $BNs(B = $B$=(B
$B$N8@8l7w$GMQ$$$kJ8;zId9f$NJ8;zNs$N$h$&$K8+Jo$7$F$-$^$7$?!#(B


	           $B(.(,(,(,(,(,(,(,(,(,(,(,(,(,(,(/(B
	           $B(-(B          message	         $B(-(B
                   $B(-(B         	                 $B(-(B
       $B(!(!(!(!(!"*(9(B			         $B(-(B
          data     $B(-(B			         $B(-(B  display
MTA      stream    $B(-(B			         $B(7(!(!(!(!(!"*(B user
           of      $B(-(B			         $B(-(B
         message   $B(-(B			         $B(-(B
       $B"+(!(!(!(!(!(9(B			         $B(-(B
	   	   $B(-(B			         $B(-(B
		   $B(-(B			         $B(-(B
		   $B(1(,(,(,(,(,(,(,(,(,(,(,(,(,(,(0(B
			$B?^(B: $BHs(B MIME MUA $B$N>l9g(B


$B$7$+$7$J$,$i!"(BMIME $B$G$O=qLL$O(B entity $B$rC10L$H$9$kLZ9=B$$K$J$j!"$^$?!"(B
$B#1$D$N=qLL$GJ#?t$NJ8;zId9f$rMQ$$$k$3$H$,$G$-$^$9!#$^$?!"(Bentity $B$NFbMF(B
$B$OJ8LL$d3($N$h$&$JC1=c$KI=<(2DG=$J$b$N$@$1$G$J$/!"2;@<$dF02h$J$I$N0lDj(B
$B;~4V:F@8$5$l$k$h$&$J$b$N$dFCDj$N%"%W%j%1!<%7%g%s$N%G!<%?$d%W%m%0%i%`$N(B
$B%=!<%9!"$"$k$$$O!"(Bftp $B$d(B mail service $B$NMxMQK!$d(B URL $B$H$$$C$?7A$GI=$5(B
$B$l$?30It;2>H$J$I$N$5$^$6$^$J$b$N$,9M$($i$^$9!#$3$N$?$a!"I=<($@$1$r9M$((B
$B$F$$$?(B STD 11 $B$K$*$1$kMxMQ<T3&LL$NC1=c$J1dD9$G$O(B MIME $B$NA4$F$N5!G=$r07(B
$B$&$3$H$O$G$-$^$;$s!#$D$^$j!"(BMIME $B$N7A<0$K9g$o$;$FI|9f$9$k$@$1$G$OIT==(B
$BJ,$G$"$j!"MxMQ<T$H$NBPOCE*$J:F@8=hM}$r9MN8$9$kI,MW$,$"$j$^$9!#(BMIME $B=q(B
$BLL$N7A<0$O<+F0=hM}$,$7$d$9$/@_7W$5$l$F$$$^$9$,!"(BMIME $B=qLL$K4^$^$l$kFb(B
$BMF$NCf$K$O%;%-%e%j%F%#!<>e$NLdBj$+$i<+F0=hM}$r$9$k$Y$-$G$J$$$b$N$,$"$j!"(B
$B$3$&$$$C$?$b$N$N:F@8$K4X$7$F$OMxMQ<T$NH=CG$r6D$0$h$&$K@_7W$5$l$k$Y$-$G(B
$B$7$g$&!#7k6I!"(BMIME $B=qLL$r07$&$?$a$K$O(B STD 11 $B$*$h$S(B MIME $B$N9=J8$G5-=R(B
$B$5$l$?%a%C%;!<%8$N>pJs8r49MQI=8=$H$=$N2r<a7k2L$G$"$kI=<(2hLL$d:F@8Ey$N(B
$B=hM}$r6hJL$7$F9M$($kI,MW$,$"$j$^$9!#$^$?!"MxMQ<T$H$NBPOCE*$J:F@8=hM}$,(B
$BI,MW$G$9!#(B


			         $B(.(,(,(,(,(,(,(,(,(,(,(/(B
			         $B(-(B      preview       $B(-(Bdisplay
                                 $B(-(B       layer        $B(-(B  or
			         $B(-(B  $B(#(!(!(!(!(!(!($(B  $B(-(Bplayback
		   $B(#!D!D!D!D!D!D(@!D(+!D!D!D(B    $B(!(+(!(@(!(!(!(!"*(B
                   $B!'(B            $B(-(B  $B("(B          $B"+(+(!(@(!(!(!(!(!(B
	       $B(.(,(;(,(,(,(,(,(,(4(B  $B(&(!(!(!(!(!(!(%(B  $B(-(B
	       $B(-(B  $B!'(B    $B(#(!($(B  $B(-(B  $B(#(!(!(!(!(!(!($(B  $B(-(B
	       $B(-(B  $B!'(B    $B("!D(+!D(@!D(+!D!D!D(B    $B(!(+(!(@(!(!(!(!"*(B
	       $B(-(B  $B!'(B  $B(#()(B  $B("(B  $B(-(B  $B("(B          $B"+(+(!(@(!(!(!(!(!(B
	       $B(-(B  $B!'(B  $B("("(B  $B("(B  $B(-(B  $B(&(!(!(!(!(!(!(%(B  $B(-(B           user
               $B(-(B  $B!'(B  $B("(&(!(%(B  $B(-(B  $B(#(!(!(!(!(!(!($(B  $B(-(B
       $B(!(!(!"*(9(#(+($("(#(!($(B  $B(-(B  $B("(B          $B(!(+(!(@(!(!(!(!"*(B
         data  $B(-("!'("("("!D(+!D(@!D(+!D!D!D(B    $B"+(+(!(@(!(!(!(!(!(B
MTA     stream $B(-("(B  $B('(+()(B  $B("(B  $B(-(B  $B(&(!(!(!(!(!(!(%(B  $B(-(B
          of   $B(-("(B  $B("("("(B  $B("(B  $B(-(B  $B(#(!(!(!(!(!(!($(B  $B(-(B
        message$B(-(&(!(%("(&(!(%(B  $B(-(B  $B("(B          $B(!(+(!(@(!(!(!(!"*(B
       $B"+(!(!(!(9(B      $B("(#(!($(B  $B(-(B  $B("(B    $B!'(B    $B"+(+(!(@(!(!(!(!(!(B
	       $B(-(B      $B("("(B  $B("(B  $B(-(B  $B(&(!(!(+(!(!(!(%(B  $B(-(Bnavigation
	       $B(-(B      $B(&()(B  $B("(B  $B(-(B        $B!'(B          $B(-(B
	       $B(-(B        $B("!D(+!D(@!D!D!D!D(%(B          $B(-(B
	       $B(-(B        $B(&(!(%(B  $B(1(3(,(,(,(,(,(,(,(,(,(0(B
	       $B(-(B       raw        $B(-(B
	       $B(-(B       layer      $B(-(B
	       $B(1(,(,(,(,(,(,(,(,(,(0(B
			    $B?^(B: MIME MUA $B$N>l9g(B


$B$3$N$?$a!"(BSEMI MIME-View $B$O#1$D$N=qLL$KBP$7$F!">pJs8r49MQI=8=$r3JG<$9(B
$B$k(B mime-raw-buffer $B$HI=<(MQI=8=$r3JG<$9$k(B mime-preview-buffer $B$N#2$D$N(B 
buffer $B$rMQ$$$^$9!#(B


* mime-raw-buffer

  `mime-raw-buffer' $B$O>pJs8r49MQ7A<0$N$^$^$N=q4J$NFbMF$,<}$a$i$l$k(B 
buffer $B$G$9!#(BMIME $B=qLL$O(B entity $B$rC10L$H$9$kLZ9=B$$G$9$,!"$3$N(B buffer
$B$NCf$G$O=qLL$r9=@.$9$k(B entity $B$O$3$N9=B$$K$7$?$,$C$F4IM}$5$l$^$9!#B($A!"(B
$B=qLLA4BN$rI=$9(B root entity $B$r;X$9(B buffer $B6I=jJQ?t(B
`mime-raw-message-info' $B$GA0>O$G2r@b$7$?(B entity $B9=B$BN$r;X$9$3$H$K$h$j!"(B
$BLZ9=B$$r4IM}$7$^$9!#(B


** API

[buffer $B6I=jJQ?t(B] mime-raw-message-info

	$B=qLL$N9=B$$K4X$9$k>pJs$r<}$a$k!#(B

	$B!N7A<0!O(Bmime-entity $B9=B$BN(B


[buffer $B6I=jJQ?t(B] mime-preview-buffer

	$BBP1~$9$k(B mime-preview-buffer $B$r<($9!#(B


[buffer $B6I=jJQ?t(B] mime-raw-representation-type

	mime-raw-buffer $B$N(B representation-type $B$rI=$9!#(B

	representation-type $B$H$O(B mime-raw-buffer $B$,$I$&$$$&7A<0$GI=8=(B
	$B$5$l$F$$$k$+$r<($9$b$N$G!"(B`binary' $B$O(B network $BI=8=$N$^$^$G$"$k(B
	$B$3$H$r<($7!"(B`cooked' $B$O(B message $BA4BN$,4{$K(B code $BJQ49$5$l$F$$$k(B
	$B$3$H$r<($9!#(B

	nil $B$N>l9g!"(Bmime-raw-representation-type-alist $B$+$iF@$i$l$?CM(B
	$B$,MQ$$$i$l$k!#(B


[buffer $B6I=jJQ?t(B] mime-raw-representation-type-alist

	major-mode $B$H(B representation-type $B$NO"A[(B list.

	$B$3$NJQ?t$+$iF@$i$l$kCM$h$j$b(B mime-raw-representation-type $B$NCM(B
	$B$NJ}$,M%@h$5$l$k!#(B


[$B4X?t(B] mime-raw-find-entity-from-node-id (ENTITY-NODE-ID
					  &optional MESSAGE-INFO)

	$B=qLL9=B$(B MESSAGE-INFO $B$K$*$$$F(B ENTITY-NODE-ID $B$KBP1~$9$k(B
	entity $B$rJV$9!#(B

	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B


[$B4X?t(B] mime-raw-find-entity-from-number (ENTITY-NUMBER
					 &optional MESSAGE-INFO)

	$B=qLL9=B$(B MESSAGE-INFO $B$K$*$$$F(B ENTITY-NUMBER $B$KBP1~$9$k(B entity 
	$B$rJV$9!#(B

	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B


[$B4X?t(B] mime-raw-find-entity-from-point (POINT &optional MESSAGE-INFO)

	$B=qLL9=B$(B MESSAGE-INFO $B$K$*$$$F(B POINT $B$KBP1~$9$k(B entity $B$rJV$9!#(B

	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B

[$B4X?t(B] mime-raw-point-to-entity-node-id (POINT &optional MESSAGE-INFO)

	$B=qLL9=B$(B MESSAGE-INFO $B$K$*$$$F(B POINT $B$KBP1~$9$k(B node-id $B$rJV$9!#(B
       
	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B


[$B4X?t(B] mime-raw-point-to-entity-number (POINT &optional MESSAGE-INFO)

	$B=qLL9=B$(B MESSAGE-INFO $B$K$*$$$F(B POINT $B$KBP1~$9$k(B entity-number
	$B$rJV$9!#(B
       
	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B


[$B4X?t(B] mime-raw-flatten-message-info (&optional message-info)

	$B=qLL9=B$(B MESSAGE-INFO $B$K4^$^$l$kA4$F$N(B entity $B$N(B list $B$rJV$9!#(B
       
	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B `mime-raw-message-info' $B$NCM$r(B
	$BMQ$$$k!#(B


* mime-preview-buffer

  `mime-raw-buffer' $B$O=q4J$N>pJs8r49MQI=8=$r2C9)$7$F:n@.$7$?I=<(MQI=8=(B
$B$r<}$a$k$?$a$N(B buffer $B$G$9!#2hLLI=<($G$b(B entity $B$O0UL#$N$"$kC10L$G!"#1(B
$B$D$N=qLL$OJ#?t$N(B entity $B$rC10L$K9=@.$5$l$^$9$,!"(BMIME $B=qLL$N(B entity $B$r(B
$BC10L$H$9$kLZ9=B$$OI,$:$7$b=EMW$G$O$J$/!"$=$l0J>e$K2hLLI=<(>e$G$N0LCV$,(B
$B=EMW$G$9!#$^$?!"(Bentity $B$O:G>.C10L$G$O$J$/!"I=<(>e$N9=@.MWAG$,B8:_$7$^(B
$B$9!#$^$?!"I=<(>e$NMW@A$+$i!"(Bentity $B$K4X78$NL5$$MWAG$bB8:_$9$k$+$bCN$l(B
$B$^$;$s!#(B

  SEMI $B$G$O(B entity $B$O(B buffer $B>e$NNN0h$KD%$jIU$1$i$l$?(B text $BB0@-(B
`mime-view-entity' $B$GI=8=$5$l!"(Bmime-raw-buffer $BCf$NBP1~$9$k(B entity $B$r(B
$B;X$7$^$9!#$^$?!"(Bentity $B0J30$N9=@.MWAG$b(B text $BB0@-$rMQ$$$FI=8=$5$l$^$9!#(B
$B$3$l$i$N9=@.MWAG$O>l9g$K$h$C$F$OMxMQ<T$NA`:n$KBP$7$F$J$K$,$7$+$NH?1~$r(B
$B<($9$?$a$K(B method $B$r8F$S=P$9$3$H$,$G$-$^$9!#$3$N>\:Y$K4X$7$F$O8e=R$7$^(B
$B$9!#(B


** API

[buffer $B6I=jJQ?t(B] mime-mother-buffer

	$BBP1~$9$k?F(B buffer $B$r<($9!#(B

	$B?F(B buffer $B$H$O$3$N(B mime-preview-buffer $B$H(B mime-raw-buffer $B$NAH(B
	$B$r:n$k85$H$J$C$?(B mime-preview-buffer $B$N$3$H$G$"$k!#(B

	$BNc$($P!"(Bmessage/partial $B7A<0$N=qLL$NI=<($KBP$7$FA`:n$r9T$&$3$H(B
	$B$K$h$C$F!"7k9g$5$l$?=qLL$KBP$9$k(B mime-preview-buffer $B$,$G$-$?(B
	$B;~!"7k9g$5$l$?$b$N$K$H$C$F!"A`:n$r9T$C$?(B message/partial $B7A<0(B
	$B$N=qLL$,?F(B buffer $B$KAjEv$9$k!#(B


[buffer $B6I=jJQ?t(B] mime-raw-buffer

	$BBP1~$9$k(B mime-raw-buffer $B$r<($9!#(B

	[$BCm0U(B] $B$3$NJQ?t$O;H$o$J$$J}$,NI$$!#$J$<$J$i!"(B
	       mime-preview-buffer $B$OJ#?t$N(B mime-raw-buffer $B$KBP1~$9$k(B
	       $B2DG=@-$,$"$k$+$i$G$"$k!#(B 


[buffer $B6I=jJQ?t(B] mime-preview-original-window-configuration

	mime-preview-buffer $B$r:n$kA0$N(B window-configuration $B$r<}$a$k!#(B


[text-property] mime-view-entity

	$B8=:_0LCV$KBP1~$9$k(B entity $B9=B$BN$r<($9!#(B


[$B4X?t(B] mime-preview-original-major-mode (&optional recursive)

	$B8=:_0LCV$KBP1~$9$k(B entity $B$NI=>]$,B8:_$9$k(B buffer $B$N(B
	major-mode $B$rJV$9!#(B

	RECURSIVE $B$K(B non-nil $B$,;XDj$5$l$?>l9g!";OAD$N(B major-mode $B$rJV(B
	$B$9!#(B


* entity

  MIME $B=qLL$O(B entity $B$rC10L$H$9$kLZ9=B$$G$9!#(Bentity $B9=B$BN$O(B entity $B$d(B
$B=qLLA4BN$N>pJs$r3JG<$9$k9=B$BN$G!"0J2<$G$OC1$K(B entity $B$H8F$V$3$H$K$7$^(B
$B$9!#(B

  SEMI MIME-View $B$O=qLL$r>pJs8r49MQI=8=$r3JG<$9$k(B mime-raw-buffer $B$HI=(B
$B<(MQI=8=$r3JG<$9$k(B mime-preview-buffer $B$N#2$D$N(B buffer $B$GI=8=$7$^$9!#(B
$B$3$N$?$a!"(Bentity $B$O$3$N#2$D$N(B buffer $B$K$^$?$,$C$FI=8=$5$l$^$9!#(B

  mime-raw-buffer $B$G$O(B entity $B$O(B message $B$N9=B$$rI=8=$9$k$N$KMQ$$$i$l!"(B
entity $B3,AX$N:,!"B($A!"(Bmessage $B$N(B entity $B9=B$BN$NCf$NLZ9=B$$H$7$F4IM}(B
$B$5$l$^$9!#0J2<$G$O!"(Bmessage $B$N(B entity $B9=B$BN$N$3$H$r(B message-info $B$H8F(B
$B$V$3$H$K$7$^$9!#(B

  message-info $BCf$N3F(B entity $B$OLZ$N@a$KEv$?$j$^$9$,!"$3$NLZ$K$O?<$5$H(B
$BF1$8?<$5$NCf$N=gHV$K=>$C$FHV9f$,IU$1$i$l$^$9!#B($A!"(B


		              $B(#(!(!(!($(B
	        	      $B("(B  nil $B("(B
                              $B(&(!(((!(%(B
              $B(#(!(!(!(!(!(!(!(!(!(+(!(!(!(!(!(!(!(!(!($(B
            $B(#(*($(B              $B(#(*($(B		    $B(#(*($(B
            $B("#0("(B              $B("#1("(B		    $B("#2("(B
            $B(&(((%(B              $B(&(((%(B		    $B(&(((%(B
              $B("(B        $B(#(!(!(!(!(+(!(!(!(!($(B	      $B("(B
	  $B(#(!(*(!($(#(!(*(!($(#(!(*(!($(#(!(*(!($(#(!(*(!($(B
	  $B("(B $B#0(B.$B#0("("(B $B#1(B.$B#0("("(B $B#1(B.$B#1("("(B $B#1(B.$B#2("("(B $B#2(B.$B#0("(B
	  $B(&(!(!(!(%(&(!(!(!(%(&(!(!(!(%(&(!(!(!(%(&(!(!(!(%(B
		       $B?^(B: entity $B$N3,AX$H@aHV9f(B


$B$N$h$&$K?<$5(B n $B$N@a$K$OD9$5(B n $B$N@0?tNs$N@aHV9f$,?6$l$^$9!#$3$l$r(B
entity-number $B$H8F$S$^$9!#(Bentity-number $B$O(B S $B<0$H$7$F$O(B (1 2 3) $B$N$h$&(B
$B$J@0?t$N%j%9%H$H$7$FI=8=$5$l$^$9!#(B

  $B0lJ}!"(BMIME-View $B$G$O(B entity $B$N4IM}$K!"$3$l$HF1MM$N(B node-id $B$rMQ$$$^(B
$B$9!#(Bnode-id $B$O$A$g$&$I(B entity-number $B$r5U$K$7$?%j%9%H$G!"(Bentity-number
1.2.3 $B$KBP1~$9$k(B node-id $B$O(B (3 2 1) $B$G$9!#(B

  entity-number $B$d(B node-id $B$rMQ$$$k$3$H$G!"(Bmime-raw-message $B$K$*$1$kLZ(B
$B9=B$Cf$G$N(B entity $B$NAjBPE*$J0LCV4X78$r07$&$3$H$,$G$-$^$9!#(B

  $B0J>e$N$h$&$K(B entity $B$O(B mime-raw-buffer $B$G$OLZ9=B$$H$7$F4IM}$5$l$^$9(B
$B$,!"(Bmime-preview-buffer $B$G$O(B entity $B$OI=<(2hLL$KBP1~$9$kNN0h$H$7$F4IM}(B
$B$5$l!"A4BN$H$7$F$ONs9=B$$K$J$j$^$9!#<B:]$K$OJQ?t$,$"$kLu$G$O$J$/!"(B
`mime-view-entity' $B$H$$$&(B text-property $B$GI=8=$5$l$^$9!#(B

  entity $B$OC10l$N(B buffer $B$K$*$1$k4IM}$d>pJs$NI=8=$K;H$o$l$k0lJ}!"$3$N(B
$B#2$D$N(B buffer $B$r$D$J$0>pJs$H$7$F$bMQ$$$i$l$^$9!#(B


** API

[$B9=B$BN(B] mime-entity

	entity $B$K4X$9$k>pJs$r<}$a$k9=B$BN!#(B

	[$BMWAG(B]

	buffer			entity $B$,B8:_$9$k(B buffer (buffer).

	node-id			message $BA4BN$rI=$9(B entity $B$N3,AX$K$*$1$k!"(B
				$B$3$N(B entity $B$N@a$H$7$F$N0LCV$rI=$9(B id
				($B@0?t$N(B list).

	header-start		header $B$N@hF,0LCV(B (point).

	header-end		header $B$NKvHx0LCV(B (point).

	body-start		body $B$N@hF,0LCV(B (point).

	body-end		body $B$NKvHx0LCV(B (point).

	content-type		content-type $BMs$N>pJs(B (content-type).

	content-disposition	content-disposition $BMs$N>pJs(B
				(content-type).

	encoding		entity $B$N(B Content-Transfer-Encoding
				($BJ8;zNs(B)

	children		entity $B$K4^$^$l$k(B entity $B$N(B list
				(entity $B9=B$BN(B $B$N(B list).

	$B>e5-$NMWAG$O;2>H4X?t(B `mime-entity-$BMWAGL>(B' $B$G;2>H$9$k!#(B


	[$B5?;wMWAG(B]

	$B$^$?!"2a5n$H$N8_49@-$N$?$a!"0J2<$NMWAGL>$N;2>H4X?t$bMxMQ2DG=$G$"(B
	$B$k!#(B

	point-min	entity $B$N@hF,0LCV(B (point).

	point-max	entity $B$NKvHx0LCV(B (point).

	type/subtype	entity $B$N(B type/subtype ($BJ8;zNs(B).

	media-type	entity $B$N(B media-primary-type (symbol).

	media-subtype	entity $B$N(B media-subtype	 (symbol).

	parameters	entity $B$N(B Content-Type field $B$N(B parameter
			($BO"A[(B list).


[$B4X?t(B] make-mime-entity (node-id point-min point-max
			 media-type media-subtype parameters encoding
			 children)

	entity $B$N@8@.;R!#(B


[$B4X?t(B] mime-entity-number (ENTITY)

	ENTITY $B$N(B entity-number $B$rJV$9!#(B


[$B4X?t(B] mime-entity-parent (ENTITY &optional MESSAGE-INFO)

	ENTITY $B$N?F$N(B entity $B$rJV$9!#(B

	MESSAGE-INFO $B$,>JN,$5$l$?>l9g$O(B ENTITY $B$,B8:_$9$k(B buffer $B$K$*(B
	$B$1$k(B `mime-raw-message-info' $B$NCM$rMQ$$$k!#(B

	MESSAGE-INFO $B$,;XDj$5$l$?>l9g!"$3$l$r:,$H8+Jo$9!#(B


[$B4X?t(B] mime-root-entity-p (ENTITY)

	ENTITY $B$,(B root-entity$B!JB($A!"(Bmessage $BA4BN!K$G$"$k>l9g$K!"Hs(B
	nil $B$rJV$9!#(B



* entity $B$N2r<a$H:F@8$N;EAH$_(B

STD 11 $B$d(B MIME $B$O4pK\E*$K=qLL$N9=J8$rDj$a$k$N$_$G$"$j!"=qLL$r$I$N$h$&(B
$B$KI=<($9$Y$-$G$"$k$H$+(B entity $B$r$I$N$h$&$K:F@8$7$?$j=hM}$7$?$j$9$Y$-$+(B
$B$H$$$C$?$3$H$rDj$a$^$;$s!#$3$N$?$a!"MxMQ<T3&LL$O=qLL$N9=J8$r2r<a$7!"$3(B
$B$&$7$?$3$H$r7h$a$kI,MW$,$"$j$^$9!#(B

$B9=B$>pJs$+$i$=$NI=<($d:F@8!&=hM}$K4X$9$k?6Iq$rDj5A$9$k0lHV4JC1$JJ}K!$O(B
$B9=B$>pJs$KBP$7$F#1BP#1$G$3$&$7$?$3$H$r7h$a$F$7$^$&$3$H$G$9!#B($A!"9=B$(B
$B$KBP$7$FI=<($d:F@8!&=hM}$rM=$aDj5A$7$F$*$/$3$H$G$9!#$7$+$7!"$3$l$G$OI=(B
$B<($d:F@8!&=hM}$K4X$7$F0[$J$k%b%G%k$N<BAu$r:n$k$3$H$,$G$-$J$$!"$"$k$$$O!"(B
$B0[$J$k<BAu4V$G>pJs8r49$r9T$&$3$H$,:$Fq$K$J$j$^$9!#(BInternet $B$G$O0[$J$k(B
$B<BAu4V$G@5$7$/>pJs$,8r49$G$-$k$3$H$,5a$a$i$l$^$9$+$i!"$3$&$7$?$3$H$O$G(B
$B$-$^$;$s!#$^$?!"FCDj$N<BAu$,$3$&$7$?2>Dj$K4p$E$$$?7A<0$r@8@.$9$k$3$H$O(B
$B:.Mp$N85$H$J$j$^$9!#$h$C$F!"(BSTD 11 $B$d(B MIME $B$O0[$J$kI=<(!&=hM}%b%G%k!&(B
$B8+$+$1$r;}$C$?J#?t$N<BAu$KBP$7$FCfN)E*$J7A<0$rDj$a$k$h$&$K@_7W$5$l$F$$(B
$B$kLu$G$9!#(B

$B9=B$>pJs$KBP$7$F!"8+$+$1$rDs6!$9$kOHAH$H$7$F$O(B SGML, XML, HTML $BEy$GMQ(B
$B$$$k%9%?%$%k%7!<%H$H$$$&J}K!$,$"$j$^$9!#$3$l$O9=B$$KBP$9$k=hM}$r7A<0E*(B
$B$KDj5A$9$k$?$a$NOHAH$N>e$G!"8+$+$1$rDj5A$9$k%9%?%$%k%7!<%H$rDj5A$7!"MQ(B
$B$$$k%9%?%$%k%7!<%H$r;XDj$9$k$3$H$G!"9=B$$KBP$7$F8+$+$1$rM?$($^$9!#(B

MIME $B$N:F@8=hM}$K4X$7$F$O(B mailcap $B$H$$$&7A<0$,$"$j$^$9!#$3$l$O(B
media-type/subtype $BEy$N(B entity $B$N9=B$!&7A<0$K4X$9$k>pJs$KBP$7$F!"I=<((B
$B$d0u:~Ey$N:F@8!&=hM}$N;EJ}$rDj5A$7$^$9!#(B

$B$3$l$i$O9=B$>pJs$KBP$7$F7A<0E*$K$=$N0UL#$rM?$($kOHAH$G!"9=B$>pJs$KBP$9(B
$B$k0UL#$rJQ$($k$3$H$r2DG=$K$7$^$9!#$7$+$7$J$,$i!"9=B$$H0UL#$O#1BP#1BP1~(B
$B$G$"$j!"2r<a$N>u670MB8@-$,B8:_$7$^$;$s!#(BInternet $B$N=qLL$K$O>o$K7A<0$d(B
$B0UL#$NMI$l$,@8$8$F$$$^$9!#$3$l$O@d$($:?7$7$$%W%m%H%3%k$,Ds0F$5$l$k0lJ}!"(B
$B8E$$<BAu$b;D$j!"$^$?!"!XCO0h2=$5$l$?(B RFC 822$B!Y$N$h$&$J47=,E*$J$b$N$bB8(B
$B:_$9$k$+$i$G$9!#$^$?!"0lHLE*$G>\:Y$J5,Dj$rDj$a$?>l9g$b4JJX$J<BAu$,B8:_(B
$B$7!"5,Dj$r40A4$K%5%]!<%H$9$k<BAu$h$j$b4JJX$J<BAu$NJ}$,B??t$r@j$a$k$3$H(B
$B$,$7$P$7$P$G$9!#0lJ}!"5,Dj$rMQ$$$F>\:Y$K;XDj$5$l$?>pJs$OM-8z$KMxMQ$7$?(B
$B$$$N$,?M>p$G$9!#(B

$B0lJ}!"(B


* Preview $B$N@8@.(B

** $BI=<(>r7o(B

[$BJQ?t(B] mime-preview-condition

	entity $B$NI=<($K4X$9$k>r7oLZ!#(B


** entity-button

[$B4X?t(B] mime-view-entity-button-visible-p (ENTITY)

	$BHs(B nil $B$N>l9g!"(Bentity-button $B$rI=<($9$k$3$H$rI=$9!#(B


[$B4X?t(B] mime-view-insert-entity-button (ENTITY SUBJECT)

	ENTITY $B$N(B entity-button $B$rA^F~$9$k!#(B


** entity-header

  preview-situation $B$N(B 'header field $B$NCM$,(B 'visible $B$G$"$k;~!"$=$N(B 
entity$B$N(B header $B$,I=<($5$l$^$9!#(B


*** header-filter

*** cutter


** entity-body

  preview-situation $B$N(B 'body-presentation-method field $B$NCM$,(B 
'with-filter $B$G$"$k$+4X?t$G$"$k;~!"$=$N(B entity $B$N(B body $B$,I=<($5$l$^$9!#(B


*** body-presentation-method

  body-presentation-method $B$O(B body $B$N8+$+$1$r@8@.$9$k4X?t$G!"(B

       (entity preview-situation)

$B$H$$$&3&LL$r;}$C$F$$$^$9!#(B


*** body-filter

  preview-situation $B$N(B 'body-presentation-method field $B$NCM$,(B 
'with-filter $B$N;~$O!"(Bfilter $B$rMQ$$$k(B body-presentation-method $B$rMQ$$$k(B
$B$3$H$r<($7$F$$$^$9!#$3$N;~!"(Bpreview-situation $B$N(B 'body-filter field $B$N(B
$BCM$G<($5$l$k(B filter $B4X?t$G=hM}$5$l$?7k2L$,I=<($5$l$^$9!#(B

  $B$3$N(B filter $B4X?t$N3&LL$O(B

       (preview-situation)

$B$G$"$j!"$3$N4X?t$,8F$P$l$k;~!"=hM}BP>]$H$J$k(B entity $B$NFbMFM=$a(B buffer 
$B$KA^F~$5$l$F$*$j!"$^$?!"$=$NNN0h$O(B narrow $B$5$l$F$$$^$9!#(B


* Entity $B$N:F@8!&=hM}(B

MIME-View $B$OMxMQ<T$,:F@8A`:n$r9T$C$?;~$K!"<B9T4D6-$K1~$8$FE,@Z$J2r<a$r(B
$B9T$$!":F@8=hM}$r9T$&$?$a$N5!9=$rDs6!$7$^$9!#(B


	                 $B(.(,(,(,(,(,(,(,(,(,(/(B
       mime-raw-buffer   $B(-(B        	     $B(-(B
   $B(.(,(,(,(,(,(,(,(,(,(,(5(/(B      	     $B(-(B
   $B(-(Binformation of message$B(-(B      	     $B(-(B
   $B(-(B		           $B(-(B       	     $B(-(B
   $B(-(B  $B(#(!(!(!($(B operation$B(-(Btype$B(#(!(!(!($(B  $B(-(B       user's 
   $B(-(B  $B("(Bentity$B('"+(!(!(!(!(@(!(!()(Bentity$B('"+(@(!(!(!(B operation
   $B(-(B  $B(&(!(((!(%(#(!(!($(B  $B(-(B    $B(&(!(!(!(%(B  $B(-(B
   $B(-(B	   $B("(B    $B("(BMUA $B("(B  $B(-(B	             $B(-(B
   $B(-(B	   $B("(B    $B("(Btype$B("(B  $B(-(B		     $B(-(B
   $B(-(B	   $B("(B    $B(&(((!(%(B  $B(2(,(,(,(,(,(,(,(,(0(B
   $B(1(,(,(,(;(,(,(,(;(,(,(,(0(Bmime-preview-buffer
    	   $B("(B	   $B("(B
Information$B("(B	   $B("(B
   of	   $B("(B	   $B("(B
  entity   $B("(B	   $B("(B
   $B!\(B	   $B("(B	   $B("(B
 operation $B("(B	   $B("(B
  type     $B("(B  	   $B("(B
	   $B"-(B      $B"-(B	
         $B!?(:(,(,(,(:!@(B
         $B(-(B  draft   $B(-(B
         $B(-(B   of     $B(-(B
         $B(-(B  acting  $B(-(B
         $B(-(B situation$B(-(B
         $B!@(,(,(,(,(,!?(B
	       $B("(B
	       $B("(Bsearch
	       $B"-(B
     $B!?(,(,(,(,(,(,(,(,(,(,(,!@(B        $B!?(,(,(,(,(,!@(B
     $B(-(Bmime-acting-condition $B(-(!(!(!"*(-(B acting   $B(-(B
     $B!@(,(,(,(,(,(,(,(,(,(,(,!?(B        $B(-(Bsituation $B(-(B
              	                       $B!@(,(,(8(,(,!?(B
					     $B("(B
					     $B("(Bcall
					     $B"-(B
				       $B(.(,(,(:(,(,(/(B        playback
				       $B(-(Bprocessing$B(7(!(!(!"*(B  for
                                       $B(-(B method   $B(-(B          user
				       $B(1(,(,(,(,(,(0(B
			  $B?^(B: $B:F@8$N;EAH$_(B


[$BJQ?t(B] mime-acting-condition

	entity $B$N:F@8!&=hM}$K4X$9$k>r7oLZ!#(B
