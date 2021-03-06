	SUBROUTINE XEQ_STAT

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
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
* execute the STAT command

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 3/25/88
* V200:  5/19/89 - 4D symmetrical
*	10/16/89 - set up adjustable array limits with NON_ARRAY_SUBSC
* V312: 5/94 - array "memory" as a calling argument
*       10/26/94 - changed "STAT" to "VAR_STAT" for IBM/AIX
* V420	 2/7/96  - added STAT/BRIEF
* V530: *sh* 9/00 - added initial data type support in get_cmnd_data 
*       *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)
* V720 *acm*  3/17 Ticket 2512: Add STAT/PRECICISION=

	include 'tmap_dims.parm'
	include	'ferret.parm'
	include 'errmsg.parm'
	include 'slash.parm'
	include 'xvariables.cmn'
	include 'xprog_state.cmn'

* calling argument declarations:

* local variable declarations:
	LOGICAL	full
	INTEGER	mv, cx, istat, lp, stat_digits, status
	REAL	value
	
* decode the qualifiers
	full = qual_given( slash_stat_brief ) .EQ. 0

* determine precision for outputting values
* First, use STAT/PREC= setting.
	stat_digits = 0
	lp = qual_given( slash_stat_precision ) 
	IF ( lp .GT. 0 ) THEN
	   CALL EQUAL_VAL( cmnd_buff(qual_start(lp):qual_end(lp)),
     .                     value, status )
           IF ( status .NE. ferr_ok ) GOTO 5000
	   stat_digits = MAX(1.,MIN(value, 16.))	! 1 to 16	   
	ENDIF

* get the requested data somehow
	CALL GET_CMND_DATA (  cx_last, ptype_native, status )
	IF ( status .NE. ferr_ok ) GOTO 5000

* compute and display the results
  	DO 400 istat = 1, num_uvars_in_cmnd
	   mv = is_mr( istat )
	   cx = is_cx( istat )
	   CALL NON_ARRAY_SUBSC( mv, 1 )
	   CALL VAR_STAT( memry(mv)%ptr, mv, cx,
     .			  ttout_lun, full, stat_digits, status )
           IF (status .NE. ferr_ok) GOTO 5000
 400	CONTINUE

	RETURN

* error exit(s)
 5000	RETURN
	END
