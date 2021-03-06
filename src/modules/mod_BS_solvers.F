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
module BS_solvers
 !
 use pars,           ONLY:SP,schlen,lchlen
 use BS,             ONLY:BS_T_grp,BS_nT_grps,BS_H_dim,BS_K_dim,BS_block,n_BS_blks,BS_blk
 use SLK_m,      ONLY:SLK_matrix
#include <memory.h>
 !
 ! Epsilon factor
 !==================
 real(SP) :: Co_factor
 !
 ! Haydock
 !========== 
 type Haydock_vector
   !
   complex(SP), allocatable :: fragment(:)
   !
 end type Haydock_vector
 !
 integer, allocatable :: Haydock_parallel_group_comm(:)
 !
 ! SCALAPACK shadow matrix
 !=========================
 type(SLK_matrix), SAVE:: K_slk
 !
 ! Solvers (General)
 !=========
 character(lchlen):: BSS_description(100)
 character(schlen):: BSS_mode
 complex(SP) :: BSS_Wd
 integer  :: BSS_n_descs
 integer  :: BSS_n_freqs
 real(SP) :: BSS_er(2)
 real(SP) :: BSS_dr(2)
 real(SP) :: BSS_damp_reference
 real(SP) :: BSS_q0(3)
 logical  :: BSS_uses_DbGd
 logical  :: BSS_Vnl_included
 logical  :: BSS_uses_GreenF
 logical  :: BSS_perturbative_width
 logical  :: BSS_eval_JDOS
 logical  :: BSS_add_antiresonant
 !
 logical  :: run_Haydock=.FALSE.
 logical  :: run_inversion=.FALSE.
 logical  :: run_Diago=.FALSE.
 !
 ! Solvers (Diago)
 !=========
 logical  :: BSS_write_eig_2_db
 !
 ! Solvers (Haydock)
 !=========
 logical  :: Haydock_terminator
 real(SP) :: Haydock_treshold
 real(SP) :: Haydock_v0_mod
 !
 ! Solvers (Inversion)
 !=========
 character(schlen)     :: BSS_inversion_mode
 logical               :: BSS_uses_partial_diago
 logical               :: K_diago_in_BS_mat
 type(SLK_matrix),SAVE :: K_inv_slk
 !
 type K_Inversion_data
   character(3)             :: what
   integer                  :: n_freqs = 0
   integer                  :: n_full_inv_freqs = 0
   real(SP)                 :: treshold 
   real(SP)                 :: PERT_FULL_ratio = 1. 
   integer    , allocatable :: err(:)
   integer    , allocatable :: iw_full(:)
   complex(SP), allocatable :: spectra(:,:)
 end type K_Inversion_data
 !
 type(K_Inversion_data), save :: K_INV_EPS
 type(K_Inversion_data), save :: K_INV_PL
 !
 ! Solvers (Temporary (LARGE) arrays to be used in solvers ONLY)
 !=========
 integer    , allocatable :: BSS_eh_table(:,:)
 real(SP)   , allocatable :: BSS_eh_E(:)
 real(SP)   , allocatable :: BSS_eh_f(:)
 real(SP)   , allocatable :: BSS_eh_W(:)
 real(SP)   , allocatable :: BSS_eh_E_SOC_corr(:,:)
 complex(SP), allocatable :: BS_diagonal(:)
 complex(SP), allocatable :: BS_mat(:,:)
 complex(SP), allocatable :: BSS_dipoles(:)
 complex(SP), allocatable :: BSS_eh_Z(:)
 !
 interface 
   !
   integer function variables_BS(ID,local_description,X)
     use pars,       ONLY:lchlen
     use X_m,        ONLY:X_t
     integer            ::ID
     character(lchlen)  ::local_description(100)
     type(X_t), optional::X
   end function
   !
   integer function io_BSS_diago(iq,ID,BS_H_dim,bsE,bsRl,BsRr,BsE_corr,bsR_kerr,bsR_pl)
     use pars,          ONLY:SP
     integer             :: iq,ID,BS_H_dim
     complex(SP)         :: bsE(BS_H_dim),bsRl(BS_H_dim),bsRr(BS_H_dim)
     real(SP),   pointer :: BsE_corr(:,:),bsR_pl(:,:)
     complex(SP),pointer :: bsR_kerr(:)
   end function
   !
   integer function io_BSS_Haydock(ID,it,BS_H_dim,reached_treshold,Af,Bf,Vnm1,Vn,Vnp1,Cf,Cf_kerr)
     use pars,          ONLY:SP
     integer             :: ID,it,BS_H_dim
     real(SP)            :: reached_treshold,Bf(it+1),Af(it)
     complex(SP)         :: Vnm1(BS_H_dim),Vn(BS_H_dim)
     complex(SP),optional:: Cf(it+1),Vnp1(BS_H_dim)
     complex(SP),optional:: Cf_kerr(it+1)
   end function
   !
 end interface
 !
 contains
   !
   subroutine BS_duplicate_K_structure(label,BLKs_in,BLKs_out)
     !
     use BS,        ONLY:n_BS_blks
     character(*)   :: label
     type(BS_block) :: BLKs_in(:),BLKs_out(:)
     integer        :: i_B
     !
     do i_B=1,n_BS_blks
       !
       YAMBO_ALLOC(BLKs_out(i_B)%mat,(BLKS_in(i_B)%size(1),BLKS_in(i_B)%size(2)))
       !
       BLKs_out(i_B)%ik         =BLKS_in(i_B)%ik
       BLKs_out(i_B)%ip         =BLKS_in(i_B)%ip
       BLKs_out(i_B)%iT_k       =BLKS_in(i_B)%iT_k
       BLKs_out(i_B)%iT_p       =BLKS_in(i_B)%iT_p
       BLKs_out(i_B)%size       =BLKS_in(i_B)%size
       BLKs_out(i_B)%mode       =BLKS_in(i_B)%mode
       BLKs_out(i_B)%coordinate =BLKS_in(i_B)%coordinate
       !
     enddo
     !
   end subroutine
   !
   subroutine BSS_alloc( )
     use pars,      ONLY:IP,cZERO,rZERO
     use electrons, ONLY:n_sp_pol
     use electrons, ONLY:E_SOC_nbands
     integer :: i_g
     logical :: W_is_allocated,Z_is_allocated
     YAMBO_ALLOC(BSS_dipoles,(BS_H_dim))
     BSS_dipoles = cZERO
     YAMBO_ALLOC(BSS_eh_table,(BS_K_dim,3+n_sp_pol-1))
     YAMBO_ALLOC(BSS_eh_E,(BS_K_dim))
     YAMBO_ALLOC(BSS_eh_f,(BS_K_dim))
     BSS_eh_table = 0
     BSS_eh_E     = rZERO
     BSS_eh_f     = rZERO
     W_is_allocated=.FALSE.
     Z_is_allocated=.FALSE.
     do i_g=1,BS_nT_grps
       if (.not.W_is_allocated) W_is_allocated=allocated(BS_T_grp(i_g)%W)
       if (.not.Z_is_allocated) Z_is_allocated=allocated(BS_T_grp(i_g)%Z)
     enddo
     if (W_is_allocated) then
       YAMBO_ALLOC(BSS_eh_W,(BS_K_dim))
       BSS_eh_W = rZERO
     endif
     if (Z_is_allocated) then
       YAMBO_ALLOC(BSS_eh_Z,(BS_K_dim))
       BSS_eh_Z = cZERO
     endif
     if (E_SOC_nbands/=0) then
       YAMBO_ALLOC(BSS_eh_E_SOC_corr,(2/n_sp_pol,BS_H_dim))
       BSS_eh_E_SOC_corr = rZERO
     endif
   end subroutine
   !
   subroutine BSS_free()
     YAMBO_FREE(BSS_eh_table)
     YAMBO_FREE(BSS_dipoles)
     YAMBO_FREE(BSS_eh_E)
     YAMBO_FREE(BSS_eh_W)
     YAMBO_FREE(BSS_eh_f)
     YAMBO_FREE(BSS_eh_Z)
     YAMBO_FREE(BSS_eh_E_SOC_corr)
   end subroutine
   !
   subroutine BS_HAYVEC_alloc(V)
     use parallel_m,    ONLY:PAR_IND_T_Haydock
     type(Haydock_vector) :: V(BS_nT_grps)
     ! ws:
     integer :: i_g
     !
     do i_g=1,BS_nT_grps
       if (.not.PAR_IND_T_Haydock%element_1D(i_g)) cycle
       YAMBO_ALLOC(V(i_g)%fragment,(BS_T_grp(i_g)%size))
     enddo
   end subroutine BS_HAYVEC_alloc
   !
   subroutine BS_HAYVEC_free(V)
     use stderr,     ONLY:intc 
     type(Haydock_vector) :: V(:)
     ! ws:
     integer :: i_g
     !
     do i_g=1,BS_nT_grps
       YAMBO_FREE(V(i_g)%fragment)
     end do
   end subroutine BS_HAYVEC_free
   !
end module BS_solvers
