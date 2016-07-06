#!/bin/bash

declare -r color_start="\033["
declare -r color_red="${color_start}0;31m"
declare -r color_green="${color_start}0;32m"
declare -r color_blue="${color_start}0;34m"
declare -r color_norm="${color_start}0m"

GRADER_ROOT=$(dirname ${BASH_SOURCE})

PROJECT_PATH=${GRADER_ROOT}/..

function print_dir_contents {
  local proj_path=$1
  echo "Project contents:"
  echo -e "${color_blue}$(ls ${proj_path})${color_norm}"
}

function find_file_or_dir_in_project {
  local proj_path=$1
  local file_or_dir_name=$2
  if [[ ! -e "${proj_path}/${file_or_dir_name}" ]]; then
    echo -e "[${color_red}FAIL${color_norm}]: no ${file_or_dir_name} found"
    print_dir_contents ${proj_path}
    echo -e "${color_red}${file_or_dir_name} [MISSING]${color_norm}"
    exit 1
  fi
}

# check project directory structure
function check_project_struct {
  find_file_or_dir_in_project ${PROJECT_PATH} run.sh
  find_file_or_dir_in_project ${PROJECT_PATH} src
  find_file_or_dir_in_project ${PROJECT_PATH} venmo_input
  find_file_or_dir_in_project ${PROJECT_PATH} venmo_output
}

# setup testing output folder
function setup_testing_input_output {
  TEST_OUTPUT_PATH=${GRADER_ROOT}/temp
  if [ -d ${TEST_OUTPUT_PATH} ]; then
    rm -rf ${TEST_OUTPUT_PATH}
  fi

  mkdir -p ${TEST_OUTPUT_PATH}

  cp -r ${PROJECT_PATH}/src ${TEST_OUTPUT_PATH}
  cp -r ${PROJECT_PATH}/run.sh ${TEST_OUTPUT_PATH}
  cp -r ${PROJECT_PATH}/venmo_input ${TEST_OUTPUT_PATH}
  cp -r ${PROJECT_PATH}/venmo_output ${TEST_OUTPUT_PATH}

  rm -r ${TEST_OUTPUT_PATH}/venmo_input/*
  rm -r ${TEST_OUTPUT_PATH}/venmo_output/*
  cp -r ${GRADER_ROOT}/tests/${test_folder}/venmo_input/venmo-trans.txt ${TEST_OUTPUT_PATH}/venmo_input/venmo-trans.txt
}

function compare_outputs {
  PROJECT_ANSWER_PATH=${GRADER_ROOT}/temp/venmo_output/output.txt
  TEST_ANSWER_PATH=${GRADER_ROOT}/tests/${test_folder}/venmo_output/output.txt

  DIFF_RESULT=$(diff -bB ${PROJECT_ANSWER_PATH} ${TEST_ANSWER_PATH} | wc -l)
  if [ "${DIFF_RESULT}" -eq "0" ] && [ -f ${PROJECT_ANSWER_PATH} ]; then
    echo -e "[${color_green}PASS${color_norm}]: ${test_folder}"
    PASS_CNT=$(($PASS_CNT+1))
  else
    echo -e "[${color_red}FAIL${color_norm}]: ${test_folder}"
    diff ${PROJECT_ANSWER_PATH} ${TEST_ANSWER_PATH}
  fi
}

function run_all_tests {
  TEST_FOLDERS=$(ls ${GRADER_ROOT}/tests)
  NUM_TESTS=$(echo $(echo ${TEST_FOLDERS} | wc -w))
  PASS_CNT=0

  # Loop through all tests
  for test_folder in ${TEST_FOLDERS}; do

    setup_testing_input_output

    cd ${GRADER_ROOT}/temp
    bash run.sh 2>&1
    cd ../

    compare_outputs
  done

  echo "[$(date)] ${PASS_CNT} of ${NUM_TESTS} tests passed" >> ${GRADER_ROOT}/results.txt
}

check_project_struct
run_all_tests

