{****************************************************************************}
{****************************************************************************}
{**           Copyright (C) Alessandro Carminati 1997,1998                 **}
{**        You are not allowed  to distribute this software                **}
{**        commercially. Please, notify me, if you make any                **}
{**                     changes to this file.                              **}
{****************************************************************************}
{*********] Written by Alessandro Carminati  (Handle@freemail.it) [**********}
{****************************************************************************}
{$G+}{$V-}
{$M 16384,0,0}

const	nmi_cycle= 50000;
	int_cycle=100000;
	main_clock:array [0..$ff] of byte=( 
		04,10,07,06,04,04,07,04,04,11,07,06,04,04,07,04,
		10,10,07,06,04,04,07,04,12,11,07,06,04,04,07,04,
		10,10,16,06,04,04,07,04,10,11,16,06,04,04,07,04,
		10,10,13,06,11,11,10,04,10,11,13,06,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		07,07,07,07,07,07,04,07,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		04,04,04,04,04,04,07,04,04,04,04,04,04,04,07,04,
		08,10,10,10,14,10,07,11,08,08,10,00,14,14,07,11,
		08,10,10,11,14,10,07,11,08,04,10,11,14,00,07,11,
		08,10,10,04,14,10,07,11,08,04,10,04,14,00,07,11,
		08,10,10,04,14,10,07,11,08,06,10,04,14,00,07,11);

					{F3,-,F1,-,SP,<-,->,-   -,-,t ,-,-,-,-,-}
	scancodes:array[0..$f] of byte= (61,0,59,0,57,75,77,0,  0,0,20,0,0,0,0,0);
	nomi:array [0..$20] of string[11]=(
		'invaders.h','invaders.g','invaders.f','invaders.e','invdelux.h','invdelux.g',
		'invdelux.f','invdelux.e','invdelux.d','galxwars.0','galxwars.1','galxwars.2',
		'galxwars.3','galxwars.4','galxwars.5','lrescue.1' ,'lrescue.2' ,'lrescue.3',
		'lrescue.4', 'lrescue.5', 'lrescue.6', 'earthinv.h','earthinv.g','earthinv.f',
		'earthinv.e','spaceatt.h','spaceatt.g','spaceatt.f','spaceatt.e','invrvnge.h',
		'invrvnge.g','invrvnge.f','invrvnge.e');
	address:array [0..$20] of word=(
		$0000,$0800,$1000,$1800,$0000,$0800,$1000,$1800,$4000,$0000,$0400,$0800,$0c00,
		$4000,$4400,$0000,$0800,$1000,$1800,$4000,$4800,$0000,$0800,$1000,$1800,$0000,
		$0800,$1000,$1800,$0000,$0800,$1000,$1800);
	index :array [0..7] of byte=($00,$04,$09,$0f,$15,$19,$1d,$21);
	xm      : array[1..54] of WORD=(
		$0008,$5f00,$3f01,$4202,$9f03,$4c04,$0005,$0014,$e317,                   { 256X200 }
		$0010,$5f00,$3f01,$4202,$9f03,$4c04,$0005,$0d06,$3e07,$4109,$ea10,$ac11,
		$df12,$0014,$e715,$0616,$e317,                                           { 256X240 }
		$0002,$0014,$E317,                                                       { 320X200 }
		$000b,$0d06,$3e07,$4109,$ea10,$ac11,$df12,$0014,$e715,$0616,$e317,       { 320X240 }
		$0003,$4009,$0014,$E317,                                                 { 320X400 }
		$0009,$6B00,$5901,$5A02,$8E03,$5E04,$8A05,$4009,$0014,$E317              { 360X400 });
	index_xm: ARRAY[1..6] of byte=($00,$09,$1a,$1d,$28,$2c);

var
(* System state *)
	main_code,cb_code,dd_code,ed_code,fd_code:	array[0..$ff] of pointer;
	cycle_code,in_code,out_code:			array[0..$ff] of pointer;
	ports:						array[0..$ff] of byte;
	c,b,e,d,l,h,f,a:				byte;
	ix,iy,spz,ip:					word;
	im,iff1,iff2,i, r,halt:				byte;
	cpr,bpr,epr,dpr,lpr,hpr,fpr,apr:		byte;
	buffer:						array[0..7] of byte;
	vmem,z80mem:					word;

(* Others *)
	int,nmi:					longint;
	s:						string;
	edit_counter:					word;
	x,xx:						^byte;
	ww:						^word;
	action:						string;
	handle:						word;
	cont,ed,go:					byte;
	i1,j1,STOP:					WORD;
	key_table:					array[0..127]of byte;
	p,old9:						pointer;
	int_status:					byte;
	deeps:						byte;
label 1;
procedure xmode(mode:byte;var x,y);assembler;
asm
        push    ds
        mov     ax,13h
        int     10h
        mov     ax,604h
        mov     dx,3C4h
        out     dx,ax
        mov     ax,100h
        out     dx,ax
        mov     dl,0C2h
        mov     al,0E3h
        out     dx,al
        mov     dl,0C4h
        mov     ax,300h
        out     dx,ax
        mov     al,11h
        mov     dl,0D4h
        out     dx,al
        inc     dx
        in      al,dx
        and     al,7Fh
        out     dx,al
        lds     si,y
        mov     al,mode
        xor     ah,ah
        add     si,ax
        lodsb
        lds     si,x
        add     ax,ax
        add     si,ax
        mov     dx,3d4h
        lodsw
        mov     cx,ax
        rep     outsw
        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax
        mov     ax,0A000h
        mov     es,ax
        xor     di,di
        mov     cx,8000h
        xor     ax,ax
        rep     stosw
        mov     dl,0D4h
        mov     al,13h
        out     dx,al
        inc     dx
        mov     al,28h
        out     dx,al
        pop     ds
end;
procedure fclose(handle:word);assembler;
asm
        Mov     ax,3e00h
        Mov     Bx,handle
        Int     21h
        mov     al,1
        Jnc     @Fine
        xor     al,al
@Fine:
end;
procedure clear(W:word);assembler;
asm
        mov     ax,w
        mov     es,ax
        xor     di,di
        mov     cx,$8000
        xor     ax,ax
        rep     stosw
end;
function gdm(size:word):word;assembler;
asm
        mov    bx,size
        shr    bx,4
        inc    bx
        mov    ah,48h
        int    21h
        jnc    @error
        mov    ax,0
@error:
end;
Function Fopen(Var Nome_F:String):word;Assembler;
asm
        push    ds
        mov     ax,3d00h
        lds     dx,nome_f
        inc     dx
        int     21h
        jnc     @Fine
        mov     ax,0ffffh
@fine:  pop ds
end;
function Fread(Handle:Word;Bytes,offset_:Word;var Buffer):word;Assembler;
Asm
        push    ds
        mov     bx,handle
        lds     dx,buffer
        add     dx,offset_
        mov     cx,bytes
        mov     ah,3Fh
        int     21h
        pop     ds
end;

(*              386'S bit operating code
BTS 0F BA E8 NN
BTR 0F BA F0 NN
BTC 0F BA F8 NN
BT  0F BA E0 NN
z80's   flags                          ³S ³Z ³  ³H ³  ³P ³N ³C ³
80X86'S FLAGS  ³  ³  ³  ³  ³O ³D ³I ³T ³S ³Z ³  ³H ³  ³P ³N ³C ³
                F  E  D  C  B  A  9  8  7  6  5  4  3  2  1  0
*)

procedure z80_virtual(ini:byte);assembler;
asm
                cmp     ini,0
                jnz     @fetchco
                jmp     @init
@Address:       dw      offset @start_building
                dw      offset @cb_code
                dw      offset @dd_code
                dw      offset @ed_code
                dw      offset @fd_code
                dw      offset @d_cb_code
                dw      offset @in_code
                dw      offset @out_code
@init:          push    ds
                push    ds
                pop     es
                mov     di,offset main_code
                push    cs
                pop     ds
                mov     bx,offset @address
                mov     dl,8			{number of iterations}
@n_iter:        mov     ax,cs:[bx]		{get offset from @address table}
                MOV     SI,ax
                mov     cx,$100
@l:             lodsb
                cmp     al,$c3
                jnz     @loop
                lodsb
                cmp     al,$90
                jnz     @loop
                mov     ax,si
                stosw
                mov     ax,ds
                stosw
                dec     cx
                jz      @llo
@loop:          jmp     @l
@llo:           add     bx,2			{ next address of the address @table}
                dec     dl			{ here di points to the first element}
                jnz     @n_iter			{ of the next look up table}
                pop     ds
                jmp     @@end

@fetchco:       call    @fetchb
                xor     AH,AH
                shl     ax,2
                mov     bx,ax
                add     bx,offset main_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                jmp     @@end
@take:          push    ds			{ regs at call: si=address => al=data }
                mov     ax,z80mem
                mov     ds,ax
                lodsb
                pop     ds
                ret
@takeW:         push    ds			{ regs at call: si=address => ax=data }
                mov     ax,z80mem
                mov     ds,ax
                lodsw
                pop     ds
                ret
@pixel:         db      $66,$60			{ pushad }
                push    es
                push    ax
                DB      $66,$33,$C0		{ xor eax,eax }
                DB      $66,$33,$FF		{ xor edi,edi }
                mov     ax,dx
                mov     di,cx
                xchg    ah, al
                DB      $66,$03,$F8		{ add edi,eax }
                DB      $66,$C1,$E8,$02		{ shr edi,2 }
                DB      $66,$03,$F8		{ add edi,eax }
                DB      $66,$8B,$CF		{ mov ecx,edi }
                DB      $66,$C1,$EF,$02		{ shr edi,2 } {offset}
                and     cx,3			{ plane }
                mov     ax,0A000h
                mov     es,ax
                mov     dx,03C4h
                mov     ax,102h
                shl     ah,cl
                out     dx,ax
                pop     ax
                stosb
                pop     es
                db      $66,$61			{ popad }
                ret
@vmem:          pusha
                mov     bh,al
                mov     dx,di
                sub     dx,$2400
                mov     cx,dx
                shr     cx,5
                and     dx,$1f
                shl     dx,3
                sub     dx,0ffh
                neg     dx
                mov     ah,0ch
                mov     bl,8
@vmcycle:       and     al,1
                push    bx
                xor     bx,bx
                or      al,al
                jz      @print
                mov     al,4
                cmp     dl,64
                jb      @print
                mov     al,$f
                cmp     dl,192
                jb      @print
                mov     al,2
@print:         call    @pixel
                pop     bx
                shr     bh,1
                mov     al,bh
                dec     dx
                dec     bl
                jnz     @vmcycle
                popa
                ret
@put:           pushf
                pusha
                push    es
                push    word ptr [z80mem]
                pop     es
                cmp     di,$2000
                jb      @nowrite		{ meno di $2000 Ã¨ rom }
                cmp     di,$3fff
                ja      @nowrite		{ oltre $3fff non c'Ã¨ niente }
                cmp     di,$2400
                jb      @store			{ da $2400 fino a $3fff c'Ã¨ memoria }
                call    @vmem			{ video }
@store:         stosb
@nowrite:       pop     es
                popa
                popf
                ret
@putw:          pushf
                pusha
                push    es
                push    word ptr [z80mem]
                pop     es
                cmp     di,$2000
                jb      @nowritew		{ meno di $2000 Ã¨ rom }
                cmp     di,$3fff
                ja      @nowritew		{ oltre $3fff non c'Ã¨ niente }
                cmp     di,$2400
                jb      @storew			{ da $2400 fino a $3fff c'Ã¨ memoria }
                call    @vmem			{ video }
                inc     di
                xchg    al,ah
                call    @vmem
                xchg    al,ah
                dec     di
@storew:        stosw
@nowritew:      pop     es
                popa
                popf
                ret
@fetchb:        pushf
                push    di
                push    si
                push    ds
                mov     ax,z80mem
                mov     si,ip
                mov     ds,ax
                lodsb
                pop     ds
                add     ip,1
                pop     si
                pop     di
                popf
                ret
@flag_lop:      pusha
                pushf				{ cl=0 #OR->H=0   cl=1 AND-> H=1 }
                pop     ax			{ sets Z S P}
                db      $0F,$BA,$E8,$01		{ bts ax,1   }{  set N}
                db      $0F,$BA,$F0,$00		{ btr ax,0   }{reset C}
                db      $0F,$BA,$F0,$04		{ btr ax,4   }{reset H}
                or      cl,cl
                jz      @lor
                db      $0F,$BA,$E8,$04		{ bts ax,4   }{  set H}
@lor:           mov     byte ptr [f],al		{ Store Z80 flags }
                popa
                ret
@flag_a16b:     pusha
                pushf				{ flags nello stack }
                pop     bx			{ flags dentro bx }
                and     bl,1			{ rimane solo C }
                mov     al,f			{ z80 flag in al }
                and     al,$fe			{ reset z80 C }
                db      $0F,$BA,$F0,$01		{ btr ax,1   } { reset N flag }
                or      cl,cl
                jz      @piu
                db      $0F,$BA,$E8,$01		{ bts ax,1   }{set N flag}
@piu:           or      al,bl
                mov     byte ptr [f],al
                popa
                ret
@flag_rxxa:     pusha
                pushf
                pop     ax
                and     al,1
                mov     bl,byte ptr [f]
                and     bl,$fe			{ only C flag }
                or      al,bl
                db      $0F,$BA,$F0,$01		{ btr ax,1   }{reset N flag}
                db      $0F,$BA,$F0,$04		{ btr ax,4   }{reset H}
                mov     byte ptr [f],al
                popa
                ret
@flag_aop:      pusha
                pushf
                pop     ax
                or      ch,ch
                jnz     @a1
                mov     bl,byte ptr[f]
                and     bl,$1
                and     al,0feh
                or      al,bl
@a1:            db      $0F,$BA,$F0,$01		{ btr ax,1   }{reset N flag}
                or      cl,cl
                jz      @_inc
                db      $0F,$BA,$E8,$01		{ bts ax,1   }{set   N flag}
@_inc:          db      $0F,$BA,$F0,$02		{ btr ax,2   }
                db      $0F,$BA,$E0,$0b		{ bt  ax,0bh }{get V flag}
                jnc     @incb1
                db      $0F,$BA,$e8,$02		{ bts ax,2   }{ up v flag }
@incb1:         mov     byte ptr [f],al
                popa
                ret
@bit_flag:      pushf
                pop     ax
                not     al
                and     al,01000000b
                mov     ah,byte ptr[f]
                and     ah,10111111b
                or      al,ah
                db      $0F,$BA,$e8,$04		{ bts ax,4   }{  set H}
                db      $0F,$BA,$F0,$01		{ btr ax,1   }{reset N flag}
                mov     byte ptr [f],al
                ret
@flag_rot:      or      al,al
                db      $0F,$BA,$F0,$01		{ btr ax,1   }{reset N flag}
                db      $0F,$BA,$F0,$04		{ btr ax,4   }{reset H}
                mov     byte ptr [f],al
                ret
@fetchw:        pushf
                push    ds
                mov     ax,z80mem
                mov     si,ip
                mov     ds,ax
                lodsw
                pop     ds
                add     ip,2
                popf
@start_building:ret;nop
@NOP:           ret;nop
@LD_BC_nn:      call    @fetchw
                mov     word ptr [c],ax		{ ho messo c invece che bc }
                ret;nop
@LD__BC__A:     mov     di,word ptr [c]
                mov     al,byte ptr [a]
                call    @put
                ret;nop
@INC_BC:        inc     word ptr [c]
                ret;nop
@INC_B:         inc     byte ptr [b]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_B:         dec     byte ptr [b]
                mov     cl,1
                call    @flag_aop
                ret;nop
@LD_B_n:        call    @fetchb
                mov     byte ptr [b],al
                ret;nop
@RLCA:          rol     byte ptr [a],1
                call    @flag_rxxa
                ret;nop
@EX_AF_AFp:     mov     ax,word ptr [f]
                mov     bx,word ptr [fpr]
                mov     word ptr [fpr],ax
                mov     word ptr [f],bx
                ret;nop
@ADD_HL_BC:     mov     bx,word ptr [c]
                add     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_A__BC_:     mov     si,word ptr [c]
                call    @take			{ ax <- ds:[si] }
                mov     byte ptr [a],al
                ret;nop
@DEC_BC:        dec     word ptr [c]		{non modifica i flag}
                ret;nop
@INC_C:         inc     byte ptr [c]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_C:         dec     byte ptr [c]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_C_n:        call    @fetchb
                mov     byte ptr [c],al
                ret;nop
@RRCA:          ror     a,1
                call    @flag_rxxa
                ret;nop
@DJNZ_e:        call    @fetchb			{al contains offset of jump}
                cbw
                dec     byte ptr [b]		{It MUST be b }
                jz      @no_djnz
                add     word ptr [ip],ax
@no_djnz:       ret;nop
@LD_DE_nn:      call    @fetchw
                mov     word ptr [e],ax
                ret;nop
@LD__DE__A:     mov     di,word ptr[e]
                mov     al,byte ptr[a]
                call    @put
                ret;nop
@INC_DE:        inc     word ptr [e]
                ret;nop
@INC_D:         inc     byte ptr [d]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_D:         dec     byte ptr [d]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_D_n:        call    @fetchb
                mov     byte ptr [d],al
                ret;nop
@RLA:           mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [a],1
                call    @flag_rxxa
                ret;nop
@JR_e:          call    @fetchb
                cbw
                add     [ip],ax
                ret;nop
@ADD_HL_DE:     mov     ax,word ptr [e]
                add     word ptr [l],ax
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_A__DE_:     mov     si,word ptr [e]
                call    @take
                mov     byte ptr [a],al
                ret;nop
@DEC_DE:        dec     word ptr [e]
                ret;nop
@INC_E:         inc     byte ptr [e]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_E:         dec     byte ptr [e]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_E_n:        call    @fetchb
                mov     byte ptr [e], al
                ret;nop
@RRA:           mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [a],1
                call    @flag_rxxa
                ret;nop
@JR_NZ_e:       mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                call    @fetchb
                jc      @njrnz
                cbw
                add     [ip],ax
@njrnz:         ret;nop
@LD_HL_nn:      call    @fetchw
                mov     word ptr [l],ax
                ret;nop
@LD__nn__HL:    call    @fetchw
                mov     di,ax
                mov     ax,word ptr [l]
                call    @putw
                ret;nop
@INC_HL:        inc     word ptr [l]
                ret;nop
@INC_H:         inc     byte ptr [h]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_H:         dec     byte ptr [e]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_H_n:        call    @fetchb
                mov     byte ptr [h],al
                ret;nop
@DAAsp:         pushf
                mov     al,[f]
                xor     ah,ah
                push    ax
                popf
                mov     al,[a]
                daa
                mov     [a],al
                mov     al,[f]
                pushf
                pop     cx
                and     al,2
                and     cl,11111101b
                or      al,cl
                mov     [f],al
                popf
                ret;nop
@JR_Z_e:        mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                call    @fetchb
                jnc     @njrz
                cbw
                add     [ip],ax
@njrz:          ret;nop
@ADD_HL_HL:     mov     bx,word ptr [l]
                add     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_HL__nn_:    call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [l],ax
                ret;nop
@DEC_HL:        dec     word ptr [l]
                ret;nop
@INC_L:         inc     byte ptr [l]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_L:         dec     byte ptr [l]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_L_n:        call    @fetchb
                mov     byte ptr [l],al
                ret;nop
@CPL:           not     [a]
                or      [f],$12
                ret;nop
@JR_NC_e:       mov     al,[f]
                db      $0F,$BA,$E0,0		{bt al,0} {test C flag}
                call    @fetchb
                jc      @njrnc
                cbw
                add     [ip],ax
@njrnc:         ret;nop
@LD_SP_nn:      call    @fetchw
                mov     word ptr[spz],ax
                ret;nop
@LD__nn__A:     call    @fetchw
                mov     di,ax
                mov     al,byte ptr [a]
                call    @put
                ret;nop
@INC_SP:        inc     word ptr [spz]
                ret;nop
@INC__HL_:      mov     si,word ptr [l]
                call    @take
                inc     al
                mov     cx,0
                call    @flag_aop
                mov     di,si
                dec     di
                call    @put
                ret;nop
@DEC__HL_:      mov     si,word ptr [l]
                call    @take
                dec     al
                mov     cx,1
                call    @flag_aop
                mov     di,si
                dec     di
                call    @put
                ret;nop
@LD__HL__n:     mov     di,word ptr [l]
                call    @fetchb
                call    @put
                ret;nop
@SCF:           mov     al,f			{set carry flag}
                db      $0F,$BA,$E8,0		{BTS ax,0}
                db      $0F,$BA,$F0,1		{BTR ax,1}
                db      $0F,$BA,$F0,4		{BTR ax,4}
                mov     f,al
                ret;nop
@JR_C_e:        mov     al,[f]
                db      $0F,$BA,$E0,0		{bt al,0} {test C flag}
                call    @fetchb
                jnc     @njrc
                cbw
                add     [ip],ax
@njrc:          ret;nop
@ADD_HL_SP:     mov     ax,word ptr[spz]
                add     word ptr [l],ax
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_A__nn_:     call    @fetchw
                mov     si,ax
                call    @take
                mov     byte ptr[a],al
                ret;nop
@DEC_SP:        dec     word ptr [spz]
                ret;nop
@INC_A:         inc     byte ptr [a]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_A:         dec     byte ptr [a]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_A_n:        call    @fetchb
                mov     byte ptr[a],al
                ret;nop
@CCF:           mov     al,f			{complements carry flag}
                db      $0F,$BA,$F8,0		{BTC ax,0}
                db      $0F,$BA,$F0,1		{BTR ax,1}
                mov     f,al
                ret;nop
@LD_B_B:        mov     al,byte ptr[b]
                mov     byte ptr[b],al
                ret;nop
@LD_B_C:        mov     al,byte ptr[c]
                mov     byte ptr[b],al
                ret;nop
@LD_B_D:        mov     al,byte ptr[d]
                mov     byte ptr[b],al
                ret;nop
@LD_B_E:        mov     al,byte ptr[e]
                mov     byte ptr[b],al
                ret;nop
@LD_B_H:        mov     al,byte ptr[h]
                mov     byte ptr[b],al
                ret;nop
@LD_B_L:        mov     al,byte ptr[l]
                mov     byte ptr[b],al
                ret;nop
@LD_B__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[b],al
                ret;nop
@LD_B_A:        mov     al,byte ptr[a]
                mov     byte ptr[b],al
                ret;nop
@LD_C_B:        mov     al,byte ptr[b]
                mov     byte ptr[c],al
                ret;nop
@LD_C_C:        mov     al,byte ptr[c]
                mov     byte ptr[c],al
                ret;nop
@LD_C_D:        mov     al,byte ptr[d]
                mov     byte ptr[c],al
                ret;nop
@LD_C_E:        mov     al,byte ptr[e]
                mov     byte ptr[c],al
                ret;nop
@LD_C_H:        mov     al,byte ptr[h]
                mov     byte ptr[c],al
                ret;nop
@LD_C_L:        mov     al,byte ptr[l]
                mov     byte ptr[c],al
                ret;nop
@LD_C__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[c],al
                ret;nop
@LD_C_A:        mov     al,byte ptr[a]
                mov     byte ptr[c],al
                ret;nop
@LD_D_B:        mov     al,byte ptr[b]
                mov     byte ptr[d],al
                ret;nop
@LD_D_C:        mov     al,byte ptr[c]
                mov     byte ptr[d],al
                ret;nop
@LD_D_D:        mov     al,byte ptr[d]
                mov     byte ptr[d],al
                ret;nop
@LD_D_E:        mov     al,byte ptr[e]
                mov     byte ptr[d],al
                ret;nop
@LD_D_H:        mov     al,byte ptr[h]
                mov     byte ptr[d],al
                ret;nop
@LD_D_L:        mov     al,byte ptr[l]
                mov     byte ptr[d],al
                ret;nop
@LD_D__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[d],al
                ret;nop
@LD_D_A:        mov     al,byte ptr[a]
                mov     byte ptr[d],al
                ret;nop
@LD_E_B:        mov     al,byte ptr[b]
                mov     byte ptr[e],al
                ret;nop
@LD_E_C:        mov     al,byte ptr[c]
                mov     byte ptr[e],al
                ret;nop
@LD_E_D:        mov     al,byte ptr[d]
                mov     byte ptr[e],al
                ret;nop
@LD_E_E:        mov     al,byte ptr[e]
                mov     byte ptr[e],al
                ret;nop
@LD_E_H:        mov     al,byte ptr[h]
                mov     byte ptr[e],al
                ret;nop
@LD_E_L:        mov     al,byte ptr[l]
                mov     byte ptr[e],al
                ret;nop
@LD_E__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[e],al
                ret;nop
@LD_E_A:        mov     al,byte ptr[a]
                mov     byte ptr[e],al
                ret;nop
@LD_H_B:        mov     al,byte ptr[b]
                mov     byte ptr[h],al
                ret;nop
@LD_H_C:        mov     al,byte ptr[c]
                mov     byte ptr[h],al
                ret;nop
@LD_H_D:        mov     al,byte ptr[d]
                mov     byte ptr[h],al
                ret;nop
@LD_H_E:        mov     al,byte ptr[e]
                mov     byte ptr[h],al
                ret;nop
@LD_H_H:        mov     al,byte ptr[h]
                mov     byte ptr[h],al
                ret;nop
@LD_H_L:        mov     al,byte ptr[l]
                mov     byte ptr[h],al
                ret;nop
@LD_H__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[h],al
                ret;nop
@LD_H_A:        mov     al,byte ptr[a]
                mov     byte ptr[h],al
                ret;nop
@LD_L_B:        mov     al,byte ptr[b]
                mov     byte ptr[l],al
                ret;nop
@LD_L_C:        mov     al,byte ptr[c]
                mov     byte ptr[l],al
                ret;nop
@LD_L_D:        mov     al,byte ptr[d]
                mov     byte ptr[l],al
                ret;nop
@LD_L_E:        mov     al,byte ptr[e]
                mov     byte ptr[l],al
                ret;nop
@LD_L_H:        mov     al,byte ptr[h]
                mov     byte ptr[l],al
                ret;nop
@LD_L_L:        mov     al,byte ptr[l]
                mov     byte ptr[l],al
                ret;nop
@LD_L__HL_:     mov     si,word ptr[l]
                call    @take
                mov     byte ptr[l],al
                ret;nop
@LD_L_A:        mov     al,byte ptr[a]
                mov     byte ptr[l],al
                ret;nop
@LD__HL__B:     mov     di,word ptr[l]
                mov     al,byte ptr[b]
                call    @put
                ret;nop
@LD__HL__C:     mov     di,word ptr[l]
                mov     al,byte ptr[c]
                call    @put
                ret;nop
@LD__HL__D:     mov     di,word ptr[l]
                mov     al,byte ptr[d]
                call    @put
                ret;nop
@LD__HL__E:     mov     di,word ptr[l]
                mov     al,byte ptr[e]
                call    @put
                ret;nop
@LD__HL__H:     mov     di,word ptr[l]
                mov     al,byte ptr[h]
                call    @put
                ret;nop
@LD__HL__L:     mov     di,word ptr[l]
                mov     al,byte ptr[l]
                call    @put
                ret;nop
@HALT:          mov     halt,1
                ret;nop
@LD__HL__A:     mov     di,word ptr[l]
                mov     al,byte ptr[a]
                call    @put
                ret;nop
@LD_A_B:        mov     al,byte ptr[b]
                mov     byte ptr[a],al
                ret;nop
@LD_A_C:        mov     al,byte ptr[c]
                mov     byte ptr[a],al
                ret;nop
@LD_A_D:        mov     al,byte ptr[d]
                mov     byte ptr[a],al
                ret;nop
@LD_A_E:        mov     al,byte ptr[e]
                mov     byte ptr[a],al
                ret;nop
@LD_A_H:        mov     al,byte ptr[h]
                mov     byte ptr[a],al
                ret;nop
@LD_A_L:        mov     al,byte ptr[l]
                mov     byte ptr[a],al
                ret;nop
@LD_A__HL_:     mov     si,word ptr [l]
                call    @take			{ ax <- ds:[si] }
                mov     a,al
                ret;nop
@LD_A_A:        mov     al,byte ptr[a]
                mov     byte ptr[a],al
                ret;nop
@ADD_A_B:       mov     al,byte ptr[b]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_C:       mov     al,byte ptr[c]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_D:       mov     al,byte ptr[d]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_E:       mov     al,byte ptr[e]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_H:       mov     al,byte ptr[h]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_L:       mov     al,byte ptr[l]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A__HL_:    mov     si,word ptr[l]
                call    @take
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_A:       mov     al,byte ptr[a]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_B:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[b]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_C:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[c]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_D:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[d]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_E:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[e]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_H:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[h]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_L:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[l]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A__HL_:    mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[l]
                call    @take
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_A:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[a]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@SUB_B:         mov     al,byte ptr[b]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_C:         mov     al,byte ptr[c]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_D:         mov     al,byte ptr[d]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_E:         mov     al,byte ptr[e]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_H:         mov     al,byte ptr[h]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_L:         mov     al,byte ptr[l]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB__HL_:      mov     si,word ptr[l]
                call    @take
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_A:         mov     al,byte ptr[a]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_B:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[b]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_C:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[c]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_D:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[d]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_E:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[e]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_H:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[h]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_L:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[l]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A__HL_:    mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[l]
                call    @take
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_A:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[a]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@AND_B:         mov     al,byte ptr[b]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_C:         mov     al,byte ptr[c]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_D:         mov     al,byte ptr[d]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_E:         mov     al,byte ptr[e]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_H:         mov     al,byte ptr[h]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_L:         mov     al,byte ptr[l]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND__HL_:      mov     si,word ptr[l]
                call    @take
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_A:         mov     al,byte ptr[a]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@XOR_B:         mov     al,byte ptr[b]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_C:         mov     al,byte ptr[c]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_D:         mov     al,byte ptr[d]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_E:         mov     al,byte ptr[e]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_H:         mov     al,byte ptr[h]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_L:         mov     al,byte ptr[l]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR__HL_:      mov     si,word ptr[l]
                call    @take
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_A:         mov     al,byte ptr[a]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_B:          mov     al,byte ptr [b]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_C:          mov     al,byte ptr [c]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_D:          mov     al,byte ptr [d]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_E:          mov     al,byte ptr [e]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_H:          mov     al,byte ptr [h]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_L:          mov     al,byte ptr [l]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR__HL_:       mov     si,word ptr [l]		{SI points to byte ptr (HL)}
                call    @take			{take the byte from z80 user memory}
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_A:          mov     al,byte ptr [a]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@CP_B:          mov     al,byte ptr[b]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_C:          mov     al,byte ptr[c]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_D:          mov     al,byte ptr[d]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_E:          mov     al,byte ptr[e]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_H:          mov     al,byte ptr[h]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_L:          mov     al,byte ptr[l]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP__HL_:       mov     si,word ptr[l]
                call    @take
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_A:          mov     al,byte ptr[a]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@RET_NZ:        mov     al,byte ptr [f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                jc      @noretnz
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretnz:       ret;nop
@POP_BC:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[c],ax
                ret;nop
@JP_NZ_nn:      mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                call    @fetchw
                jc      @njpnz
                mov     [ip],ax
@njpnz:         ret;nop
@JP_nn:         call    @fetchw
                mov     word ptr[ip],ax
                ret;nop
@CALL_NZ_nn:    call    @fetchw
                mov     bx,ax
                mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                jc      @nocallnz
                mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallnz:      ret;nop
@PUSH_BC:       mov     ax,word ptr[c]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
@ADD_A_n:       call    @fetchb
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@RST_00H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,0
                mov     word ptr[ip],ax
                ret;nop
@RET_Z:         mov     al,byte ptr [f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}{ok}
                jnc     @noretz
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretz:        ret;nop
@RETsp:         mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
                ret;nop
@JP_Z_nn:       mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                call    @fetchw
                jnc     @njpz
                mov     [ip],ax
@njpz:          ret;nop
@CODICE_CB:     call    @fetchb
                xor     AH,AH
                shl     ax,2
                add     ax,offset cb_code
                mov     bx,ax
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@CALL_Z_nn:     call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,6		{bt al,6} {test z flag}
                jnc     @nocallz
                mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallz:       ret;nop
@CALL_nn:       mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                call    @fetchw
                mov     word ptr[ip],ax
                ret;nop
@ADC_A_n:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                call    @fetchb			{<<<<!}
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@RST_08H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,8
                mov     word ptr[ip],ax
                ret;nop
@RET_NC:        mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt al,0} {test c flag}
                jc      @noretnc
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretnc:       ret;nop
@POP_DE:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[e],ax
                ret;nop
@JP_NC_nn:      mov     al,[f]
                db      $0F,$BA,$E0,0		{bt al,0} {test c flag}
                call    @fetchw
                jc      @njpnc
                mov     [ip],ax
@njpnc:         ret;nop
@OUT__n__A:     call    @fetchb
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[a]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@CALL_NC_nn:    call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,1		{bt al,1} {test c flag}
                jc      @nocallnc
                mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallnc:      ret;nop
@PUSH_DE:       mov     ax,word ptr[e]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
@SUB_n:         call    @fetchb
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@RST_10H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,10h
                mov     word ptr[ip],ax
                ret;nop
@RET_C:         mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt al,0} {test c flag}
                jnc     @noretc
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretc:        ret;nop
@EXX:           mov     bx,word ptr [c]		{get BC}
                mov     ax,word ptr [cpr]	{get BC'}
                mov     word ptr [c],ax		{BC <- BC'}
                mov     word ptr [cpr],bx	{BC' <- BC}
                mov     bx,word ptr [e]		{get DE}
                mov     ax,word ptr [epr]	{get DE'}
                mov     word ptr [e],ax		{DE <- DE'}
                mov     word ptr [epr],bx	{DE' <- DE}
                mov     bx,word ptr [l]		{get HL}
                mov     ax,word ptr [lpr]	{get HL'}
                mov     word ptr [l],ax		{HL <- HL'}
                mov     word ptr [lpr],bx	{HL' <- HL}
                ret;nop
@JP_C_nn:       mov     al,[f]
                db      $0F,$BA,$E0,0		{bt al,0} {test c flag}
                call    @fetchw
                jnc     @njpc
                mov     [ip],ax
@njpc:          ret;nop
@IN_A__n_:      call    @fetchb
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[a],al
                ret;nop
@CALL_C_nn:     call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,1		{bt al,1} {test c flag}
                jnc     @nocallc
                mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallc:       ret;nop
@CODICE_DD:     call    @fetchb
                xor     AH,AH
                shl     ax,2
                mov     bx,ax
                add     bx,offset dd_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@SBC_A_n:       mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                CALL    @fetchb
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@RST_18H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,18h
                mov     word ptr[ip],ax
                ret;nop
@RET_PO:        mov     al,byte ptr [f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                jc      @noretpo
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretpo:       ret;nop
@POP_HL:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[l],ax
                ret;nop
@JP_PO_nn:      mov     al,[f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                call    @fetchw
                jc      @njppo
                mov     [ip],ax
@njppo:         ret;nop
@EX__SP__HL:    mov     si,word ptr [spz]
                call    @takew
                mov     bx,ax
                mov     di,si
                mov     ax,word ptr [l]
                call    @putw
                mov     word ptr [l],bx
                ret;nop
@CALL_PO_nn:    call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                jc      @nocallpo
                mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallpo:      ret;nop
@PUSH_HL:       mov     ax,word ptr[l]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
@AND_n:         call    @fetchb
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@RST_20H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,20h
                mov     word ptr[ip],ax
                ret;nop
@RET_PE:        mov     al,byte ptr [f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                jnc     @noretpe
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretpe:       ret;nop
@JP__HL_:       mov     ax,word ptr[l]
                mov     [ip],ax
                ret;nop
@JP_PE_nn:      mov     al,[f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                call    @fetchw
                jnc     @njppe
                mov     [ip],ax
@njppe:         ret;nop
@EX_DE_HL:      mov     bx,word ptr [e]		{get DE}
                mov     ax,word ptr [l]		{get HL}
                mov     word ptr [e],ax		{DE <- HL}
                mov     word ptr [l],bx		{HL <- DE}
                ret;nop
@CALL_PE_nn:    call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,2		{bt al,2} {test p flag}
                jnc     @nocallpe
                mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallpe:      ret;nop
@CODICE_ED:     call    @fetchb
                xor     AH,AH
                shl     ax,2
                add     ax,offset ed_code
                mov     bx,ax
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@XOR_n:         call    @fetchb
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@RST_28H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,28h
                mov     word ptr[ip],ax
                ret;nop
@RET_P:         mov     al,byte ptr[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                jc     @noretp
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretp:        ret;nop
@POP_AF:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[f],ax
                ret;nop
@JP_P_nn:       mov     al,[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                call    @fetchw
                jc      @njpp
                mov     [ip],ax
@njpp:          ret;nop
@DI:            mov     iff1,0
                ret;nop
@CALL_P_nn:     call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                jc      @nocallp
                mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallp:       ret;nop
@PUSH_AF:       mov     ax,word ptr[f]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
@OR_n:          call    @fetchb
                or      byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@RST_30H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,30h
                mov     word ptr[ip],ax
                ret;nop
@RET_M:         mov     al,byte ptr[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                jnc     @noretm
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
@noretm:        ret;nop
@LD_SP_HL:      mov     ax,word ptr [l]
                mov     word ptr [spz],ax
                ret;nop
@JP_M_nn:       mov     al,[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                call    @fetchw
                jnc     @njpm
                mov     [ip],ax
@njpm:          ret;nop
@EI:            mov     iff1,1
                ret;nop
@CALL_M_nn:     call    @fetchw
                push    ax
                pop     bx
                mov     al,[f]
                db      $0F,$BA,$E0,7		{bt al,7} {test s flag}
                jnc      @nocallm
                mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     word ptr[ip],bx
@nocallm:       ret;nop
@CODICE_FD:     call    @fetchb
                xor     AH,AH
                shl     ax,2
                add     ax,offset FD_code
                mov     bx,ax
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@CP_n:          call    @fetchb
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@RST_38H:       mov     ax,word ptr[ip]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                mov     ax,38h
                mov     word ptr[ip],ax
                ret;nop
@CB_code:       ret;nop				{>>>>>> CB <<<<<<}
@RLC_B:         rol     byte ptr [b],1
                mov     al,byte ptr[b]
                call    @flag_rot
                ret;nop{00}
@RLC_C:         rol     byte ptr [c],1
                mov     al,byte ptr[c]
                call    @flag_rot
                ret;nop
@RLC_D:         rol     byte ptr [d],1
                mov     al,byte ptr[d]
                call    @flag_rot
                ret;nop
@RLC_E:         rol     byte ptr [e],1
                mov     al,byte ptr[e]
                call    @flag_rot
                ret;nop
@RLC_H:         rol     byte ptr [h],1
                mov     al,byte ptr[h]
                call    @flag_rot
                ret;nop
@RLC_L:         rol     byte ptr [l],1
                mov     al,byte ptr[l]
                call    @flag_rot
                ret;nop
@RLC__HL_:      mov     si,word ptr [l]
                call    @take			{ per adesso non mi interessa ma take}
                rol     al,1			{sposta di!!}
                mov     di,si
                call    @put
                mov     al,byte ptr[si]
                call    @flag_rot
                ret;nop
@RLC_A:         rol     byte ptr [a],1
                mov     al,byte ptr[a]
                call    @flag_rot
                ret;nop
@RRC_B:         ror     byte ptr [b],1
                mov     al,byte ptr[b]
                call    @flag_rot
                ret;nop
@RRC_C:         ror     byte ptr [c],1
                mov     al,byte ptr[c]
                call    @flag_rot
                ret;nop
@RRC_D:         ror     byte ptr [d],1
                mov     al,byte ptr[d]
                call    @flag_rot
                ret;nop
@RRC_E:         ror     byte ptr [e],1
                mov     al,byte ptr[e]
                call    @flag_rot
                ret;nop
@RRC_H:         ror     byte ptr [h],1
                mov     al,byte ptr[h]
                call    @flag_rot
                ret;nop
@RRC_L:         ror     byte ptr [l],1
                mov     al,byte ptr[l]
                call    @flag_rot
                ret;nop
@RRC__HL_:      mov     si,word ptr [l]
                call    @take
                ror     al,1
                mov     di,si
                call    @put
                mov     al,byte ptr[si]
                call    @flag_rot
                ret;nop
@RRC_A:         ror     byte ptr [a],1
                mov     al,byte ptr[a]
                call    @flag_rot
                ret;nop
@RL_B:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [b],1
                call    @flag_rot
                ret;nop				{10}
@RL_C:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [c],1
                call    @flag_rot
                ret;nop
@RL_D:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [d],1
                call    @flag_rot
                ret;nop
@RL_E:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [e],1
                call    @flag_rot
                ret;nop
@RL_H:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [h],1
                call    @flag_rot
                ret;nop
@RL_L:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [l],1
                call    @flag_rot
                ret;nop
@RL__HL_:       mov     si,word ptr [l]
                call    @take
                mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     al,1
                mov     di,si
                call    @put
                mov     al,byte ptr[si]
                call    @flag_rot
                ret;nop
@RL_A:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcl     [b],1
                call    @flag_rot
                ret;nop
@RR_B:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [b],1
                call    @flag_rot
                ret;nop
@RR_C:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [c],1
                call    @flag_rot
                ret;nop
@RR_D:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [d],1
                call    @flag_rot
                ret;nop
@RR_E:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [e],1
                call    @flag_rot
                ret;nop
@RR_H:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [h],1
                call    @flag_rot
                ret;nop
@RR_L:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [l],1
                call    @flag_rot
                ret;nop
@RR__HL_:       mov     si,word ptr [l]
                call    @take
                mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     al,1
                mov     di,si
                call    @put
                mov     al,byte ptr[si]
                call    @flag_rot
                ret;nop
@RR_A:          mov     al,[f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                rcr     [a],1
                call    @flag_rot
                ret;nop
                nop
@SLA_B:         shl     byte ptr[b],1
                call    @flag_rot
                ret;nop				{20}
@SLA_C:         shl     byte ptr[c],1
                call    @flag_rot
                ret;nop
@SLA_D:         shl     byte ptr[d],1
                call    @flag_rot
                ret;nop
@SLA_E:         shl     byte ptr[e],1
                call    @flag_rot
                ret;nop
@SLA_H:         shl     byte ptr[h],1
                call    @flag_rot
                ret;nop
@SLA_L:         shl     byte ptr[l],1
                call    @flag_rot
                ret;nop
@SLA__HL_:      mov     si,word ptr[l]
                call    @take
                shl     al,1
                mov     si,di
                call    @put
                ret;nop
@SLA_A:         shl     byte ptr[a],1
                call    @flag_rot
                ret;nop
@SRA_B:         sar     byte ptr[b],1
                call    @flag_rot
                ret;nop
@SRA_C:         sar     byte ptr[c],1
                call    @flag_rot
                ret;nop
@SRA_D:         sar     byte ptr[d],1
                call    @flag_rot
                ret;nop
@SRA_E:         sar     byte ptr[e],1
                call    @flag_rot
                ret;nop
@SRA_H:         sar     byte ptr[h],1
                call    @flag_rot
                ret;nop
@SRA_L:         sar     byte ptr[l],1
                call    @flag_rot
                ret;nop
@SRA__HL_:      mov     si,word ptr[l]
                call    @take
                sar     al,1
                mov     si,di
                call    @put
                ret;nop
@SRA_A:         sar     byte ptr[a],1
                call    @flag_rot
                ret;nop
@SLL_B:         shl     byte ptr[b],1
                call    @flag_rot
                ret;nop{30}
@SLL_C:         shl     byte ptr[c],1
                call    @flag_rot
                ret;nop
@SLL_D:         shl     byte ptr[d],1
                call    @flag_rot
                ret;nop
@SLL_E:         shl     byte ptr[e],1
                call    @flag_rot
                ret;nop
@SLL_H:         shl     byte ptr[h],1
                call    @flag_rot
                ret;nop
@SLL_L:         shl     byte ptr[l],1
                call    @flag_rot
                ret;nop
@SLL__HL_:      mov     si,word ptr[l]
                call    @take
                shl     al,1
                call    @flag_rot
                mov     si,di
                call    @put
                ret;nop
@SLL_A:         shl     byte ptr[a],1
                call    @flag_rot
                ret;nop
@SRL_B:         shr     byte ptr[b],1
                call    @flag_rot
                ret;nop
@SRL_C:         shr     byte ptr[c],1
                call    @flag_rot
                ret;nop
@SRL_D:         shr     byte ptr[d],1
                call    @flag_rot
                ret;nop
@SRL_E:         shr     byte ptr[e],1
                call    @flag_rot
                ret;nop
@SRL_H:         shr     byte ptr[h],1
                call    @flag_rot
                ret;nop
@SRL_L:         shr     byte ptr[l],1
                call    @flag_rot
                ret;nop
@SRL__HL_:      mov     si,word ptr[l]
                call    @take
                shr     al,1
                call    @flag_rot
                mov     si,di
                call    @put
                ret;nop
@SRL_A:         shr     byte ptr[a],1
                call    @flag_rot
                ret;nop
@BIT_0_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_0_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,0		{bt ax,0}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_1_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,1		{bt ax,1}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_2_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,2		{bt ax,2}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_3_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,3		{bt ax,3}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_4_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,4		{bt ax,4}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_5_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,5		{bt ax,5}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_6_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,6		{bt ax,6}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@BIT_7_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E0,7		{bt ax,7}
                db      0d6h			{setalc}
                or      al,al
                call    @bit_flag
                ret;nop
@RES_0_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[b],al
                ret;nop
@RES_0_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[c],al
                ret;nop
@RES_0_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[d],al
                ret;nop
@RES_0_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[e],al
                ret;nop
@RES_0_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[h],al
                ret;nop
@RES_0_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[l],al
                ret;nop
@RES_0__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     si,di
                call    @put
                ret;nop
@RES_0_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,0		{btr ax,0}
                mov     byte ptr[a],al
                ret;nop
@RES_1_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[b],al
                ret;nop
@RES_1_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[c],al
                ret;nop
@RES_1_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[d],al
                ret;nop
@RES_1_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[e],al
                ret;nop
@RES_1_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[h],al
                ret;nop
@RES_1_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[l],al
                ret;nop
@RES_1__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     si,di
                call    @put
                ret;nop
@RES_1_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,1		{btr ax,1}
                mov     byte ptr[a],al
                ret;nop
@RES_2_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[b],al
                ret;nop
@RES_2_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[c],al
                ret;nop
@RES_2_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[d],al
                ret;nop
@RES_2_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[e],al
                ret;nop
@RES_2_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[h],al
                ret;nop
@RES_2_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[l],al
                ret;nop
@RES_2__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     si,di
                call    @put
                ret;nop
@RES_2_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,2		{btr ax,2}
                mov     byte ptr[a],al
                ret;nop
@RES_3_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[b],al
                ret;nop
@RES_3_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[c],al
                ret;nop
@RES_3_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[d],al
                ret;nop
@RES_3_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[e],al
                ret;nop
@RES_3_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[h],al
                ret;nop
@RES_3_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[l],al
                ret;nop
@RES_3__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     si,di
                call    @put
                ret;nop
@RES_3_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,3		{btr ax,3}
                mov     byte ptr[a],al
                ret;nop
@RES_4_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[b],al
                ret;nop
@RES_4_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[c],al
                ret;nop
@RES_4_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[d],al
                ret;nop
@RES_4_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[e],al
                ret;nop
@RES_4_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[h],al
                ret;nop
@RES_4_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[l],al
                ret;nop
@RES_4__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     si,di
                call    @put
                ret;nop
@RES_4_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,4		{btr ax,4}
                mov     byte ptr[a],al
                ret;nop
@RES_5_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[b],al
                ret;nop
@RES_5_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[c],al
                ret;nop
@RES_5_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[d],al
                ret;nop
@RES_5_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[e],al
                ret;nop
@RES_5_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[h],al
                ret;nop
@RES_5_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[l],al
                ret;nop
@RES_5__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     si,di
                call    @put
                ret;nop
@RES_5_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,5		{btr ax,5}
                mov     byte ptr[a],al
                ret;nop
@RES_6_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[b],al
                ret;nop
@RES_6_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[c],al
                ret;nop
@RES_6_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[d],al
                ret;nop
@RES_6_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[e],al
                ret;nop
@RES_6_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[h],al
                ret;nop
@RES_6_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[l],al
                ret;nop
@RES_6__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     si,di
                call    @put
                ret;nop
@RES_6_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[a],al
                ret;nop
@RES_7_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$F0,7		{btr ax,7}
                mov     byte ptr[b],al
                ret;nop
@RES_7_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[c],al
                ret;nop
@RES_7_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[d],al
                ret;nop
@RES_7_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[e],al
                ret;nop
@RES_7_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[h],al
                ret;nop
@RES_7_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[l],al
                ret;nop
@RES_7__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$F0,7		{btr ax,7}
                mov     si,di
                call    @put
                ret;nop
@RES_7_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$F0,6		{btr ax,6}
                mov     byte ptr[a],al
                ret;nop
@SET_0_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[b],al
                ret;nop
@SET_0_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[c],al
                ret;nop
@SET_0_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[d],al
                ret;nop
@SET_0_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[e],al
                ret;nop
@SET_0_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[h],al
                ret;nop
@SET_0_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[l],al
                ret;nop
@SET_0__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     si,di
                call    @put
                ret;nop
@SET_0_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,0		{bts ax,0}
                mov     byte ptr[a],al
                ret;nop
@SET_1_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[b],al
                ret;nop
@SET_1_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[c],al
                ret;nop
@SET_1_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[d],al
                ret;nop
@SET_1_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[e],al
                ret;nop
@SET_1_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[h],al
                ret;nop
@SET_1_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[l],al
                ret;nop
@SET_1__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     si,di
                call    @put
                ret;nop
@SET_1_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,1		{bts ax,1}
                mov     byte ptr[a],al
                ret;nop
@SET_2_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[b],al
                ret;nop
@SET_2_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[c],al
                ret;nop
@SET_2_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[d],al
                ret;nop
@SET_2_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[e],al
                ret;nop
@SET_2_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[h],al
                ret;nop
@SET_2_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[l],al
                ret;nop
@SET_2__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     si,di
                call    @put
                ret;nop
@SET_2_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,2		{bts ax,2}
                mov     byte ptr[a],al
                ret;nop
@SET_3_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[b],al
                ret;nop
@SET_3_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[c],al
                ret;nop
@SET_3_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[d],al
                ret;nop
@SET_3_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[e],al
                ret;nop
@SET_3_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[h],al
                ret;nop
@SET_3_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[l],al
                ret;nop
@SET_3__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     si,di
                call    @put
                ret;nop
@SET_3_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,3		{bts ax,3}
                mov     byte ptr[a],al
                ret;nop
@SET_4_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[b],al
                ret;nop
@SET_4_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[c],al
                ret;nop
@SET_4_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[d],al
                ret;nop
@SET_4_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[e],al
                ret;nop
@SET_4_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[h],al
                ret;nop
@SET_4_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[l],al
                ret;nop
@SET_4__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     si,di
                call    @put
                ret;nop
@SET_4_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,4		{bts ax,4}
                mov     byte ptr[a],al
                ret;nop
@SET_5_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[b],al
                ret;nop
@SET_5_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[c],al
                ret;nop
@SET_5_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[d],al
                ret;nop
@SET_5_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[e],al
                ret;nop
@SET_5_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[h],al
                ret;nop
@SET_5_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[l],al
                ret;nop
@SET_5__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     si,di
                call    @put
                ret;nop
@SET_5_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,5		{bts ax,5}
                mov     byte ptr[a],al
                ret;nop
@SET_6_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[b],al
                ret;nop
@SET_6_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[c],al
                ret;nop
@SET_6_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[d],al
                ret;nop
@SET_6_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[e],al
                ret;nop
@SET_6_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[h],al
                ret;nop
@SET_6_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[l],al
                ret;nop
@SET_6__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     si,di
                call    @put
                ret;nop
@SET_6_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,6		{bts ax,6}
                mov     byte ptr[a],al
                ret;nop
@SET_7_B:       mov     al,byte ptr[b]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[b],al
                ret;nop
@SET_7_C:       mov     al,byte ptr[c]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[c],al
                ret;nop
@SET_7_D:       mov     al,byte ptr[d]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[d],al
                ret;nop
@SET_7_E:       mov     al,byte ptr[e]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[e],al
                ret;nop
@SET_7_H:       mov     al,byte ptr[h]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[h],al
                ret;nop
@SET_7_L:       mov     al,byte ptr[l]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[l],al
                ret;nop
@SET_7__HL_:    mov     si,word ptr[l]
                call    @take
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     si,di
                call    @put
                ret;nop
@SET_7_A:       mov     al,byte ptr[a]
                db      $0F,$BA,$E8,7		{bts ax,7}
                mov     byte ptr[a],al
                ret;nop

@DD_code:       ret;nop				{>>>>>> DD code <<<<<<}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_IX_BC:     mov     bx,word ptr [c]
                add     word ptr [ix],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop				{09}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop				{10}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_IX_DE:     mov     bx,word ptr [e]
                add     word ptr [ix],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop				{19}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop				{20}
@LD_IX_nn:      call    @fetchw
                mov     word ptr[ix],ax
                ret;nop				{21}
@LD__nn__IX:    call    @fetchw
                mov     di,word ptr[ix]
                call    @putw
                ret;nop				{22}
@INC_IX:        inc     word ptr[ix]
                ret;nop				{23}
@INC_IXH:       inc     byte ptr [ix+1]
                mov     cx,0000h
                call    @flag_aop
                ret;nop				{24}
@DEC_IXH:       dec     byte ptr [ix+1]
                mov     cx,0001h
                call    @flag_aop
                ret;nop				{25}
@LD_IXH_n:      call    @fetchb
                mov     byte ptr [ix+1],al
                ret;nop				{26}
                ret;nop
                ret;nop
@ADD_IX_IX:     mov     bx,word ptr [ix]
                add     word ptr [ix],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop				{29}
@LD_IX__nn_:    call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [ix],ax
                ret;nop				{2a}
@DEC_IX:        dec     word ptr [ix]
                ret;nop				{2b}
@INC_IXL:       inc     byte ptr [ix]
                mov     cx,0000h
                call    @flag_aop
                ret;nop				{2c}
@DEC_IXL:       inc     byte ptr [ix]
                mov     cx,0001h
                call    @flag_aop
                ret;nop				{2d}
@LD_IXL_n:      call    @fetchb
                mov     byte ptr [ix],al
                ret;nop				{2e}
                ret;nop
                ret;nop				{30}
                ret;nop
                ret;nop
                ret;nop
@INC__IX_d_:    mov     si,word ptr [ix]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                inc     al
                mov     di,si
                call    @put
                mov     cl,0
                call    @flag_aop
                ret;nop
@DEC__IX_d_:    mov     si,word ptr [ix]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                dec     al
                mov     di,si
                call    @put
                mov     cl,0
                call    @flag_aop
                ret;nop
@LD__IX_d__n:   call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [ix],ax
                ret;nop
                ret;nop
                ret;nop
@ADD_IX_SP:     mov     bx,word ptr [spz]
                add     word ptr [ix],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_B_IXH:      mov     al,byte ptr[ix+1]
                mov     byte ptr[b],al
                ret;nop
@LD_B_IXL:      mov     al,byte ptr[ix]
                mov     byte ptr[b],al
                ret;nop
@LD_B__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[b],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_C_IXH:      mov     al,byte ptr[ix+1]
                mov     byte ptr[c],al
                ret;nop
@LD_C_IXL:      mov     al,byte ptr[ix]
                mov     byte ptr[b],al
                ret;nop
@LD_C__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[c],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_D_IXH:      mov     al,byte ptr[ix+1]
                mov     byte ptr[d],al
                ret;nop
@LD_D_IXL:      mov     al,byte ptr[ix]
                mov     byte ptr[d],al
                ret;nop
@LD_D__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[d],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_E_IXH:      mov     al,byte ptr[ix+1]
                mov     byte ptr[e],al
                ret;nop
@LD_E_IXL:      mov     al,byte ptr[ix]
                mov     byte ptr[e],al
                ret;nop
@LD_E__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[e],al
                ret;nop
                ret;nop
@LD_IXH_B:      mov     al,byte ptr[b]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXH_C:      mov     al,byte ptr[c]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXH_D:      mov     al,byte ptr[d]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXH_E:      mov     al,byte ptr[e]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXH_IXH:    mov     al,byte ptr[ix+1]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXH_IXL:    mov     al,byte ptr[ix]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_H__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[h],al
                ret;nop
@LD_IXH_A:      mov     al,byte ptr[a]
                mov     byte ptr[ix+1],al
                ret;nop
@LD_IXL_B:      mov     al,byte ptr[b]
                mov     byte ptr[ix],al
                ret;nop
@LD_IXL_C:      mov     al,byte ptr[c]
                mov     byte ptr[ix],al
                ret;nop
@LD_IXL_D:      mov     al,byte ptr[d]
                mov     byte ptr[ix],al
                ret;nop
@LD_IXL_E:      mov     al,byte ptr[e]
                mov     byte ptr[ix],al
                ret;nop
@LD_IXL_IXH:    mov     al,byte ptr[ix+1]
                mov     byte ptr[ix],al
                ret;nop
@LD_IXL_IXL:    mov     al,byte ptr[ix]
                mov     byte ptr[ix],al
                ret;nop
@LD_L__IX_d_:   mov     si,word ptr[ix]
                call    @take
                mov     byte ptr[l],al
                ret;nop
@LD_IXL_A:      mov     al,byte ptr[a]
                mov     byte ptr[ix],al
                ret;nop
@LD__IX_d__B:   mov     di,word ptr[ix]
                mov     al,byte ptr[b]
                call    @put
                ret;nop
@LD__IX_d__C:   mov     di,word ptr[ix]
                mov     al,byte ptr[c]
                call    @put
                ret;nop
@LD__IX_d__D:   mov     di,word ptr[ix]
                mov     al,byte ptr[d]
                call    @put
                ret;nop
@LD__IX_d__E:   mov     di,word ptr[ix]
                mov     al,byte ptr[e]
                call    @put
                ret;nop
@LD__IX_d__H:   mov     di,word ptr[ix]
                mov     al,byte ptr[h]
                call    @put
                ret;nop
@LD__IX_d__L:   mov     di,word ptr[ix]
                mov     al,byte ptr[l]
                call    @put
                ret;nop
                ret;nop
@LD__IX_d__A:   mov     di,word ptr[ix]
                mov     al,byte ptr[a]
                call    @put
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_A_IXH:      mov     al,byte ptr[ix+1]
                mov     byte ptr[a],al
                ret;nop
@LD_A_IXL:      mov     al,byte ptr[ix]
                mov     byte ptr[a],al
                ret;nop
@LD_A__IX_d_:   mov     si,word ptr[ix]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                mov     byte ptr[a],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_A_IXH:     mov     al,byte ptr[ix+1]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_IXL:     mov     al,byte ptr[ix]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A__IX_d_:  mov     si,word ptr[ix]
                call    @take
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADC_A_IXH:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[ix+1]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_IXL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[ix]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A__IX_d_:  mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[ix]
                call    @take
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SUB_IXH:       mov     al,byte ptr[ix+1]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_IXL:       mov     al,byte ptr[ix]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB__IX_d_:    mov     si,word ptr[ix]
                call    @take
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SBC_A_IXH:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[ix+1]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_IXL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[ix]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A__IX_d_:  mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[ix]
                call    @take
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@AND_IXH:       mov     al,byte ptr[ix+1]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_IXL:       mov     al,byte ptr[ix]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND__IX_d_:    mov     si,word ptr[ix]
                call    @take
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@XOR_IXH:       mov     al,byte ptr[ix+1]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_IXL:       mov     al,byte ptr[ix]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR__IX_d_:    mov     si,word ptr[ix]
                call    @take
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@OR_IXH:        mov     al,byte ptr [ix+1]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_IXL:        mov     al,byte ptr[ix]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR__IX_d_:     mov     si,word ptr [ix]		{SI points to byte ptr (HL)}
                call    @take				{take the byte from z80 user memory}
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@CP_IXH:        mov     al,byte ptr[ix+1]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_IXL:        mov     al,byte ptr[ix]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP__IX_d_:     mov     si,word ptr[ix]
                call    @take
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@loop_CB_code_D:ret;nop
                ret;nop
@CALL_nn_DD:    mov     ax,word ptr[ip]
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                call    @fetchw
                mov     word ptr[ip],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@POP_IX:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ix],ax
                ret;nop
                ret;nop
@EX__SP__IX:    ret;nop   (*************************************************)
                ret;nop
@PUSH_IX:       mov     ax,word ptr[ix]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@JP__IX_:       mov     ax,word ptr[ix]
                mov     [ip],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_SP_IX:      mov     ax,word ptr [ix]
                mov     word ptr [spz],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop


@ED_code:       ret;nop			{>>>>>> ED <<<<<<}
@NOPsp:         ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@IN_B__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[b],al
                ret;nop
@OUT__C__B:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[b]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@SBC_HL_BC:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [c]
                sbb     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD__nn__BC:    call    @fetchw
                mov     di,ax
                mov     ax,word ptr [c]
                call    @putw
                ret;nop
@NEGsp:         neg     byte ptr [a]
{****************************************************************************}
                ret;nop
@RETNsp:        mov     al,byte ptr [iff2]
                mov     byte ptr [iff1],al
                mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
                ret;nop
@IM_0:          mov     byte ptr[im],0
                ret;nop
@LD_I_A:        mov     al,byte ptr [a]
                mov     byte ptr [i],al
                ret;nop
@IN_C__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[c],al
                ret;nop
@OUT__C__C:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[c]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@ADC_HL_BC:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [c]
                adc     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_BC__nn_:    call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [c],ax
                ret;nop
                ret;nop
@RETI_2:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[ip],ax
                ret;nop
                ret;nop
@LD_R_A:        mov     al,byte ptr [a]
                mov     byte ptr [r],al
                ret;nop
@IN_D__C_:            mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[d],al
                ret;nop
@OUT__C__D:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[d]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@SBC_HL_DE:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [e]
                sbb     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD__nn__DE:    call    @fetchw
                mov     di,ax
                mov     ax,word ptr [e]
                call    @putw
                ret;nop
                ret;nop
                ret;nop
@IM_1:          mov     byte ptr[im],1
                ret;nop
@LD_A_I:        mov    al,byte ptr [i]
                mov    byte ptr [a],al
                ret;nop
@IN_E__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[b],al
                ret;nop
@OUT__C__E:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[e]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@ADC_HL_DE:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [e]
                adc     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_DE__nn_:    call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [e],ax
                ret;nop
                ret;nop
                ret;nop
@IM_2:          mov     byte ptr[im],2
                ret;nop
@LD_A_R:        ret;nop
@IN_H__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[h],al
                ret;nop
@OUT__C__H:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[h]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@SBC_HL_HL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [l]
                sbb     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD__nn__HL_D:  call    @fetchw
                mov     di,ax
                mov     ax,word ptr [l]
                call    @putw
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RRD:           ret;nop
@IN_L__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[l],al
                ret;nop
@OUT__C__L:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[l]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@ADC_HL_HL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [l]
                adc     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_HL__nn__D:  call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [l],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RLD:           ret;nop
@IN_F__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[f],al
                and     al,$fe
                and     bl,1
                or      al,bl {keep old carry flag}
                db      $0F,$BA,$F0,$01		{btr ax,1}{reset z80's N flag}
                mov     byte ptr[h],al
                ret;nop
@OUT__C__0:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@SBC_HL_SP:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [spz]
                sbb     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD__nn__SP_2:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@IN_A__C_:      mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                shl     bx,2
                add     bx,offset in_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                mov     byte ptr[a],al
                ret;nop
@OUT__C__A:     mov     al,byte ptr[c]
                xor     AH,AH
                mov     bx,ax
                mov     ah,byte ptr[a]
                shl     bx,2
                add     bx,offset out_code
                db      $3e,$ff,$17		{call    ds:[bx]}
                ret;nop
@ADC_HL_SP:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     bx,word ptr [spz]
                adc     word ptr [l],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_SP__nn_:    ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LDI:           ret;nop
@CPI:           ret;nop
@INI:           ret;nop
@OUTI:          ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LDD:           ret;nop
@CPD:           ret;nop
@IND:           ret;nop
@OUTD:          ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LDIR:          ret;nop
@CPIR:          ret;nop
@INIR:          ret;nop
@OTIR:          ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LDDR:          ret;nop
@CPDR:          ret;nop
@INDR:          ret;nop
@OTDR:          ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop

@FD_code:       ret;nop			{>>>>>> FD code <<<<<<}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_IY_BC:     mov     bx,word ptr [c]
                add     word ptr [iy],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_IY_DE:     mov     bx,word ptr [e]
                add     word ptr [iy],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_IY_nn:      call    @fetchw
                mov     word ptr[iy],ax
                ret;nop
@LD__nn__IY:    call    @fetchw
                mov     di,word ptr[iy]
                call    @putw
                ret;nop
@INC_IY:        inc     word ptr[iy]
                ret;nop
@INC_IYH:       inc     byte ptr [iy+1]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_IYH:       dec     byte ptr [iy+1]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_IYH_n:      call    @fetchb
                mov     byte ptr [iy+1],al
                ret;nop
                ret;nop
                ret;nop
@ADD_IY_IY:     mov     bx,word ptr [iy]
                add     word ptr [iy],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
@LD_IY__nn_:    call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [iy],ax
                ret;nop
@DEC_IY:        dec     word ptr [iy]
                ret;nop
@INC_IYL:       inc     byte ptr [iy]
                mov     cx,0000h
                call    @flag_aop
                ret;nop
@DEC_IYL:       inc     byte ptr [iy]
                mov     cx,0001h
                call    @flag_aop
                ret;nop
@LD_IYL_n:      call    @fetchb
                mov     byte ptr [iy],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@INC__IY_d_:    mov     si,word ptr [iy]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                inc     al
                mov     di,si
                call    @put
                mov     cl,0
                call    @flag_aop
                ret;nop
@DEC__IY_d_:    mov     si,word ptr [iy]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                dec     al
                mov     di,si
                call    @put
                mov     cl,0
                call    @flag_aop
                ret;nop
@LD__IY_d__n:   call    @fetchw
                mov     si,ax
                call    @takew
                mov     word ptr [iy],ax
                ret;nop
                ret;nop
                ret;nop
@ADD_IY_SP:     mov     bx,word ptr [spz]
                add     word ptr [iy],bx
                mov     cl,0
                call    @flag_a16b
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_B_IYH:      mov     al,byte ptr[iy+1]
                mov     byte ptr[b],al
                ret;nop
@LD_B_IYL:      mov     al,byte ptr[iy]
                mov     byte ptr[b],al
                ret;nop
@LD_B__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[b],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_C_IYH:      mov     al,byte ptr[iy+1]
                mov     byte ptr[c],al
                ret;nop
@LD_C_IYL:      mov     al,byte ptr[iy]
                mov     byte ptr[b],al
                ret;nop
@LD_C__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[c],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_D_IYH:      mov     al,byte ptr[iy+1]
                mov     byte ptr[d],al
                ret;nop
@LD_D_IYL:      mov     al,byte ptr[iy]
                mov     byte ptr[d],al
                ret;nop
@LD_D__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[d],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_E_IYH:      mov     al,byte ptr[iy+1]
                mov     byte ptr[e],al
                ret;nop
@LD_E_IYL:      mov     al,byte ptr[iy]
                mov     byte ptr[e],al
                ret;nop
@LD_E__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[e],al
                ret;nop
                ret;nop
@LD_IYH_B:      mov     al,byte ptr[b]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYH_C:      mov     al,byte ptr[c]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYH_D:      mov     al,byte ptr[d]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYH_E:      mov     al,byte ptr[e]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYH_IYH:    mov     al,byte ptr[iy+1]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYH_IYL:    mov     al,byte ptr[iy]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_H__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[h],al
                ret;nop
@LD_IYH_A:      mov     al,byte ptr[a]
                mov     byte ptr[iy+1],al
                ret;nop
@LD_IYL_B:      mov     al,byte ptr[b]
                mov     byte ptr[iy],al
                ret;nop
@LD_IYL_C:      mov     al,byte ptr[c]
                mov     byte ptr[iy],al
                ret;nop
@LD_IYL_D:      mov     al,byte ptr[d]
                mov     byte ptr[iy],al
                ret;nop
@LD_IYL_E:      mov     al,byte ptr[e]
                mov     byte ptr[iy],al
                ret;nop
@LD_IYL_IYH:    mov     al,byte ptr[iy+1]
                mov     byte ptr[iy],al
                ret;nop
@LD_IYL_IYL:    mov     al,byte ptr[iy]
                mov     byte ptr[iy],al
                ret;nop
@LD_L__IY_d_:   mov     si,word ptr[iy]
                call    @take
                mov     byte ptr[l],al
                ret;nop
@LD_IYL_A:      mov     al,byte ptr[a]
                mov     byte ptr[iy],al
                ret;nop
@LD__IY_d__B:   mov     di,word ptr[iy]
                mov     al,byte ptr[b]
                call    @put
                ret;nop
@LD__IY_d__C:   mov     di,word ptr[iy]
                mov     al,byte ptr[c]
                call    @put
                ret;nop
@LD__IY_d__D:   mov     di,word ptr[iy]
                mov     al,byte ptr[d]
                call    @put
                ret;nop
@LD__IY_d__E:   mov     di,word ptr[iy]
                mov     al,byte ptr[e]
                call    @put
                ret;nop
@LD__IY_d__H:   mov     di,word ptr[iy]
                mov     al,byte ptr[h]
                call    @put
                ret;nop
@LD__IY_d__L:   mov     di,word ptr[iy]
                mov     al,byte ptr[l]
                call    @put
                ret;nop
                ret;nop
@LD__IY_d__A:   mov     di,word ptr[iy]
                mov     al,byte ptr[a]
                call    @put
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_A_IYH:      mov     al,byte ptr[iy+1]
                mov     byte ptr[a],al
                ret;nop
@LD_A_IYL:      mov     al,byte ptr[iy]
                mov     byte ptr[a],al
                ret;nop
@LD_A__IY_d_:   mov     si,word ptr[iy]
                call    @fetchb
                cbw
                add     si,ax
                call    @take
                mov     byte ptr[a],al
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADD_A_IYH:     mov     al,byte ptr[iy+1]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A_IYL:     mov     al,byte ptr[iy]
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADD_A__IY_d_:  mov     si,word ptr[iy]
                call    @take
                add     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@ADC_A_IYH:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[iy+1]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A_IYL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[iy]
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
@ADC_A__IY_d_:  mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[iy]
                call    @take
                adc     byte ptr[a],al
                mov     cx,0100h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SUB_IYH:       mov     al,byte ptr[iy+1]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB_IYL:       mov     al,byte ptr[iy]
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SUB__IY_d_:    mov     si,word ptr[iy]
                call    @take
                sub     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SBC_A_IYH:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[iy+1]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A_IYL:     mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     al,byte ptr[iy]
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@SBC_A__IY_d_:  mov     al,byte ptr [f]
                db      $0F,$BA,$E0,0		{bt ax,0}{80x86 carry <- z80 carry }
                mov     si,word ptr[iy]
                call    @take
                sbb     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@AND_IYH:       mov     al,byte ptr[iy+1]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND_IYL:       mov     al,byte ptr[iy]
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
@AND__IY_d_:    mov     si,word ptr[iy]
                call    @take
                and     byte ptr[a],al
                mov     cl,1
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@XOR_IYH:       mov     al,byte ptr[iy+1]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR_IYL:       mov     al,byte ptr[iy]
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@XOR__IY_d_:    mov     si,word ptr[iy]
                call    @take
                xor     byte ptr[a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@OR_IYH:        mov     al,byte ptr [iy+1]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR_IYL:        mov     al,byte ptr[iy]
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
@OR__IY_d_:     mov     si,word ptr [iy]	{SI points to byte ptr (HL)}
                call    @take			{take the byte from z80 user memory}
                or      byte ptr [a],al
                mov     cl,0
                call    @flag_lop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@CP_IYH:        mov     al,byte ptr[iy+1]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP_IYL:        mov     al,byte ptr[iy]
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
@CP__IY_d_:     mov     si,word ptr[iy]
                call    @take
                cmp     byte ptr[a],al
                mov     cx,0101h
                call    @flag_aop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@loop_CB_code:  ret;nop
                ret;nop
@CALL_nn_DD_d:  mov     ax,word ptr[ip](* pd32, la call c' ha un bug!!!! *)
                add     ax,2
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                call    @fetchw
                mov     word ptr[ip],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@POP_IY:        mov     si,word ptr[spz]
                call    @takew
                add     word ptr[spz],2
                mov     word ptr[iy],ax
                ret;nop
                ret;nop
@EX__SP__IY:    ret;nop   (*************************************************)
                ret;nop
@PUSH_IY:       mov     ax,word ptr[iy]
                sub     word ptr[spz],2
                mov     di,word ptr[spz]
                call    @putw
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@JP__IY_:       mov     ax,word ptr[iy]
                mov     [ip],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@LD_SP_IY:      mov     ax,word ptr [iy]
                mov     word ptr [spz],ax
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop


@D_CB_code:     ret;nop			{00}
                ret;nop			{01}
                ret;nop			{02}
                ret;nop			{03}
                ret;nop			{04}
                ret;nop			{05}
                ret;nop			{06}
@RLC__Ix_d_:    ret;nop			{07}
                ret;nop			{08}
                ret;nop			{09}
                ret;nop			{0a}
                ret;nop			{0b}
                ret;nop			{0c}
                ret;nop			{0d}
                ret;nop			{0e}
@RRC__Ix_d_:    ret;nop			{0f}
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RL__Ix_d_:     ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RR__Ix_d_:     ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SLA__Ix_d_:    ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SRA__Ix_d_:    ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SLL__Ix_d_:    ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SRL__Ix_d_:    ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_0__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_1__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_2__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_3__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_4__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_5__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_6__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@BIT_7__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_0__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_1__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_2__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_3__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_4__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_5__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_6__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@RES_7__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_0__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_1__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_2__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_3__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_4__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_5__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_6__Ix_d_:  ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
                ret;nop
@SET_7__Ix_d_:  ret;nop
                ret;nop
@OUT_code:      ret;nop			{>>>>>> OUT <<<<<<}{ax= valore porta}
@O00:           ret;nop
@O01:           ret;nop
@O02:           mov      bx,offset ports
                mov      ds:[bx+2],ah
                ret;nop
@O03:           ret;nop
@O04:           mov      bx,offset ports
                mov      cl,ds:[bx+4]
                mov      ds:[bx+$10],cl
                mov      ds:[bx+4],ah
                ret;nop
@O05:           ret;nop
@O06:           ret;nop
@O07:           ret;nop
@O08:           ret;nop
@O09:           ret;nop
@O0A:           ret;nop
@O0B:           ret;nop
@O0C:           ret;nop
@O0D:           ret;nop
@O0E:           ret;nop
@O0F:           ret;nop
@O10:           ret;nop
@O11:           ret;nop
@O12:           ret;nop
@O13:           ret;nop
@O14:           ret;nop
@O15:           ret;nop
@O16:           ret;nop
@O17:           ret;nop
@O18:           ret;nop
@O19:           ret;nop
@O1A:           ret;nop
@O1B:           ret;nop
@O1C:           ret;nop
@O1D:           ret;nop
@O1E:           ret;nop
@O1F:           ret;nop
@O20:           ret;nop
@O21:           ret;nop
@O22:           ret;nop
@O23:           ret;nop
@O24:           ret;nop
@O25:           ret;nop
@O26:           ret;nop
@O27:           ret;nop
@O28:           ret;nop
@O29:           ret;nop
@O2A:           ret;nop
@O2B:           ret;nop
@O2C:           ret;nop
@O2D:           ret;nop
@O2E:           ret;nop
@O2F:           ret;nop
@O30:           ret;nop
@O31:           ret;nop
@O32:           ret;nop
@O33:           ret;nop
@O34:           ret;nop
@O35:           ret;nop
@O36:           ret;nop
@O37:           ret;nop
@O38:           ret;nop
@O39:           ret;nop
@O3A:           ret;nop
@O3B:           ret;nop
@O3C:           ret;nop
@O3D:           ret;nop
@O3E:           ret;nop
@O3F:           ret;nop
@O40:           ret;nop
@O41:           ret;nop
@O42:           ret;nop
@O43:           ret;nop
@O44:           ret;nop
@O45:           ret;nop
@O46:           ret;nop
@O47:           ret;nop
@O48:           ret;nop
@O49:           ret;nop
@O4A:           ret;nop
@O4B:           ret;nop
@O4C:           ret;nop
@O4D:           ret;nop
@O4E:           ret;nop
@O4F:           ret;nop
@O50:           ret;nop
@O51:           ret;nop
@O52:           ret;nop
@O53:           ret;nop
@O54:           ret;nop
@O55:           ret;nop
@O56:           ret;nop
@O57:           ret;nop
@O58:           ret;nop
@O59:           ret;nop
@O5A:           ret;nop
@O5B:           ret;nop
@O5C:           ret;nop
@O5D:           ret;nop
@O5E:           ret;nop
@O5F:           ret;nop
@O60:           ret;nop
@O61:           ret;nop
@O62:           ret;nop
@O63:           ret;nop
@O64:           ret;nop
@O65:           ret;nop
@O66:           ret;nop
@O67:           ret;nop
@O68:           ret;nop
@O69:           ret;nop
@O6A:           ret;nop
@O6B:           ret;nop
@O6C:           ret;nop
@O6D:           ret;nop
@O6E:           ret;nop
@O6F:           ret;nop
@O70:           ret;nop
@O71:           ret;nop
@O72:           ret;nop
@O73:           ret;nop
@O74:           ret;nop
@O75:           ret;nop
@O76:           ret;nop
@O77:           ret;nop
@O78:           ret;nop
@O79:           ret;nop
@O7A:           ret;nop
@O7B:           ret;nop
@O7C:           ret;nop
@O7D:           ret;nop
@O7E:           ret;nop
@O7F:           ret;nop
@O80:           ret;nop
@O81:           ret;nop
@O82:           ret;nop
@O83:           ret;nop
@O84:           ret;nop
@O85:           ret;nop
@O86:           ret;nop
@O87:           ret;nop
@O88:           ret;nop
@O89:           ret;nop
@O8A:           ret;nop
@O8B:           ret;nop
@O8C:           ret;nop
@O8D:           ret;nop
@O8E:           ret;nop
@O8F:           ret;nop
@O90:           ret;nop
@O91:           ret;nop
@O92:           ret;nop
@O93:           ret;nop
@O94:           ret;nop
@O95:           ret;nop
@O96:           ret;nop
@O97:           ret;nop
@O98:           ret;nop
@O99:           ret;nop
@O9A:           ret;nop
@O9B:           ret;nop
@O9C:           ret;nop
@O9D:           ret;nop
@O9E:           ret;nop
@O9F:           ret;nop
@OA0:           ret;nop
@OA1:           ret;nop
@OA2:           ret;nop
@OA3:           ret;nop
@OA4:           ret;nop
@OA5:           ret;nop
@OA6:           ret;nop
@OA7:           ret;nop
@OA8:           ret;nop
@OA9:           ret;nop
@OAA:           ret;nop
@OAB:           ret;nop
@OAC:           ret;nop
@OAD:           ret;nop
@OAE:           ret;nop
@OAF:           ret;nop
@OB0:           ret;nop
@OB1:           ret;nop
@OB2:           ret;nop
@OB3:           ret;nop
@OB4:           ret;nop
@OB5:           ret;nop
@OB6:           ret;nop
@OB7:           ret;nop
@OB8:           ret;nop
@OB9:           ret;nop
@OBA:           ret;nop
@OBB:           ret;nop
@OBC:           ret;nop
@OBD:           ret;nop
@OBE:           ret;nop
@OBF:           ret;nop
@OC0:           ret;nop
@OC1:           ret;nop
@OC2:           ret;nop
@OC3:           ret;nop
@OC4:           ret;nop
@OC5:           ret;nop
@OC6:           ret;nop
@OC7:           ret;nop
@OC8:           ret;nop
@OC9:           ret;nop
@OCA:           ret;nop
@OCB:           ret;nop
@OCC:           ret;nop
@OCD:           ret;nop
@OCE:           ret;nop
@OCF:           ret;nop
@OD0:           ret;nop
@OD1:           ret;nop
@OD2:           ret;nop
@OD3:           ret;nop
@OD4:           ret;nop
@OD5:           ret;nop
@OD6:           ret;nop
@OD7:           ret;nop
@OD8:           ret;nop
@OD9:           ret;nop
@ODA:           ret;nop
@ODB:           ret;nop
@ODC:           ret;nop
@ODD:           ret;nop
@ODE:           ret;nop
@ODF:           ret;nop
@OE0:           ret;nop
@OE1:           ret;nop
@OE2:           ret;nop
@OE3:           ret;nop
@OE4:           ret;nop
@OE5:           ret;nop
@OE6:           ret;nop
@OE7:           ret;nop
@OE8:           ret;nop
@OE9:           ret;nop
@OEA:           ret;nop
@OEB:           ret;nop
@OEC:           ret;nop
@OED:           ret;nop
@OEE:           ret;nop
@OEF:           ret;nop
@OF0:           ret;nop
@OF1:           ret;nop
@OF2:           ret;nop
@OF3:           ret;nop
@OF4:           ret;nop
@OF5:           ret;nop
@OF6:           ret;nop
@OF7:           ret;nop
@OF8:           ret;nop
@OF9:           ret;nop
@OFA:           ret;nop
@OFB:           ret;nop
@OFC:           ret;nop
@OFD:           ret;nop
@OFE:           ret;nop
@OFF:           ret;nop

@IN_code:       ret;nop				{>>>>>> IN <<<<<<}{ds:[bx] -> ports, al=port}
@I00:           ret;nop
@I01:           mov      bx,offset ports
                xlat
                ret;nop
@I02:           mov      bx,offset ports
                xlat
                ret;nop
@I03:           mov      bx,offset ports
                mov      ah,ds:[bx+4]
                mov      al,ds:[bx+$10]
                mov      cl,ds:[bx+2]
                shl      ax,cl
                mov      ds:[bx+3],ah
                mov      al,ah
                ret;nop
@I04:           ret;nop
@I05:           ret;nop
@I06:           ret;nop
@I07:           ret;nop
@I08:           ret;nop
@I09:           ret;nop
@I0A:           ret;nop
@I0B:           ret;nop
@I0C:           ret;nop
@I0D:           ret;nop
@I0E:           ret;nop
@I0F:           ret;nop
@I10:           ret;nop
@I11:           ret;nop
@I12:           ret;nop
@I13:           ret;nop
@I14:           ret;nop
@I15:           ret;nop
@I16:           ret;nop
@I17:           ret;nop
@I18:           ret;nop
@I19:           ret;nop
@I1A:           ret;nop
@I1B:           ret;nop
@I1C:           ret;nop
@I1D:           ret;nop
@I1E:           ret;nop
@I1F:           ret;nop
@I20:           ret;nop
@I21:           ret;nop
@I22:           ret;nop
@I23:           ret;nop
@I24:           ret;nop
@I25:           ret;nop
@I26:           ret;nop
@I27:           ret;nop
@I28:           ret;nop
@I29:           ret;nop
@I2A:           ret;nop
@I2B:           ret;nop
@I2C:           ret;nop
@I2D:           ret;nop
@I2E:           ret;nop
@I2F:           ret;nop
@I30:           ret;nop
@I31:           ret;nop
@I32:           ret;nop
@I33:           ret;nop
@I34:           ret;nop
@I35:           ret;nop
@I36:           ret;nop
@I37:           ret;nop
@I38:           ret;nop
@I39:           ret;nop
@I3A:           ret;nop
@I3B:           ret;nop
@I3C:           ret;nop
@I3D:           ret;nop
@I3E:           ret;nop
@I3F:           ret;nop
@I40:           ret;nop
@I41:           ret;nop
@I42:           ret;nop
@I43:           ret;nop
@I44:           ret;nop
@I45:           ret;nop
@I46:           ret;nop
@I47:           ret;nop
@I48:           ret;nop
@I49:           ret;nop
@I4A:           ret;nop
@I4B:           ret;nop
@I4C:           ret;nop
@I4D:           ret;nop
@I4E:           ret;nop
@I4F:           ret;nop
@I50:           ret;nop
@I51:           ret;nop
@I52:           ret;nop
@I53:           ret;nop
@I54:           ret;nop
@I55:           ret;nop
@I56:           ret;nop
@I57:           ret;nop
@I58:           ret;nop
@I59:           ret;nop
@I5A:           ret;nop
@I5B:           ret;nop
@I5C:           ret;nop
@I5D:           ret;nop
@I5E:           ret;nop
@I5F:           ret;nop
@I60:           ret;nop
@I61:           ret;nop
@I62:           ret;nop
@I63:           ret;nop
@I64:           ret;nop
@I65:           ret;nop
@I66:           ret;nop
@I67:           ret;nop
@I68:           ret;nop
@I69:           ret;nop
@I6A:           ret;nop
@I6B:           ret;nop
@I6C:           ret;nop
@I6D:           ret;nop
@I6E:           ret;nop
@I6F:           ret;nop
@I70:           ret;nop
@I71:           ret;nop
@I72:           ret;nop
@I73:           ret;nop
@I74:           ret;nop
@I75:           ret;nop
@I76:           ret;nop
@I77:           ret;nop
@I78:           ret;nop
@I79:           ret;nop
@I7A:           ret;nop
@I7B:           ret;nop
@I7C:           ret;nop
@I7D:           ret;nop
@I7E:           ret;nop
@I7F:           ret;nop
@I80:           ret;nop
@I81:           ret;nop
@I82:           ret;nop
@I83:           ret;nop
@I84:           ret;nop
@I85:           ret;nop
@I86:           ret;nop
@I87:           ret;nop
@I88:           ret;nop
@I89:           ret;nop
@I8A:           ret;nop
@I8B:           ret;nop
@I8C:           ret;nop
@I8D:           ret;nop
@I8E:           ret;nop
@I8F:           ret;nop
@I90:           ret;nop
@I91:           ret;nop
@I92:           ret;nop
@I93:           ret;nop
@I94:           ret;nop
@I95:           ret;nop
@I96:           ret;nop
@I97:           ret;nop
@I98:           ret;nop
@I99:           ret;nop
@I9A:           ret;nop
@I9B:           ret;nop
@I9C:           ret;nop
@I9D:           ret;nop
@I9E:           ret;nop
@I9F:           ret;nop
@IA0:           ret;nop
@IA1:           ret;nop
@IA2:           ret;nop
@IA3:           ret;nop
@IA4:           ret;nop
@IA5:           ret;nop
@IA6:           ret;nop
@IA7:           ret;nop
@IA8:           ret;nop
@IA9:           ret;nop
@IAA:           ret;nop
@IAB:           ret;nop
@IAC:           ret;nop
@IAD:           ret;nop
@IAE:           ret;nop
@IAF:           ret;nop
@IB0:           ret;nop
@IB1:           ret;nop
@IB2:           ret;nop
@IB3:           ret;nop
@IB4:           ret;nop
@IB5:           ret;nop
@IB6:           ret;nop
@IB7:           ret;nop
@IB8:           ret;nop
@IB9:           ret;nop
@IBA:           ret;nop
@IBB:           ret;nop
@IBC:           ret;nop
@IBD:           ret;nop
@IBE:           ret;nop
@IBF:           ret;nop
@IC0:           ret;nop
@IC1:           ret;nop
@IC2:           ret;nop
@IC3:           ret;nop
@IC4:           ret;nop
@IC5:           ret;nop
@IC6:           ret;nop
@IC7:           ret;nop
@IC8:           ret;nop
@IC9:           ret;nop
@ICA:           ret;nop
@ICB:           ret;nop
@ICC:           ret;nop
@ICD:           ret;nop
@ICE:           ret;nop
@ICF:           ret;nop
@ID0:           ret;nop
@ID1:           ret;nop
@ID2:           ret;nop
@ID3:           ret;nop
@ID4:           ret;nop
@ID5:           ret;nop
@ID6:           ret;nop
@ID7:           ret;nop
@ID8:           ret;nop
@ID9:           ret;nop
@IDA:           ret;nop
@IDB:           ret;nop
@IDC:           ret;nop
@IDD:           ret;nop
@IDE:           ret;nop
@IDF:           ret;nop
@IE0:           ret;nop
@IE1:           ret;nop
@IE2:           ret;nop
@IE3:           ret;nop
@IE4:           ret;nop
@IE5:           ret;nop
@IE6:           ret;nop
@IE7:           ret;nop
@IE8:           ret;nop
@IE9:           ret;nop
@IEA:           ret;nop
@IEB:           ret;nop
@IEC:           ret;nop
@IED:           ret;nop
@IEE:           ret;nop
@IEF:           ret;nop
@IF0:           ret;nop
@IF1:           ret;nop
@IF2:           ret;nop
@IF3:           ret;nop
@IF4:           ret;nop
@IF5:           ret;nop
@IF6:           ret;nop
@IF7:           ret;nop
@IF8:           ret;nop
@IF9:           ret;nop
@IFA:           ret;nop
@IFB:           ret;nop
@IFC:           ret;nop
@IFD:           ret;nop
@IFE:           ret;nop
@IFF:           ret;nop
@@end:
END;
procedure giv(intnum:byte;var p);assembler;
asm
        push    ds
        xor     ax,ax
        mov     ds,ax
        mov     al,intnum
        cbw
        add     ax,ax
        add     ax,ax
        mov     si,ax
        les     di,p
        lodsw
        stosw
        lodsw
        stosw
        pop     ds
end;
procedure siv(intnum:byte;var p);assembler;
asm
        push    ds
        xor     ax,ax
        mov     es,ax
        mov     al,intnum
        cbw
        add     ax,ax
        add     ax,ax
        mov     di,ax
        lds     si,p
        lodsw
        stosw
        lodsw
        stosw
        pop     ds
end;
Procedure int9handler;assembler;
asm
        push    ds
        pusha
        mov     ax,cs:[offset @dseg]
        mov     ds,ax
        in      al,60h
        mov     bl,al
        and     bx,$7f
        and     al,$80
        mov     ds:[bx+offset key_table],al

        mov     bx,offset key_table
        xor     ah,ah
        mov     cl,$7
        mov     si,offset scancodes
@l_sc:  lodsb                     {load scancode}
        xlat                      {load scancode's status}
        shr     al,cl
        or      ah,al
        dec     cl
        jns     @l_sc
        mov     dl,ah

        xor     ah,ah
        mov     cl,$7
        mov     si,offset scancodes + 8
@l_sc2: lodsb                     {load scancode}
        xlat                      {load scancode's status}
        shr     al,cl
        or      ah,al
        dec     cl
        jns     @l_sc2
        mov     dh,ah

        mov     bx,offset ports
        not     dx
        xor     dl,1            { credit is active low}
        or      dl,10001000b
        or      dh,deeps
        mov     ds:[bx+1],dl
        mov     ds:[bx+2],dh

        mov     al,20h
        out     20h,al
        popa
        pop     ds
        iret
@dseg:  dw      00 {<----------|}
end;                          {|}
procedure putdseg;assembler;  {|}
asm                           {|}
        push    ds            {|}
        call    @dopo         {|}
@dopo:  pop     bx   {get ip} {|}
        mov     ax,ds         {|}
        mov     cs:[bx-7],ax{<-|}
        pop     ds
end;
(*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*)
(*                          ²² ²² ²²²²² ² ²  ²                        *)
(*                          ² ² ² ²   ² ² ²² ²                        *)
(*                          ²   ² ²²²²² ² ² ²²                        *)
(*                          ²   ² ²   ² ² ²  ²                        *)
(*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*)
begin
putdseg;  {In modalit… protetta esplode}
z80mem:=gdm($ffff);
vmem:=gdm($ffff);
clear(z80mem);
val(paramstr(1),i1,j1);
if j1<>0 then i1:=0;
for i:= 0 to index[i1+1]-index[i1]-1 do
                                   begin
                                   s:='roms\'+nomi[index[i1]+i]+#0;
                                   write('Loading ',s,'->');
                                   handle:=fopen(s);
                                   if handle=$ffff then begin
                                                        writeln('Fail');
                                                        goto 1;
                                                        end;
                                   writeln('OK');
                                   x:=ptr(z80mem,0);
                                   fread(handle,$ffff,address[index[i1]+i],x^);
                                   fclose(handle);
                                   end;

asm
xor     ax,ax
int     16h
end;
giv(9,old9);
p:=addr(int9handler);
siv(9,p);
z80_virtual(0);
a:=$00;f:=$00;b:=$00;c:=$00;d:=$00;e:=$00;h:=$00;l:=$00;
spz:=$0000;ip:=$000;iff1:=1;
deeps:=1;
key_table[1]:=1;key_table[2]:=1;key_table[3]:=1;
key_table[0]:=$80;
key_table[61]:=$80;key_table[59]:=$80;key_table[57]:=$80;key_table[20]:=$80;
key_table[75]:=$80;key_table[77]:=$80;
xmode(4,xm,index_xm);
nmi:=nmi_cycle;
int:=int_Cycle;
repeat
z80_virtual(1);
x:=ptr(z80mem,ip);
nmi:=nmi-main_clock[x^];
if nmi<30 then begin
               nmi:=nmi_Cycle;
               if iff1=1 then begin
                              spz:=spz-2;
                              ww:=ptr(z80mem,spz);
                              ww^:=ip;
                              ip:=$10;
                              end;
               end;
int:=int-main_clock[x^];
if int <30 then begin
                int:=int_Cycle;
                if iff1=1 then begin
                               iff1:=0;
                               iff2:=0;
                               spz:=spz-2;
                               ww:=ptr(z80mem,spz);
                               ww^:=ip;
                               ip:=8;
                               end;
                end;
if key_table[3]=0 then begin
                       asm int 3 end;
                       end;
until key_table[1]<>1;
asm
        mov     ax,3
        int     10h
end;
1:
siv(9,old9);
mem[$40:$17]:=0;
end.
