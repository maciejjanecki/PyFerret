	INTEGER FUNCTION DO_FILL_AVE(	idim, arg,
     .					com, com_mr, com_cx,
     .					res, res_mr, res_cx,
     .					buff	)


*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* fill along axis idim by a running mean window

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  6/2/89
*	10/11/89 - modified array declarations using XMEM_SUBSC.CMN
* V550 *sh* 8/2/02 - support for modulo lengths. ensure that filling 
*		    does not operate acros the subspan modulo void point
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include	'ferret.parm'
	include	'errmsg.parm'
	include	'interp_stack.parm'
	include	'xcontext.cmn'
	include	'xvariables.cmn'
	include	'xmem_subsc.cmn'
	include	'xprog_state.cmn'

* calling argument declarations:
	INTEGER	idim, com_mr, com_cx, res_mr, res_cx
	REAL	arg, buff(*),
     .          com( m1lox:m1hix,m1loy:m1hiy,m1loz:m1hiz,
     .               m1lot:m1hit,m1loe:m1hie,m1lof:m1hif ),
     .          res( m2lox:m2hix,m2loy:m2hiy,m2loz:m2hiz,
     .               m2lot:m2hit,m2loe:m2hie,m2lof:m2hif )

* internal variable declarations:
	LOGICAL	TM_ITS_SUBSPAN_MODULO, has_mod_void
	INTEGER	TM_MODULO_LINE_DIM, CGRID_AXIS, 
     .		i, j, k, l, m, n, ii, cnt, haf,
     .          lo_sub(nferdims), hi_sub(nferdims),
     .		ii_com, lo_com, hi_com, lo_com0, hi_com0,
     .		lo_modlim, hi_modlim, nmod, nmod_prev, modlen

	REAL	bad_res, sum, comp

* internal (convenience) equivalences
	INTEGER	lo_s1, lo_s2, lo_s3, lo_s4, lo_s5, lo_s6,
     .          hi_s1, hi_s2, hi_s3, hi_s4, hi_s5, hi_s6
	EQUIVALENCE (lo_s1, lo_sub(1)) , (lo_s2, lo_sub(2)),
     .		    (lo_s3, lo_sub(3)) , (lo_s4, lo_sub(4)),
     .		    (lo_s5, lo_sub(5)) , (lo_s6, lo_sub(6)),
     .		    (hi_s1, hi_sub(1)) , (hi_s2, hi_sub(2)),
     .		    (hi_s3, hi_sub(3)) , (hi_s4, hi_sub(4)),
     .		    (hi_s5, hi_sub(5)) , (hi_s6, hi_sub(6))

* diagnostic mode output: " doing --> VAR_NAME[x=lo:hi@TRN:n,D=#]"
	IF ( mode_diagnostic ) 	CALL DIAG_OP
     .				( 'doing', isact_class_trans, res_cx, idim )

* initialize
	haf = arg * .5
	bad_res = mr_bad_data( com_mr )
	nmod_prev = -99999

* compute limits within which calculation is straightforward
	DO 10 ii = 1, nferdims
	   lo_sub(ii) = cx_lo_ss(res_cx,ii)
	   hi_sub(ii) = cx_hi_ss(res_cx,ii)
 10	CONTINUE
	lo_com0 = cx_lo_ss(com_cx,idim)
	hi_com0 = cx_hi_ss(com_cx,idim)
	lo_com = lo_com0
	hi_com = hi_com0

* it his a subspan modulo axis?
	has_mod_void = TM_ITS_SUBSPAN_MODULO( CGRID_AXIS(idim,com_cx) )
	IF (has_mod_void) THEN
	   modlen = TM_MODULO_LINE_DIM( CGRID_AXIS(idim,com_cx) )
	   has_mod_void = lo_com.LE.0 .OR. hi_com.GE.modlen
	ENDIF

* FILL ALONG X AXIS
	IF ( idim .EQ. x_dim ) THEN
	   DO 110 n = lo_s6, hi_s6
	   DO 110 m = lo_s5, hi_s5
	   DO 110 l = lo_s4, hi_s4
	   DO 110 k = lo_s3, hi_s3
	   DO 110 j = lo_s2, hi_s2
	   DO 110 i = lo_s1, hi_s1
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(i,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 110
	         ENDIF
	         nmod = (i-1)/modlen 
	         IF (i.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 110
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 100 ii = -haf, haf
	         ii_com = i + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 100
	         comp = com(ii_com,j,k,l,m,n)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 100	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 110	   CONTINUE

* FILL ALONG Y AXIS
	ELSEIF ( idim .EQ. y_dim ) THEN
	   DO 220 n = lo_s6, hi_s6
	   DO 220 m = lo_s5, hi_s5
	   DO 220 l = lo_s4, hi_s4
	   DO 220 k = lo_s3, hi_s3
	   DO 220 j = lo_s2, hi_s2
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(j,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 220
	         ENDIF
	         nmod = (j-1)/modlen 
	         IF (j.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	   DO 210 i = lo_s1, hi_s1
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 210
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 200 ii = -haf, haf
	         ii_com = j + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 200
	         comp = com(i,ii_com,k,l,m,n)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 200	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 210	   CONTINUE
 220	   CONTINUE

* FILL ALONG Z AXIS
	ELSEIF ( idim .EQ. z_dim ) THEN
	   DO 320 n = lo_s6, hi_s6
	   DO 320 m = lo_s5, hi_s5
	   DO 320 l = lo_s4, hi_s4
	   DO 320 k = lo_s3, hi_s3
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(k,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 320
	         ENDIF
	         nmod = (k-1)/modlen 
	         IF (k.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	   DO 310 j = lo_s2, hi_s2
	   DO 310 i = lo_s1, hi_s1
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 310
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 300 ii = -haf, haf
	         ii_com = k + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 300
	         comp = com(i,j,ii_com,l,m,n)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 300	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 310	   CONTINUE
 320	   CONTINUE

* FILL ALONG T AXIS
	ELSEIF ( idim .EQ. t_dim ) THEN
	   DO 420 n = lo_s6, hi_s6
	   DO 420 m = lo_s5, hi_s5
	   DO 420 l = lo_s4, hi_s4
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(l,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 420
	         ENDIF
	         nmod = (l-1)/modlen 
	         IF (l.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	   DO 410 k = lo_s3, hi_s3
	   DO 410 j = lo_s2, hi_s2
	   DO 410 i = lo_s1, hi_s1
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 410
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 400 ii = -haf, haf
	         ii_com = l + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 400
	         comp = com(i,j,k,ii_com,m,n)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 400	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 410	   CONTINUE
 420	   CONTINUE

* FILL ALONG E AXIS
	ELSEIF ( idim .EQ. e_dim ) THEN
	   DO 520 n = lo_s6, hi_s6
	   DO 520 m = lo_s5, hi_s5
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(m,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 520
	         ENDIF
	         nmod = (m-1)/modlen 
	         IF (m.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	   DO 510 l = lo_s4, hi_s4
	   DO 510 k = lo_s3, hi_s3
	   DO 510 j = lo_s2, hi_s2
	   DO 510 i = lo_s1, hi_s1
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 510
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 500 ii = -haf, haf
	         ii_com = m + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 500
	         comp = com(i,j,k,l,ii_com,n)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 500	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 510	   CONTINUE
 520	   CONTINUE

* FILL ALONG F AXIS
	ELSEIF ( idim .EQ. f_dim ) THEN
	   DO 620 n = lo_s6, hi_s6
*  ... do not allow filling based upon values across a subspan modulo void
	      IF (has_mod_void) THEN
	         IF (MOD(n,modlen) .EQ. 0) THEN
	            res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	            GOTO 620
	         ENDIF
	         nmod = (n-1)/modlen 
	         IF (n.LE.0) nmod = nmod - 1
	         IF ( nmod .NE. nmod_prev ) THEN
	            nmod_prev = nmod
	            lo_modlim = nmod*modlen + 1
	            hi_modlim = (nmod+1) * modlen
	            lo_com = MAX( lo_modlim, lo_com0 )
	            hi_com = MIN( hi_modlim, hi_com0 )
	         ENDIF
	      ENDIF
* ... end of subspan modulo adjustment
	   DO 610 m = lo_s5, hi_s5
	   DO 610 l = lo_s4, hi_s4
	   DO 610 k = lo_s3, hi_s3
	   DO 610 j = lo_s2, hi_s2
	   DO 610 i = lo_s1, hi_s1
	      IF ( com(i,j,k,l,m,n) .NE. bad_res ) THEN
	         res(i,j,k,l,m,n) = com(i,j,k,l,m,n)
	         GOTO 610
	      ENDIF
	      cnt = 0
	      sum = 0.0
	      DO 600 ii = -haf, haf
	         ii_com = n + ii
	         IF ( ii_com.LT.lo_com .OR. ii_com.GT.hi_com ) GOTO 600
	         comp = com(i,j,k,l,m,ii_com)
	         IF ( comp .NE. bad_res ) THEN
	            cnt = cnt + 1
	            sum = sum + comp
	         ENDIF
 600	      CONTINUE
	      IF ( cnt .GT. 0 ) THEN
	         res(i,j,k,l,m,n) = sum / cnt
	      ELSE
	         res(i,j,k,l,m,n) = bad_res
	      ENDIF
 610	   CONTINUE
 620	   CONTINUE

	ENDIF

* always success
	DO_FILL_AVE = ferr_ok
	RETURN

	END

