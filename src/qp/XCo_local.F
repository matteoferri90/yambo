!
! Copyright (C) 2000-2010 A. Marini and the YAMBO team 
!              http://www.yambo-code.org
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
subroutine XCo_local(E,Xk)
 !
 ! Local V_xc
 !
 use pars,          ONLY:SP,DP,pi
 use electrons,     ONLY:levels,n_spin,n_spinor,n_sp_pol,spin
 use QP_m,          ONLY:QP_Vxc,QP_n_states,QP_table,QP_nk
 use R_lattice,     ONLY:bz_samp
 use FFT_m,         ONLY:fft_size
 use wave_func,     ONLY:wf,wf_state
 use xc_functionals,ONLY:V_xc,xc_string
 use global_XC,     ONLY:WF_kind,WF_xc_functional
 !
 implicit none
 type(levels) ::E       
 type(bz_samp)::k,Xk,q
 !
 ! Work Space
 !
 integer     ::i1,ifft,ifftp,ifft_sp1,ifftp_sp1,ifft_sp2,ib,ibp,ik,i_sp1
#if defined _DOUBLE
 complex(DP) ::zdotc,zdotu
#else 
 complex(SP) ::cdotc,cdotu
#endif
 complex(SP) ::c_ws(fft_size,n_spin)
 !
 ! Spin support (collinear and not collinear)
 !
 real(SP)    :: mod_mag,vxc_plus(fft_size),vxc_minus(fft_size)
 complex(SP) :: V_xc_mat(fft_size,n_spin,n_spin)
 logical     :: l_call_the_driver
 !
 ! Allocation 
 !
 if (.not.allocated(V_xc))   allocate(V_xc(fft_size,n_spin))
 !
 !
 ! Precompiler options in case a non-DFT potential is required
 !
   !
   l_call_the_driver=.TRUE.
   !
   if (l_call_the_driver) then
     call XC_potential_driver(E,Xk,WF_KIND,WF_xc_functional,1)
   endif
   !
 !
 if (n_spin==1) then
   ! 
   do i1=1,QP_n_states
     !
     ib =QP_table(i1,1)
     ibp=QP_table(i1,2)
     ik =QP_table(i1,3)
     !
     ! <ifft|V_xc|ifftp>
     !
     ifft =wf_state(ib,ik,1)
     ifftp=wf_state(ibp,ik,1)
     c_ws(:,1)=V_xc(:,1)*wf(:,ifftp)
     !
#if defined _DOUBLE
     QP_Vxc(i1)=zdotc(fft_size,wf(:,ifft),1,c_ws(:,1),1)
#else 
     QP_Vxc(i1)=cdotc(fft_size,wf(:,ifft),1,c_ws(:,1),1)
#endif
     !
   enddo
   !
   !
   return
   !
 endif
 !
 !
end subroutine