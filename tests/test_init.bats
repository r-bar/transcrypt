#!/usr/bin/env bats

load $BATS_TEST_DIRNAME/_test_helper.bash

function init_transcrypt {
  $BATS_TEST_DIRNAME/../transcrypt --cipher=aes-256-cbc --password=abc123 --yes
}

function setup {
  pushd $BATS_TEST_DIRNAME
  init_git_repo
}

function teardown {
  cleanup_all
  popd
}

@test "init works" {
  # Use literal command not function to confirm command works at least once
  run ../transcrypt --cipher=aes-256-cbc --password=abc123 --yes
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "The repository has been successfully configured by transcrypt." ]
}

@test "init creates .gitattributes" {
  init_transcrypt
  [ -f .gitattributes ]
  run cat .gitattributes
  [ "${lines[0]}" = "#pattern  filter=crypt diff=crypt merge=crypt" ]
}

@test "init creates scripts in .git/crypt/" {
  init_transcrypt
  [ -d .git/crypt ]
  [ -f .git/crypt/clean ]
  [ -f .git/crypt/smudge ]
  [ -f .git/crypt/textconv ]
}

@test "init applies git config" {
  init_transcrypt
  VERSION=`../transcrypt -v | awk '{print $2}'`
  GIT_DIR=`git rev-parse --git-dir`

  [ `git config --get transcrypt.version` = $VERSION ]
  [ `git config --get transcrypt.cipher` = "aes-256-cbc" ]
  [ `git config --get transcrypt.password` = "abc123" ]

  [[ `git config --get filter.crypt.clean` = '"$(git rev-parse --git-common-dir)"/crypt/clean %f' ]]
  [[ `git config --get filter.crypt.smudge` = '"$(git rev-parse --git-common-dir)"/crypt/smudge' ]]
  [[ `git config --get filter.crypt.textconv` = '"$(git rev-parse --git-common-dir)"/crypt/textconv' ]]

  [ `git config --get filter.crypt.required` = "true" ]
  [ `git config --get diff.crypt.cachetextconv` = "true" ]
  [ `git config --get diff.crypt.binary` = "true" ]
  [ `git config --get merge.renormalize` = "true" ]

  [[ `git config --get alias.ls-crypt` = "!git ls-files"* ]]
}