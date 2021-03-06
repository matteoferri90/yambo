!
!        Copyright (C) 2000-2017 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): DS,AM
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
subroutine YPP_SET_defaults()
 !
 use YPP
 use units,          ONLY:FS2AUT
 use D_lattice,      ONLY:alat
 use interpolate,    ONLY:lpfac,interpls,max_interpls
 use electrons,      ONLY:n_bands
#if defined _YPP_RT
 use YPP_real_time
 use fields,         ONLY:n_ext_fields
#endif
#if defined _YPP_ELPH
 use YPP_ELPH
 use ELPH,           ONLY:gsqF_energy_steps
#endif
 !
 implicit none
 !
 ! DOS
 !
 l_dos=.false.
 dos_broadening=0.1_SP/HA2EV
 dos_bands=(/1,n_bands/)
 dos_E_range=(/1._SP,-1._SP/)/HA2EV
 dos_E_steps=500
 WF_ref=0
 !
 ! RT OCCUPATIONS
 !
#if defined _YPP_RT
 !
 l_RealTime=.FALSE.
 l_RT_DBs  =.FALSE.
 !
 ! Absorption, occupations, lifetimes, density
 !
 l_RT_X           =.FALSE.
 l_RT_abs         =.FALSE.
 l_RT_occupations =.FALSE.
 l_RT_lifetimes   =.FALSE.
 l_RT_density     =.FALSE.
 !
 ! PP kind
 !
 l_RT_time  =.FALSE.
 l_RT_energy=.FALSE.
 l_RT_2D_dos=.FALSE.
 l_RT_bands =.FALSE.
 !
#endif
 !
 ! BANDS
 !
 BANDS_steps=0
 l_bands=.false.
 lpfac=20._SP
 interp_grid = (/-1, -1, -1/)
#if defined _YPP_RT
 Nel_fac=1._SP
#endif
 !
 ! Interpolation
 !
 interpls(1:max_interpls)%ndim=0
 !
 ! PLOT
 !
 p_dir      ='1'
 mag_dir    ='X'
 p_format   ='g'
 l_exc_wf   =.false.
 l_density  =.false.
 l_current  =.false.
 V_value    ='RE'
 l_mag=.false.
 l_sp_wf=.false.
 l_norm_to_one=.true.
 output_fname=' '
 plot_title=' '
 !
 ! EXC WF
 !
 l_spin=.false.
 l_sort=.false.
 l_amplitude=.false.
 ncell = (/1, 1, 1/) 
 r_hole= (/0._SP,0._SP,0._SP/)
 state_ctl = '1 - 1'
 deg_energy =0.01_SP/HA2EV
 min_weight =0.01_SP
 WF_multiplier=1._SP
 !
#if defined _YPP_ELPH
 !
 ! ELPH
 !
 l_phonons=.false.
 l_gkkp=.false.
 l_eliashberg=.false.
 l_atomic_amplitude=.false.
 elph_steps=200
 ph_broad=0.01_SP/HA2EV
 elph_gamma_broad=0._SP
 elph_Ef=0._SP
 elph_dbs_path='.'
 ph_freqs_file='none'
 ph_modes_file='none'
 gsqF_energy_steps=1
 !
#endif
 !
 ! Wannier interface
 !
 l_wannier=.FALSE.
 seed_name=" "
 what_to_write=" "
 !
 ! BZ grids
 !
 coo_in="rlu"
 coo_out="rlu"
 PtsPath= ' '
 N_path_pts=0
 alat_used_for_output=alat(1)
 !
 ! BZ RIM
 !
 gamma_radius=0._SP
 !
 ! WFs perturbative SOC
 !
 perturbative_SOC_path=""
 SOC_bands_to_map=(/ 1, n_bands /)
 SOC_bands_buffer=1
 SOC_split=0.1_SP/HA2EV
 !
 ! BXSF interpolation
 !
 w90_fname="./w90.bxsf"
 wannier_bands=(/1,n_bands/)
 ord_dgrid_ipol = 0
 !
 !
end subroutine YPP_SET_defaults
