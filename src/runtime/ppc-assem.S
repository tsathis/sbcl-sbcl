#define LANGUAGE_ASSEMBLY

#include "sbcl.h" 
#include "lispregs.h"
#include "globals.h"

#include "genesis/simple-fun.h"
#include "genesis/fdefn.h"
#include "genesis/closure.h"
#include "genesis/static-symbols.h"

#ifdef LISP_FEATURE_DARWIN
#define CSYMBOL(x) _ ## x
#else
#define CSYMBOL(x) x
#endif

#if defined LISP_FEATURE_DARWIN
#define FUNCDEF(x)	.text @ \
			.align 3 @ \
_##x:

#define GFUNCDEF(x)	.globl _/**/x @ \
	FUNCDEF(x)
#else
#define FUNCDEF(x)	.text ; \
			.align 3 ; \
			.type x,@function ; \
x:

#define GFUNCDEF(x)	.globl x ; \
	FUNCDEF(x)
#endif

#if defined LISP_FEATURE_DARWIN
#define SET_SIZE(x)
#else
#define SET_SIZE(x) .size x,.-x
#endif

/* Load a register from a global, using the register as an intermediary */
/* The register will be a fixnum for one instruction, so this is gc-safe */

#if defined LISP_FEATURE_DARWIN
#define load(reg,global) \
	lis reg,ha16(global) @ \
	lwz reg,lo16(global)(reg) ; Comment
#define store(reg,temp,global) \
	lis temp,ha16(global) @\
	stw reg,lo16(global)(temp) ; Comment
#else
#define load(reg,global) \
	lis reg,global@ha; lwz reg,global@l(reg)
#define store(reg,temp,global) \
	lis temp,global@ha; stw reg,global@l(temp)
#endif
	
#define	FIRST_SAVE_FPR	14	/* lowest-numbered non-volatile FPR */
#ifdef LISP_FEATURE_DARWIN
#define	FIRST_SAVE_GPR	13	/* lowest-numbered non-volatile GPR */
#define NGPR_SAVE_BYTES(n) ((32-(n))*4)
#define FRAME_ARG_BYTES(n)  (((((n)+6)*4)+15)&~15)
#else
#define	FIRST_SAVE_GPR	14	/* lowest-numbered non-volatile GPR */
#define NGPR_SAVE_BYTES(n) ((32-(~1&((n)+1)))*4)
#define FRAME_ARG_BYTES(n)  (((((n)+2)*4)+15)&~15)
#endif
#define	NFPR_SAVE_BYTES(n) ((32-(n))*8)

#ifdef LISP_FEATURE_DARWIN
#define FRAME_SIZE(first_g,first_f,out_arg_words,savecr) \
(NFPR_SAVE_BYTES(first_f)+ NGPR_SAVE_BYTES(first_g)+ FRAME_ARG_BYTES(out_arg_words))
#define SAVE_FPR(n) stfd f##n,-8*(32- n)(r11)
#define SAVE_GPR(n) stw r##n,-4*(32- n)(r11)
#define FULL_FRAME_SIZE FRAME_SIZE(FIRST_SAVE_GPR,FIRST_SAVE_FPR,8,1)
#define RESTORE_FPR(n) lfd f##n,-8*(32- n)(r11)
#define RESTORE_GPR(n) lwz r##n,-4*(32- n)(r11)
#else
#define FRAME_SIZE(first_g,first_f,out_arg_words,savecr) \
(NFPR_SAVE_BYTES(first_f)+ NGPR_SAVE_BYTES(first_g)+ FRAME_ARG_BYTES(out_arg_words+savecr))
#define SAVE_FPR(n) stfd n,-8*(32-(n))(11)
#define SAVE_GPR(n) stw n,-4*(32-(n))(11)
#define FULL_FRAME_SIZE FRAME_SIZE(FIRST_SAVE_GPR,FIRST_SAVE_FPR,0,1)

#define RESTORE_FPR(n) lfd n,-8*(32-(n))(11)
#define RESTORE_GPR(n) lwz n,-4*(32-(n))(11)
#endif

#ifdef LISP_FEATURE_DARWIN
#define C_FULL_PROLOG \
	nop @\
	nop @ \
	mfcr REG(0) @ \
	stw REG(0),4(REG(1)) @ \
	mflr REG(0) @ \
	stw REG(0),8(REG(1)) @ \
	mr REG(11),REG(1) @ \
	stwu REG(1),-FULL_FRAME_SIZE(REG(1)) @ \
	SAVE_FPR(14) @ \
	SAVE_FPR(15) @ \
	SAVE_FPR(16) @ \
	SAVE_FPR(17) @ \
	SAVE_FPR(18) @ \
	SAVE_FPR(19) @ \
	SAVE_FPR(20) @ \
	SAVE_FPR(21) @ \
	SAVE_FPR(22) @ \
	SAVE_FPR(23) @ \
	SAVE_FPR(24) @ \
	SAVE_FPR(25) @ \
	SAVE_FPR(26) @ \
	SAVE_FPR(27) @ \
	SAVE_FPR(28) @ \
	SAVE_FPR(29) @ \
	SAVE_FPR(30) @ \
	SAVE_FPR(31) @ \
	la REG(11),-NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(REG(11)) @ \
	SAVE_GPR(13) @ \
	SAVE_GPR(14) @ \
	SAVE_GPR(15) @ \
	SAVE_GPR(16) @ \
	SAVE_GPR(17) @ \
	SAVE_GPR(18) @ \
	SAVE_GPR(19) @ \
	SAVE_GPR(20) @ \
	SAVE_GPR(21) @ \
	SAVE_GPR(22) @ \
	SAVE_GPR(23) @ \
	SAVE_GPR(24) @ \
	SAVE_GPR(25) @ \
	SAVE_GPR(26) @ \
	SAVE_GPR(27) @ \
	SAVE_GPR(28) @ \
	SAVE_GPR(29) @ \
	SAVE_GPR(30) @ \
	SAVE_GPR(31)


#define C_FULL_EPILOG \
	la REG(11),FULL_FRAME_SIZE-NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(REG(1)) @ \
	RESTORE_GPR(13) @ \
	RESTORE_GPR(14) @ \
	RESTORE_GPR(15) @ \
	RESTORE_GPR(16) @ \
	RESTORE_GPR(17) @ \
	RESTORE_GPR(18) @ \
	RESTORE_GPR(19) @ \
	RESTORE_GPR(20) @ \
	RESTORE_GPR(21) @ \
	RESTORE_GPR(22) @ \
	RESTORE_GPR(23) @ \
	RESTORE_GPR(24) @ \
	RESTORE_GPR(25) @ \
	RESTORE_GPR(26) @ \
	RESTORE_GPR(27) @ \
	RESTORE_GPR(28) @ \
	RESTORE_GPR(29) @ \
	RESTORE_GPR(30) @ \
	RESTORE_GPR(31) @ \
	la REG(11),NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(REG(11)) @ \
	RESTORE_FPR(14) @ \
	RESTORE_FPR(15) @ \
	RESTORE_FPR(16) @ \
	RESTORE_FPR(17) @ \
	RESTORE_FPR(18) @ \
	RESTORE_FPR(19) @ \
	RESTORE_FPR(20) @ \
	RESTORE_FPR(21) @ \
	RESTORE_FPR(22) @ \
	RESTORE_FPR(23) @ \
	RESTORE_FPR(24) @ \
	RESTORE_FPR(25) @ \
	RESTORE_FPR(26) @ \
	RESTORE_FPR(27) @ \
	RESTORE_FPR(28) @ \
	RESTORE_FPR(29) @ \
	RESTORE_FPR(30) @ \
	RESTORE_FPR(31) @ \
	lwz REG(1),0(REG(1)) @ \
	lwz REG(0),4(REG(1)) @ \
	mtcr REG(0) @ \
	lwz REG(0),8(REG(1)) @ \
	mtlr REG(0) @ \
	
#else	

#define C_FULL_PROLOG \
	mflr 0 ; \
	stw 0,4(1) ; \
	mr 11,1 ; \
	stwu 1,-FULL_FRAME_SIZE(1) ; \
	SAVE_FPR(14) ; \
	SAVE_FPR(15) ; \
	SAVE_FPR(16) ; \
	SAVE_FPR(17) ; \
	SAVE_FPR(18) ; \
	SAVE_FPR(19) ; \
	SAVE_FPR(20) ; \
	SAVE_FPR(21) ; \
	SAVE_FPR(22) ; \
	SAVE_FPR(23) ; \
	SAVE_FPR(24) ; \
	SAVE_FPR(25) ; \
	SAVE_FPR(26) ; \
	SAVE_FPR(27) ; \
	SAVE_FPR(28) ; \
	SAVE_FPR(29) ; \
	SAVE_FPR(30) ; \
	SAVE_FPR(31) ; \
	la 11,-NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(11) ; \
	SAVE_GPR(14) ; \
	SAVE_GPR(15) ; \
	SAVE_GPR(16) ; \
	SAVE_GPR(17) ; \
	SAVE_GPR(18) ; \
	SAVE_GPR(19) ; \
	SAVE_GPR(20) ; \
	SAVE_GPR(21) ; \
	SAVE_GPR(22) ; \
	SAVE_GPR(23) ; \
	SAVE_GPR(24) ; \
	SAVE_GPR(25) ; \
	SAVE_GPR(26) ; \
	SAVE_GPR(27) ; \
	SAVE_GPR(28) ; \
	SAVE_GPR(29) ; \
	SAVE_GPR(30) ; \
	SAVE_GPR(31) ; \
	mfcr 0	; \
	stw 0,8(1)

#define C_FULL_EPILOG \
	lwz 5,8(1) ; \
	mtcrf 255,5 ; \
	la 11,FULL_FRAME_SIZE-NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(1) ; \
	RESTORE_GPR(14) ; \
	RESTORE_GPR(15) ; \
	RESTORE_GPR(16) ; \
	RESTORE_GPR(17) ; \
	RESTORE_GPR(18) ; \
	RESTORE_GPR(19) ; \
	RESTORE_GPR(20) ; \
	RESTORE_GPR(21) ; \
	RESTORE_GPR(22) ; \
	RESTORE_GPR(23) ; \
	RESTORE_GPR(24) ; \
	RESTORE_GPR(25) ; \
	RESTORE_GPR(26) ; \
	RESTORE_GPR(27) ; \
	RESTORE_GPR(28) ; \
	RESTORE_GPR(29) ; \
	RESTORE_GPR(30) ; \
	RESTORE_GPR(31) ; \
	la 11,NFPR_SAVE_BYTES(FIRST_SAVE_FPR)(11) ; \
	RESTORE_FPR(14) ; \
	RESTORE_FPR(15) ; \
	RESTORE_FPR(16) ; \
	RESTORE_FPR(17) ; \
	RESTORE_FPR(18) ; \
	RESTORE_FPR(19) ; \
	RESTORE_FPR(20) ; \
	RESTORE_FPR(21) ; \
	RESTORE_FPR(22) ; \
	RESTORE_FPR(23) ; \
	RESTORE_FPR(24) ; \
	RESTORE_FPR(25) ; \
	RESTORE_FPR(26) ; \
	RESTORE_FPR(27) ; \
	RESTORE_FPR(28) ; \
	RESTORE_FPR(29) ; \
	RESTORE_FPR(30) ; \
	RESTORE_FPR(31) ; \
	lwz 1,0(1) ; \
	lwz 0,4(1) ; \
	mtlr 0 ; \
	
#endif
	
	.text

/*
 * Function to transfer control into lisp.  The lisp object to invoke is
 * passed as the first argument, which puts it in NL0
 */

	GFUNCDEF(call_into_lisp)
	C_FULL_PROLOG
	/* store(reg_POLL,11,saver2) */
	/* Initialize tagged registers */
	li reg_ZERO,0
	li reg_CODE,0
	li reg_CNAME,0
	li reg_LEXENV,0
	li reg_FDEFN,0
	li reg_OCFP,0
	li reg_LRA,0
	li reg_A0,0
	li reg_A1,0
	li reg_A2,0
	li reg_A3,0
	li reg_L0,0
	li reg_L1,0
	li reg_L2,0
	li reg_LIP,0
#ifdef LISP_FEATURE_DARWIN	
	lis reg_NULL,hi16(NIL)
	ori reg_NULL,reg_NULL,lo16(NIL)
#else
	lis reg_NULL,NIL@h
	ori reg_NULL,reg_NULL,NIL@l
#endif
	/* Turn on pseudo-atomic */

	li reg_NL3,-4
	li reg_ALLOC,4
	store(reg_ZERO,reg_NL4,CSYMBOL(foreign_function_call_active))
	load(reg_NL4,CSYMBOL(dynamic_space_free_pointer))
	add reg_ALLOC,reg_ALLOC,reg_NL4
	load(reg_BSP,CSYMBOL(current_binding_stack_pointer))
	load(reg_CSP,CSYMBOL(current_control_stack_pointer))
	load(reg_OCFP,CSYMBOL(current_control_frame_pointer))

	/* No longer atomic, and check for interrupt */
	add reg_ALLOC,reg_ALLOC,reg_NL3
	twlti reg_ALLOC,0

	/* Pass in the arguments */

	mr reg_CFP,reg_NL1
	mr reg_LEXENV,reg_NL0
	lwz reg_A0,0(reg_CFP)
	lwz reg_A1,4(reg_CFP)
	lwz reg_A2,8(reg_CFP)
	lwz reg_A3,12(reg_CFP)

	/* Calculate LRA */
#ifdef LISP_FEATURE_DARWIN
	lis reg_LRA,ha16(lra)
	addi reg_LRA,reg_LRA,lo16(lra)
#else
	lis reg_LRA,lra@h
	addi reg_LRA,reg_LRA,lra@l
#endif
	addi reg_LRA,reg_LRA,OTHER_POINTER_LOWTAG

	/* Function is an indirect closure */
	lwz reg_CODE,SIMPLE_FUN_SELF_OFFSET(reg_LEXENV)
	addi reg_LIP,reg_CODE,6*4-FUN_POINTER_LOWTAG
	mtctr reg_LIP
	slwi reg_NARGS,reg_NL2,2
	bctr			
	
	.align 3
lra:
	.long RETURN_PC_HEADER_WIDETAG 

	/* Blow off any extra values. */
	mr reg_CSP,reg_OCFP
	nop

	/* Return the one value. */

	mr REG(3),reg_A0

	/* Turn on  pseudo-atomic */
	li reg_NL3,-4
	la reg_ALLOC,4(reg_ALLOC)

	/* Store lisp state */
	clrrwi reg_NL1,reg_ALLOC,3
	store(reg_NL1,reg_NL2,CSYMBOL(dynamic_space_free_pointer))
	/* store(reg_POLL,reg_NL2,poll_flag) */
	/* load(reg_NL2,current_thread) */
	store(reg_BSP,reg_NL2,CSYMBOL(current_binding_stack_pointer))
	store(reg_CSP,reg_NL2,CSYMBOL(current_control_stack_pointer))
	store(reg_CFP,reg_NL2,CSYMBOL(current_control_frame_pointer))
	/* load(reg_POLL,saver2) */

	/* No longer in Lisp. */
	store(reg_NL1,reg_NL2,CSYMBOL(foreign_function_call_active))

	/* Check for interrupt */
	add reg_ALLOC,reg_ALLOC,reg_NL3
	twlti reg_ALLOC,0

	/* Back to C */
	C_FULL_EPILOG
	blr
	SET_SIZE(call_into_lisp)


	GFUNCDEF(call_into_c)
	/* We're kind of low on unboxed, non-dedicated registers here:
	most of the unboxed registers may have outgoing C args in them.
	CFUNC is going to have to go in the CTR in a moment, anyway
	so we'll free it up soon.  reg_NFP is preserved by lisp if it
	has a meaningful value in it, so we can use it.  reg_NARGS is
	free when it's not holding a copy of the "real" reg_NL3, which
	gets tied up by the pseudo-atomic mechanism */
	mtctr reg_CFUNC
	mflr reg_LIP
	/* Build a lisp stack frame */
	mr reg_OCFP,reg_CFP
	mr reg_CFP,reg_CSP
	la reg_CSP,32(reg_CSP)
	stw reg_OCFP,0(reg_CFP)
	stw reg_CODE,8(reg_CFP)
	/* The pseudo-atomic mechanism wants to use reg_NL3, but that
	may be an outgoing C argument.  Copy reg_NL3 to something that's
	unboxed and -not- one of the C argument registers */
	mr reg_NARGS,reg_NL3

	/* Turn on pseudo-atomic */
	li reg_NL3,-4
	la reg_ALLOC,4(reg_ALLOC)

	/* Convert the return address to an offset and save it on the stack. */
	sub reg_NFP,reg_LIP,reg_CODE
	la reg_NFP,OTHER_POINTER_LOWTAG(reg_NFP)
	stw reg_NFP,4(reg_CFP)

	/* Store Lisp state */
	clrrwi reg_NFP,reg_ALLOC,3
	store(reg_NFP,reg_CFUNC,CSYMBOL(dynamic_space_free_pointer))
	/* load(reg_CFUNC,current_thread) */
	
	store(reg_BSP,reg_CFUNC,CSYMBOL(current_binding_stack_pointer))
	store(reg_CSP,reg_CFUNC,CSYMBOL(current_control_stack_pointer))
	store(reg_CFP,reg_CFUNC,CSYMBOL(current_control_frame_pointer))

	/* No longer in Lisp */
	store(reg_CSP,reg_CFUNC,CSYMBOL(foreign_function_call_active))
	/* load(reg_POLL,saver2) */
	/* Disable pseudo-atomic; check pending interrupt */
	add reg_ALLOC,reg_ALLOC,reg_NL3
	twlti reg_ALLOC,0
	mr reg_NL3,reg_NARGS

#ifdef LISP_FEATURE_DARWIN
	/* PowerOpen (i.e. OS X) requires the callee address in r12
           (a.k.a. CFUNC), so move it back there, too. */
	mfctr reg_CFUNC
#endif
        /* Into C we go. */
	bctrl

	/* Re-establish NIL */
#ifdef LISP_FEATURE_DARWIN
	lis reg_NULL,hi16(NIL)
	ori reg_NULL,reg_NULL,lo16(NIL)
#else
	lis reg_NULL,NIL@h
	ori reg_NULL,reg_NULL,NIL@l
#endif
	/* And reg_ZERO */
	li reg_ZERO,0

	/* If we GC'ed during the FF code (as the result of a callback ?)
	the tagged lisp registers may now contain garbage (since the
	registers were saved by C and not seen by the GC.)  Put something
	harmless in all such registers before allowing an interrupt */
	li reg_CODE,0
	li reg_CNAME,0
	li reg_LEXENV,0
	/* reg_OCFP was pointing to a control stack frame & was preserved by C */
	li reg_LRA,0
	li reg_A0,0
	li reg_A1,0
	li reg_A2,0
	li reg_A3,0
	li reg_L0,0
	li reg_L1,0
	li reg_L2,0
	li reg_LIP,0

	/* Atomic ... */
	li reg_NL3,-4
	li reg_ALLOC,4

	/* No long in foreign function call. */
	store(reg_ZERO,reg_NL2,CSYMBOL(foreign_function_call_active))

	/* The free pointer may have moved */
	load(reg_NL4,CSYMBOL(dynamic_space_free_pointer))
	add reg_ALLOC,reg_ALLOC,reg_NL4

	/* The BSP wasn't preserved by C, so load it */
	load(reg_BSP,CSYMBOL(current_binding_stack_pointer))

	/* Other lisp stack/frame pointers were preserved by C.
	I can't imagine why they'd have moved */

	/* Get the return address back. */
	lwz reg_LIP,4(reg_CFP)
	lwz reg_CODE,8(reg_CFP)
	add reg_LIP,reg_CODE,reg_LIP
	la reg_LIP,-OTHER_POINTER_LOWTAG(reg_LIP)

	/* No longer atomic */
	add reg_ALLOC,reg_ALLOC,reg_NL3
	twlti reg_ALLOC,0
	mtlr reg_LIP
	
	/* Reset the lisp stack. */
	mr reg_CSP,reg_CFP
	mr reg_CFP,reg_OCFP
	
	/* And back into Lisp. */
	blr

	SET_SIZE(call_into_c)

	GFUNCDEF(xundefined_tramp)
	.globl CSYMBOL(undefined_tramp)
	.byte 0,0,0,SIMPLE_FUN_HEADER_WIDETAG
	.byte 18<<2
CSYMBOL(undefined_tramp):	
	.byte 0,0,48
	.long CSYMBOL(undefined_tramp)
	.long NIL
	.long NIL
	.long NIL
	twllei reg_ZERO,trap_Cerror
	.byte 4
	.byte UNDEFINED_FUN_ERROR
	.byte 254, sc_DescriptorReg+0x40, 1	/* 140?  sparc says sc_descriptorReg */
	.align 2
1:	lwz reg_CODE,FDEFN_RAW_ADDR_OFFSET(reg_FDEFN)
	la reg_LIP,SIMPLE_FUN_CODE_OFFSET(reg_CODE)
	mtctr reg_LIP
	bctr
	mr reg_CSP,reg_CFP
	b 1b

	SET_SIZE(xundefined_tramp)

	GFUNCDEF(xclosure_tramp)
	.globl CSYMBOL(closure_tramp)
	.byte 0,0,0,SIMPLE_FUN_HEADER_WIDETAG
	.byte 18<<2
CSYMBOL(closure_tramp):
	.byte 0,0,24
	.long CSYMBOL(closure_tramp)
	.long NIL 
	.long NIL
	.long NIL
	.long NIL
	lwz reg_LEXENV,FDEFN_FUN_OFFSET(reg_FDEFN)
	lwz reg_CODE,CLOSURE_FUN_OFFSET(reg_LEXENV)
	la reg_LIP,SIMPLE_FUN_CODE_OFFSET(reg_CODE)
	mtctr reg_LIP
	bctr

	SET_SIZE(xclosure_tramp)

	GFUNCDEF(fun_end_breakpoint_trap)
	.long 0
	SET_SIZE(fun_end_breakpoint_trap)

	GFUNCDEF(fun_end_breakpoint)
	.long 0
	SET_SIZE(fun_end_breakpoint)

	GFUNCDEF(fun_end_breakpoint_guts)
	.long 0
	SET_SIZE(fun_end_breakpoint_guts)

	GFUNCDEF(fun_end_breakpoint_end)
	.long 0
	SET_SIZE(fun_end_breakpoint_end)


	GFUNCDEF(ppc_flush_cache_line)
	dcbf 0,REG(3)
	sync
	icbi 0,REG(3)
	sync
	isync
	blr
	SET_SIZE(ppc_flush_cache_line)

