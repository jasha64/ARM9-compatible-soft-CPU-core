#!/bin/bash -f
# Vivado (TM) v2015.4 (64-bit)
#
# Filename    : pll.sh
# Simulator   : Synopsys Verilog Compiler Simulator
# Description : Simulation script for compiling, elaborating and verifying the project source files.
#               The script will automatically create the design libraries sub-directories in the run
#               directory, add the library logical mappings in the simulator setup file, create default
#               'do/prj' file, execute compilation, elaboration and simulation steps.
#
# Generated by Vivado on Tue Sep 17 23:58:18 +0800 2019
# IP Build 1412160 on Tue Nov 17 13:47:24 MST 2015 
#
# usage: pll.sh [-help]
# usage: pll.sh [-lib_map_path]
# usage: pll.sh [-noclean_files]
# usage: pll.sh [-reset_run]
#
# Prerequisite:- To compile and run simulation, you must compile the Xilinx simulation libraries using the
# 'compile_simlib' TCL command. For more information about this command, run 'compile_simlib -help' in the
# Vivado Tcl Shell. Once the libraries have been compiled successfully, specify the -lib_map_path switch
# that points to these libraries and rerun export_simulation. For more information about this switch please
# type 'export_simulation -help' in the Tcl shell.
#
# You can also point to the simulation libraries by either replacing the <SPECIFY_COMPILED_LIB_PATH> in this
# script with the compiled library directory path or specify this path with the '-lib_map_path' switch when
# executing this script. Please type 'pll.sh -help' for more information.
#
# Additional references - 'Xilinx Vivado Design Suite User Guide:Logic simulation (UG900)'
#
# ********************************************************************************************************

# Script info
echo -e "pll.sh - Script generated by export_simulation (Vivado v2015.4 (64-bit)-id)\n"

# Script usage
usage()
{
  msg="Usage: pll.sh [-help]\n\
Usage: pll.sh [-lib_map_path]\n\
Usage: pll.sh [-reset_run]\n\
Usage: pll.sh [-noclean_files]\n\n\
[-help] -- Print help information for this script\n\n\
[-lib_map_path <path>] -- Compiled simulation library directory path. The simulation library is compiled\n\
using the compile_simlib tcl command. Please see 'compile_simlib -help' for more information.\n\n\
[-reset_run] -- Recreate simulator setup files and library mappings for a clean run. The generated files\n\
from the previous run will be removed. If you don't want to remove the simulator generated files, use the\n\
-noclean_files switch.\n\n\
[-noclean_files] -- Reset previous run, but do not remove simulator generated files from the previous run.\n\n"
  echo -e $msg
  exit 1
}

if [[ ($# == 1 ) && ($1 != "-lib_map_path" && $1 != "-noclean_files" && $1 != "-reset_run" && $1 != "-help" && $1 != "-h") ]]; then
  echo -e "ERROR: Unknown option specified '$1' (type \"./pll.sh -help\" for more information)\n"
  exit 1
fi

if [[ ($1 == "-help" || $1 == "-h") ]]; then
  usage
fi

# STEP: setup
setup()
{
  case $1 in
    "-lib_map_path" )
      if [[ ($2 == "") ]]; then
        echo -e "ERROR: Simulation library directory path not specified (type \"./pll.sh -help\" for more information)\n"
        exit 1
      fi
      # precompiled simulation library directory path
     create_lib_mappings $2
    ;;
    "-reset_run" )
      reset_run
      echo -e "INFO: Simulation run files deleted.\n"
      exit 0
    ;;
    "-noclean_files" )
      # do not remove previous data
    ;;
    * )
     create_lib_mappings $2
  esac

  # Add any setup/initialization commands here:-

  # <user specific commands>

}

# Remove generated data from the previous run and re-create setup files/library mappings
reset_run()
{
  files_to_remove=(ucli.key pll_simv vlogan.log vhdlan.log compile.log elaborate.log simulate.log .vlogansetup.env .vlogansetup.args .vcs_lib_lock scirocco_command.log 64 AN.DB csrc pll_simv.daidir)
  for (( i=0; i<${#files_to_remove[*]}; i++ )); do
    file="${files_to_remove[i]}"
    if [[ -e $file ]]; then
      rm -rf $file
    fi
  done
}

# Main steps
run()
{
  setup $1 $2
  compile
  elaborate
  simulate
}

# Create design library directory paths and define design library mappings in cds.lib
create_lib_mappings()
{
  libs=(xil_defaultlib)
  file="synopsys_sim.setup"
  dir="vcs"

  if [[ -e $file ]]; then
    rm -f $file
  fi

  if [[ -e $dir ]]; then
    rm -rf $dir
  fi

  touch $file
  lib_map_path="<SPECIFY_COMPILED_LIB_PATH>"
  if [[ ($1 != "" && -e $1) ]]; then
    lib_map_path="$1"
  else
    echo -e "ERROR: Compiled simulation library directory path not specified or does not exist (type "./top.sh -help" for more information)\n"
  fi
  incl_ref="OTHERS=$lib_map_path/synopsys_sim.setup"
  echo $incl_ref >> $file

  for (( i=0; i<${#libs[*]}; i++ )); do
    lib="${libs[i]}"
    lib_dir="$dir/$lib"
    if [[ ! -e $lib_dir ]]; then
      mkdir -p $lib_dir
      mapping="$lib : $dir/$lib"
      echo $mapping >> $file
    fi
  done
}


# RUN_STEP: <compile>
compile()
{
  # Directory path for design sources and include directories (if any) wrt this path
  ref_dir="."
  # Command line options
  opts_ver="-full64 -timescale=1ps/1ps"
  opts_vhd="-full64"

  # Compile design files
  vlogan -work xil_defaultlib $opts_ver +v2k \
    "$ref_dir/../../../../ARM9_HelloWorld.srcs/sources_1/ip/pll/pll_clk_wiz.v" \
    "$ref_dir/../../../../ARM9_HelloWorld.srcs/sources_1/ip/pll/pll.v" \
  2>&1 | tee -a vlogan.log


  vlogan -work xil_defaultlib $opts_ver +v2k \
    glbl.v \
  2>&1 | tee -a vlogan.log

}

# RUN_STEP: <elaborate>
elaborate()
{
  opts="-full64 -debug_pp -t ps -licqueue -l elaborate.log"

  vcs $opts xil_defaultlib.pll xil_defaultlib.glbl -o pll_simv
}

# RUN_STEP: <simulate>
simulate()
{
  opts="-ucli -licqueue -l simulate.log"

  ./pll_simv $opts -do simulate.do
}
# Script usage
usage()
{
  msg="Usage: pll.sh [-help]\n\
Usage: pll.sh [-lib_map_path]\n\
Usage: pll.sh [-reset_run]\n\
Usage: pll.sh [-noclean_files]\n\n\
[-help] -- Print help information for this script\n\n\
[-lib_map_path <path>] -- Compiled simulation library directory path. The simulation library is compiled\n\
using the compile_simlib tcl command. Please see 'compile_simlib -help' for more information.\n\n\
[-reset_run] -- Recreate simulator setup files and library mappings for a clean run. The generated files\n\
from the previous run will be removed. If you don't want to remove the simulator generated files, use the\n\
-noclean_files switch.\n\n\
[-noclean_files] -- Reset previous run, but do not remove simulator generated files from the previous run.\n\n"
  echo -e $msg
  exit 1
}


# Launch script
run $1 $2
