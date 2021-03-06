#!/usr/bin/env bats


setup() {
    export SLS_DEBUG=t
    if ! [ -z "$CI" ]; then
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
    fi
    export USR_CACHE_DIR=`node -e 'console.log(require("./lib/shared").getUserCachePath())'`
    if [ -d "${USR_CACHE_DIR}" ] ; then
      rm -Rf "${USR_CACHE_DIR}"
    fi
}

teardown() {
    rm -rf puck puck2 puck3 node_modules .serverless .requirements.zip .requirements-cache \
        foobar package-lock.json serverless-python-requirements-*.tgz
    if [ -f serverless.yml.bak ]; then mv serverless.yml.bak serverless.yml; fi
    if [ -d "${USR_CACHE_DIR}" ] ; then
        rm -Rf "${USR_CACHE_DIR}"
    fi
}

@test "py3.6 supports custom file name with fileName option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    fileName: puck/' serverless.yml
    echo "requests" > puck
    sls package
    ls .serverless/requirements/requests
    ! ls .serverless/requirements/flask
}

@test "py3.6 can package flask with default options" {
    cd tests/base
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
}

@test "py3.6 can package flask with zip option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
    ! ls puck/flask
}

@test "py3.6 can package flask with slim options" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --slim=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}

@test "py3.6 can package flask with slim & slimPatterns options" {
    cd tests/base
    mv _slimPatterns.yml slimPatterns.yml
    npm i $(npm pack ../..)
    sls --slim=true package
    mv slimPatterns.yml _slimPatterns.yml    
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
    test $(find puck -type d -name "*.egg-info*" | wc -l) -eq 0  
}

@test "py3.6 doesn't package boto3 by default" {
    cd tests/base
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/boto3
}

@test "py3.6 doesn't package bottle with noDeploy option" {
    cd tests/base
    npm i $(npm pack ../..)
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    noDeploy: [bottle]/' serverless.yml
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/bottle.py
    ! ls puck/__pycache__/bottle.cpython-36.pyc
}

@test "py3.6 can package flask with zip & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py3.6 can package flask with zip & slim & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --zip=true --slim=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py3.6 can package flask with dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
}

@test "py3.6 uses download cache with useDownloadCache option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true/' serverless.yml
    sls package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls $USR_CACHE_DIR/downloadCacheslspyc/http
}

@test "py3.6 uses download cache with cacheLocation option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true\n    cacheLocation: .requirements-cache/' serverless.yml
    sls package
    ls .requirements-cache/downloadCacheslspyc/http
}

@test "py3.6 uses download cache with dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true/' serverless.yml
    sls --dockerizePip=true package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls $USR_CACHE_DIR/downloadCacheslspyc/http
}

@test "py3.6 uses download cache with dockerizePip + cacheLocation option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true\n    cacheLocation: .requirements-cache/' serverless.yml
    sls --dockerizePip=true package
    ls .requirements-cache/downloadCacheslspyc/http
}

@test "py3.6 uses static and download cache" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true\n    useStaticCache: true/' serverless.yml
    sls package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls $USR_CACHE_DIR/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/flask
    ls $USR_CACHE_DIR/downloadCacheslspyc/http
}

@test "py3.6 can package flask with slim & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --slim=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}

@test "py3.6 can package flask with slim & dockerizePip & slimPatterns options" {
    cd tests/base
    mv _slimPatterns.yml slimPatterns.yml
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --slim=true package
    mv slimPatterns.yml _slimPatterns.yml    
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
    test $(find puck -type d -name "*.egg-info*" | wc -l) -eq 0  
}

@test "py3.6 uses cache with dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useDownloadCache: true\n    useStaticCache: true/' serverless.yml
    sls --dockerizePip=true package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls $USR_CACHE_DIR/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/flask
    ls $USR_CACHE_DIR/downloadCacheslspyc/http
}

@test "py3.6 uses static cache" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useStaticCache: true/' serverless.yml
    sls package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls $USR_CACHE_DIR/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/flask
    ls $USR_CACHE_DIR/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/.completed_requirements
}

@test "py3.6 uses static cache with cacheLocation option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useStaticCache: true\n    cacheLocation: .requirements-cache/' serverless.yml
    sls package
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    ls .requirements-cache/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/flask
    ls .requirements-cache/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/.completed_requirements
}

@test "py3.6 checking that static cache actually pulls from cache (by poisoning it)" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    useStaticCache: true/' serverless.yml
    sls package
    cp .serverless/sls-py-req-test.zip ./puck
    USR_CACHE_DIR=`node -e 'console.log(require("../../lib/shared").getUserCachePath())'`
    echo "injected new file into static cache folder" > $USR_CACHE_DIR/b8b9d2be59f6f2ea5778e8b2aa4d2ddc_slspyc/injected_file_is_bad_form
    sls package
    [ `wc -c ./.serverless/sls-py-req-test.zip | awk '{ print $1 }'` -gt `wc -c ./puck | awk '{ print $1 }'` ]
}

@test "py3.6 uses cache with dockerizePip & slim option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    pipCmdExtraArgs: ["--cache-dir", ".requirements-cache"]/' serverless.yml
    sls --dockerizePip=true --slim=true package
    ls .requirements-cache/http
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}


@test "py2.7 can package flask with default options" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --runtime=python2.7 package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
}

@test "py2.7 can package flask with slim option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --runtime=python2.7 --slim=true package 
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}

@test "py2.7 can package flask with zip option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --runtime=python2.7 --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py2.7 can package flask with slim & dockerizePip & slimPatterns options" {
    cd tests/base
    mv _slimPatterns.yml slimPatterns.yml
    npm i $(npm pack ../..)
    sls --runtime=python2.7 --slim=true packag
    mv slimPatterns.yml _slimPatterns.yml    
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
    test $(find puck -type d -name "*.egg-info*" | wc -l) -eq 0  
}

@test "py2.7 doesn't package boto3 by default" {
    cd tests/base
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/boto3
}

@test "py2.7 doesn't package bottle with noDeploy option" {
    cd tests/base
    npm i $(npm pack ../..)
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    noDeploy: [bottle]/' serverless.yml
    sls --runtime=python2.7 package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/bottle.py
}

@test "py2.7 can package flask with zip & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --runtime=python2.7 --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py2.7 can package flask with zip & slim & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --runtime=python2.7 --zip=true --slim=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py2.7 can package flask with dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --runtime=python2.7 package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
}

@test "py2.7 can package flask with slim & dockerizePip option" {
    cd tests/base
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --slim=true --runtime=python2.7 package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}

@test "py2.7 can package flask with slim & dockerizePip & slimPatterns options" {
    cd tests/base
    mv _slimPatterns.yml slimPatterns.yml
    npm i $(npm pack ../..)
    ! uname -sm|grep Linux || groups|grep docker || id -u|egrep '^0$' || skip "can't dockerize on linux if not root & not in docker group"
    sls --dockerizePip=true --slim=true --runtime=python2.7 package
    mv slimPatterns.yml _slimPatterns.yml    
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
    test $(find puck -type d -name "*.egg-info*" | wc -l) -eq 0  
}

@test "pipenv py3.6 can package flask with default options" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
}

@test "pipenv py3.6 can package flask with slim option" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    sls --slim=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
}

@test "pipenv py3.6 can package flask with slim & slimPatterns option" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    mv _slimPatterns.yml slimPatterns.yml
    sls --slim=true package
    mv slimPatterns.yml _slimPatterns.yml    
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    test $(find puck -name "*.pyc" | wc -l) -eq 0
    test $(find puck -type d -name "*.egg-info*" | wc -l) -eq 0  
}

@test "pipenv py3.6 can package flask with zip option" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    sls --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "pipenv py3.6 doesn't package boto3 by default" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/boto3
}

@test "pipenv py3.6 doesn't package bottle with noDeploy option" {
    cd tests/pipenv
    npm i $(npm pack ../..)
    perl -p -i'.bak' -e 's/(pythonRequirements:$)/\1\n    noDeploy: [bottle]/' serverless.yml
    sls package
    unzip .serverless/sls-py-req-test.zip -d puck
    ! ls puck/bottle.py
}

@test "py3.6 can package flask with zip option and no explicit include" {
    cd tests/base
    npm i $(npm pack ../..)
    sed -i'.bak' -e 's/include://' -e 's/^.*handler.py//' serverless.yml
    sls --zip=true package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/.requirements.zip puck/unzip_requirements.py
}

@test "py3.6 can package flask with package individually option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --individually=true package
    unzip .serverless/hello.zip -d puck
    unzip .serverless/hello2.zip -d puck2
    unzip .serverless/hello3.zip -d puck3
    ls puck/flask
    ls puck2/flask
    ! ls puck3/flask
}

@test "py3.6 can package flask with package individually & slim option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --individually=true --slim=true package
    unzip .serverless/hello.zip -d puck
    unzip .serverless/hello2.zip -d puck2
    unzip .serverless/hello3.zip -d puck3
    ls puck/flask
    ls puck2/flask
    ! ls puck3/flask
    test $(find "puck*" -name "*.pyc" | wc -l) -eq 0
}


@test "py2.7 can package flask with package individually option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --individually=true --runtime=python2.7 package
    unzip .serverless/hello.zip -d puck
    unzip .serverless/hello2.zip -d puck2
    unzip .serverless/hello3.zip -d puck3
    ls puck/flask
    ls puck2/flask
    ! ls puck3/flask
}

@test "py2.7 can package flask with package individually & slim option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --individually=true --slim=true --runtime=python2.7 package
    unzip .serverless/hello.zip -d puck
    unzip .serverless/hello2.zip -d puck2
    unzip .serverless/hello3.zip -d puck3
    ls puck/flask
    ls puck2/flask
    ! ls puck3/flask
    test $(find puck* -name "*.pyc" | wc -l) -eq 0
}


@test "py3.6 can package only requirements of module" {
    cd tests/individually
    npm i $(npm pack ../..)
    sls package
    unzip .serverless/module1-sls-py-req-test-indiv-dev-hello1.zip -d puck
    unzip .serverless/module2-sls-py-req-test-indiv-dev-hello2.zip -d puck2
    ls puck/handler1.py
    ls puck2/handler2.py
    ls puck/pyaml
    ls puck2/flask
    ! ls puck/handler2.py
    ! ls puck2/handler1.py
    ! ls puck/flask
    ! ls puck2/pyaml
}

@test "py3.6 can package lambda-decorators using vendor option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --vendor=./vendor package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    ls puck/lambda_decorators.py
}

@test "py3.6 can package lambda-decorators using vendor and invidiually option" {
    cd tests/base
    npm i $(npm pack ../..)
    sls --individually=true --vendor=./vendor package
    unzip .serverless/hello.zip -d puck
    unzip .serverless/hello2.zip -d puck2
    unzip .serverless/hello3.zip -d puck3
    ls puck/flask
    ls puck2/flask
    ! ls puck3/flask
    ls puck/lambda_decorators.py
    ls puck2/lambda_decorators.py
    ! ls puck3/lambda_decorators.py
}

@test "Don't nuke execute perms" {
    cd tests/base
    npm i $(npm pack ../..)
    touch foobar
    chmod +x foobar
    perl -p -i'.bak' -e 's/(handler.py$)/\1\n    - foobar/' serverless.yml
    sls --vendor=./vendor package
    unzip .serverless/sls-py-req-test.zip -d puck
    ls puck/flask
    ls puck/lambda_decorators.py
    ./puck/foobar
}
