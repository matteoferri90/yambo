!
!        Copyright (C) 2000-2017 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): CA, AF
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
module wrapper
 !
 ! To remember:
 !
 ! TRANSA = 'N' or 'n',  op( A ) = A.
 ! TRANSA = 'T' or 't',  op( A ) = A'.
 ! TRANSA = 'C' or 'c',  op( A ) = conjg( A' ).
 !
 use pars,   ONLY:SP
 !
 implicit none
 !
 interface M_by_M
   module procedure mm_cgemm,mm_c 
 end interface
 !
 interface M_by_V 
   module procedure mv_cgemv,mv_sgemv,mv_c,mv_r
 end interface
 !
 interface V_by_V_plus_V
   module procedure vv_saxpy,vv_caxpy,MM_caxpy
 end interface
 !
 public :: V_copy
 public :: Vstar_dot_V
 public :: V_dot_V
 public :: real_V_dot_V
 public :: M_by_V
 !
 contains
   !
   !===================
   ! interface M_by_M 
   !===================
   !
   subroutine mm_cgemm(TRANSA,TRANSB,M,N,K,ALPHA,A,LDA,B,LDB,BETA,C,LDC)
     !
     ! CGEMM  performs one of the matrix-matrix operations
     !
     !    C := alpha*op( A )*op( B ) + beta*C,
     !
     ! where  op( X ) is one of
     !
     !    op( X ) = X   or   op( X ) = X**T   or   op( X ) = X**H,
     !
     ! alpha and beta are scalars, and A, B and C are matrices, with op( A )
     ! an m by k matrix,  op( B )  a  k by n matrix and  C an m by n matrix.
     !
     complex(SP), intent(in)  :: ALPHA,BETA
     integer,     intent(in)  :: K,LDA,LDB,LDC,M,N
     character,   intent(in)  :: TRANSA,TRANSB
     complex(SP), intent(in)  :: A(LDA,*),B(LDB,*)
     complex(SP), intent(out) :: C(LDC,*)
#if defined _DOUBLE
     call ZGEMM(TRANSA,TRANSB,M,N,K,ALPHA,A,LDA,B,LDB,BETA,C,LDC)
#else
     call CGEMM(TRANSA,TRANSB,M,N,K,ALPHA,A,LDA,B,LDB,BETA,C,LDC)
#endif
   end subroutine mm_cgemm
   !
   subroutine mm_c(TRANSA,TRANSB,msize,A,B,C)
     integer,  intent(in)  :: msize
     complex(SP), intent(in)  :: A(msize,msize),B(msize,msize)
     complex(SP), intent(out) :: C(msize,msize)
     character,   intent(in)  :: TRANSA,TRANSB
#if defined _DOUBLE
     call ZGEMM(TRANSA,TRANSB,msize,msize,msize,(1._SP,0._SP),A,msize,B,msize,(0._SP,0._SP),C,msize)
#else
     call CGEMM(TRANSA,TRANSB,msize,msize,msize,(1._SP,0._SP),A,msize,B,msize,(0._SP,0._SP),C,msize)
#endif
   end subroutine mm_c
   !
   !===================
   ! interface M_by_V 
   !===================
   !
   subroutine mv_sgemv(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
     real(SP), intent(in) :: ALPHA,BETA
     integer,  intent(in) :: INCX,INCY,LDA,M,N
     character,intent(in) :: TRANS
     real(SP), intent(in) :: A(LDA,*),X(*)
     real(SP), intent(out):: Y(*)
#if defined _DOUBLE
     call DGEMV(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
#else
     call SGEMV(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
#endif
   end subroutine mv_sgemv
   !
   subroutine mv_cgemv(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
     complex(SP), intent(in) :: ALPHA,BETA
     integer,     intent(in) :: INCX,INCY,LDA,M,N
     character,   intent(in) :: TRANS
     complex(SP), intent(in) :: A(LDA,*),X(*)
     complex(SP), intent(out):: Y(*)
#if defined _DOUBLE
     call ZGEMV(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
#else
     call CGEMV(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
#endif
   end subroutine mv_cgemv
   !
   subroutine mv_c(TRANS,msize,A,X,Y)
     integer,     intent(in) :: msize
     complex(SP), intent(in) :: A(msize,*),X(*)
     complex(SP), intent(out):: Y(*)
     character,   intent(in) :: TRANS
#if defined _DOUBLE
     call ZGEMV(TRANS,msize,msize,(1._SP,0._SP),A,msize,X,1,(0._SP,0._SP),Y,1)
#else
     call CGEMV(TRANS,msize,msize,(1._SP,0._SP),A,msize,X,1,(0._SP,0._SP),Y,1)
#endif
   end subroutine mv_c
   !
   subroutine mv_r(TRANS,msize,A,X,Y)
     integer,  intent(in) :: msize
     real(SP), intent(in) :: A(msize,*),X(*)
     real(SP), intent(out):: Y(*)
     character,intent(in) :: TRANS
#if defined _DOUBLE
     call DGEMV(TRANS,msize,msize,1._SP,A,msize,X,1,0._SP,Y,1)
#else
     call SGEMV(TRANS,msize,msize,1._SP,A,msize,X,1,0._SP,Y,1)
#endif
   end subroutine mv_r
   !
   !=========================
   ! interface V_by_V_plus_V 
   !=========================
   !
   subroutine MM_caxpy(N, CA, CX,  CY )
     complex(SP), intent(in) :: CA
     integer,     intent(in) :: N
     complex(SP), intent(in) :: CX(N,N)
     complex(SP), intent(out):: CY(N,N)
#if defined _DOUBLE
     call ZAXPY(N**2,CA,CX,1,CY,1)
#else
     call CAXPY(N**2,CA,CX,1,CY,1)
#endif
   end subroutine MM_caxpy
   !
   subroutine vv_caxpy(N, CA, CX,  CY )
     complex(SP), intent(in) :: CA
     integer,     intent(in) :: N
     complex(SP), intent(in) :: CX(*)
     complex(SP), intent(out):: CY(*)
#if defined _DOUBLE
     call ZAXPY(N,CA,CX,1,CY,1)
#else
     call CAXPY(N,CA,CX,1,CY,1)
#endif
   end subroutine vv_caxpy
   !
   subroutine vv_saxpy(N, CA, CX, CY )
     real(SP),    intent(in) :: CA
     integer,     intent(in) :: N
     real(SP),    intent(in) :: CX(*)
     real(SP),    intent(out):: CY(*)
#if defined _DOUBLE
     call DAXPY(N,CA,CX,1,CY,1)
#else
     call SAXPY(N,CA,CX,1,CY,1)
#endif
   end subroutine vv_saxpy   
   !
   !======
   ! COPY 
   !======
   !
   subroutine V_copy(N,CX,CY)
     integer,    intent(in)  :: N
     complex(SP),intent(in)  :: CX(*)
     complex(SP),intent(out) :: CY(*)
#if defined _DOUBLE
     call zcopy(N,CX,1,CY,1)
#else
     call ccopy(N,CX,1,CY,1)
#endif
   end subroutine V_copy   
   !
   !==============
   ! DOT PRODUCTS
   !==============
   !
   complex(SP) function Vstar_dot_V(N,CX,CY)
     integer,    intent(in) :: N
     complex(SP),intent(in) :: CX(*),CY(*)
#if defined _DOUBLE
     complex(SP)::zdotc
     Vstar_dot_V=ZDOTC(N,CX,1,CY,1)
#else
     complex(SP)::cdotc
     Vstar_dot_V=CDOTC(N,CX,1,CY,1)
#endif
     !
   end function Vstar_dot_V   
   !
   real(SP) function real_V_dot_V(N,CX,CY)
     integer, intent(in) :: N
     real(SP),intent(in) :: CX(*),CY(*)
#if defined _DOUBLE
     real(SP)::ddot
     real_V_dot_V=DDOT(N,CX,1,CY,1)
#else
     real(SP)::sdot
     real_V_dot_V=SDOT(N,CX,1,CY,1)
#endif
   end function real_V_dot_V
   !
   complex(SP) function V_dot_V(N,CX,CY)
     integer,    intent(in) :: N
     complex(SP),intent(in) :: CX(*),CY(*)
#if defined _DOUBLE
     complex(SP)::zdotu
     V_dot_V=ZDOTU(N,CX,1,CY,1)
#else
     complex(SP)::cdotu
     V_dot_V=CDOTU(N,CX,1,CY,1)
#endif
     !
   end function V_dot_V
   !
end module
