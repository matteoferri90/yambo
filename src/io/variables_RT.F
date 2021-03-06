!
!        Copyright (C) 2000-2017 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): DS
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
integer function variables_RT(ID,local_description,what)
 !
 use pars,           ONLY:lchlen,SP
 use units,          ONLY:AUT2FS,AU2KWCMm2,HA2EV
 use drivers,        ONLY:l_elph_scatt,l_elel_scatt,l_elel_corr,l_elphoton_scatt
 use stderr,         ONLY:intc
 use RT_control,     ONLY:RT_description,n_RT_descriptions,TIME_STEP_CONF_description,&
&                         n_TIME_STEP_CONF_descriptions,JPC_RT_IO_t,GF_RT_IO_t,RT_IO_t
 use real_time,      ONLY:RT_nk,l_NE_with_fields,RT_step,RT_dyn_step, &
&                         Integrator_name,RT_bands,l_RT_lifetimes_extrapolation, &
&                         RAD_LifeTime,Phase_LifeTime,NE_initial_time_step_update,NE_time_step_update_jump,&
&                         l_RT_induced_field,G_MEM_steps,NE_tot_time,NE_time,NE_steps,&
&                         l_RT_CCA_Kernel,Gr_description,l_RT_impose_N_dN,NE_time_step_update_jump_SAVE, &
&                         l_RT_uses_E_DbGd,N_Gr_descs,RT_life_extrap_times_SAVE,&
&                         DbGd_EE_percent,l_RT_impose_E,l_Update_Time_Step,RT_DbGd_nk,&
&                         NE_step_update_treshold,RT_life_extrap_times,RT_MAX_step
#if defined _ELPH
 use ELPH,           ONLY:elph_branches
#endif
 !
 ! GPL_EXCLUDE_END
 !
 use X_m,            ONLY:global_gauge
 use fields,         ONLY:n_ext_fields,Efield
 use IO_m,           ONLY:io_elemental,io_status,ver_is_gt_or_eq
 !
 implicit none
 !
 integer            ::ID
 character(lchlen)  ::local_description(100)
 character(*)       ::what
 !
 integer               :: i1,i_desc
 logical               :: l_JPSM,l_G,l_carriers,l_NE_with_fields_disk,l_RT_diamagnetic
 real(SP)              :: RT_life_extrap_decay_time
 character(lchlen)     :: ch
 !
 l_RT_diamagnetic          = .false.
 RT_life_extrap_decay_time = 0._SP
 !
 l_JPSM        = what=="JPSM"
 l_G           = what=="G"
 l_carriers    = what=="carriers"
 !
 i_desc=0
 local_description=' '
 !
 ! RT_vars
 !
 call io_elemental(ID,VAR="RT_vars",VAR_SZ=3,MENU=0) 
 i_desc=i_desc+1
 call io_elemental(ID,I1=RT_bands,&
&     VAR=' [RT] Bands                      :',CHECK=.true.,OP=(/"==","=="/),&
&     DESCRIPTION=local_description(i_desc))
 i_desc=i_desc+1
 call io_elemental(ID,I0=RT_nk,&
&     VAR=' [RT] K-points                   :',CHECK=.true.,OP=(/"==","=="/),&
&     DESCRIPTION=local_description(i_desc))
 call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
 !
 !
 if(.not.any((/l_JPSM,l_G,l_carriers/))) call io_elemental(ID,VAR="",VAR_SZ=0,MENU=1)
 !
 if(any((/l_JPSM,l_G,l_carriers/))) then
   !
   ! RT_DYNAMICS
   !
   call io_elemental(ID,VAR="RT_DYNAMICS",VAR_SZ=14,MENU=0) 
   i_desc=i_desc+1
   call io_elemental(ID,&
&    VAR=" [RT] Time step     (initial)[fs]:",R0=RT_step,CHECK=.true.,OP=(/"=="/),UNIT=AUT2FS,&
&    DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,&
&    VAR=" [RT]                   (now)[fs]:",R0=RT_dyn_step,DB_R0=RT_dyn_step,WARN=.true.,OP=(/"=="/),UNIT=AUT2FS,&
&    DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,&
&    VAR=" [RT] NE time       (planned)[fs]:",R0=NE_tot_time,WARN=.true.,OP=(/"=="/),UNIT=AUT2FS,&
&    DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,&
&    VAR=" [RT]                  (done)[fs]:",R0=NE_time,WARN=.true.,OP=(/"=="/),UNIT=AUT2FS,&
&    DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   !
   !
   if (l_JPSM.or.l_carriers) call LOCAL_IO_variables(JPC_RT_IO_t)
   if (l_G)                  call LOCAL_IO_variables(GF_RT_IO_t)
   !
   i_desc=i_desc+1
   call io_elemental(ID,&
&    VAR=" [RT] NE steps         (done)[fs]:",I0=NE_steps,WARN=.true.,OP=(/"=="/),&
&    DESCRIPTION=local_description(i_desc))
   !
   call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   !
   !
   ! INTEGRATOR
   !   
   call io_elemental(ID,VAR="INTEGRATOR",CH0="",VAR_SZ=1,MENU=0) 
   i_desc=i_desc+1
   call io_elemental(ID,CH0=Integrator_name, &
&    VAR=' [RT] Integrator                 :',CHECK=.true.,OP=(/"=="/),&
&    DESCRIPTION=local_description(i_desc))
   call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   !
   ! RT_OTHERS
   !
   call io_elemental(ID,VAR="RT_OTHERS",VAR_SZ=6,MENU=0) 
   i_desc=i_desc+1
   call io_elemental(ID,R0=RAD_LifeTime,&
&    VAR=' [RT] Radiative life time    [fs]:', CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc),UNIT=AUT2FS)
   i_desc=i_desc+1
   call io_elemental(ID,R0=Phase_LifeTime,&
&    VAR=' [RT] Dephasing life time    [fs]:', CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc),UNIT=AUT2FS)
   i_desc=i_desc+1
   call io_elemental(ID,L0=l_NE_with_fields,DB_L0=l_NE_with_fields_disk,&
&    VAR=' [RT] External Field(s)          :', CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,I0=n_ext_fields,&
&    VAR=' [RT] Number of Fields           :', CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,L0=l_RT_diamagnetic,&
&    VAR=' [RT] Diamagnetic term           :',  CHECK=.false.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,L0=l_RT_induced_field,&
&    VAR=' [RT] Induced field              :',  CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   !
   ! Time-Steps configurations
   !===========================
   call io_elemental(ID,VAR="N_TIME_STEP_CONFS",VAR_SZ=1,MENU=0) 
   call io_elemental(ID,I0=n_TIME_STEP_CONF_descriptions)
   call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   do i1=1,n_TIME_STEP_CONF_descriptions
     call io_elemental(ID,VAR="TIME_STEP_CONF_"//trim(intc(i1)),CH0="",VAR_SZ=1,MENU=0)
     i_desc=i_desc+1
     call io_elemental(ID,CH0=TIME_STEP_CONF_description(i1),VAR='',DESCRIPTION=local_description(i_desc))
     call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   enddo
   !
   !
   ! Double Grid
   !======================
   call io_elemental(ID,VAR="Double_Grid_support",VAR_SZ=3,MENU=0) 
   i_desc=i_desc+1
   call io_elemental(ID,L0=l_RT_uses_E_DbGd,&
&    VAR=' [DbGd] Double Grid support      :',  CHECK=.true.,OP=(/"=="/),&
&    DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,I0=RT_DbGd_nk,&
&    VAR=' [DbGd] Number of k-points       :',  CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   i_desc=i_desc+1
   call io_elemental(ID,R0=DbGd_EE_percent,&
&    VAR=' [DbGd] Used for e-e        [o/o]:',  CHECK=.true.,OP=(/"=="/),&
&     DESCRIPTION=local_description(i_desc))
   call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
   !
   !
   ! FIELDS
   !======================
   if (l_NE_with_fields_disk) then
     !
     call io_elemental(ID,VAR="GAUGE_TYPE",CH0="",VAR_SZ=1,MENU=0)
     i_desc=i_desc+1
     call io_elemental(ID,CH0=global_gauge, &
&       VAR=' [FIELDs] Gauge Type             :',CHECK=.true.,OP=(/"=="/),&
&       DESCRIPTION=local_description(i_desc))
     call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
     !
     do i1=1,n_ext_fields
       call io_elemental(ID,VAR="FIELD_NAME"//trim(intc(i1)),CH0="",VAR_SZ=1,MENU=0)
       i_desc=i_desc+1
       call io_elemental(ID,CH0=Efield(i1)%ef_name, &
&        VAR=' [FIELDs] Type                   :',CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc))
       !
       call io_elemental(ID,VAR="FIELD_POL"//trim(intc(i1)),CH0="",VAR_SZ=1,MENU=0)
       i_desc=i_desc+1
       call io_elemental(ID,CH0=Efield(i1)%ef_pol, &
&        VAR=' [FIELDs] Polarization           :',CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc))
       call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
       !
       call io_elemental(ID,VAR="EXTERNAL_FIELD"//trim(intc(i1)),VAR_SZ=13,MENU=0)
       i_desc=i_desc+1
       call io_elemental(ID,R1=Efield(i1)%versor,WARN=.true., &
&        VAR=" [FIELDs] Versor                 :",OP=(/"==","==","=="/),&
&        DESCRIPTION=local_description(i_desc))
       i_desc=i_desc+1
       call io_elemental(ID,R1=Efield(i1)%versor_circ,WARN=.true., &
&        VAR=" [FIELDs] Versor_circ            :",OP=(/"==","==","=="/),&
&        DESCRIPTION=local_description(i_desc))
       i_desc=i_desc+1
       call io_elemental(ID,&
&        VAR=" [FIELDs] Intensity      [kWCMm2]:",R0=Efield(i1)%intensity,CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc),UNIT=AU2KWCMm2)
       i_desc=i_desc+1
       call io_elemental(ID,&
&        VAR=" [FIELDs] Damping            [fs]:",R0=Efield(i1)%width,CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc),UNIT=AUT2FS)
       i_desc=i_desc+1
       call io_elemental(ID,&
&        VAR=" [FIELDs] Frequency range    [eV]:",R1=Efield(i1)%frequency,CHECK=.true.,OP=(/"==","=="/),&
&        DESCRIPTION=local_description(i_desc),UNIT=HA2EV)
       i_desc=i_desc+1
       call io_elemental(ID,&
&        VAR=" [FIELDs] Frequency steps        :",I0=Efield(i1)%n_frequencies,CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc))
       i_desc=i_desc+1
       call io_elemental(ID,&
&        VAR=" [FIELDs] Frequency step     [eV]:",R0=Efield(i1)%W_step,CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc),UNIT=HA2EV)
       i_desc=i_desc+1
       call io_elemental(ID,R0=Efield(i1)%t_initial,&
&        VAR=' [FIELDs] Initial time       [fs]:',CHECK=.true.,OP=(/"=="/),&
&        DESCRIPTION=local_description(i_desc),UNIT=AUT2FS)
       !                       
       if (i1/=n_ext_fields) call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
       if (i1==n_ext_fields) call io_elemental(ID,VAR="",VAR_SZ=0,MENU=1)
     enddo
     !
   else
     call io_elemental(ID,VAR="",VAR_SZ=0,MENU=1)
   endif
 endif
 !
 variables_RT           =io_status(ID)
 n_RT_descriptions      =i_desc
 RT_description(:i_desc)=local_description(:i_desc)
 !
 contains
   !
   subroutine LOCAL_IO_variables(TYP)
     !
     type(RT_IO_t) :: TYP
     !
     i_desc=i_desc+1
     call io_elemental(ID,&
&      VAR=" [RT] I/O time               [fs]:",R0=TYP%INTERVAL_time_SAVE,CHECK=.true.,OP=(/"=="/),&
&      DESCRIPTION=local_description(i_desc),UNIT=AUT2FS)
     ! ... for RESTART purposes...
     call io_elemental(ID,R0=TYP%INTERVAL_time,  DB_r0=TYP%INTERVAL_time,CHECK=.FALSE.)
     call io_elemental(ID,I0=TYP%INTERVAL_steps, DB_I0=TYP%INTERVAL_steps,CHECK=.FALSE.)
     !
     call io_elemental(ID,I0=TYP%last_point,CHECK=.true.,OP=(/"=="/))
     !
   end subroutine
   !
end function
