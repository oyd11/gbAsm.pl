#!/usr/bin/perl
# gbAsm.pl - Assebler for the GameBoy CPU -
# A processor which is quite, but not entirely, unlike the Zilog Z-80.
#
# Version history:
#
# Initial Version 0.01 31st of May, 2003, by Oyd11
#

$version = 0.01;

# in case of weird bugs, check chomp'ing //'ing etc first...

($outFile,$inFile)=@ARGV;

Usage() unless defined $outFile;

$outFile="delme.bin" unless defined $outFile;
$hexDump=0;

my @out ; # binary output buffer
my @word; # current parsed word

########## Opcode definitions: ##############
sub NOP {
	push @out , 0x00 ;
}

sub def0operand {
	my (@opcodes) = @_;
	return sub {
		push @out , @opcodes ;
	}
}

# Typeglobs get us straight to the sym-table
*CCF = def0operand  0x3f ;
*CPL = def0operand  0x2f ;
*DAA = def0operand 0x27 ;
*DI = def0operand 0xf3 ; 
*EI = def0operand 0xfb ; 
*HALT = def0operand  0x76 ; 
*RETI = def0operand  0xd9 ; 
*RLA = def0operand  0x17 ; 
*RLCA = def0operand  0x07 ; 
*RRA = def0operand  0x1f ; 
*RRCA = def0operand  0x0f ; 
*SCF = def0operand  0x37 ; 
*STOP = def0operand  0x10 ; 

%reg8 = ( # 8bit regs, for most ops
	"B" => 0 ,
	"C" => 1 ,
	"D" => 2 ,
	"E" => 3 ,
	"H" => 4 ,
	"L" => 5 ,
#	"[HL]" => 6 ,
# '[' gives up a hard time, since it evals to anonymous array...
# if perl doesn't want us to use [] syntax, we'll use ()... no prob...
	"(HL)" => 6 ,
	"A" => 7 );

%reg16 = ( # regs for 16bit loads
	"BC" => 0 << 4,
	"DE" => 1 << 4 ,
	"HL" => 2 << 4,
	"SP" => 3 << 4);

%reg16stack = ( # regs for push/pop
	"BC" => 0 << 4,
	"DE" => 1 << 4 ,
	"HL" => 2 << 4,
	"AF" => 3 << 4);

%cc = ( # condition codes
	"NZ" => 0 << 3,
	"Z" => 1 << 3,
	"NC" => 2 << 3,
	"C" => 3 << 3);

%indRegs = ( # index regs, for 8bit loads
	"(BC)" => 0 << 4,
	"(DE)" => 1 << 4,
	"(HL+)" => 2 << 4,
	"(HLI)" => 2 << 4,
	"(HL-)" => 3 << 4,
	"(HLD)" => 3 << 4);

my $val; # val will be global, this is getting dirtier and dirtier...

sub getNum { # how do we pass by ref? this is so messy...
	my ($op)=@_;
	if ( $op =~ /^0x/ ) {
		$val = hex($op);
	} elsif ( $op =~ /^0/ ) {
		$val = oct($op) ;
	} elsif ( $op =~ s/^\$/0x/ ) {
		$val = hex($op);
	} elsif ( $op =~ /^-?\d+$/ ) {
		$val = $op;
	} else { # not a number
		undef $val;
#		return undef;
# Return undef ain't good, bare return compiles into:
# return ( wantarray ? () : undef ) ; or smthing...
		return;
	}
	$val;
}

sub def1operand46 {
	my ($opcode) = @_;
	return sub {
		my $opcode=$opcode; # create local version of closure var.
		my $op0=shift @in ;
		chomp $op0;
		getNum $op0;
		if (defined $val ) {  # is a number
			$val &= 0xff ; # be safe(r)
				$opcode |= 0x46;
			push @out , $opcode ,$val;
		} else {
			$op0 =~ tr/a-z/A-Z/ ;
# This is becoming stupid...
			my $opr0 = $reg8{ $op0 } ;
			if (!defined $opr0) { # not a valid reg..
				die " $op0 not a valid 8bit reg! ";
			}
			$opcode |= $opr0;
			push @out , $opcode ;
		}
	}
}

# def '46' sort of opcodes:
*OR = def1operand46  0xb0 ; 
*XOR = def1operand46  0xa8 ;
*AND = def1operand46 0xa0 ;
*CP = def1operand46 0xb8 ;
*SBC = def1operand46 0x98 ;
*SUB = def1operand46 0x90 ;
*ADC = def1operand46 0x88 ;

sub def1operandShifts {
	my ($opcode) = @_;
	return sub {
		my $opcode=$opcode; # create local version of closure var.
		my $op0=shift @in ;
		chomp $op0;
		$op0 =~ tr/a-z/A-Z/ ;
		my $opr0 = $reg8{ $op0 } ;
		if (!defined $opr0) { # not a valid reg..
			die " $op0 not a valid 8bit reg! ";
		}
		$opcode |= $opr0;
		push @out , 0xcb , $opcode ;
	}
}

*SWAP = def1operandShifts  0x30 ; 
*SLA = def1operandShifts  0x20 ; 
*SRA = def1operandShifts  0x28 ; 
*SRL = def1operandShifts  0x38 ; 
*RL = def1operandShifts  0x10 ; 
*RLC = def1operandShifts  0x00 ; 
*RR = def1operandShifts  0x18 ; 
*RRC = def1operandShifts  0x08 ; 

sub def1operandBits { # 'almost' the same...
	my ($opcode) = @_;
	return sub {
		my $opcode=$opcode; # create local version of closure var.
		my $op0=shift @in ;
#		chomp $op0;
# this chomp'ing thing is abit beyond me...
# I'm spending deci-minutes trying to find this sort of bugs here!
		getNum $op0;
		if (!defined $val ) {
			die 
" $op0 is not a number! Must provide n bits";
		}
		my $op1=shift @in ;
		chomp $op1;
		$op1 =~ tr/a-z/A-Z/ ;
		my $opr1 = $reg8{ $op1 } ;
		if (!defined $opr1) { # not a valid reg..
			die " $op1 not a valid 8bit reg! ";
		}
		$val <<=3;
		$opcode |= $opr1|$val;
		push @out , 0xcb , $opcode ;
	}
}

*BIT = def1operandBits 0x40;
*RES = def1operandBits 0x80;
*SET = def1operandBits 0xc0;

sub def1operandINC {
	my ($opcode8,$opcode16) = @_;
	return sub {
		my $opcode;
		my $op0=shift @in ;
		chomp $op0;
		$op0 =~ tr/a-z/A-Z/ ;
		my $opr0 = $reg8{ $op0 } ;
		if (defined $opr0) {
			$opcode = $opcode8;
			$opr0 <<=3;
		} else {
			$opr0 = $reg16{ $op0 };
			if (!defined $opr0) {
				die " $op0 not a valid reg for op ";
			}
			$opcode = $opcode16;
		}
		$opcode |= $opr0;
		push @out , $opcode ;
	}
}

*INC = def1operandINC 0x04,0x03;
*DEC = def1operandINC 0x05,0x0b;

sub ADD { # many cases.
	my $opcode;
	my $op0=shift @in ;
	my $op1;
	chomp $op0;
	getNum $op0;
	if (defined $val ) {
		$opcode = 0xc6 ;
		$val &= 0xff ; # be safe(r)
		return push @out , $opcode ,$val;
	}
	$op0 =~ tr/a-z/A-Z/ ;
	my $opr0 = $reg8{ $op0 } ;
	if (defined $opr0) {
		$opcode = 0x80;
		$opcode |= $opr0;
		return push @out , $opcode ;
	}
	if ( $op0 =~ /HL/ ) {
		$opcode=0x09;
		$op1 = shift @in;
		$op1 =~ tr/a-z/A-Z/ ;
		chomp $op1;
		$opr1 = $reg16{ $op1 };
		if (!defined $opr1) {
			die " $op0,$op1 not a valid reg comb op ";
		}
		$opcode |= $opr1;
		return push @out , $opcode ;
	}
	if ( $op0 =~ /SP/ ) {
		$opcode=0xe8;
		$op1 = shift @in;
		chomp $op1;
		getNum $op1;
		if (!defined $val ) {
			die 
" $op1 is not a number! 8bit offset expected.";
		}
		$val &= 0xff ; # be safe(r)
		return push @out , $opcode,$val ;
	}
	die " Invalid $op0 ";
}

sub def1operandPUSHPOP {
	my ($opcode) = @_;
	return sub {
		my $opcode=$opcode;
		my $op0=shift @in ;
		chomp $op0;
		$op0 =~ tr/a-z/A-Z/ ;
		my $opr0 = $reg16stack{ $op0 } ;
		if (!defined $opr0) {
die " Unexcepted regname $op0 ";
		}
		$opcode |= $opr0;
		push @out , $opcode ;
	}
}

*POP = def1operandPUSHPOP 0xc1;
*PUSH = def1operandPUSHPOP 0xc5;

sub RET {
	my $opcode=0xc0;
	my $op0=shift @in ;
	chomp $op0;
	if ($op0 =~ /^$/ ) {
		$opcode |= 0x09;
	} else {
		$op0 =~ tr/a-z/A-Z/ ;
		my $opr0 = $cc { $op0 } ;
		if (!defined $opr0) {
die " Unexcepted condition code $op0 ";
		}
		$opcode |= $opr0;
	}
	push @out , $opcode ;
}

sub JP { # 16bit jump
	my $opcode=0xc3;
	my $op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	if ($op0 =~ /^HL$/ ) {
		return push @out, 0xe9; # LD PC,HL
	}
	my $opr0 = $cc { $op0 } ;
	if (!defined $opr0) { # try to get number, else, assume it's a label.
getAddr:
		getNum $op0;
		if (!defined $val ) {
			$val = $resLabels{$op0};
#			if (!defined $val) {
#				push @unresLabels , $op0;
#				push @out , 0xc3;
##				push @patchList, $#out ;
#				# jp will have to be patched
#				return @out , 0x00;
#			}
			print "undefed Val!\n";
		}
		$val &= 0xffff ; # be safe(r)
		return push @out, $opcode,unpack("C2",pack "v",$val);
# output little-endian (as in GB) - pack/unpack should handler
# host's endianness..
		#return push @out, unpack("C2",pack "n",$val);
# output big-endian (for other assemblers.)
	}
	# we have a condition code. Jolly.
	$opcode =0xc2 | $opr0;
	$op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	goto getAddr;
}

sub JR { # 8bit offset jump
	my $opcode=0x18;
	my $op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	my $opr0 = $cc { $op0 } ;
	if (!defined $opr0) { # try to get number, else, assume it's a label.
getAddr:
		getNum $op0;
		if (!defined $val ) {
			$val = $resLabels{$op0};
#			if (!defined $val) {
#				push @unresLabels , $op0;
#				push @out , 0xc3;
##				push @patchList, $#out ;
#				# jp will have to be patched
#				return @out , 0x00;
#			}
		}
		$val &= 0xff ; # be safe(r)
		return push @out,$opcode,$val;
	}
	# we have a condition code. Jolly.
	$opcode =0x20 | $opr0;
	$op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	goto getAddr;
}

# Duplicating code for CALL, to avoid CALL (HL) case...
sub CALL { # 16bit CALL
	my $opcode=0xcd;
	my $op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	my $opr0 = $cc { $op0 } ;
	if (!defined $opr0) { # try to get number, else, assume it's a label.
getAddr:
		getNum $op0;
		if (!defined $val ) {
			$val = $resLabels{$op0};
#			if (!defined $val) {
#				push @unresLabels , $op0;
#				push @out , 0xc3;
##				push @patchList, $#out ;
#				# jp will have to be patched
#				return @out , 0x00;
#			}
			print "undefed Val!\n";
		}
		$val &= 0xffff ; # be safe(r)
		return push @out, $opcode,unpack("C2",pack "v",$val);
# output little-endian (as in GB) - pack/unpack should handler
# host's endianness..
		#return push @out, unpack("C2",pack "n",$val);
# output big-endian (for other assemblers.)
	}
	# we have a condition code. Jolly.
	$opcode =0xc4 | $opr0;
	$op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	goto getAddr;
}

# Simplify LD logic by using alternative mnemonics. 
# I prefer them anyway.
sub LDHL { # LDHL SP , n
	my $opcode=0xf8;
	my $op0=shift @in ;
	chomp $op0;
	$op0 =~ tr/a-z/A-Z/ ;
	die " $op0 unexpected operand "
		unless ($op0 =~ /^SP$/ );
	my $op1=shift @in;
	chomp $op1;
	getNum $op1;
	die " $op1 unexpected op " unless defined $val;
	$val &= 0xff;
	push @out, $opcode,$val;
}

sub LDSP { # LDSP HL
	my $opcode=0xf9;
	my $op0=shift @in ;
	chomp $op0;
	goto ok if ( $op0 =~ /^$/ ); # allow with no arg
	$op0 =~ tr/a-z/A-Z/ ;
	die " $op0 unexpected operand "
		unless ($op0 =~ /^HL$/ );
ok:
	push @out, $opcode;
}

sub LDIO { # Load/store in IO space ($ffxx)
# e2 e0 store at [c]/imm, f2 f0 ld from [c]/imm
	my $opcode=0xe0;
getop:
	my $op0=shift @in ;
	chomp $op0;
	if ($op0 =~ /^\((.*)\)/ ) {
# this is a 'store'
		$op0 = $1;
		getNum $op0;
		if (defined $val) {
			$val &= 0xff;
			return push @out , $opcode , $val;
		} else {
			$opcode |= 0x2;
die " unexpected op $op0 " unless ( $op0 =~ /[Cc]/ );
			return push @out , $opcode;
		}
	}
# this is a 'load'
	$opcode |= 0x10;
die " unexpected op $op0  " unless ($op0 =~ /[Aa]/ );
	goto getop;
}

sub LD { # Load is a nasty one...
# NOTE: LD (HL),(HL) proboably assembles as 'halt'
	my ($opcode,$op0,$op1,$opr0,$opr1);
	$op0=shift @in ;
	chomp $op0;
# TODO: a 'getinsideof()' func
	if ($op0 =~ /^\((.*)\)/ ) {
# this is a 'store'
		$op0 = $1;
		getNum $op0;
		if (defined $val) {
			$val &= 0xffff ;
			my %opcode = ( "SP" => 0x08, "A" => 0xEA );
			$op1=shift @in;
			chomp $op1;
			$op1=~ tr/a-z/A-Z/;
			$opcode = $opcode{$op1};
			die "unexpected $op1 " unless defined $opcode;
			return push @out, $opcode,unpack("C2",pack "v",$val);
		}
# check if it's an index reg:
		$op0=~ tr/a-z/A-Z/;
		$op0 = "(" . $op0 . ")" ; 
# Yeah, it's a bit silly, we just removed them...
		$opr0 = $indRegs{ $op0 };
		if (defined $opr0) {
			$opcode = 0x02 | $opr0;
			$op1 = shift @in;
			chomp $op1;
			die " unexpected $op1 " unless $op1 =~ /^[Aa]$/;

			return push @out,$opcode;
		}
doreg8:
		$opr0 = $reg8{ $op0 }; # it's here for (HL)
		if (defined $opr0) {
			$opr0 <<=3;
			$op1 = shift @in;
			chomp $op1;
			getNum $op1;
			if (!defined $val) {
				$op1 =~ tr/a-z/A-Z/;
				$opr1=$reg8{$op1};
				goto chk16bit unless defined $opr1;
				$opcode=0x40;
				$opcode |= $opr0 | $opr1;
				return push @out,$opcode;
			}
			$val&=0xff;
			$opcode = 0x06 | $opr0;
			return push @out,$opcode,$val;
		}
		die " $op0 unexcpected ";
	}
	$op0=~ tr/a-z/A-Z/;
	$opr0 = $reg8{$op0};
	goto doreg8 if defined $opr0;
# 16 bit loads here:
chk16bit:
	if ($op0 =~ /^A$/) {
### chk: ld a (de)
		$opr1 = $indRegs{$op1};
		if (!defined $opr1) {
			$op1 =~ s/^\((.*)\)/\1/  ;
			$op1 =~ s/X/x/; # it's been upcased..
			getNum $op1;
			if (!defined $val) {
				die " $op0 $op1 invalid reg comb ";
			}
			$val &= 0xffff;
			$opcode = 0xFA;
			return push @out, $opcode,unpack("C2",pack "v",$val);
		}
		$opcode = 0x0a | $opr1;
		return push @out,$opcode;
	}
# the actual 16 bit loads:
	$opr0=$reg16{$op0};
	die " $op0 unexpected " unless defined $opr0;
	$opcode = 0x01 | $opr0 ;
	$op1=shift @in;
	chomp $op1;
	$op1 =~ s/^\((.*)\)/\1/; # remove ()
	getNum $op1;
	die " $op0 $op1 unexpected " unless defined $val;
	return push @out, $opcode,unpack("C2",pack "v",$val);
} # END OF SUB 'LD'

sub RST { # last opcode, and a simple one...
	my $opcode=0xc7;
	my $op0=shift @in ;
	chomp $op0;
	getNum $op0;
	die " $op0 unexpected operand " unless defined $val;
	$val &=0xff;
	$opcode |= $val;
# TODO: maybe some error chking for value?
	return push @out , $opcode;
}

######### End of Opcode definitions. ###########


# ------------ Main Loop code: -------------

my $line = 1;

while (<>) {
	chomp;
	s/^\s*// ; # eat trailing (trailing?) spaces
	s/;.*// ; # remove comments
#	s/\s+/ /g ; # eat more spaces!
	next if /^$/;
	@in = split /[ ,]+/;
	foreach (@word) {
		chomp;
	}
#	next if ($#in == 0);
# for now, ',' is just like space, and words will just run.
	$first=shift @in;
	$first =~ tr/a-z/A-Z/ ; # convert opcode to UPPERCASE

	$err=eval $first;
	if ($err == undef) {
		die "Error assembling line $line!\n >> '$_'\n !! $@" 
	}
	++$line;
}

if ($hexDump) {
foreach (@out) {
	printf("%.2X",$_);
	print "."; #
} print "\n";}

foreach (@out) {
	$_ = chr($_);
} # convert to binary... I hate this nonsence. I didn't want to 
# store strings in the first place...
# maybe we can do it?? hmm...
# if we emit the chr, chk it...

open OUTBIN , ">$outFile" or die $!;
print "Writing to opcodes to $outFile\n";
binmode OUTBIN;
{
	undef $,; # field sep, just in case
	undef $\ ; # record sep, just in case
	print OUTBIN @out ;
}

print "Done.\n";

############## End Of Main ################
	
sub Usage {
	print " $0 Version $version\n";
	print "Usage: $0 <outBinFile> [<in TextFile>]\n";
	print "if no 'in' provides, assembles from stdin\n";
	die "missing parameters!";
}

