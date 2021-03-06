!
!        Copyright (C) 2000-2017 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM, DS
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
subroutine el_density_matrix(G_lesser,en,Xk,rho,lowest_band)
 !
 ! Electronic density matrix including the off-diagonal
 ! elements of the lesser Green function
 !
 use pars,           ONLY:SP,cI,cZERO
 use electrons,      ONLY:levels,n_spinor,n_sp_pol
 use R_lattice,      ONLY:bz_samp
 use D_lattice,      ONLY:nsym,i_time_rev
 use FFT_m,          ONLY:fft_size,fft_rot_r
 use wave_func,      ONLY:WF
 use real_time,      ONLY:RT_nk,RT_bands,RT_ibz_coo,RT_Nk_ibz
 use parallel_m,     ONLY:PP_redux_wait,PAR_IND_WF_k,PAR_IND_B_mat_ordered,PAR_IND_WF_linear
 use matrix_operate, ONLY:UP_matrix_index
 !
 implicit none
 !
 type(bz_samp), intent(in)  :: Xk
 complex(SP),   intent(in)  :: G_lesser(RT_bands(1):RT_bands(2),RT_bands(1):RT_bands(2),RT_nk,n_sp_pol)
 integer,       intent(in)  :: lowest_band
 type(levels),  intent(in)  :: en       
 real(SP),      intent(out) :: rho(fft_size)
 !
 ! Work Space 
 !
 integer     :: ib1,ib2,ik,ik_RT,i_wf1,rho_syms,i_wf2,ir,i_sp_pol,i_spinor
 real(SP)    :: rho_no_sym(fft_size)
 complex(SP) :: f_occ
 !
 rho=0._SP
 rho_no_sym=0._SP
 !
 if(lowest_band<RT_bands(1)-1) then
   !
   do i_sp_pol=1,n_sp_pol
     do ik=1,Xk%nibz
       do ib1=lowest_band,RT_bands(1)-1
         !
         if (.not.PAR_IND_WF_linear%element_2D(ib1,ik)) cycle
         !
         f_occ=en%f(ib1,ik,1)
         !
         i_wf1=WF%index(ib1,ik,i_sp_pol)
         do i_spinor=1,n_spinor         
           rho_no_sym(:)=rho_no_sym(:)+real(f_occ*Xk%weights(ik)*abs(WF%c(:,i_spinor,i_wf1))**2)
         enddo
         !
       enddo
     enddo
   enddo
   !
 endif
 !
 do i_sp_pol=1,n_sp_pol
   do ik=1,Xk%nibz
     !
#if !defined _YPP_RT
     if (.not.PAR_IND_WF_k%element_1D(ik)) cycle
#endif
     !      
     do ib1=RT_bands(1),RT_bands(2)
       !
#if defined _YPP_RT
       if (.not.PAR_IND_WF_linear%element_2D(ib1,ik)) cycle
#endif
       !
       do ib2=ib1,RT_bands(2)
         !
         !
#if !defined _YPP_RT
         if (.not.PAR_IND_B_mat_ordered%element_1D(  UP_matrix_index(ib1-RT_bands(1)+1,ib2-RT_bands(1)+1)-1 )) cycle
#endif
         !
         f_occ=cZERO
         do ik_RT=RT_ibz_coo(ik,1),RT_ibz_coo(ik,2)
           if (ib1==ib2) f_occ=f_occ-cI*G_lesser(ib1,ib2,ik_RT,i_sp_pol)
           if (ib1/=ib2) f_occ=f_occ-cI*G_lesser(ib1,ib2,ik_RT,i_sp_pol)*2._SP
         enddo
         f_occ=f_occ/real(RT_Nk_ibz(ik),SP)
         !
         i_wf1=WF%index(ib1,ik,i_sp_pol)
         i_wf2=WF%index(ib2,ik,i_sp_pol)
         do i_spinor=1,n_spinor
           rho_no_sym(:)=rho_no_sym(:)+Xk%weights(ik)*real(f_occ*WF%c(:,i_spinor,i_wf1)*conjg(WF%c(:,i_spinor,i_wf2)),SP)
         enddo
         !
       enddo
     enddo
     !
   enddo
 enddo
 !
 call PP_redux_wait(rho_no_sym)
 !
 ! Symmetrization
 !
 rho_syms=nsym/(i_time_rev+1)
 !
 do ir=1,rho_syms
   rho(:)=rho(:)+rho_no_sym(fft_rot_r(:,ir))/real(nsym,SP)
 enddo
 !
 rho(:)=real(1+i_time_rev,SP)*rho(:)
 !
end subroutine
