	SUBROUTINE COPY_2D_TO_3D ( src, msrc, dst, mdst )

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
* copy data from a 2D (XY and T) grid to a 3D grid and then replicate the
* data along the Z axis of the dstination

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  8/1/89 - 4D symmetrical
*	10/11/89 - use ..._SUB - avoid adjustable dimensioning with array
*       *acm* 3/12 cleanup ifdefs and unnecessary include files
* TODO: what changes to make for 6D Ferret?

	include 'tmap_dims.parm'
	include 'ferret.parm'
	include	'xvariables.cmn'

* calling argument declarations:
	INTEGER msrc, mdst
	REAL    src( * ), dst( * )

* --- end of introductory code ---

	CALL COPY_2D_TO_3D_SUB(
     .			    src, mr_lo_s1(msrc), mr_hi_s1(msrc),
     .				 mr_lo_s2(msrc), mr_hi_s2(msrc),
     .
     .				 mr_lo_s4(msrc), mr_hi_s4(msrc),
     .			    dst, mr_lo_s1(mdst), mr_hi_s1(mdst),
     .				 mr_lo_s2(mdst), mr_hi_s2(mdst),
     .				 mr_lo_s3(mdst), mr_hi_s3(mdst),
     .				 mr_lo_s4(mdst), mr_hi_s4(mdst)	)


	RETURN
	END 
