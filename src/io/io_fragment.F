!
!        Copyright (C) 2000-2017 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM
! 
! This file is distributed under the terms of the GNU 
! General Public License. You can redistribute it and/or 
! modify it under the terms of the GNU General Public 
! License as published by the Free Software Foundation; 
! either version 2, or (at your option) any later version.
!
! This program is distributed in the hope that it will 
! be useful, but WITHOUT ANY WARRANTY; without even the 
! implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License 
! for more details.
!
! You should have received a copy of the GNU General Public 
! License along with this program; if not, write to the Free 
! Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
! MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
!
subroutine io_fragment(ID,i_fragment,j_fragment,ierr)
 !
 ! This routine closes the main DB and opens the fragment. 
 !
 ! Note that, as io_disconnect is called with a negative
 ! argument io_reset is no called. This is needed to save
 ! the properties of the DB that have been read previously 
 ! (like io_nectdf_support or io_code_version/revision).
 !
 use pars,       ONLY:schlen
 use IO_m,       ONLY:close_is_on,io_connect,io_resetable,io_file,&
&                     io_sec,io_extension,io_action,read_is_on,write_is_on,&
&                     OP_RD_CL,OP_WR_CL,io_type,io_disconnect,io_folder,io_raw_extension
 use IO_m,       ONLY:frag_WF,frag_DIP,frag_RESPONSE,frag_QINDX,frag_HF,&
                      frag_SC,frag_RT,frag_ELPH,frag_BS_K,frag_SCREEN
 use stderr,     ONLY:intc,write_fragments_IO_log,logfile
 use interfaces, ONLY:PARALLEL_live_message
 use parallel_m, ONLY:ncpu
 !
#if defined _TIMING
 use timing_m,       ONLY:timing
#endif
 implicit none
 integer           :: ID
 integer, optional :: i_fragment,j_fragment,ierr
 !
 ! Work Space
 !
 integer           :: ierr_,i_frag
 logical           :: close_is_on_save
 character(schlen) :: fragment_filename
 !
 if (present(ierr)) then
   ierr=0
 endif
 !
 select case (trim(io_raw_extension(ID)))
   case("Vnl","wf","kb_pp","kb_pp_pwscf")
     if (.not.frag_WF) return
   case("kindx")
     if (.not.frag_QINDX) return
   case("dip_iR_and_P","Overlaps")
     if (.not.frag_DIP) return
   case("HF_and_locXC","xxvxc")
     if (.not.frag_HF) return
   case("em1s","em1d","pp","Xx")
     if (.not.frag_RESPONSE) return
   case("carriers","THETA","JPSM","G","REF")
     if (.not.frag_RT) return
   case("scE","scWFs","scV","sc_MeanPotential")
     if (.not.frag_SC) return
   case("elph_gkkp","elph_gkkp_expanded","elph_gFsq")
     if (.not.frag_ELPH) return
 end select
 !
 if (index(trim(io_raw_extension(ID)),"BS_Q")>0) then
   if (.not.frag_BS_K) return
 endif
 !
#if defined _TIMING
 call timing('io_fragment',OPR='start')
#endif
 !
 close_is_on_save=close_is_on(ID)
 !
 if (read_is_on(ID))  io_action(ID)=OP_RD_CL
 if (write_is_on(ID)) io_action(ID)=OP_WR_CL
 !
 if (present(i_fragment))      i_frag=i_fragment
 if (.not.present(i_fragment)) i_frag=maxval(io_sec(ID,:))
 !
 ! Disconnect without calling io_reset
 !
 io_resetable(ID)=.false.
 !
 call io_disconnect(ID)
 !
 ! io_file is redefined by io_connect
 !
 io_file(ID)=' '
 !
 fragment_filename=trim(io_extension(ID))//"_fragment_"//trim(intc(i_frag))
 if (present(j_fragment)) then
   fragment_filename=trim(io_extension(ID)) &
&                    //"_fragments_"//trim(intc(i_frag))//"_"//trim(intc(j_fragment))
 endif
 ierr_=io_connect(fragment_filename,type=io_type(ID),subfolder=trim(io_folder(ID)),ID=ID)
 !
 if (ncpu>1.and.write_fragments_IO_log.and.index(logfile,"stderr")==0) then
   if (write_is_on(ID)) call PARALLEL_live_message("Writing "//trim(fragment_filename))
   if (read_is_on(ID) ) call PARALLEL_live_message("Reading "//trim(fragment_filename))
 endif
 !
 if (present(ierr)) then
   ierr=ierr_
 endif
 !
 ! io_action must be saved otherwise any io_disconnect call would call io_reset (like in ioWF) 
 !
 if (close_is_on_save) io_resetable(ID)=.true.
 !
#if defined _TIMING
 call timing('io_fragment',OPR='stop')
#endif
 !
end subroutine 
