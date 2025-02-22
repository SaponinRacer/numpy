set_travis_vars() {
    # Set env vars
    echo "TRAVIS_EVENT_TYPE is $TRAVIS_EVENT_TYPE"
    echo CIRRUS_TASK_NAME is "$CIRRUS_TASK_NAME"
    echo "TRAVIS_TAG is $TRAVIS_TAG"
    echo "CIRRUS_TAG is $CIRRUS_TAG"
    echo "CIRRUS_API_CREATED is $CIRRUS_API_CREATED"
    echo "CIRRUS_PR is $CIRRUS_PR"
    if [[ "$TRAVIS_EVENT_TYPE" == "push" && "$TRAVIS_TAG" == v* ]]; then
      IS_PUSH="true"
    elif [[ "$CIRRUS_PR" == "" && "$CIRRUS_TAG" == v* ]]; then
      IS_PUSH="true"
    else
      IS_PUSH="false"
    fi
    if [[ "$TRAVIS_EVENT_TYPE" == "cron"  || -v CIRRUS_CRON ]]; then
      IS_SCHEDULE_DISPATCH="true"
    elif [[ "$TRAVIS_EVENT_TYPE" == "api"  || "$CIRRUS_API_CREATED" == "true" ]]; then
      # Manual CI run, so upload
      IS_SCHEDULE_DISPATCH="true"
    else
      IS_SCHEDULE_DISPATCH="false"
    fi
}
set_upload_vars() {
    echo "IS_PUSH is $IS_PUSH"
    echo "IS_SCHEDULE_DISPATCH is $IS_SCHEDULE_DISPATCH"
    if [[ "$IS_PUSH" == "true" ]]; then
        echo push and tag event
        export ANACONDA_ORG="multibuild-wheels-staging"
        export TOKEN="$NUMPY_STAGING_UPLOAD_TOKEN"
        export ANACONDA_UPLOAD="true"
    elif [[ "$IS_SCHEDULE_DISPATCH" == "true" ]]; then
        echo scheduled or dispatched event
        export ANACONDA_ORG="scipy-wheels-nightly"
        export TOKEN="$NUMPY_NIGHTLY_UPLOAD_TOKEN"
        export ANACONDA_UPLOAD="true"
    else
        echo non-dispatch event
        export ANACONDA_UPLOAD="false"
    fi
}
upload_wheels() {
    echo ${PWD}
    if [[ ${ANACONDA_UPLOAD} == true ]]; then
        if [ -z ${TOKEN} ]; then
            echo no token set, not uploading
        else
            python -m pip install \
            git+https://github.com/Anaconda-Platform/anaconda-client.git@be1e14936a8e947da94d026c990715f0596d7043
            # sdists are located under dist folder when built through setup.py
            if compgen -G "./dist/*.gz"; then
                echo "Found sdist"
                anaconda -q -t ${TOKEN} upload --skip -u ${ANACONDA_ORG} ./dist/*.gz
            elif compgen -G "./wheelhouse/*.whl"; then
                echo "Found wheel"
                anaconda -q -t ${TOKEN} upload --skip -u ${ANACONDA_ORG} ./wheelhouse/*.whl
            else
                echo "Files do not exist"
                return 1
            fi
            echo "PyPI-style index: https://pypi.anaconda.org/$ANACONDA_ORG/simple"
        fi
    fi
}
