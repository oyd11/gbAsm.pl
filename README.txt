
gbAsm.pl - A Gameboy CPU assembler in perl.

The actual assembling works, no label support, + bugs on num prefices (0x,$)

I was happy to see other very different assemblers written in Perl or
any other 'script' like simple assemblers, please mail me such references,
it could be useful to have an index of such assemblers somewhere.

Files:

gbAsm.pl       - The assembler
gbAsm.txt      - This file
opcodes.asm    - opcodes test
syntax.txt     - description of syntax
BLURB.TXT      - brief implementation blurb

The result of a (dirty-)hacking sunday + monday 'morning'. There seems to be other assemblers written in Perl avaliable online, all taking quite different approaches, and most seem to be weekend hacks. It seems that Perl is not the worst choice for quick assembler implementation, plus you get a certain degree of 'portability' for the host.
