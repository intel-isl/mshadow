set(mshadow_LINKER_LIBS "")

set(BLAS "Open" CACHE STRING "Selected BLAS library")
set_property(CACHE BLAS PROPERTY STRINGS "Atlas;Blas;Open;MKL")

if(DEFINED USE_BLAS)
  set(BLAS "${USE_BLAS}")
else()
  if(USE_MKL_IF_AVAILABLE)
    if(NOT MKL_FOUND)
      find_package(MKL)
    endif()
    if(MKL_FOUND)
      set(BLAS "MKL")
    endif()
  endif()
endif()

if(BLAS STREQUAL "Atlas" OR BLAS STREQUAL "atlas")
  find_package(Atlas REQUIRED)
  include_directories(SYSTEM ${Atlas_INCLUDE_DIR})
  list(APPEND mshadow_LINKER_LIBS ${Atlas_LIBRARIES})
  add_definitions(-DMSHADOW_USE_CBLAS=1)
  add_definitions(-DMSHADOW_USE_MKL=0)
elseif(BLAS STREQUAL "Blas" OR BLAS STREQUAL "blas")
  find_package(BLAS REQUIRED)
  include_directories(SYSTEM ${BLAS_INCLUDE_DIR})
  list(APPEND mshadow_LINKER_LIBS ${BLAS_LIB})
  add_definitions(-DMSHADOW_USE_CBLAS=1)
  add_definitions(-DMSHADOW_USE_MKL=0)
elseif(BLAS STREQUAL "Open" OR BLAS STREQUAL "open")
  find_package(OpenBLAS REQUIRED)
  include_directories(SYSTEM ${OpenBLAS_INCLUDE_DIR})
  list(APPEND mshadow_LINKER_LIBS ${OpenBLAS_LIB})
  add_definitions(-DMSHADOW_USE_CBLAS=1)
  add_definitions(-DMSHADOW_USE_MKL=0)
elseif(BLAS STREQUAL "MKL" OR BLAS STREQUAL "mkl")
  find_package(MKL REQUIRED)
  include_directories(SYSTEM ${MKL_INCLUDE_DIR})
  list(APPEND mshadow_LINKER_LIBS ${MKL_LIBRARIES})
  add_definitions(-DMSHADOW_USE_CBLAS=0)
  add_definitions(-DMSHADOW_USE_MKL=1)
elseif(BLAS STREQUAL "apple")
  find_package(Accelerate REQUIRED)
  include_directories(SYSTEM ${Accelerate_INCLUDE_DIR})
  list(APPEND mshadow_LINKER_LIBS ${Accelerate_LIBRARIES})
  add_definitions(-DMSHADOW_USE_MKL=0)
  add_definitions(-DMSHADOW_USE_CBLAS=1)
endif()

if(SUPPORT_MSSE2)
	add_definitions(-DMSHADOW_USE_SSE=1)
else()
	add_definitions(-DMSHADOW_USE_SSE=0)
endif()

if(NOT DEFINED SUPPORT_F16C AND NOT MSVC)
    check_cxx_compiler_flag("-mf16c"     COMPILER_SUPPORT_MF16C)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        execute_process(COMMAND cat /proc/cpuinfo
                COMMAND grep flags
                COMMAND grep f16c
                OUTPUT_VARIABLE CPU_SUPPORT_F16C)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        execute_process(COMMAND sysctl -a
                COMMAND grep machdep.cpu.features
                COMMAND grep F16C
                OUTPUT_VARIABLE CPU_SUPPORT_F16C)
    endif()
    if(NOT CPU_SUPPORT_F16C)
        message("CPU does not support F16C instructions")
    endif()
    if(CPU_SUPPORT_F16C AND COMPILER_SUPPORT_MF16C)
        set(SUPPORT_F16C TRUE)
    endif()
endif()

if(SUPPORT_F16C)
    set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -mf16c")
else()
    add_definitions(-DMSHADOW_USE_F16C=0)
endif()

if(USE_CUDA)
	find_package(CUDA 5.5 QUIET)
	find_cuda_helper_libs(curand)
	if(NOT CUDA_FOUND)
		message(FATAL_ERROR "-- CUDA is disabled.")
	endif()
	add_definitions(-DMSHADOW_USE_CUDA=1)
	add_definitions(-DMSHADOW_FORCE_STREAM)
	include_directories(SYSTEM ${CUDA_INCLUDE_DIRS})
    list(APPEND mshadow_LINKER_LIBS
        ${CUDA_CUDART_LIBRARY}
        ${CUDA_curand_LIBRARY}
        ${CUDA_CUBLAS_LIBRARIES}
        ${CUDA_cusolver_LIBRARY}
    )
else()
  add_definitions(-DMSHADOW_USE_CUDA=0)
endif()
