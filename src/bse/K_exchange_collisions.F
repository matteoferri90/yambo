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
subroutine K_exchange_collisions(iq,Xk,i_T_grp)
 !
 use drivers,        ONLY:l_col_cut
 use D_lattice,      ONLY:nsym,i_time_rev,sop_inv
 use BS,             ONLY:BS_T_grp,K_EXCH_collision,BS_oscillators_alloc,BS_n_g_exch
 use R_lattice,      ONLY:g_rot,qindx_X,bz_samp,bare_qpg
#if defined _TIMING
 use timing_m,       ONLY:timing
#endif
 implicit none
 !
 type(bz_samp) :: Xk
 integer       :: iq,i_T_grp
 !
 ! Work Space
 !
 logical :: divide_by_qpg
 integer :: i_T_el,i_T_el_p,N_T_el_p,i_c,i_v,i_spin,i_k_bz,i_k,i_s,i_g1,i_g2,i_p_bz,i_p,&
&           i_sp,i_T_el_last_with_identity_sym,i_T_grp_last_with_identity_sym,i_T_grp_p
 !
 ! Oscillators already done ?
 !
 if (allocated( BS_T_grp(i_T_grp)%O_x )) return
 !
#if defined _TIMING
 call timing('T_space EXX Osc.',OPR='start')
#endif
 !
 divide_by_qpg=.not.l_col_cut
 !
 ! Allocate
 !
 call BS_oscillators_alloc(.TRUE.,i_T_grp,.FALSE.,0)
 !
 T_loop: do i_T_el=1,BS_T_grp(i_T_grp)%size
   !
   i_k_bz=BS_T_grp(i_T_grp)%table(i_T_el,1)
   i_k   =Xk%sstar(i_k_bz,1)
   i_s   =Xk%sstar(i_k_bz,2)
   !
   i_p_bz=qindx_X(iq,i_k_bz,1)
   i_p   =Xk%sstar(i_p_bz,1)
   i_sp  =Xk%sstar(i_p_bz,2)
   !
   i_v   =BS_T_grp(i_T_grp)%table(i_T_el,2)
   i_c   =BS_T_grp(i_T_grp)%table(i_T_el,3)
   i_spin=BS_T_grp(i_T_grp)%table(i_T_el,4)
   !
   K_EXCH_collision%is=(/i_c,i_k,i_s,i_spin/)
   K_EXCH_collision%os=(/i_v,i_p,i_sp,i_spin/)
   K_EXCH_collision%qs=(/qindx_X(iq,i_k_bz,2),iq,1/)
   !
   if (iq==1) then
     !
     i_T_grp_last_with_identity_sym=-1
     i_T_el_last_with_identity_sym=-1
     if (i_s>1) then
       do i_T_grp_p=i_T_grp,1,-1
         if ( .not.allocated(BS_T_grp(i_T_grp_p)%O_x)      ) cycle
         if ( BS_T_grp(i_T_grp_p)%ik/=BS_T_grp(i_T_grp)%ik ) exit
         if ( i_T_grp_p==i_T_grp ) N_T_el_p=i_T_el-1
         if ( i_T_grp_p/=i_T_grp ) N_T_el_p=BS_T_grp(i_T_grp_p)%size
         do i_T_el_p=N_T_el_p,1,-1
           if ( all( BS_T_grp(i_T_grp_p)%table(i_T_el_p,:)==(/Xk%k_table(i_k,1),i_v,i_c,i_spin/)) ) then
             i_T_grp_last_with_identity_sym=i_T_grp_p
             i_T_el_last_with_identity_sym =i_T_el_p
             exit
           endif
         enddo
       enddo
     endif
     !
     if  (i_s==1.or.i_T_grp_last_with_identity_sym<0) then
       !
       call scatter_Bamp(K_EXCH_collision)
       !
#if defined _OPENMP
!$omp parallel do default(shared), private(i_g1,i_g2)
#endif
       do i_g1=1,BS_n_g_exch
         if (     divide_by_qpg) BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=K_EXCH_collision%rhotw(i_g1)/bare_qpg(iq,i_g1)
         if (.not.divide_by_qpg) BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=K_EXCH_collision%rhotw(i_g1)
       enddo
#if defined _OPENMP
!$omp end parallel do
#endif
     else
#if defined _OPENMP
!$omp parallel do default(shared), private(i_g1,i_g2)
#endif
       do i_g1=1,BS_n_g_exch
         i_g2=g_rot(sop_inv(i_s),i_g1)
         BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=BS_T_grp(i_T_grp_last_with_identity_sym)%O_x(i_g2,i_T_el_last_with_identity_sym)
         if (i_s>nsym/(i_time_rev+1)) BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=conjg(BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el))
       enddo
#if defined _OPENMP
!$omp end parallel do
#endif
     endif
   else
     !
     call scatter_Bamp(K_EXCH_collision)
     !
#if defined _OPENMP
!$omp parallel do default(shared), private(i_g1)
#endif
     do i_g1=1,BS_n_g_exch
       if (     divide_by_qpg) BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=K_EXCH_collision%rhotw(i_g1)/bare_qpg(iq,i_g1)
       if (.not.divide_by_qpg) BS_T_grp(i_T_grp)%O_x(i_g1,i_T_el)=K_EXCH_collision%rhotw(i_g1)
     enddo
#if defined _OPENMP
!$omp end parallel do
#endif
     !
   endif
   !
 enddo T_loop
 !
#if defined _TIMING
 call timing('T_space EXX Osc.',OPR='stop')
#endif
 !
end subroutine K_exchange_collisions
